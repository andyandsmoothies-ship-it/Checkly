using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// GET /api/stores/{id} — returns a single active store.
/// Requires authentication (any role).
/// Returns 404 if the store doesn't exist or is deactivated.
/// </summary>
public static class GetStore
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        AppDbContext db,
        CancellationToken ct)
    {
        // Subquery: SM name per store (mirrors ListStores projection)
        var smLookup = db.Profiles
            .Join(db.AppUserRoles, p => p.Id, r => r.UserId,
                  (p, r) => new { p.StoreId, p.FullName, r.Role })
            .Where(x => x.Role == "store_manager" && x.StoreId != null);

        var amLookup = db.ProfileStoreAssignments
            .Join(db.Profiles, a => a.ProfileId, p => p.Id,
                  (a, p) => new { a.StoreId, a.ProfileId, p.FullName })
            .Join(db.AppUserRoles, x => x.ProfileId, r => r.UserId,
                  (x, r) => new { x.StoreId, x.FullName, r.Role })
            .Where(x => x.Role == "area_manager");

        var store = await db.Stores
            .AsNoTracking()
            .Where(s => s.Id == id && s.IsActive == true)
            .Select(s => new StoreDto(
                s.Id, s.Name, s.Address,
                smLookup.Where(m => m.StoreId == s.Id).Select(m => m.FullName).FirstOrDefault(),
                s.GpsLat, s.GpsLng, s.IsActive, s.CreatedAt,
                // SL-1: Structured address fields
                s.Address2 != null ? s.Address2.Province : null,
                s.Address2 != null ? s.Address2.District : null,
                s.Address2 != null ? s.Address2.Ward : null,
                s.Address2 != null ? s.Address2.Street : null))
            .FirstOrDefaultAsync(ct);

        return store is null
            ? TypedResults.NotFound(new { error = "Store not found" })
            : TypedResults.Ok(store);
    }
}
