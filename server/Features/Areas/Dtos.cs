namespace Checkly.Api.Features.Areas;

/// <summary>Areas endpoint DTOs.</summary>
public sealed record AreaDto(
    Guid Id,
    string Name,
    string? Description,
    int StoreCount,
    int UserCount,
    DateTimeOffset CreatedAt);
