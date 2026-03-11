import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../manager/dashboard_manager.dart';

final _di = GetIt.instance;

/// Dashboard page — shows stats from local Drift cache.
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
    _manager.loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = _manager.stats;

          return RefreshIndicator(
            onRefresh: _manager.loadStats,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(
                  icon: Icons.assignment_turned_in,
                  label: 'Audits Completed',
                  value: '${stats.recentAuditCount}',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.score,
                  label: 'Average Score',
                  value: '${stats.averageScore}%',
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.pending_actions,
                  label: 'Pending Action Plans',
                  value: '${stats.pendingActionPlanCount}',
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.notifications_active,
                  label: 'Unread Notifications',
                  value: '${stats.unreadNotificationCount}',
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
