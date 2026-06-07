namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Audit headers with scores and GPS.
/// Maps to: public.submissions (27 columns)
/// Status check: 'scheduled', 'draft', 'completed', 'pending_approval', 'approved', 'rejected'
/// ReviewStatus check: 'approved', 'rejected'
/// </summary>
public sealed class Submission
{
    public Guid Id { get; set; }
    public Guid? ProgramAssignmentId { get; set; }
    public Guid? TemplateId { get; set; }
    public Guid? AuditorId { get; set; }
    public Guid? StoreId { get; set; }
    public string Status { get; set; } = "draft";
    public string? ScoringMode { get; set; }
    public string ScoreDirection { get; set; } = "down";
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
    public string? TemplateType { get; set; }
    public string? DisplayNoun { get; set; }
    public string? ApproverName { get; set; }
    public string? ReviewStatus { get; set; }

    public Guid? AreaManagerId { get; set; }
    public string? AreaManagerName { get; set; }
    public Guid? StoreManagerId { get; set; }
    public string? StoreManagerName { get; set; }

    // Template versioning — frozen template tree at submission creation
    public string? TemplateSnapshot { get; set; }
    public int? TemplateVersion { get; set; }

    // Dual-layer scoring — raw points captured from ScoringVerifier (accumulation mode only)
    public decimal? RawEarnedPoints { get; set; }
    public decimal? RawMaxPoints { get; set; }
    public bool? IsWeighted { get; set; }
    public bool? IsGeofenceBypassed { get; set; }
    public int? DistanceMetersOff { get; set; }

    public string? VoidReason { get; set; }
    public DateTimeOffset? VoidedAt { get; set; }

    /// <summary>Optimistic concurrency token (PostgreSQL xmin).</summary>
    public uint RowVersion { get; set; }

    // Navigation properties
    public Template? Template { get; set; }
    public Store? Store { get; set; }
    public ProgramAssignment? ProgramAssignment { get; set; }
    public ICollection<Answer> Answers { get; set; } = [];
    public ICollection<ActionPlan> ActionPlans { get; set; } = [];
    public ICollection<SubmissionRisk> SubmissionRisks { get; set; } = [];
}
