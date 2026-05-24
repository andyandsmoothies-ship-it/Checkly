import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/manager/auth_manager.dart';
import '../constants/app_capabilities.dart';
import '../services/policy_manager.dart';
import 'auth_redirect.dart';
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
import '../../features/admin/pages/role_list_page.dart';
import '../../features/admin/pages/role_detail_page.dart';
import '../../features/analytics/pages/analytics_page.dart';
import '../../features/analytics/pages/bod_analytics_page.dart';
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
import '../../features/programs/pages/program_create_wizard_page.dart';
import '../../features/programs/pages/program_assignment_list_page.dart';
import '../../features/programs/pages/area_campaign_list_page.dart';

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
      redirect: (context, state) {
        final pm = _di<PolicyManager>();
        if (!pm.can(AppCapabilities.submissionsCreate)) return '/home';
        return null;
      },
      builder: (context, state) => StoreSelectorPage(
        templateId: state.uri.queryParameters['templateId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/audit',
      redirect: (context, state) {
        // Allow resuming an existing draft — the draft already exists locally
        // and blocking it would cause data loss if capabilities changed after creation.
        final params = state.uri.queryParameters;
        final isResume =
            params['autoResume'] == 'true' || params['submissionId'] != null;
        if (isResume) return null;
        final pm = _di<PolicyManager>();
        if (params['programAssignmentId'] != null) {
          if (!pm.can(AppCapabilities.programsExecute)) return '/home';
          return null;
        }
        if (!pm.can(AppCapabilities.submissionsCreate)) return '/home';
        return null;
      },
      builder: (context, state) => AuditFormPage(
        templateId: state.uri.queryParameters['templateId'] ?? '',
        storeId: state.uri.queryParameters['storeId'] ?? '',
        autoResume: state.uri.queryParameters['autoResume'] == 'true',
        targetSubmissionId: state.uri.queryParameters['submissionId'],
        programAssignmentId: state.uri.queryParameters['programAssignmentId'],
      ),
    ),
    GoRoute(
      path: '/plans/:id',
      builder: (context, state) =>
          ActionPlanDetailPage(actionPlanId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/programs/new',
      redirect: (context, state) {
        final pm = _di<PolicyManager>();
        if (!pm.can(AppCapabilities.programsCreate)) return '/home';
        return null;
      },
      builder: (context, state) => const ProgramCreateWizardPage(),
    ),
    GoRoute(
      path: '/programs/assignments',
      builder: (context, state) => const ProgramAssignmentListPage(),
    ),
    GoRoute(
      path: '/programs/area-campaigns',
      builder: (context, state) => const AreaCampaignListPage(),
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
      builder: (context, state) => const StoreManagementPage(),
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
      redirect: (context, state) {
        final pm = _di<PolicyManager>();
        if (!pm.can(AppCapabilities.usersManage)) return '/home';
        return null;
      },
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
      path: '/analytics/bod',
      redirect: (context, state) {
        final pm = _di<PolicyManager>();
        if (!pm.can(AppCapabilities.analyticsBod)) return '/home';
        return null;
      },
      builder: (context, state) => const BodAnalyticsPage(),
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
