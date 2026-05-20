using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Reference;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// PUT /api/stores/{id} — update store metadata (AdminOnly).
/// Updates mutable fields: Name, Address, GpsLat, GpsLng, IsActive.
/// </summary>
public static class UpdateStore
{
    public record Request(
        string? Name,
        string? Address,
        decimal? GpsLat,
        decimal? GpsLng,
        bool? IsActive,
        // SL-1: Structured address fields
        string? Province,
        string? District,
        string? Ward,
        string? Street);

    public static async Task<IResult> HandleAsync(Guid id, Request request, ClaimsPrincipal user, AppDbContext db, CancellationToken ct)
    {
        var store = await db.Stores.FindAsync([id], ct);
        if (store is null)
            return Results.NotFound();

        if (request.Name != null)
            store.Name = request.Name.Trim();
        if (request.Address != null)
            store.Address = request.Address.Trim();

        if (request.GpsLat.HasValue)
            store.GpsLat = request.GpsLat;
        if (request.GpsLng.HasValue)
            store.GpsLng = request.GpsLng;
        if (request.IsActive.HasValue)
            store.IsActive = request.IsActive.Value;

        // SL-1: Province validation
        if (request.Province is not null && !VietnamLocations.IsValidProvince(request.Province))
            return Results.BadRequest(new { error = $"Province '{request.Province}' is not a valid Vietnam administrative province." });

        // SL-1: Street length validation
        if (request.Street?.Length > 200)
            return Results.BadRequest(new { error = "Street must not exceed 200 characters" });

        // SL-1: Patch Address2 when any address field is provided
        if (request.Province is not null || request.District is not null
            || request.Ward is not null || request.Street is not null)
        {
            store.Address2 ??= new StoreAddress();
            if (request.Province is not null) store.Address2.Province = request.Province.Trim();
            if (request.District is not null) store.Address2.District = request.District.Trim();
            if (request.Ward is not null) store.Address2.Ward = request.Ward.Trim();
            if (request.Street is not null) store.Address2.Street = request.Street.Trim();
        }

        store.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);
        AuditLogger.Log(db, user, "store_updated", "Store", store.Id,
            message: $"Store '{store.Name}' updated",
            userEmail: user.FindFirstValue(ClaimTypes.Email));
        await db.SaveChangesAsync(ct);



        return Results.Ok(new
        {
            id = store.Id,
            name = store.Name,
            address = store.Address,
            isActive = store.IsActive,
            // SL-1: Address fields in response
            addressProvince = store.Address2?.Province,
            addressDistrict = store.Address2?.District,
            addressWard = store.Address2?.Ward,
            addressStreet = store.Address2?.Street,
        });
    }
}
