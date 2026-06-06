using System.Security.Claims;
using System.Text.Json;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// PUT /api/admin/users/{id} — update user role, store assignment, or area assignment.
/// Enforces S9 (1 SM per store) and supports direct AM store assignments.
/// </summary>
public static class UpdateUser
{
    public record Request(
        string? FullName,
        string? Role,
        Guid? StoreId,
        Guid[]? AssignedStoreIds,
        bool ForceReassign = false);

    private static readonly HashSet<string> ValidRoles = ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        Guid id,
        JsonElement requestJson,
        ClaimsPrincipal user,
        AppDbContext db,
        UserManager<AppUser> userManager,
        CancellationToken ct)
    {
        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var request = requestJson.Deserialize<Request>(options);
        if (request is null)
            return TypedResults.BadRequest(new { error = "Invalid request payload" });

        bool hasStoreId = requestJson.TryGetProperty("storeId", out _);
        bool hasAssignedStoreIds = requestJson.TryGetProperty("assignedStoreIds", out _);
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        // Validate role if provided
        if (request.Role != null && !ValidRoles.Contains(request.Role))
            return TypedResults.BadRequest(new { error = $"Invalid role. Must be one of: {string.Join(", ", ValidRoles)}" });

        var profile = await db.Profiles.FirstOrDefaultAsync(p => p.Id == id, ct);
        if (profile is null)
            return TypedResults.NotFound(new { error = "User not found" });

        var userRole = await db.AppUserRoles.FirstOrDefaultAsync(r => r.UserId == id, ct);
        if (userRole is null)
            return TypedResults.NotFound(new { error = "User role not found" });

        var effectiveRole = request.Role ?? userRole.Role;

        // Prevent self-demotion
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (id == callerId && effectiveRole != "admin")
            return TypedResults.BadRequest(new { error = "Cannot demote your own admin account. Have another admin perform this action." });

        string? previousManagerName = null;

        // S9: 1 SM per store
        if (effectiveRole == "store_manager" && request.StoreId.HasValue)
        {
            var existingSm = await RoleAssignmentGuard.FindExistingStoreManager(
                db, request.StoreId.Value, id, ct);
            if (existingSm.HasValue)
            {
                if (!request.ForceReassign)
                {
                    var existingName = await db.Profiles.Where(p => p.Id == existingSm.Value)
                        .Select(p => p.FullName).FirstOrDefaultAsync(ct);
                    return TypedResults.Conflict(new
                    {
                        error = "Store already has a store manager assigned",
                        existingManagerId = existingSm.Value,
                        existingManagerName = existingName,
                    });
                }
                // Force reassign: null out old SM's StoreId
                var oldSm = await db.Profiles.FirstOrDefaultAsync(p => p.Id == existingSm.Value, ct);
                if (oldSm != null)
                {
                    previousManagerName = oldSm.FullName;
                    oldSm.StoreId = null;
                    oldSm.UpdatedAt = DateTimeOffset.UtcNow;
                }
            }
        }

        // Apply updates
        if (request.Role != null)
            userRole.Role = request.Role;

        string? storeName = null;
        if (effectiveRole != "store_manager")
        {
            profile.StoreId = null;
        }
        else if (hasStoreId)
        {
            if (request.StoreId.HasValue)
            {
                var targetStore = await db.Stores.AsNoTracking()
                    .FirstOrDefaultAsync(s => s.Id == request.StoreId.Value, ct);
                if (targetStore is null)
                    return TypedResults.BadRequest(new { error = "Store not found" });
                if (targetStore.IsActive == false)
                    return TypedResults.BadRequest(new { error = "Cannot assign user to a deactivated store" });

                profile.StoreId = request.StoreId;
                storeName = targetStore.Name;
            }
            else
            {
                profile.StoreId = null;
            }
        }
        else if (profile.StoreId.HasValue)
        {
            storeName = await db.Stores.AsNoTracking()
                .Where(s => s.Id == profile.StoreId.Value)
                .Select(s => s.Name)
                .FirstOrDefaultAsync(ct);
        }

        if (effectiveRole != "area_manager")
        {
            var existingAssignments = await db.ProfileStoreAssignments
                .Where(a => a.ProfileId == id)
                .ToListAsync(ct);
            if (existingAssignments.Count > 0)
            {
                db.ProfileStoreAssignments.RemoveRange(existingAssignments);
            }
        }

        var targetStoreIds = new HashSet<Guid>();
        if (effectiveRole == "area_manager")
        {
            if (hasAssignedStoreIds)
            {
                var assignedStoreIds = request.AssignedStoreIds ?? Array.Empty<Guid>();
                targetStoreIds.UnionWith(assignedStoreIds);

                if (targetStoreIds.Count > 0)
                {
                    var existingStoreIds = await db.Stores
                        .AsNoTracking()
                        .Where(s => targetStoreIds.Contains(s.Id))
                        .Select(s => s.Id)
                        .ToListAsync(ct);

                    if (existingStoreIds.Count != targetStoreIds.Count)
                        return TypedResults.BadRequest(new { error = "One or more assigned stores do not exist" });

                    foreach (var storeId in targetStoreIds)
                    {
                        var existingAm = await RoleAssignmentGuard.FindExistingAreaManagerForStore(
                            db, storeId, id, ct);
                        if (existingAm.HasValue)
                        {
                            if (!request.ForceReassign)
                            {
                                var existingName = await db.Profiles.Where(p => p.Id == existingAm.Value)
                                    .Select(p => p.FullName).FirstOrDefaultAsync(ct);
                                var targetStoreName = await db.Stores.Where(s => s.Id == storeId).Select(s => s.Name).FirstOrDefaultAsync(ct);
                                return TypedResults.Conflict(new
                                {
                                    error = "Store already has an area manager assigned",
                                    existingManagerId = existingAm.Value,
                                    existingManagerName = existingName,
                                    storeName = targetStoreName
                                });
                            }

                            // Force reassign: remove existing AM's assignment to this store
                            var oldAssignment = await db.ProfileStoreAssignments
                                .FirstOrDefaultAsync(a => a.StoreId == storeId && a.ProfileId == existingAm.Value, ct);
                            if (oldAssignment != null)
                            {
                                db.ProfileStoreAssignments.Remove(oldAssignment);
                                if (previousManagerName == null)
                                {
                                    previousManagerName = await db.Profiles.Where(p => p.Id == existingAm.Value)
                                        .Select(p => p.FullName).FirstOrDefaultAsync(ct);
                                }
                            }
                        }
                    }
                }

                var existingAssignments = await db.ProfileStoreAssignments
                    .Where(a => a.ProfileId == id)
                    .ToListAsync(ct);

                var toRemove = existingAssignments
                    .Where(a => !targetStoreIds.Contains(a.StoreId))
                    .ToList();
                if (toRemove.Count > 0)
                    db.ProfileStoreAssignments.RemoveRange(toRemove);

                var assignedStoreSet = existingAssignments
                    .Select(a => a.StoreId)
                    .ToHashSet();

                var now = DateTimeOffset.UtcNow;
                var toAdd = targetStoreIds
                    .Where(storeId => !assignedStoreSet.Contains(storeId))
                    .Select(storeId => new ProfileStoreAssignment
                    {
                        ProfileId = id,
                        StoreId = storeId,
                        CreatedAt = now,
                    });
                db.ProfileStoreAssignments.AddRange(toAdd);
            }
            else
            {
                var currentAssignments = await db.ProfileStoreAssignments
                    .Where(a => a.ProfileId == id)
                    .Select(a => a.StoreId)
                    .ToListAsync(ct);
                targetStoreIds.UnionWith(currentAssignments);
            }
        }

        if (!string.IsNullOrWhiteSpace(request.FullName))
            profile.FullName = request.FullName.Trim();

        profile.UpdatedAt = DateTimeOffset.UtcNow;

        // Log the admin action
        var logMessage = request.ForceReassign && previousManagerName != null
            ? $"Updated user {profile.FullName} ({profile.Email}): role={effectiveRole}, transferred from {previousManagerName}"
            : $"Updated user {profile.FullName} ({profile.Email}): role={effectiveRole}";

        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = callerId,
            Action = request.ForceReassign ? "transfer_role" : "update_user",
            Category = "admin",
            EntityType = "user",
            EntityId = id,
            Message = logMessage,
            Path = $"/api/admin/users/{id}",
            Level = "info",
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync(ct);

        // F2 Fix: Invalidate all existing tokens for this user immediately on role change.
        // Any JWT issued before this moment will be rejected by the OnTokenValidated hook.
        if (request.Role != null)
        {
            var appUser = await userManager.FindByIdAsync(id.ToString());
            if (appUser is not null)
            {
                // Set to 2 seconds ago to avoid JWT second-level precision truncation issues
                // when tokens are generated immediately after role updates.
                appUser.InvalidateTokensBefore = DateTimeOffset.UtcNow.AddSeconds(-2);
                await userManager.UpdateAsync(appUser);
            }
        }

        return TypedResults.Ok(new
        {
            id = profile.Id,
            role = userRole.Role,
            storeId = profile.StoreId,
            storeName,
            assignedStoreIds = effectiveRole == "area_manager" ? targetStoreIds.ToArray() : null,
            transferred = request.ForceReassign && previousManagerName != null,
            previousManagerName,
        });
    }
}
