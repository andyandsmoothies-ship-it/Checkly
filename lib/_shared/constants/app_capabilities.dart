/// Strongly-typed PBAC capability constants.
/// Mirrors `AppCapabilities.cs` on the backend to eliminate naked strings.
///
/// Anti-Magic-String Mandate: Never use raw capability strings in production code.
/// Always use these constants so the compiler catches typos at build time.
class AppCapabilities {
  AppCapabilities._(); // prevent instantiation

  static const adminAccess = 'admin:access';
  static const templatesCreate = 'templates:create';
  static const templatesUpdate = 'templates:update';
  static const templatesDelete = 'templates:delete';
  static const storesWrite = 'stores:write';
  static const areasWrite = 'areas:write';
  static const usersManage = 'users:manage';
  static const analyticsAdmin = 'analytics:admin';
  static const analyticsArea = 'analytics:area';
  static const submissionsList = 'submissions:list';
  static const adminManageRoles = 'admin:manage_roles';
  // Phase 3 PBAC additions
  static const submissionsCreate = 'submissions:create';
  static const submissionsReview = 'submissions:review';
  static const actionPlansWrite = 'action_plans:write';
  static const actionPlansVerify = 'action_plans:verify';
}
