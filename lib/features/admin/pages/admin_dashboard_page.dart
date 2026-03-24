import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/section_header.dart';
import '../../dashboard/manager/dashboard_manager.dart';
import '../../stores/services/store_api_service.dart';
import '../../templates/services/template_api_service.dart';
import '../services/admin_api_service.dart';

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
  int _userCount = 0;
  int _storeCount = 0;
  int _templateCount = 0;

  @override
  void initState() {
    super.initState();
    _manager = _di<DashboardManager>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manager.loadStats();
      _loadCounts();
    });
  }

  Future<void> _loadCounts() async {
    try {
      final usersResponse = await _di<AdminApiService>().getUsersRaw(
        pageSize: 1,
      );
      final stores = await _di<StoreApiService>().getStores();
      final templates = await _di<TemplateApiService>().getTemplates();
      if (mounted) {
        setState(() {
          _userCount = usersResponse['total'] as int? ?? 0;
          _storeCount = stores.length;
          _templateCount = templates.length;
        });
      }
    } catch (_) {
      // API unavailable — keep defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          final isLoading = _manager.isLoading;
          final adminState = _manager.dashboardState is AdminDashboardState
              ? _manager.dashboardState as AdminDashboardState
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Subtitle
              const SectionHeader('SYSTEM MANAGEMENT'),

              // Stats grid (2×2) — shows shimmer values while loading
              Row(
                children: [
                  Expanded(
                    child: _AdminStat(
                      icon: Icons.people,
                      label: 'USERS',
                      value: isLoading ? '—' : '$_userCount',
                      color: theme.colorScheme.primary,
                      filled: true,
                      dimmed: isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStat(
                      icon: Icons.store,
                      label: 'STORES',
                      value: isLoading ? '—' : '$_storeCount',
                      color: AppTheme.success,
                      dimmed: isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AdminStat(
                      icon: Icons.description,
                      label: 'TEMPLATES',
                      value: isLoading ? '—' : '$_templateCount',
                      color: AppTheme.info,
                      dimmed: isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStat(
                      icon: Icons.hourglass_empty,
                      label: 'PENDING',
                      value: isLoading
                          ? '—'
                          : '${adminState?.openActionPlans ?? 0}',
                      color: AppTheme.warning,
                      dimmed: isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Menu items — always visible, no waiting
              _MenuItem(
                icon: Icons.people,
                title: 'User Management',
                subtitle: 'Manage auditors & managers',
                onTap: () => context.push('/admin/users'),
              ),
              _MenuItem(
                icon: Icons.store,
                title: 'Store Management',
                subtitle: 'Manage store locations',
                onTap: () => context.push('/admin/stores'),
              ),
              _MenuItem(
                icon: Icons.map_outlined,
                title: 'Area Management',
                subtitle: 'Manage geographic areas',
                onTap: () => context.push('/admin/areas'),
              ),
              _MenuItem(
                icon: Icons.assignment,
                title: 'Audit Approvals',
                subtitle: 'Review submitted audits',
                onTap: () => context.push('/admin/approvals'),
              ),
              _MenuItem(
                icon: Icons.warning_amber,
                title: 'System Logs',
                subtitle: 'Monitor application events',
                onTap: () => context.push('/admin/logs'),
              ),
              _MenuItem(
                icon: Icons.bar_chart,
                title: 'Analytics',
                subtitle: 'View performance data',
                onTap: () => context.push('/analytics'),
              ),
              _MenuItem(
                icon: Icons.event_note,
                title: 'Schedule Audit',
                subtitle: 'Delegate audits to auditors',
                onTap: () => context.push('/admin/schedule'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool filled;
  final bool dimmed;

  const _AdminStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.filled = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ignore: unused_local_variable

    return AnimatedOpacity(
      opacity: dimmed ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: filled ? AppTheme.softPeach : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(color: AppTheme.sageGray.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppFonts.serifStyle(
                fontSize: 28,
                color: AppTheme.charcoal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppFonts.displayStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoal.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
      ),
    );
  }
}
