import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/manager/auth_manager.dart';
import '../../features/auth/model/auth_state.dart';
import '../constants/app_capabilities.dart';
import '../services/policy_manager.dart';
import 'main_shell.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/access_pending_page.dart';
import '../../features/templates/pages/template_list_page.dart';
import '../../features/templates/pages/template_detail_page.dart';
import '../../features/stores/pages/store_selector_page.dart';
import '../../features/audit/pages/audit_form_page.dart';
import '../../features/audit/pages/history_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/action_plans/pages/action_plans_page.dart';
import '../../features/action_plans/pages/action_plan_detail_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/admin/pages/admin_dashboard_page.dart';
import '../../features/admin/pages/audit_approval_page.dart';
import '../../features/admin/pages/user_management_page.dart';
import '../../features/admin/pages/store_management_page.dart';
import '../../features/admin/pages/system_logs_page.dart';
import '../../features/admin/pages/schedule_audit_page.dart';
import '../../features/admin/pages/area_management_page.dart';
import '../../features/admin/pages/role_list_page.dart';
import '../../features/admin/pages/role_detail_page.dart';
import '../../features/analytics/pages/analytics_page.dart';
import '../../features/stores/pages/store_dashboard_page.dart';
import '../../features/templates/pages/template_builder_page.dart';
import '../../features/templates/pages/template_wizard_page.dart';
import '../../features/notifications/pages/inbox_page.dart';
import '../../features/audit/pages/survey_results_page.dart';
import '../../features/user_groups/pages/user_group_list_page.dart';
import '../../features/admin/pages/global_risk_management_page.dart';
import '../../features/programs/pages/program_execution_page.dart';
import '../../features/programs/pages/program_list_page.dart';
import '../../features/programs/pages/program_dashboard_page.dart';

final _di = GetIt.instance;

