import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/section_header.dart';
import '../../dashboard/manager/dashboard_manager.dart';
import '../manager/admin_dashboard_manager.dart';
import '../../../_shared/widgets/compact_status_panel.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We couldn\'t load the latest data. Please check your internet connection and refresh.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
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
              child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Subtitle
              const SectionHeader('SYSTEM MANAGEMENT'),

              // Dense stats panel
              CompactStatusPanel(
                metrics: [
                  StatRowData(
                    icon: Icons.people,
                    label: 'USERS',
                    value: isLoading ? '—' : '${_countsManager.userCount}',
                    iconColor: theme.colorScheme.primary,
                    onTap: () => context.push('/admin/users'),
                  ),
                  StatRowData(
                    icon: Icons.store,
                    label: 'STORES',
                    value: isLoading ? '—' : '${_countsManager.storeCount}',
                    iconColor: AppTheme.success,
                    onTap: () => context.push('/admin/stores'),
                  ),
                  StatRowData(
                    icon: Icons.description,
                    label: 'TEMPLATES',
                    value: isLoading ? '—' : '${_countsManager.templateCount}',
                    iconColor: AppTheme.info,
                    onTap: () {},
                  ),
                  StatRowData(
                    icon: Icons.hourglass_empty,
                    label: 'OPEN PLANS',
                    value: isLoading
                        ? '—'
                        : '${adminState?.openActionPlans ?? 0}',
                    iconColor: AppTheme.warning,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Menu items — grouped elegantly in a single card
              Card(
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.people,
                      title: 'User Management',
                      subtitle: 'Manage auditors & managers',
                      onTap: () => context.push('/admin/users'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.store,
                      title: 'Store Management',
                      subtitle: 'Manage store locations',
                      onTap: () => context.push('/admin/stores'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.map_outlined,
                      title: 'Area Management',
                      subtitle: 'Manage geographic areas',
                      onTap: () => context.push('/admin/areas'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.assignment,
                      title: 'Audit Approvals',
                      subtitle: 'Review submitted audits',
                      onTap: () => context.push('/admin/approvals'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.warning_amber,
                      title: 'System Logs',
                      subtitle: 'Monitor application events',
                      onTap: () => context.push('/admin/logs'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.bar_chart,
                      title: 'Analytics',
                      subtitle: 'View performance data',
                      onTap: () => context.push('/analytics'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.event_note,
                      title: 'Schedule Audit',
                      subtitle: 'Delegate audits to auditors',
                      onTap: () => context.push('/admin/schedule'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.manage_accounts,
                      title: 'Role Management',
                      subtitle: 'Manage role capabilities',
                      onTap: () => context.push('/admin/roles'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.group_work_outlined,
                      title: 'User Groups',
                      subtitle: 'Manage user group assignments',
                      onTap: () => context.push('/admin/user-groups'),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant),
                    _MenuItem(
                      icon: Icons.shield_outlined,
                      title: 'Global Risk Management',
                      subtitle: 'Configure risk categories for audits',
                      onTap: () => context.push('/admin/global-risks'),
                    ),
                  ],
                ),
              ),
            ],
          ),
            ),
          );
        },
      ),
    );
  }
}


class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
