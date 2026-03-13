namespace Checkly.Api.Features.Areas;

/// <summary>Areas endpoint DTOs.</summary>
public sealed record AreaDto(
    Guid Id,
    string Name,
    string Code,
    bool IsActive,
    DateTimeOffset CreatedAt);
