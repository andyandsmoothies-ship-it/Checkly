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

        var query = db.Stores.Where(s => s.IsActive == true);

        if (!string.IsNullOrEmpty(search))
            query = query.Where(s =>
                s.Name.Contains(search) ||
                (s.Area != null && s.Area.Name.Contains(search)));

        var stores = await query
            .OrderBy(s => s.Name)
            .Take(50)
            .Select(s => new StoreDto(
                s.Id, s.Name, s.Address, s.AreaId,
                s.GpsLat, s.GpsLng, s.IsActive, s.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(stores);
    }
}
