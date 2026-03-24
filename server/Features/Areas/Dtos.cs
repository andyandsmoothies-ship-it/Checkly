namespace Checkly.Api.Features.Areas;

/// <summary>Areas endpoint DTOs.</summary>
public sealed record AreaDto(
    Guid Id,
    string Name,
    string? Description,
    int StoreCount,
    string? ManagerName,
    DateTimeOffset CreatedAt,
    bool IsActive = true);
