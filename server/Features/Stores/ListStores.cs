using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// GET /api/stores — list all active stores with GPS coordinates.
/// </summary>
public static class ListStores
{
    public static async Task<IResult> HandleAsync(AppDbContext db, CancellationToken ct)
    {
        var stores = await db.Stores
            .Where(s => s.IsActive == true)
            .OrderBy(s => s.Name)
            .Select(s => new StoreDto(
                s.Id, s.Name, s.Address, s.AreaCode,
                s.GpsLat, s.GpsLng, s.IsActive, s.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(stores);
    }
}
