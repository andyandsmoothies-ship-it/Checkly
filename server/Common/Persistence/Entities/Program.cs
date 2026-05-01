namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// A ChecklyProgram is an HQ-created compliance campaign.
/// It acts as the parent container; child ProgramAssignment rows
/// represent the per-store execution tasks.
/// Maps to: public.programs
/// Status values: 'active', 'completed', 'cancelled'
/// Note: Named 'ChecklyProgram' to avoid clash with top-level Program class.
/// </summary>
public sealed class ChecklyProgram
{
    public Guid Id { get; set; }
    public Guid TemplateId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public DateTimeOffset Deadline { get; set; }
    public string Status { get; set; } = "active";
    public Guid CreatedBy { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    /// <summary>Optimistic concurrency token (PostgreSQL xmin).</summary>
    public uint RowVersion { get; set; }

    // Navigation properties
    public Template? Template { get; set; }
    public ICollection<ProgramAssignment> Assignments { get; set; } = [];
}
