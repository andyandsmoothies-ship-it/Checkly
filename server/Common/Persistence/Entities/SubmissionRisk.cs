namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// A triggered instance of a GlobalRisk linked to a specific submission.
/// Maps to: public.submission_risks (7 columns)
/// Risks are immutable once created — no UpdatedAt field.
/// </summary>
public sealed class SubmissionRisk
{
    public Guid Id { get; set; }
    public Guid SubmissionId { get; set; }
    public Guid GlobalRiskId { get; set; }
    public Guid? TriggeredById { get; set; }
    public string? Note { get; set; }
    public DateTimeOffset TriggeredAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    // Navigation properties
    public Submission Submission { get; set; } = null!;
    public GlobalRisk GlobalRisk { get; set; } = null!;
}
