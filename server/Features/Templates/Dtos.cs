namespace Checkly.Api.Features.Templates;

/// <summary>
/// DTOs for template API responses.
/// </summary>
public sealed record TemplateDto(
    Guid Id,
    string Title,
    string? Description,
    string Type,
    int Version,
    string? ScoringLogicConfig,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public sealed record TemplateTreeDto(
    Guid Id,
    string Title,
    string? Description,
    string Type,
    int Version,
    string? ScoringLogicConfig,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    List<GroupDto> Groups);

public sealed record GroupDto(
    Guid Id,
    string Title,
    string? Description,
    decimal? Weight,
    decimal? MaxDeductionPoints,
    decimal? MinusPerFault,
    int OrderIndex,
    string? Metadata,
    List<GroupDto> Children,
    List<CriterionDto> Criteria);

public sealed record CriterionDto(
    Guid Id,
    string Label,
    string? Description,
    string InputType,
    decimal? PointsWeight,
    bool IsCcp,
    bool IsRisk,
    int OrderIndex,
    string? Metadata);

public sealed record CreateTemplateRequest(
    string Title,
    string Type,
    string? Description,
    string? ScoringLogicConfig);
