namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// Item-14 / CRIT-02: Centralized action plan lifecycle status constants.
/// These values are stored as raw strings in the DB <c>action_plans.status</c> column.
/// Use these constants for all comparisons and assignments. NEVER use raw string literals.
/// IMPORTANT: Do NOT change these values without a corresponding database migration.
/// </summary>
public static class ActionPlanStatus
{
    public const string Open = "open";
    public const string InProgress = "in_progress";
    public const string Closed = "closed";
    public const string Overdue = "overdue";
}
