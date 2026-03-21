using Checkly.Api.Common;
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
        var includeInactive = httpContext.Request.Query["includeInactive"].FirstOrDefault();
        var areaIdParam = httpContext.Request.Query["areaId"].FirstOrDefault();

        var query = db.Stores.AsQueryable();

        // Default: only active stores (unless includeInactive or assignable_as filter)
        if (string.IsNullOrEmpty(assignableAs) && !string.Equals(includeInactive, "true", StringComparison.OrdinalIgnoreCase))
            query = query.Where(s => s.IsActive == true);

        if (!string.IsNullOrEmpty(search))
            query = query.Where(s =>
                s.Name.Contains(search) ||
                (s.Area != null && s.Area.Name.Contains(search)));

        // Filter by area
        if (Guid.TryParse(areaIdParam, out var areaId))
            query = query.Where(s => s.AreaId == areaId);

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

        // Pagination (defaults: page 1, 50 items, max 200)
        var page = int.TryParse(httpContext.Request.Query["page"], out var pg) ? Math.Max(1, pg) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 200) : 50;

        var total = await query.CountAsync(ct);

        var stores = await query
            .OrderBy(s => s.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new StoreDto(
                s.Id, s.Name, s.Address, s.AreaId,
                s.Area != null ? s.Area.Name : null,
                smLookup.Where(m => m.StoreId == s.Id).Select(m => m.FullName).FirstOrDefault(),
                s.GpsLat, s.GpsLng, s.IsActive, s.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new PagedResult<StoreDto>(stores, total, page, pageSize));
    }
}
