import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
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
    _manager.loadStats();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final users = await _di<AdminApiService>().getUsers();
      final stores = await _di<StoreApiService>().getStores();
      final templates = await _di<TemplateApiService>().getTemplates();
      if (mounted) {
        setState(() {
          _userCount = users.length;
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
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = _manager.stats;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Subtitle
              Text(
                'System management',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Stats grid (2×2)
              Row(
                children: [
                  Expanded(
                    child: _AdminStat(
                      icon: Icons.people,
                      label: 'USERS',
                      value: '$_userCount',
                      color: theme.colorScheme.primary,
                      filled: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStat(
                      icon: Icons.store,
                      label: 'STORES',
                      value: '$_storeCount',
                      color: AppTheme.success,
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
                      value: '$_templateCount',
                      color: AppTheme.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AdminStat(
                      icon: Icons.hourglass_empty,
                      label: 'PENDING',
                      value: '${stats.pendingActionPlanCount}',
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Menu items
              _MenuItem(
                icon: Icons.people,
                title: 'User Management',
                subtitle: 'Manage auditors & managers',
                onTap: () => context.push('/admin/approvals'),
              ),
              _MenuItem(
                icon: Icons.store,
                title: 'Store Management',
                subtitle: 'Manage store locations',
                onTap: () => context.push('/admin/dashboard'),
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
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System logs — coming soon')),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.bar_chart,
                title: 'Analytics',
                subtitle: 'View performance data',
                onTap: () => context.push('/analytics'),
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

  const _AdminStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: filled ? color : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: filled ? Colors.white : color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: filled ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: filled
                    ? Colors.white.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
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
