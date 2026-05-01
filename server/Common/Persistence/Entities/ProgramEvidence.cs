namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Evidence submitted by a Store Manager for a ProgramAssignment.
/// Write-once: immutable after submission. No xmin needed.
/// Maps to: public.program_evidence
/// </summary>
public sealed class ProgramEvidence
{
    public Guid Id { get; set; }
    public Guid AssignmentId { get; set; }

    /// <summary>Nullable: criteria may be deleted after evidence is recorded.</summary>
    public Guid? CriteriaId { get; set; }

    /// <summary>Denormalized label snapshot at submit time.</summary>
    public string CriteriaLabel { get; set; } = string.Empty;

    public string Value { get; set; } = string.Empty;

    /// <summary>Optional. Storage URL of uploaded photo, or a client-local key for offline sync.</summary>
    public string? PhotoLocalKey { get; set; }

    public DateTimeOffset CreatedAt { get; set; }

    // Navigation
    public ProgramAssignment? Assignment { get; set; }
}
