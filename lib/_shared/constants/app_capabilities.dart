/// Strongly-typed PBAC capability constants.
/// Mirrors `AppCapabilities.cs` on the backend to eliminate naked strings.
///
///
/// Anti-Magic-String Mandate: Never use raw capability strings in production code.
/// Always use these constants so the compiler catches typos at build time.
///
/// ARCHITECTURE NOTE: Capabilities are NOT FIXED to specific roles. The PRD matrix
/// represents "Factory Defaults". An Admin can dynamically assign or unassign ANY
/// capability to ANY role via the UI at runtime.
class AppCapabilities {
  AppCapabilities._(); // prevent instantiation

  static const adminAccess = 'admin:access';
  static const templatesCreate = 'templates:create';
  static const templatesUpdate = 'templates:update';
  static const templatesDelete = 'templates:delete';
  static const storesWrite = 'stores:write';
  static const usersManage = 'users:manage';
  static const analyticsAdmin = 'analytics:admin';
  static const submissionsList = 'submissions:list';
  static const adminManageRoles = 'admin:manage_roles';
  // Phase 3 PBAC additions
  static const submissionsCreate = 'submissions:create';
  static const submissionsReview = 'submissions:review';
  static const actionPlansWrite = 'action_plans:write';
  static const actionPlansVerify = 'action_plans:verify';
  static const programsCreate = 'programs:create';
  static const programsList = 'programs:list';
  static const programsExecute = 'programs:execute';
  static const programsManage = 'programs:manage';
  static const programsReview = 'programs:review';
  static const programsAssignmentsMy = 'programs:assignments_my';
  static const programsAssignmentsList = 'programs:assignments_list';
  static const globalRisksManage = 'global_risks:manage';
  static const analyticsView = 'analytics:view';

  // --- Implicit Admin Access Domain ---
  // Any capability in this set grants implicit admin:access via PolicyManager.
  // MAINTENANCE: When adding a new admin-scope capability above, also add it here.
  static const Set<String> adminDomainCapabilities = {
    templatesCreate,
    templatesUpdate,
    templatesDelete,
    storesWrite,
    usersManage,
    analyticsAdmin,
    adminManageRoles,
    programsCreate,
    globalRisksManage,
  };
}
