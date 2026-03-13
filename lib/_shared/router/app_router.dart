import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/manager/auth_manager.dart';
import '../../features/auth/model/auth_state.dart';
import '../../features/auth/pages/login_page.dart';
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
import '../../features/profile/pages/activity_history_page.dart';
import '../../features/analytics/pages/analytics_page.dart';
import '../../features/stores/pages/store_dashboard_page.dart';
import '../../features/templates/pages/template_builder_page.dart';

final _di = GetIt.instance;

/// Application router with auth guard.
final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: _di<AuthManager>(),
  redirect: _authRedirect,
  routes: [
    // ---------- Auth ----------
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

    // ---------- Shell (bottom nav — 5 tabs) ----------
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/audits',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          path: '/actions',
          builder: (context, state) => const ActionPlansPage(),
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
      ),
    ),
    GoRoute(
      path: '/actions/:id',
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
      builder: (context, state) => const UserManagementPage(),
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
      path: '/activity',
      builder: (context, state) => const ActivityHistoryPage(),
    ),

    // Legacy redirect: /history → /audits
    GoRoute(path: '/history', redirect: (_, _) => '/audits'),

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
  ],
);

/// Auth redirect guard.
/// Redirects unauthenticated users to /login.
/// Redirects non-admin users away from /admin/* routes to /home.
String? _authRedirect(BuildContext context, GoRouterState state) {
  final auth = _di<AuthManager>();
  final isAuthenticated = auth.authState.value == AuthState.authenticated;
  final isOnLogin = state.matchedLocation == '/login';

  if (auth.authState.value == AuthState.loading) return null;
  if (!isAuthenticated && !isOnLogin) return '/login';
  if (isAuthenticated && isOnLogin) return '/home';

  // Admin role guard: non-admin users cannot access /admin/* routes
  if (isAuthenticated && state.matchedLocation.startsWith('/admin')) {
    final role = auth.currentUser?.role;
    if (role != 'admin') return '/home';
  }

  return null;
}

/// Main shell with 5-tab bottom navigation matching PWA.
/// Tabs: Home | Audits | Actions | Templates | Profile
class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  static int _indexFromLocation(String location) {
    if (location.startsWith('/audits')) return 1;
    if (location.startsWith('/actions')) return 2;
    if (location.startsWith('/templates')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // /home
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/audits');
            case 2:
              context.go('/actions');
            case 3:
              context.go('/templates');
            case 4:
              context.go('/profile');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_turned_in_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in),
            label: 'Audits',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Actions',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
