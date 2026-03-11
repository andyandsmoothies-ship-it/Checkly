namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Audit headers with scores and GPS.
/// Maps to: public.submissions (24 columns)
/// Status check: 'scheduled', 'draft', 'completed', 'pending_approval', 'approved', 'rejected'
/// ReviewStatus check: 'approved', 'rejected'
/// </summary>
public sealed class Submission
{
    public Guid Id { get; set; }
    public Guid? TemplateId { get; set; }
    public Guid? AuditorId { get; set; }
    public Guid? StoreId { get; set; }
    public string Status { get; set; } = "draft";
    public decimal? TotalScore { get; set; }
    public string? SectionScores { get; set; }
    public decimal? GpsLat { get; set; }
    public decimal? GpsLng { get; set; }
    public DateTimeOffset? GpsVerifiedAt { get; set; }
    public string? Notes { get; set; }
    public DateTimeOffset? ScheduledAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public Guid? ApprovedBy { get; set; }
    public DateTimeOffset? ApprovedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public DateTimeOffset? StartedAt { get; set; }
    public string? IdempotencyKey { get; set; }

    // Snapshot fields (denormalized at submission time)
    public string? AuditorName { get; set; }
    public string? AuditorEmail { get; set; }
    public string? StoreName { get; set; }
    public string? TemplateTitle { get; set; }
    public string? ApproverName { get; set; }
    public string? ReviewStatus { get; set; }

    // Navigation properties
    public Template? Template { get; set; }
    public Store? Store { get; set; }
    public ICollection<Answer> Answers { get; set; } = [];
    public ICollection<ActionPlan> ActionPlans { get; set; } = [];
}
