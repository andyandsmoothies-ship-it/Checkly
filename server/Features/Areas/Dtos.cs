namespace Checkly.Api.Features.Areas;

/// <summary>Areas endpoint DTOs.</summary>
public sealed record AreaDto(
    Guid Id,
    string Name,
    string? Description,
    bool IsActive,
    DateTimeOffset CreatedAt);
