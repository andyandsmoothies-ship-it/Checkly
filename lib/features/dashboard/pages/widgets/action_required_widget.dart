import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../manager/dashboard_manager.dart';
import 'hero_card.dart';

/// Displays an amber action-required banner when the SM has pending program
/// assignments.
///
/// Consumes [DashboardManager.watchActionRequired()] which maps the raw Drift
/// stream to a [PendingAssignmentVm] — this widget never imports database
/// generated types directly.
///
/// Behaviour:
/// - null / 0 pending → renders [SizedBox.shrink] (invisible, no space taken).
/// - ≥ 1 pending → amber [HeroCard] with count; taps into the first pending
///   assignment's execution page.
class ActionRequiredWidget extends StatelessWidget {
  const ActionRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = GetIt.instance<DashboardManager>();

    return StreamBuilder(
      stream: manager.watchActionRequired(),
      builder: (context, snapshot) {
        final vm = snapshot.data;

        if (vm == null) {
          return const SizedBox.shrink();
        }

        final label =
            '${vm.count} Program Task${vm.count > 1 ? 's' : ''} Need Completion';

        return Column(
          children: [
            HeroCard(
              icon: Icons.assignment_late_outlined,
              title: label,
              subtitle: 'Action Required · Tap to complete',
              color: AppTheme.warning.withValues(alpha: 0.10),
              iconColor: AppTheme.warning,
              onTap: () => context.push('/programs/${vm.firstId}'),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
