using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common;

/// <summary>
/// Reusable IDOR guard for resource-scoped access (submissions, photos, program assignments, etc.).
/// Checks whether the current user has role-appropriate access to a resource identified by a ResourceScope.
/// </summary>
public static class ResourceAccessGuard
{
    /// <summary>
    /// Returns true if the user can access a resource described by the given scope.
    /// </summary>
    public static async Task<bool> CanAccessAsync(
        ClaimsPrincipal user, ResourceScope scope,
        AppDbContext db, CancellationToken ct)
    {
        if (!Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            return false;

        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";

        return role switch
        {
            "admin" => true,
            "auditor" => scope.OwnerId == userId,
            "store_manager" => await IsUserStoreAsync(userId, scope.StoreId, db, ct),
            "area_manager" => await IsUserAreaAsync(userId, scope.StoreId, scope.AreaId, db, ct),
            _ => false
        };
    }

    private static async Task<bool> IsUserStoreAsync(Guid userId, Guid? storeId, AppDbContext db, CancellationToken ct)
    {
        if (storeId is null) return false;
        var profile = await db.Profiles.AsNoTracking().FirstOrDefaultAsync(p => p.Id == userId, ct);
        return profile?.StoreId == storeId;
    }

    private static async Task<bool> IsUserAreaAsync(Guid userId, Guid? storeId, Guid? areaId, AppDbContext db, CancellationToken ct)
    {
        if (storeId is null && areaId is null) return false;
        var profile = await db.Profiles.AsNoTracking().FirstOrDefaultAsync(p => p.Id == userId, ct);
        if (profile?.AreaId is null) return false;

        if (areaId.HasValue) return areaId.Value == profile.AreaId;

        // Single query instead of two separate round-trips
        return await db.Stores.AsNoTracking()
            .AnyAsync(s => s.Id == storeId && s.AreaId == profile.AreaId, ct);
    }

    /// <summary>
    /// Returns true if the user is permitted to assign an audit to a different user.
    /// Synchronous fast-path: admin → always true, others → always false.
    /// Use CanDelegateAsync for area_manager role to enforce area-scoped IDOR check.
    /// </summary>
    public static bool CanDelegate(ClaimsPrincipal user)
    {
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";
        return role is "admin";
    }

    /// <summary>
    /// Returns true if the user is permitted to delegate a submission for the given store.
    /// - Admin: always true (no DB hit).
    /// - Area Manager: only if the target store belongs to the manager's assigned area (DB check).
    /// - All others: false.
    /// </summary>
    public static async Task<bool> CanDelegateAsync(
        ClaimsPrincipal user, ResourceScope scope,
        AppDbContext db, CancellationToken ct)
    {
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";

        if (role == "admin") return true;

        if (role == "area_manager")
        {
            if (!Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                return false;

            return await IsUserAreaAsync(userId, scope.StoreId, scope.AreaId, db, ct);
        }

        return false;
    }
}
