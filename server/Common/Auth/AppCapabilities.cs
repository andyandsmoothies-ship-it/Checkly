namespace Checkly.Api.Common.Auth;

/// <summary>
/// Canonical PBAC capability string constants.
///
/// These constants are the single source of truth for all capability identifiers
/// used in RequireCapability() guards and Flutter UI permission checks.
///
/// RULE: AdminAccess is a UI-Signal Only constant.
/// It MUST NEVER be passed to RequireCapability() on a C# route.
/// It exists solely so Flutter can check one value to show/hide the Admin Console.
///
/// RULE: AnalyticsArea is reserved for Slice 2.
/// The 'analytics:area' DB row does not exist until the Slice 2 migration runs.
/// </summary>
public static class AppCapabilities
{
    // ── UI Signal Only ────────────────────────────────────────────────────────
    // Flutter reads this to show/hide the Admin Console button.
    // NEVER apply to a C# RequireCapability() route guard.
    public const string AdminAccess = "admin:access";

    // ── Granular Action Gates ─────────────────────────────────────────────────
    // These are safe to use in RequireCapability() on C# endpoints.

    public const string TemplatesCreate = "templates:create";
    public const string TemplatesUpdate = "templates:update";
    public const string TemplatesDelete = "templates:delete";
    public const string StoresWrite = "stores:write";
    public const string AreasWrite = "areas:write";
    public const string UsersManage = "users:manage";
    public const string AnalyticsAdmin = "analytics:admin";
    public const string AnalyticsArea = "analytics:area";  // Seeded in Slice 2 migration
    public const string SubmissionsList = "submissions:list";
    public const string SubmissionsCreate = "submissions:create";
    public const string SubmissionsReview = "submissions:review";
    public const string AdminManageRoles = "admin:manage_roles";

    // ── Action Plan Transitions ───────────────────────────────────────────────
    // Imperative checks inside UpdateActionPlan.HandleAsync — not route-level guards.
    public const string ActionPlansWrite  = "action_plans:write";   // store_manager: submit evidence
    public const string ActionPlansVerify = "action_plans:verify";  // auditor/area_manager: close or reject
}
