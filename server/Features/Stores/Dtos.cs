namespace Checkly.Api.Features.Stores;

/// <summary>
/// DTOs for store API responses.
/// </summary>
public sealed record StoreDto(
    Guid Id,
    string Name,
    string? Address,
    string? ManagerName,
    string? AreaManagerName,
    decimal? GpsLat,
    decimal? GpsLng,
    bool? IsActive,
    DateTimeOffset CreatedAt,
    // SL-1: Structured address fields (nullable — populated by B1 migration backfill)
    string? AddressProvince,
    string? AddressDistrict,
    string? AddressWard,
    string? AddressStreet);

