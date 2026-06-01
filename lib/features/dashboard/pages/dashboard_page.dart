import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/widgets/checkly_fab.dart';
import '../../admin/widgets/schedule_audit_form.dart';
import '../../auth/manager/auth_manager.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/constants/user_persona.dart';
import '../manager/dashboard_manager.dart';
import 'widgets/admin_dashboard_variant.dart';
import 'widgets/auditor_dashboard_variant.dart';
import 'widgets/dashboard_error_view.dart';
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
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Assign Task',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(sheetContext),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ScheduleAuditForm(
                onSuccess: () {
                  Navigator.maybePop(sheetContext);
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
    final persona = UserPersona.fromRole(_di<AuthManager>().currentUser?.role);

    return Scaffold(
      floatingActionButton: ChecklyFab(
        canAssignTask: _di<PolicyManager>().can(AppCapabilities.programsCreate),
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: ListenableBuilder(
                listenable: _manager,
                builder: (context, _) =>
                    Greeting(persona: persona, isSyncing: _manager.isSyncing, lastSync: _manager.lastSync),
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
                  DashboardErrorState e => DashboardErrorView(
                    message: e.message,
                    onRetry: () => _manager.loadStats(),
                  ),
                  AuditorDashboardState s => AuditorDashboardVariant(
                    state: s,
                    onRefresh: () => _manager.loadStats(showLoading: false),
                  ),
                  ManagerDashboardState s => ManagerDashboardVariant(
                    state: s,
                    persona: persona,
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
  final UserPersona persona;
  final bool isSyncing;
  final DateTime? lastSync;
  const Greeting({required this.persona, this.isSyncing = false, this.lastSync, super.key});

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
    final String title = switch (persona) {
      UserPersona.admin => 'Platform Overview',
      UserPersona.areaManager => 'Area Overview',
      _ => 'Store Overview',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              personalizedGreeting.toUpperCase(),
              style: AppFonts.displayStyle(
                fontSize: 11,
                color: AppColors.wolf,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            if (isSyncing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.seaSponge,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.turtle, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFF388E3C),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SYNCING',
                      style: AppFonts.displayStyle(
                        fontSize: 9,
                        color: const Color(0xFF388E3C),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            else if (lastSync != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.blueJay.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync, size: 10, color: AppColors.humpback),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(lastSync!),
                      style: AppFonts.displayStyle(
                        fontSize: 9,
                        color: AppColors.humpback,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppFonts.displayStyle(
            fontSize: 22,
            color: AppColors.eel,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
