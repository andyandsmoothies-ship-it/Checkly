using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// Enforces S9 (1 store_manager per store) and S10 (1 area_manager per area).
/// Call before assigning a user to a store or area role.
/// </summary>
public static class RoleAssignmentGuard
{
    /// <summary>
    /// S9: Checks if a store already has a store_manager assigned.
    /// Returns the existing SM's profile ID if one exists, null otherwise.
    /// </summary>
    public static async Task<Guid?> FindExistingStoreManager(
        AppDbContext db, Guid storeId, Guid? excludeUserId, CancellationToken ct)
    {
        var existing = await db.Profiles
            .AsNoTracking()
            .Where(p => p.StoreId == storeId)
            .Join(db.AppUserRoles,
                  p => p.Id,
                  r => r.UserId,
                  (p, r) => new { p.Id, r.Role })
            .Where(x => x.Role == "store_manager")
            .Where(x => excludeUserId == null || x.Id != excludeUserId)
            .Select(x => (Guid?)x.Id)
            .FirstOrDefaultAsync(ct);

        return existing;
    }

    /// <summary>
    /// S10: Checks if an area already has an area_manager assigned.
    /// Returns the existing AM's profile ID if one exists, null otherwise.
    /// </summary>
    public static async Task<Guid?> FindExistingAreaManager(
        AppDbContext db, Guid areaId, Guid? excludeUserId, CancellationToken ct)
    {
        var existing = await db.Profiles
            .AsNoTracking()
            .Where(p => p.AreaId == areaId)
            .Join(db.AppUserRoles,
                  p => p.Id,
                  r => r.UserId,
                  (p, r) => new { p.Id, r.Role })
            .Where(x => x.Role == "area_manager")
            .Where(x => excludeUserId == null || x.Id != excludeUserId)
            .Select(x => (Guid?)x.Id)
            .FirstOrDefaultAsync(ct);

        return existing;
    }

    /// <summary>
    /// Checks if a store already has an area_manager assigned via ProfileStoreAssignments.
    /// Returns the existing AM's profile ID if one exists, null otherwise.
    /// </summary>
    public static async Task<Guid?> FindExistingAreaManagerForStore(
        AppDbContext db, Guid storeId, Guid? excludeUserId, CancellationToken ct)
    {
        var existing = await db.ProfileStoreAssignments
            .AsNoTracking()
            .Where(a => a.StoreId == storeId)
            .Join(db.AppUserRoles,
                  a => a.ProfileId,
                  r => r.UserId,
                  (a, r) => new { a.ProfileId, r.Role })
            .Where(x => x.Role == "area_manager")
            .Where(x => excludeUserId == null || x.ProfileId != excludeUserId)
            .Select(x => (Guid?)x.ProfileId)
            .FirstOrDefaultAsync(ct);

        return existing;
    }
}
