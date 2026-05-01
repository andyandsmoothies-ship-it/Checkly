import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/database/app_database.dart';
import '../../../../_shared/database/dao/program_outbox_dao.dart';
import '../../../../_shared/theme/app_theme.dart';
import 'hero_card.dart';

/// Displays an amber action-required banner when the SM has pending program
/// assignments.
///
/// Reads directly from [ProgramOutboxDao.watchPendingAssignments()] via a
/// [StreamBuilder] — no DashboardManager involvement. This ensures sub-100ms
/// offline display since Drift streams read from the local SQLite cache.
///
/// Behaviour:
/// - 0 pending → renders [SizedBox.shrink] (invisible, no space taken).
/// - ≥ 1 pending → amber [HeroCard] with count; taps into the first pending
///   assignment's execution page.
class ActionRequiredWidget extends StatelessWidget {
  const ActionRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final dao = GetIt.instance<ProgramOutboxDao>();

    return StreamBuilder<List<CachedProgramAssignment>>(
      stream: dao.watchPendingAssignments(),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        final count = assignments.length;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        final firstId = assignments.first.id;
        final label =
            '$count Program Task${count > 1 ? 's' : ''} Need Completion';

        return Column(
          children: [
            HeroCard(
              icon: Icons.assignment_late_outlined,
              title: label,
              subtitle: 'Action Required · Tap to complete',
              color: AppTheme.warning.withValues(alpha: 0.10),
              iconColor: AppTheme.warning,
              onTap: () => context.push('/programs/$firstId'),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
