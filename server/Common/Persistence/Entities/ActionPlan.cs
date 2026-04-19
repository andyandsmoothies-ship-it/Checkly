namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Corrective actions from failed audit criteria.
/// Maps to: public.action_plans (22 columns)
/// Status check: 'open', 'in_progress', 'pending_verify', 'closed', 'overdue'
/// </summary>
public sealed class ActionPlan
{
    public Guid Id { get; set; }
    public Guid? AnswerId { get; set; }
    public Guid? SubmissionId { get; set; }
    public Guid? StoreId { get; set; }
    public Guid? StoreManagerId { get; set; }
    public string CriteriaLabel { get; set; } = string.Empty;
    public string GroupTitle { get; set; } = string.Empty;
    public string? PlanDescription { get; set; }
    public string? EvidencePhotoUrl { get; set; }
    public string? EvidenceNote { get; set; }
    public string Status { get; set; } = "open";
    public DateTimeOffset? Deadline { get; set; }
    public DateTimeOffset? ClosedAt { get; set; }
    public Guid? VerifiedBy { get; set; }
    public DateTimeOffset? VerifiedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public string? RootCause { get; set; }
    public string? CorrectionPlan { get; set; }

    // Snapshot fields
    public string? StoreName { get; set; }
    public string? StoreManagerName { get; set; }
    public string? VerifierName { get; set; }
    public DateTimeOffset? EvidenceSubmittedAt { get; set; }
    public string? EvidenceSubmittedByName { get; set; }

    // Navigation properties
    public Answer? Answer { get; set; }
    public Submission? Submission { get; set; }
    public Store? Store { get; set; }
}
