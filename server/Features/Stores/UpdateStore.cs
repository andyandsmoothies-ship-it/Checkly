using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// PUT /api/stores/{id} — update store metadata (AdminOnly).
/// Updates mutable fields: Name, Address, AreaCode, GpsLat, GpsLng, IsActive.
/// </summary>
public static class UpdateStore
{
    public record Request(
        string? Name,
        string? Address,
        string? AreaCode,
        decimal? GpsLat,
        decimal? GpsLng,
        bool? IsActive);

    public static async Task<IResult> HandleAsync(Guid id, Request request, AppDbContext db)
    {
        var store = await db.Stores.FindAsync(id);
        if (store is null)
            return Results.NotFound();

        if (request.Name != null)
            store.Name = request.Name.Trim();
        if (request.Address != null)
            store.Address = request.Address.Trim();
        if (request.AreaCode != null)
            store.AreaCode = request.AreaCode.Trim();
        if (request.GpsLat.HasValue)
            store.GpsLat = request.GpsLat;
        if (request.GpsLng.HasValue)
            store.GpsLng = request.GpsLng;
        if (request.IsActive.HasValue)
            store.IsActive = request.IsActive.Value;

        store.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();

        return Results.Ok(new
        {
            id = store.Id,
            name = store.Name,
            address = store.Address,
            areaCode = store.AreaCode,
            isActive = store.IsActive,
        });
    }
}
