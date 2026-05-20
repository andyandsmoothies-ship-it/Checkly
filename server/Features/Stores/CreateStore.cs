using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Reference;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// POST /api/stores — create a new store (AdminOnly).
/// SL-1: Now accepts optional structured address fields (Province, District, Ward, Street).
/// Province, when provided, is validated against VietnamLocations.Provinces.
/// </summary>
public static class CreateStore
{
    public record Request(
        string Name,
        string? Address,
        decimal? GpsLat,
        decimal? GpsLng,
        // SL-1: Structured address fields
        string? Province,
        string? District,
        string? Ward,
        string? Street);

    public static async Task<IResult> HandleAsync(Request request, ClaimsPrincipal user, AppDbContext db, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return Results.BadRequest(new { error = "Store name is required" });

        if (request.Name.Length > 200)
            return Results.BadRequest(new { error = "Name must not exceed 200 characters" });

        if (request.Address?.Length > 500)
            return Results.BadRequest(new { error = "Address must not exceed 500 characters" });

        // SL-1: Province validation — TC-SL1-02
        if (request.Province is not null && !VietnamLocations.IsValidProvince(request.Province))
            return Results.BadRequest(new { error = $"Province '{request.Province}' is not a valid Vietnam administrative province." });

        // SL-1: Street length validation — Gap1
        if (request.Street?.Length > 200)
            return Results.BadRequest(new { error = "Street must not exceed 200 characters" });



        var now = DateTimeOffset.UtcNow;
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Address = request.Address?.Trim(),

            GpsLat = request.GpsLat,
            GpsLng = request.GpsLng,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
            // SL-1: Structured address — TC-SL1-08
            Address2 = request.Province is not null || request.District is not null
                        || request.Ward is not null || request.Street is not null
                ? new StoreAddress
                {
                    Province = request.Province?.Trim(),
                    District = request.District?.Trim(),
                    Ward = request.Ward?.Trim(),
                    Street = request.Street?.Trim(),
                }
                : null,
        };

        db.Stores.Add(store);
        await db.SaveChangesAsync(ct);
        AuditLogger.Log(db, user, "store_created", "Store", store.Id,
            message: $"Store '{store.Name}' created",
            userEmail: user.FindFirstValue(ClaimTypes.Email));
        await db.SaveChangesAsync(ct);

        return Results.Created($"/api/stores/{store.Id}", new
        {
            id = store.Id,
            name = store.Name,
            address = store.Address,
            // SL-1: Address fields in response — TC-SL1-08
            addressProvince = store.Address2?.Province,
            addressDistrict = store.Address2?.District,
            addressWard = store.Address2?.Ward,
            addressStreet = store.Address2?.Street,
        });
    }
}
