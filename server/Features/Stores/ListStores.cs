using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// GET /api/stores — list all active stores with GPS coordinates.
/// </summary>
public static class ListStores
{
    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var search = httpContext.Request.Query["search"].FirstOrDefault();
        var assignableAs = httpContext.Request.Query["assignable_as"].FirstOrDefault();
        var exceptUser = httpContext.Request.Query["except_user"].FirstOrDefault();

        var query = db.Stores.AsQueryable();

        if (!string.IsNullOrEmpty(search))
            query = query.Where(s =>
                s.Name.Contains(search) ||
                (s.Area != null && s.Area.Name.Contains(search)));

        // Smart filter: only stores assignable to a specific role
        if (assignableAs == "store_manager")
        {
            // Only active stores
            query = query.Where(s => s.IsActive == true);

            // Exclude stores that already have a store_manager
            Guid? exceptUserId = null;
            if (Guid.TryParse(exceptUser, out var parsed))
                exceptUserId = parsed;

            // Subquery: store IDs that have an active store_manager (excluding except_user)
            var takenStoreIds = db.Profiles
                .Join(db.AppUserRoles, p => p.Id, r => r.UserId, (p, r) => new { p.StoreId, r.Role, p.Id })
                .Where(x => x.Role == "store_manager" && x.StoreId != null)
                .Where(x => exceptUserId == null || x.Id != exceptUserId)
                .Select(x => x.StoreId);

            query = query.Where(s => !takenStoreIds.Contains(s.Id));
        }

        // Subquery: SM name per store
        var smLookup = db.Profiles
            .Join(db.AppUserRoles, p => p.Id, r => r.UserId,
                  (p, r) => new { p.StoreId, p.FullName, r.Role })
            .Where(x => x.Role == "store_manager" && x.StoreId != null);

        var stores = await query
            .OrderBy(s => s.Name)
            .Take(50)
            .Select(s => new StoreDto(
                s.Id, s.Name, s.Address, s.AreaId,
                s.Area != null ? s.Area.Name : null,
                smLookup.Where(m => m.StoreId == s.Id).Select(m => m.FullName).FirstOrDefault(),
                s.GpsLat, s.GpsLng, s.IsActive, s.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(stores);
    }
}
