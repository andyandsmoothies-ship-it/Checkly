namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Relational row for one section's score within a submission.
/// Replaces JSONB ParseSectionBreakdown — written during FinalizeSubmission.
/// Maps to: public.submission_section_scores
/// </summary>
public sealed class SubmissionSectionScore
{
    public Guid Id { get; set; }
    public Guid SubmissionId { get; set; }
    public Guid? StoreId { get; set; }
    public Guid? TemplateId { get; set; }
    public string SectionTitle { get; set; } = "";
    public decimal Score { get; set; }
    public decimal MaxScore { get; set; }
    public decimal? Ratio { get; set; }
    public bool IsCcpFailed { get; set; }
    public decimal? Weight { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    // Navigation
    public Submission? Submission { get; set; }
}
