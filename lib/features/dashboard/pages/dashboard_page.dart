import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/widgets/checkly_fab.dart';
import '../../admin/widgets/schedule_audit_form.dart';
import '../../auth/manager/auth_manager.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../manager/dashboard_manager.dart';
import 'widgets/admin_dashboard_variant.dart';
import 'widgets/auditor_dashboard_variant.dart';
import 'widgets/dashboard_loading_view.dart';
import 'widgets/manager_dashboard_variant.dart';

final _di = GetIt.instance;

/// Dashboard page — "The Checkly Stream" enterprise layout.
/// Compact header + Bento Box action cards + chronological submission feed.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = _di<DashboardManager>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manager.loadStats();
    });
  }

  void _showScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Assign Task',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ScheduleAuditForm(
                onSuccess: () {
                  Navigator.pop(sheetContext);
                  _manager.loadStats();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _di<AuthManager>().currentUser?.role ?? 'admin';

    return Scaffold(
      floatingActionButton: ChecklyFab(
        isAdmin: role == 'admin',
        canCreateSubmission: _di<PolicyManager>().can(
          AppCapabilities.submissionsCreate,
        ),
        onNewAudit: () => context.push('/templates'),
        onAssignTask: () => _showScheduleSheet(context),
      ),
      body: Column(
        children: [
          // ── Compact header: greeting ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Greeting(role: role),
            ),
          ),
          // ── Role-scoped body ──
          Expanded(
            child: ListenableBuilder(
              listenable: _manager,
              builder: (context, _) {
                return switch (_manager.dashboardState) {
                  DashboardLoading() => const DashboardLoadingView(),
                  AuditorDashboardState s => AuditorDashboardVariant(
                    state: s,
                    onRefresh: () => _manager.loadStats(showLoading: false),
                  ),
                  ManagerDashboardState s => ManagerDashboardVariant(
                    state: s,
                    role: role,
                    onRefresh: () => _manager.loadStats(showLoading: false),
                  ),
                  AdminDashboardState s => AdminDashboardVariant(
                    state: s,
                    onRefresh: () => _manager.loadStats(showLoading: false),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Greeting widget ──

@visibleForTesting
class Greeting extends StatelessWidget {
  final String role;
  const Greeting({required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final user = GetIt.instance<AuthManager>().currentUser;
    final name = user?.fullName ?? user?.email.split('@').first ?? '';
    final timeGreeting = hour < 12
        ? 'Good Morning'
        : hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';
    final personalizedGreeting = name.isNotEmpty
        ? '$timeGreeting, $name'
        : timeGreeting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          personalizedGreeting.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Store Overview',
          style: AppFonts.serifStyle(
            fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
