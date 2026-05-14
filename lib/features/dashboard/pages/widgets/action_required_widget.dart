import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../programs/model/pending_assignment_vm.dart';
import '../../manager/dashboard_manager.dart';

/// Displays an amber action-required banner when the SM has pending program
/// assignments.
///
/// Consumes [DashboardManager.watchActionRequired()] which maps the raw Drift
/// stream to a [PendingAssignmentVm] — this widget never imports database
/// generated types directly.
///
/// Behaviour:
/// - null / 0 pending → renders [SizedBox.shrink] (invisible, no space taken).
/// - 1-3 pending → amber [HeroCard] with count; taps into the execution page.
/// - >3 pending → truncates list to 3, shows a "View All Campaigns (X)" button.
class ActionRequiredWidget extends StatelessWidget {
  const ActionRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = GetIt.instance<DashboardManager>();

    return StreamBuilder<List<PendingAssignmentVm>?>(
      stream: manager.watchActionRequired(),
      builder: (context, snapshot) {
        final vms = snapshot.data;

        if (vms == null || vms.isEmpty) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final displayVms = vms.take(3).toList();
        final hasMore = vms.length > 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Pending Campaigns',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...displayVms.map(
              (vm) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  elevation: 0,
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.assignment_late_outlined,
                      color: AppTheme.warning,
                    ),
                    title: Text(
                      vm.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Action Required · Tap to complete'),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.warning,
                    ),
                    onTap: () => context.push('/programs/${vm.id}'),
                  ),
                ),
              ),
            ),
            if (hasMore) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/programs/assignments'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('View All Campaigns (${vms.length})'),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
