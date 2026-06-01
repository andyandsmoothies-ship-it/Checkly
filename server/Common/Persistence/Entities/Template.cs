namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Master audit template definitions. Soft delete via IsActive.
/// Maps to: public.templates (10 columns)
/// Type check: 'QC', 'Training', 'General'
/// </summary>
public sealed class Template
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Type { get; set; } = string.Empty;
    public int Version { get; set; }
    public string? ScoringLogicConfig { get; set; }
    public string? DisplayNoun { get; set; }
    public string GeofenceMode { get; set; } = "none";
    public int GeofenceRadiusMeters { get; set; } = 100;
    public bool IsActive { get; set; }
    public Guid? CreatedBy { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    /// <summary>Optimistic concurrency token (PostgreSQL xmin).</summary>
    public uint RowVersion { get; set; }

    // Navigation properties
    public ICollection<Group> Groups { get; set; } = [];
    public ICollection<Submission> Submissions { get; set; } = [];
    public ICollection<TemplateAssignment> Assignments { get; set; } = [];
}
