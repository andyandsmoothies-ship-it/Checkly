namespace Checkly.Api.Features.Programs;

/// <summary>
/// Item-14 / CRIT-01 (Org Audit): Centralized program lifecycle status constants.
/// These values are stored as raw strings in the DB <c>programs.status</c> column.
/// Use these constants for all comparisons and assignments. NEVER use raw string literals.
/// IMPORTANT: Do NOT change these values without a corresponding database migration.
/// </summary>
public static class ProgramStatus
{
    public const string Active = "active";
    public const string Cancelled = "cancelled";
    public const string Pending = "pending";
}

/// <summary>
/// Assignment status values for the <c>program_assignments.status</c> column.
/// </summary>
public static class AssignmentStatus
{
    public const string Pending = "pending";
    public const string InProgress = "in_progress";
    public const string Submitted = "submitted";
    public const string NeedsRevision = "needs_revision";
    public const string Verified = "verified";
    public const string Overdue = "overdue";
}
