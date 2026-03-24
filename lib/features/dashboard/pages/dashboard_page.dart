import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/checkly_fab.dart';
import '../../admin/pages/schedule_audit_page.dart';
import '../../auth/manager/auth_manager.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../manager/dashboard_manager.dart';
import '../../notifications/widgets/notification_bell.dart';
import 'widgets/dashboard_variants.dart';

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
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
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
              child: ScheduleAuditForm(onSuccess: () => Navigator.pop(context)),
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
        onNewAudit: () => context.push('/templates'),
        onAssignTask: () => _showScheduleSheet(context),
      ),
      body: Column(
        children: [
          // ── Compact header: greeting + bell ──
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Expanded(child: _Greeting(role: role)),
                  const NotificationBell(),
                ],
              ),
            ),
          ),
          // ── Role-scoped body ──
          Expanded(
            child: ListenableBuilder(
              listenable: _manager,
              builder: (context, _) {
                return switch (_manager.dashboardState) {
                  DashboardLoading() => const DashboardLoadingView(),
                  AuditorDashboardState s => AuditorDashboardVariant(state: s),
                  ManagerDashboardState s => ManagerDashboardVariant(
                    state: s,
                    role: role,
                  ),
                  AdminDashboardState s => AdminDashboardVariant(state: s),
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

class _Greeting extends StatelessWidget {
  final String role;
  const _Greeting({required this.role});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final name =
        GetIt.instance<AuthManager>().currentUser?.email.split('@').first ?? '';
    final timeGreeting = hour < 12
        ? 'Good Morning'
        : hour < 18
        ? 'Good Afternoon'
        : 'Good Evening';
    final greeting = name.isNotEmpty ? '$timeGreeting, $name' : timeGreeting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppFonts.serifStyle(fontSize: 22, color: Colors.black87),
        ),
      ],
    );
  }
}
