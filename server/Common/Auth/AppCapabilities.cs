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
///
/// ARCHITECTURE NOTE: Capabilities are NOT FIXED to specific roles. The PRD and DB 
/// Migrations represent "Factory Defaults". An Admin can dynamically assign or 
/// unassign ANY capability to ANY role via the UI at runtime.
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

    public const string UsersManage = "users:manage";
    public const string AnalyticsAdmin = "analytics:admin";
    public const string AnalyticsView = "analytics:view";
    public const string AnalyticsMyStats = "analytics:my_stats"; // OBS-5: auditor personal stats

    public const string SubmissionsList = "submissions:list";
    public const string SubmissionsCreate = "submissions:create";
    public const string SubmissionsReview = "submissions:review";
    public const string AdminManageRoles = "admin:manage_roles";
    public const string GlobalRisksManage = "global_risks:manage";
    public const string ProgramsCreate = "programs:create";
    public const string ProgramsList = "programs:list";
    public const string ProgramsAssignmentsMy = "programs:assignments_my"; // SM: view own store's assignments
    public const string ProgramsExecute = "programs:execute"; // submit evidence for assigned program work
    public const string ProgramsAssignmentsList = "programs:assignments_list"; // HQ/admin: view all assignments for a program
    public const string ProgramsReview = "programs:review"; // HQ/admin: reject or verify a submitted assignment
    public const string ProgramsManage = "programs:manage"; // HQ/admin: update mutable fields or archive a program

    // ── Action Plan Transitions ───────────────────────────────────────────────
    // Imperative checks inside UpdateActionPlan.HandleAsync — not route-level guards.
    public const string ActionPlansWrite = "action_plans:write";   // store_manager: submit evidence
    public const string ActionPlansVerify = "action_plans:verify";  // auditor/area_manager: close or reject
}
