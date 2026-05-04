using System.Security.Claims;
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
        Guid? AreaId,
        Guid? VirtualAreaId,
        Guid[]? AssignedStoreIds,
        bool ForceReassign = false);

    private static readonly HashSet<string> ValidRoles = ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        UserManager<AppUser> userManager,
        CancellationToken ct)
    {
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

        string? areaName = null;
        if (request.AreaId.HasValue || request.VirtualAreaId.HasValue)
        {
            var resolvedAreaId = request.AreaId ?? request.VirtualAreaId;
            var targetArea = await db.Areas.AsNoTracking()
                .FirstOrDefaultAsync(a => a.Id == resolvedAreaId!.Value, ct);
            if (targetArea is null)
                return TypedResults.BadRequest(new { error = "Area not found" });
            areaName = targetArea?.Name;
            profile.AreaId = resolvedAreaId;
        }

        var targetStoreIds = new HashSet<Guid>();
        if (effectiveRole == "area_manager")
        {
            if (request.VirtualAreaId.HasValue)
            {
                var virtualAreaStoreIds = await db.Stores
                    .AsNoTracking()
                    .Where(s => s.AreaId == request.VirtualAreaId.Value && s.IsActive == true)
                    .Select(s => s.Id)
                    .ToListAsync(ct);
                targetStoreIds.UnionWith(virtualAreaStoreIds);
            }

            if (request.AssignedStoreIds is not null)
            {
                targetStoreIds.UnionWith(request.AssignedStoreIds);

                if (targetStoreIds.Count > 0)
                {
                    var existingStoreIds = await db.Stores
                        .AsNoTracking()
                        .Where(s => targetStoreIds.Contains(s.Id))
                        .Select(s => s.Id)
                        .ToListAsync(ct);

                    if (existingStoreIds.Count != targetStoreIds.Count)
                        return TypedResults.BadRequest(new { error = "One or more assigned stores do not exist" });
                }
            }

            if (request.VirtualAreaId.HasValue || request.AssignedStoreIds is not null)
            {
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
                appUser.InvalidateTokensBefore = DateTimeOffset.UtcNow;
                await userManager.UpdateAsync(appUser);
            }
        }

        return TypedResults.Ok(new
        {
            id = profile.Id,
            role = userRole.Role,
            storeId = profile.StoreId,
            storeName,
            areaId = profile.AreaId,
            areaName,
            assignedStoreIds = effectiveRole == "area_manager" ? targetStoreIds.ToArray() : null,
            transferred = request.ForceReassign && previousManagerName != null,
            previousManagerName,
        });
    }
}
