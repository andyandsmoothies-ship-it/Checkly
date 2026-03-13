using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// POST /api/stores — create a new store (AdminOnly).
/// </summary>
public static class CreateStore
{
    public record Request(
        string Name,
        string? Address,
        Guid? AreaId,
        decimal? GpsLat,
        decimal? GpsLng);

    public static async Task<IResult> HandleAsync(Request request, AppDbContext db)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return Results.BadRequest(new { error = "Store name is required" });

        // Look up area to include areaName in the response
        Area? area = null;
        if (request.AreaId.HasValue)
            area = await db.Areas.AsNoTracking().FirstOrDefaultAsync(a => a.Id == request.AreaId.Value);

        var now = DateTimeOffset.UtcNow;
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Address = request.Address?.Trim(),
            AreaId = request.AreaId,
            GpsLat = request.GpsLat,
            GpsLng = request.GpsLng,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
        };

        db.Stores.Add(store);
        await db.SaveChangesAsync();

        return Results.Created($"/api/stores/{store.Id}", new
        {
            id = store.Id,
            name = store.Name,
            address = store.Address,
            areaId = store.AreaId,
            areaName = area?.Name,
        });
    }
}
