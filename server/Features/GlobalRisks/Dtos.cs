namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// Shared DTOs for GlobalRisk CRUD endpoints.
/// </summary>
public record GlobalRiskDto(
    Guid Id,
    string Label,
    string? Description,
    bool IsActive,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

public record CreateGlobalRiskRequest(string Label, string? Description);

public record UpdateGlobalRiskRequest(string? Label, string? Description, bool? IsActive);

public record SubmissionRiskDto(
    Guid Id,
    Guid SubmissionId,
    Guid GlobalRiskId,
    string GlobalRiskLabel,
    Guid? TriggeredById,
    DateTimeOffset TriggeredAt,
    DateTimeOffset CreatedAt);

public record TriggerSubmissionRiskRequest(Guid GlobalRiskId);

