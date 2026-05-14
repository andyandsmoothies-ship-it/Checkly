import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../dashboard/manager/dashboard_manager.dart';
import '../model/pending_assignment_vm.dart';

/// Full-screen list of a store manager's pending campaign assignments.
///
/// Driven by the same [DashboardManager.watchActionRequired()] stream
/// as the dashboard widget, allowing the user to view all items if
/// they exceed the dashboard's truncation limit.
class ProgramAssignmentListPage extends StatelessWidget {
  const ProgramAssignmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = GetIt.instance<DashboardManager>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Campaigns'),
      ),
      body: StreamBuilder<List<PendingAssignmentVm>?>(
        stream: manager.watchActionRequired(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vms = snapshot.data;
          if (vms == null || vms.isEmpty) {
            return Center(
              child: Text(
                'No pending campaigns at this time.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final vm = vms[index];
              return Card(
                elevation: 0,
                color: AppTheme.warning.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    Icons.assignment_late_outlined,
                    color: AppTheme.warning,
                  ),
                  title: Text(
                    vm.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Action Required · Tap to complete'),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.warning,
                  ),
                  onTap: () => context.push('/programs/${vm.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
