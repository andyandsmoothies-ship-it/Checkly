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
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public string? Metadata { get; set; }
    public string? CriteriaLabel { get; set; }

    // Navigation properties
    public Submission? Submission { get; set; }
    public Criterion? Criterion { get; set; }
    public ICollection<ActionPlan> ActionPlans { get; set; } = [];
}
