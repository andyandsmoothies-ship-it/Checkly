import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/exceptions/app_error.dart';
import '../../../_shared/services/error_display_service.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/section_header.dart';
import '../../dashboard/manager/dashboard_manager.dart';
import '../manager/admin_dashboard_manager.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import 'widgets/admin_menu_item.dart';
import 'widgets/kpi_card.dart';

final _di = GetIt.instance;

/// Admin Dashboard — stats grid + 5 navigation menu items.
/// Only accessible by admin role users.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final DashboardManager _manager;
  late final AdminDashboardManager _countsManager;

  @override
  void initState() {
    super.initState();
    _manager = _di<DashboardManager>();
    _countsManager = _di.isRegistered<AdminDashboardManager>()
        ? _di<AdminDashboardManager>()
        : AdminDashboardManager();
    _countsManager.addListener(_onCountsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manager.loadStats();
      _countsManager.loadCounts();
    });
  }

  @override
  void dispose() {
    _countsManager.removeListener(_onCountsChanged);
    super.dispose();
  }

  void _onCountsChanged() {
    if (!mounted) return;
    if (_countsManager.error != null && !_countsManager.isLoading) {
      _di<ErrorDisplayService>().show(const AppError(code: 'unknown'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pm = _di<PolicyManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('System Management')),
      body: ListenableBuilder(
        listenable: Listenable.merge([_manager, _countsManager]),
        builder: (context, _) {
          final isLoading = _manager.isLoading || _countsManager.isLoading;
          final adminState = _manager.dashboardState is AdminDashboardState
              ? _manager.dashboardState as AdminDashboardState
              : null;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: RefreshIndicator(
                onRefresh: () async {
                  _manager.loadStats(showLoading: false);
                  _countsManager.loadCounts();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Subtitle
                    const SectionHeader('SYSTEM MANAGEMENT'),
                    const SizedBox(height: 12),

                    if (_countsManager.error != null && !isLoading)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: StrokeCard(
                          color: const Color(0xFFFFEBEB),
                          borderColor: AppColors.destructive,
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.destructive),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Failed to load counts. Pull down to retry.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.destructive,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppColors.destructive),
                                onPressed: () {
                                  _manager.loadStats(showLoading: false);
                                  _countsManager.loadCounts();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Premium 2x2 Grid of KPIs with prominent numbers and custom colors
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        KpiCard(
                          icon: Icons.people,
                          label: 'USERS',
                          value: isLoading
                              ? '—'
                              : '${_countsManager.userCount}',
                          iconColor: AppColors.humpback,
                          backgroundColor: const Color(0xFFDDF4FF),
                          borderColor: AppColors.blueJay,
                        ),
                        KpiCard(
                          icon: Icons.store,
                          label: 'STORES',
                          value: isLoading
                              ? '—'
                              : '${_countsManager.storeCount}',
                          iconColor: const Color(0xFF388E3C),
                          backgroundColor: AppColors.seaSponge,
                          borderColor: AppColors.turtle,
                        ),
                        KpiCard(
                          icon: Icons.description,
                          label: 'TEMPLATES',
                          value: isLoading
                              ? '—'
                              : '${_countsManager.templateCount}',
                          iconColor: AppColors.beetle,
                          backgroundColor: const Color(0xFFFBE4FF),
                          borderColor: AppColors.starfish,
                        ),
                        KpiCard(
                          icon: Icons.hourglass_empty,
                          label: 'OPEN PLANS',
                          value: isLoading
                              ? '—'
                              : '${adminState?.openActionPlans ?? 0}',
                          iconColor: AppColors.fox,
                          backgroundColor: AppColors.canary,
                          borderColor: AppColors.duck,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Group 1: Core Management ──
                    const SectionHeader('CORE'),
                    const SizedBox(height: 8),
                    StrokeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: _buildCoreMenuItems(context, theme, pm),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Group 2: Operations ──
                    const SectionHeader('OPERATIONS'),
                    const SizedBox(height: 8),
                    StrokeCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: _buildOperationsMenuItems(context, theme, pm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds Core management items: User, Store, Role Management, User Groups.
  List<Widget> _buildCoreMenuItems(
    BuildContext context,
    ThemeData theme,
    PolicyManager pm,
  ) {
    final divider = Divider(
      height: 1,
      indent: 64,
      color: theme.colorScheme.outlineVariant,
    );
    final gated = <({String? cap, AdminMenuItem item})>[
      (
        cap: AppCapabilities.usersManage,
        item: AdminMenuItem(
          icon: Icons.people,
          title: 'User Management',
          subtitle: 'Manage auditors & managers',
          onTap: () => context.push('/admin/users'),
          iconColor: AppColors.humpback,
          backgroundColor: const Color(0xFFDDF4FF),
          borderColor: AppColors.blueJay,
        ),
      ),
      (
        cap: AppCapabilities.storesWrite,
        item: AdminMenuItem(
          icon: Icons.store,
          title: 'Store Management',
          subtitle: 'Manage store locations',
          onTap: () => context.push('/admin/stores'),
          iconColor: const Color(0xFF388E3C),
          backgroundColor: AppColors.seaSponge,
          borderColor: AppColors.turtle,
        ),
      ),
      (
        cap: AppCapabilities.adminManageRoles,
        item: AdminMenuItem(
          icon: Icons.manage_accounts,
          title: 'Role Management',
          subtitle: 'Manage role capabilities',
          onTap: () => context.push('/admin/roles'),
          iconColor: AppColors.beetle,
          backgroundColor: const Color(0xFFFBE4FF),
          borderColor: AppColors.starfish,
        ),
      ),
      (
        cap: null,
        item: AdminMenuItem(
          icon: Icons.group_work_outlined,
          title: 'User Groups',
          subtitle: 'Manage user group assignments',
          onTap: () => context.push('/admin/user-groups'),
          iconColor: AppColors.fox,
          backgroundColor: AppColors.canary,
          borderColor: AppColors.duck,
        ),
      ),
    ];
    return _interleave(gated, divider, pm);
  }

  /// Builds Operations items: Approvals, Schedule, Analytics, Logs, Risk.
  List<Widget> _buildOperationsMenuItems(
    BuildContext context,
    ThemeData theme,
    PolicyManager pm,
  ) {
    final divider = Divider(
      height: 1,
      indent: 64,
      color: theme.colorScheme.outlineVariant,
    );
    final gated = <({String? cap, AdminMenuItem item})>[
      (
        cap: null,
        item: AdminMenuItem(
          icon: Icons.assignment,
          title: 'Audit Approvals',
          subtitle: 'Review submitted audits',
          onTap: () => context.push('/admin/approvals'),
          iconColor: const Color(0xFF388E3C),
          backgroundColor: AppColors.seaSponge,
          borderColor: AppColors.turtle,
        ),
      ),
      (
        cap: null,
        item: AdminMenuItem(
          icon: Icons.event_note,
          title: 'Schedule Audit',
          subtitle: 'Delegate audits to auditors',
          onTap: () => context.push('/admin/schedule'),
          iconColor: AppColors.humpback,
          backgroundColor: const Color(0xFFDDF4FF),
          borderColor: AppColors.blueJay,
        ),
      ),
      (
        cap: null,
        item: AdminMenuItem(
          icon: Icons.bar_chart,
          title: 'Analytics',
          subtitle: 'View performance data',
          onTap: () => context.push('/analytics'),
          iconColor: AppColors.cardinal,
          backgroundColor: AppColors.walkingFish,
          borderColor: AppColors.flamingo,
        ),
      ),
      (
        cap: AppCapabilities.analyticsBod,
        item: AdminMenuItem(
          icon: Icons.analytics_outlined,
          title: 'BOD Analytics',
          subtitle: 'View executive performance data',
          onTap: () => context.push('/analytics/bod'),
          iconColor: AppColors.fox,
          backgroundColor: AppColors.canary,
          borderColor: AppColors.duck,
        ),
      ),
      (
        cap: null,
        item: AdminMenuItem(
          icon: Icons.warning_amber,
          title: 'System Logs',
          subtitle: 'Monitor application events',
          onTap: () => context.push('/admin/logs'),
          iconColor: AppColors.cardinal,
          backgroundColor: AppColors.walkingFish,
          borderColor: AppColors.flamingo,
        ),
      ),
      (
        cap: AppCapabilities.globalRisksManage,
        item: AdminMenuItem(
          icon: Icons.shield_outlined,
          title: 'Global Risk Management',
          subtitle: 'Configure risk categories for audits',
          onTap: () => context.push('/admin/global-risks'),
          iconColor: AppColors.beetle,
          backgroundColor: const Color(0xFFFBE4FF),
          borderColor: AppColors.starfish,
        ),
      ),
    ];
    return _interleave(gated, divider, pm);
  }

  /// Filters gated items by capability and interleaves dividers.
  List<Widget> _interleave(
    List<({String? cap, AdminMenuItem item})> gated,
    Divider divider,
    PolicyManager pm,
  ) {
    final visible = gated
        .where((e) => e.cap == null || pm.can(e.cap!))
        .map((e) => e.item)
        .toList();
    final widgets = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      widgets.add(visible[i]);
      if (i < visible.length - 1) widgets.add(divider);
    }
    return widgets;
  }
}