/// Application router with auth guard.
final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _di<AuthManager>(),
  redirect: authRedirect,
  routes: [
    // ---------- Auth ----------
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/access-pending',
      builder: (context, state) => const AccessPendingPage(),
    ),

    // ---------- Shell (bottom nav — 6 tabs) ----------
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/activity',
          builder: (context, state) => HistoryPage(
            initialMonth: state.uri.queryParameters['month'],
            initialFilter: state.uri.queryParameters['filter'],
          ),
        ),
        GoRoute(
          path: '/plans',
          builder: (context, state) => ActionPlansPage(
            initialFilter: state.uri.queryParameters['filter'],
            initialSort: state.uri.queryParameters['sort'],
          ),
        ),
        GoRoute(
          path: '/templates',
          builder: (context, state) => const TemplateListPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(path: '/inbox', builder: (context, state) => const InboxPage()),
      ],
    ),

    // ---------- Detail routes (no bottom nav) ----------
    GoRoute(
      path: '/templates/new',
      builder: (context, state) => const TemplateBuilderPage(templateId: 'new'),
    ),
    GoRoute(
      path: '/templates/wizard',
      builder: (context, state) => const TemplateWizardPage(),
    ),
    GoRoute(
      path: '/templates/edit/:id',
      builder: (context, state) =>
          TemplateBuilderPage(templateId: state.pathParameters['id']!),
    ),
    // Legacy redirect: /notifications → /inbox (preserves deep links)
    GoRoute(path: '/notifications', redirect: (context, state) => '/inbox'),
    GoRoute(
      path: '/templates/:id',
      builder: (context, state) =>
          TemplateDetailPage(templateId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/stores/select',
      builder: (context, state) => StoreSelectorPage(
        templateId: state.uri.queryParameters['templateId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/audit',
      builder: (context, state) => AuditFormPage(
        templateId: state.uri.queryParameters['templateId'] ?? '',
        storeId: state.uri.queryParameters['storeId'] ?? '',
        autoResume: state.uri.queryParameters['autoResume'] == 'true',
        targetSubmissionId: state.uri.queryParameters['submissionId'],
      ),
    ),
    GoRoute(
      path: '/plans/:id',
      builder: (context, state) =>
          ActionPlanDetailPage(actionPlanId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/programs/:assignmentId',
      builder: (context, state) => ProgramExecutionPage(
        assignmentId: state.pathParameters['assignmentId']!,
      ),
    ),

    // ── Slice 3: HQ Review routes (online-only) ──
    GoRoute(
      path: '/programs',
      builder: (context, state) => const ProgramListPage(),
    ),
    GoRoute(
      path: '/programs/review/:programId',
      builder: (context, state) =>
          ProgramDashboardPage(programId: state.pathParameters['programId']!),
    ),

    // ---------- Admin routes ----------
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/admin/approvals',
      builder: (context, state) => const AuditApprovalPage(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => UserManagementPage(
        initialSearch: state.uri.queryParameters['search'],
      ),
    ),
    GoRoute(
      path: '/admin/stores',
      builder: (context, state) => StoreManagementPage(
        initialAreaId: state.uri.queryParameters['areaId'],
      ),
    ),
    GoRoute(
      path: '/admin/logs',
      builder: (context, state) => const SystemLogsPage(),
    ),
    GoRoute(
      path: '/admin/schedule',
      builder: (context, state) => const ScheduleAuditPage(),
    ),
    GoRoute(
      path: '/admin/areas',
      builder: (context, state) => const AreaManagementPage(),
    ),
    GoRoute(
      path: '/admin/roles',
      builder: (context, state) => const RoleListPage(),
    ),
    GoRoute(
      path: '/admin/roles/:role',
      builder: (context, state) =>
          RoleDetailPage(role: state.pathParameters['role']!),
    ),
    GoRoute(
      path: '/admin/user-groups',
      builder: (context, state) => const UserGroupListPage(),
    ),
    GoRoute(
      path: '/admin/global-risks',
      builder: (context, state) => const GlobalRiskManagementPage(),
    ),

    // Legacy redirects: old routes → new routes
    GoRoute(path: '/history', redirect: (_, _) => '/activity'),
    GoRoute(path: '/audits', redirect: (_, _) => '/activity'),
    GoRoute(path: '/actions', redirect: (_, _) => '/plans'),

    // Notification Deep Link redirects: backend ActionUrls → flutter routes
    GoRoute(path: '/action-plans', redirect: (_, _) => '/plans'),
    GoRoute(
      path: '/action-plans/:id',
      redirect: (context, state) => '/plans/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/submissions/:id',
      redirect: (context, state) => '/activity',
    ),

    // ---------- 6C: Analytics + Store Dashboard + Template Builder ----------
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsPage(),
    ),
    GoRoute(
      path: '/stores/:id/dashboard',
      builder: (context, state) =>
          StoreDashboardPage(storeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/templates/:id/builder',
      builder: (context, state) =>
          TemplateBuilderPage(templateId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/survey-results/:templateId',
      builder: (context, state) =>
          SurveyResultsPage(templateId: state.pathParameters['templateId']!),
    ),
  ],
);

/// Auth redirect guard.
/// Redirects unauthenticated users to /login.
/// Redirects non-admin users away from /admin/* routes to /home.
/// Redirects non-admin users away from /templates/* mutation routes to /home.
/// Read-only /templates/:id detail pages are whitelisted for all authenticated roles.
@visibleForTesting
String? authRedirect(BuildContext context, GoRouterState state) {
  final auth = _di<AuthManager>();
  final isAuthenticated = auth.authState.value == AuthState.authenticated;
  final isOnLogin = state.matchedLocation == '/login';

  if (auth.authState.value == AuthState.loading) return null;
  if (!isAuthenticated &&
      !isOnLogin &&
      state.matchedLocation != '/access-pending') {
    return '/login';
  }
  if (isAuthenticated && isOnLogin) {
    // No-role guard: users without a valid role see Access Pending
    final role = auth.currentUser?.role;
    if (role == null || role.isEmpty) return '/access-pending';
    return '/home';
  }

  // Admin capability guard: requires 'admin:access' UI-Signal capability.
  // This is the ONLY capability checked at the router prefix level.
  // Granular capability checks (e.g. admin:manage_roles) belong inside individual
  // admin pages/widgets — NOT here. Checking granulars here causes the
  // Group Policy Trap: a user with stores:write but not manage_roles gets locked out.
  // Fail-safe deny: empty capabilities → redirect to /home.
  //
  // Whitelist: /admin/approvals is also accessible to users with submissions:review
  // (Area Managers) without granting full admin:access to the entire /admin/* prefix.
  if (isAuthenticated && state.matchedLocation.startsWith('/admin')) {
    final pm = _di<PolicyManager>();
    final isApprovalRoute = state.matchedLocation == '/admin/approvals';
    final canReview = pm.can(AppCapabilities.submissionsReview);
    final hasAdminAccess = pm.can(AppCapabilities.adminAccess);

    if (isApprovalRoute && (hasAdminAccess || canReview)) {
      // Allow: user has either full admin or the specific review capability
    } else if (!isApprovalRoute && !hasAdminAccess) {
      return '/home';
    } else if (isApprovalRoute && !hasAdminAccess && !canReview) {
      return '/home';
    }
  }

  // Template mutation capability guard: requires 'templates:create' capability.
  // Default Deny: ALL /templates/* paths are mutations EXCEPT the exact read-only
  // detail path /templates/:id (exactly 3 path segments, not 'new' or 'wizard').
  if (isAuthenticated && state.matchedLocation.startsWith('/templates/')) {
    final parts = state.matchedLocation.split('/');
    // Whitelist: ['', 'templates', '<id>'] — must be exactly 3 segments
    // and the id segment cannot be a known mutation keyword.
    final isReadOnlyDetail =
        parts.length == 3 && parts[2] != 'new' && parts[2] != 'wizard';
    if (!isReadOnlyDetail &&
        !_di<PolicyManager>().can(AppCapabilities.templatesCreate)) {
      return '/home';
    }
  }

  // No-role guard on all app routes (except /access-pending and /login)
  if (isAuthenticated &&
      state.matchedLocation != '/access-pending' &&
      state.matchedLocation != '/login') {
    final role = auth.currentUser?.role;
    if (role == null || role.isEmpty) return '/access-pending';
  }

  return null;
}

@visibleForTesting
int shellIndexFromLocation(String location) {
  if (location.startsWith('/activity')) return 1;
  if (location.startsWith('/plans')) return 2;
  if (location.startsWith('/templates')) return 3;
  if (location.startsWith('/profile')) return 4;
  if (location.startsWith('/admin')) return 4;
  if (location.startsWith('/inbox')) return 5;
  return 0; // /home
}
