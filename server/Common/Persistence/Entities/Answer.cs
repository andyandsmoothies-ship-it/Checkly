namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Individual audit responses per criteria.
/// Maps to: public.answers (13 columns)
/// Value: 'conform', 'non_conform', 'na'
/// </summary>
public sealed class Answer
{
    public Guid Id { get; set; }
    public Guid? SubmissionId { get; set; }
    public Guid? CriteriaId { get; set; }
    public string? Value { get; set; }
    public decimal? NumericValue { get; set; }
    public string? Note { get; set; }
    public string? PhotoUrl { get; set; }
    public string? PhotoMetadata { get; set; }
    public bool IsRepeatedError { get; set; }

    /// <summary>
    /// Auditor-applied CCP escalation override at answer time.
    /// Persisted for back-office audit trail — explains why a section scored 0
    /// even if the template criterion was not originally flagged as CCP.
    /// </summary>
    public bool IsCcp { get; set; }

    /// <summary>
    /// Auditor-applied RISK escalation override at answer time.
    /// Persisted for back-office audit trail — explains why total score was forced to 0
    /// even if the answer value is 'conform'.
    /// </summary>
    public bool IsRisk { get; set; }

    /// <summary>
    /// Server-derived semantic failure flag. Set by FinalizeSubmission using ScoringVerifier.FailedCriteriaIds.
    /// Analytics-only — excluded from AnswerDto and AnswerInput (never sent by Flutter client).
    /// </summary>
    public bool IsFailure { get; set; }
    public int RepeatedFaults { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public string? Metadata { get; set; }
    public string? CriteriaLabel { get; set; }

    // Navigation properties
    public Submission? Submission { get; set; }
    public Criterion? Criterion { get; set; }
    public ICollection<ActionPlan> ActionPlans { get; set; } = [];
}
