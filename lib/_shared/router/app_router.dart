import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/manager/auth_manager.dart';
import '../../features/auth/model/auth_state.dart';
import '../constants/app_capabilities.dart';
import '../services/policy_manager.dart';
import '../services/sync_engine.dart';
import '../theme/app_theme.dart';
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
import '../../features/notifications/pages/notification_drawer_page.dart';
import '../../features/audit/pages/survey_results_page.dart';
import '../database/dao/outbox_dao.dart';

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

    // ---------- Shell (bottom nav — 5 tabs) ----------
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
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
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationDrawerPage(),
    ),
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

    // Legacy redirects: old routes → new routes
    GoRoute(path: '/history', redirect: (_, _) => '/activity'),
    GoRoute(path: '/audits', redirect: (_, _) => '/activity'),
    GoRoute(path: '/actions', redirect: (_, _) => '/plans'),

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
  if (isAuthenticated && state.matchedLocation.startsWith('/admin')) {
    if (!_di<PolicyManager>().can(AppCapabilities.adminAccess)) return '/home';
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
    if (!isReadOnlyDetail && !_di<PolicyManager>().can(AppCapabilities.templatesCreate)) {
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
  return 0; // /home
}

/// Main shell with 5-tab bottom navigation matching PWA.
/// Tabs: Home | Audits | Actions | Templates | Profile
class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = shellIndexFromLocation(location);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          child,
          // --- Pillar D: Exhausted Sync Data Safety Net ---
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: StreamBuilder<int>(
              stream: _di<OutboxDao>().watchExhaustedCount(),
              initialData: 0,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Theme.of(context).colorScheme.error,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$count unsynced record${count > 1 ? 's' : ''} exhausted',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            // Show confirmation dialog before deleting permanently
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Discard Corrupted Audits?'),
                                content: const Text(
                                  'This will permanently delete the failed audits from this device. '
                                  'They cannot be recovered.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                                    child: Text(
                                      'Discard',
                                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _di<OutboxDao>().discardExhausted();
                            }
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Discard permanently',
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            // Tap to requeue: clears nextRetryAt and retryCount
                            await _di<OutboxDao>().requeueExhausted();
                            // Trigger sync cycle explicitly so records don't just sit there
                            _di<SyncEngine>().requestSync();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('RETRY'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.8),
              border: Border(
                top: BorderSide(
                  color: AppTheme.sageGray.withValues(alpha: 0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.grid_view,
                  label: 'HOME',
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: Icons.assignment,
                  label: 'ACTIVITY',
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/activity'),
                ),
                _NavItem(
                  icon: Icons.fact_check,
                  label: 'PLANS',
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/plans'),
                ),
                _NavItem(
                  icon: Icons.description_outlined,
                  label: 'TEMPLATES',
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/templates'),
                ),
                _NavItem(
                  icon: Icons.account_circle,
                  label: 'PROFILE',
                  isActive: currentIndex == 4,
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
