namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// A ProgramAssignment is the per-store execution task generated when an HQ Admin
/// assigns a Program to a store. One Program → N ProgramAssignment rows.
/// Maps to: public.program_assignments
/// Status values: 'pending', 'submitted', 'needs_revision', 'verified'
/// Note: 'overdue' is COMPUTED in DTOs only (deadline &lt; now &amp;&amp; status == 'pending').
/// It is NOT stored in the DB to avoid stale data.
/// </summary>
public sealed class ProgramAssignment
{
    public Guid Id { get; set; }
    public Guid ProgramId { get; set; }
    public Guid StoreId { get; set; }
    public Guid AssignedById { get; set; }
    public Guid? AssigneeId { get; set; }
    public string Status { get; set; } = "pending";
    public DateTimeOffset? CompletedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    /// <summary>
    /// HQ rejection reason. Populated when status → 'needs_revision'.
    /// Cleared (set to null) when SM resubmits (status → 'submitted').
    /// </summary>
    public string? RejectionComment { get; set; }

    /// <summary>Timestamp set when HQ verifies. Null until status = 'verified'.</summary>
    public DateTimeOffset? VerifiedAt { get; set; }

    /// <summary>Optimistic concurrency token (PostgreSQL xmin).</summary>
    public uint RowVersion { get; set; }

    // Navigation properties
    public ChecklyProgram? Program { get; set; }
    public Store? Store { get; set; }
    public ICollection<Submission> Submissions { get; set; } = [];
}
