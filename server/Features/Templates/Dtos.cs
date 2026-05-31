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
    string? DisplayNoun,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public sealed record LintIssue(
    string RuleId,
    string Message,
    Guid? TargetId,
    string Severity);

public sealed record LintResult(
    List<LintIssue> Errors,
    List<LintIssue> Warnings);

public sealed record TemplateTreeDto(
    Guid Id,
    string Title,
    string? Description,
    string Type,
    int Version,
    string? ScoringLogicConfig,
    string? DisplayNoun,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    List<GroupDto> Groups,
    LintResult? LintResult = null);

public sealed record GroupDto(
    Guid Id,
    string Title,
    string? Description,
    decimal? Weight,
    decimal? MaxDeductionPoints,
    decimal? MinusPerFault,
    int OrderIndex,
    string? Metadata,
    List<string>? CategoryTags,
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
    decimal? MinusImpact,
    decimal? MaxDeductionPoints,
    int OrderIndex,
    string? Metadata,
    List<string>? CategoryTags);

public sealed record CreateTemplateRequest(
    string Title,
    string Type,
    string? Description,
    string? ScoringLogicConfig,
    string? DisplayNoun);
