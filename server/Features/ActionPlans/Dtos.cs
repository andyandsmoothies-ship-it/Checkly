namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// DTOs for action plan API.
/// </summary>
public sealed record CreateActionPlanRequest(
    Guid SubmissionId,
    Guid? AnswerId,
    string CriteriaLabel,
    string GroupTitle,
    string? PlanDescription,
    string? RootCause,
    string? CorrectionPlan,
    DateTimeOffset? Deadline);

public sealed record UpdateActionPlanRequest(
    string? PlanDescription,
    string? RootCause,
    string? CorrectionPlan,
    string? EvidencePhotoUrl,
    string? EvidenceNote,
    string? Status,
    DateTimeOffset? Deadline);

public sealed record ActionPlanDto(
    Guid Id,
    Guid? SubmissionId,
    Guid? StoreId,
    string? StoreName,
    Guid? StoreManagerId,
    string? StoreManagerName,
    string CriteriaLabel,
    string GroupTitle,
    string? PlanDescription,
    string? RootCause,
    string? CorrectionPlan,
    string? EvidencePhotoUrl,
    string? EvidenceNote,
    string Status,
    DateTimeOffset? Deadline,
    DateTimeOffset? ClosedAt,
    string? VerifierName,
    DateTimeOffset? EvidenceSubmittedAt,
    string? EvidenceSubmittedByName,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);
public sealed record AddCommentRequest(string Body);

public sealed record CommentDto(
    Guid Id,
    Guid UserId,
    string Body,
    DateTimeOffset CreatedAt);
