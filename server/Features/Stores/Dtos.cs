namespace Checkly.Api.Features.Stores;

/// <summary>
/// DTOs for store API responses.
/// </summary>
public sealed record StoreDto(
    Guid Id,
    string Name,
    string? Address,
    string? AreaCode,
    decimal? GpsLat,
    decimal? GpsLng,
    bool? IsActive,
    DateTimeOffset CreatedAt);
