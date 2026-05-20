namespace Checkly.Api.Features.Submissions;

/// <summary>
/// Item-14 / CRIT-02: Centralized submission lifecycle status constants.
/// These values are stored as raw strings in the DB <c>submissions.status</c> column.
/// Use these constants for all comparisons and assignments. NEVER use raw string literals.
/// IMPORTANT: Do NOT change these values without a corresponding database migration.
/// </summary>
public static class SubmissionStatus
{
    public const string Draft = "draft";
    public const string Scheduled = "scheduled";
    public const string Completed = "completed";
    public const string Voided = "voided";
}

/// <summary>
/// Review status values for the <c>submissions.review_status</c> column.
/// </summary>
public static class ReviewStatus
{
    public const string Approved = "approved";
    public const string Rejected = "rejected";
}
