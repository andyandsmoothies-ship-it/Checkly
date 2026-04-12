using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// PUT /api/admin/users/{id} — update user role, store assignment, or area assignment.
/// Enforces S9 (1 SM per store) and S10 (1 AM per area).
/// </summary>
public static class UpdateUser
{
    public record Request(string? FullName, string? Role, Guid? StoreId, Guid? AreaId, bool ForceReassign = false);

    private static readonly HashSet<string> ValidRoles = ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
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

        // S10: 1 AM per area
        if (effectiveRole == "area_manager" && request.AreaId.HasValue)
        {
            var existingAm = await RoleAssignmentGuard.FindExistingAreaManager(
                db, request.AreaId.Value, id, ct);
            if (existingAm.HasValue)
            {
                if (!request.ForceReassign)
                {
                    var existingName = await db.Profiles.Where(p => p.Id == existingAm.Value)
                        .Select(p => p.FullName).FirstOrDefaultAsync(ct);
                    return TypedResults.Conflict(new
                    {
                        error = "Area already has an area manager assigned",
                        existingManagerId = existingAm.Value,
                        existingManagerName = existingName,
                    });
                }
                // Force reassign: null out old AM's AreaId
                var oldAm = await db.Profiles.FirstOrDefaultAsync(p => p.Id == existingAm.Value, ct);
                if (oldAm != null)
                {
                    previousManagerName = oldAm.FullName;
                    oldAm.AreaId = null;
                    oldAm.UpdatedAt = DateTimeOffset.UtcNow;
                }
            }
        }

        // Apply updates
        if (request.Role != null)
            userRole.Role = request.Role;

        if (request.StoreId.HasValue)
        {
            var targetStore = await db.Stores.AsNoTracking()
                .FirstOrDefaultAsync(s => s.Id == request.StoreId.Value, ct);
            if (targetStore is null)
                return TypedResults.BadRequest(new { error = "Store not found" });
            if (targetStore.IsActive == false)
                return TypedResults.BadRequest(new { error = "Cannot assign user to a deactivated store" });

            profile.StoreId = request.StoreId;
        }

        if (request.AreaId.HasValue)
            profile.AreaId = request.AreaId;

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

        return TypedResults.Ok(new
        {
            id = profile.Id,
            role = userRole.Role,
            storeId = profile.StoreId,
            areaId = profile.AreaId,
            transferred = request.ForceReassign && previousManagerName != null,
            previousManagerName,
        });
    }
}
