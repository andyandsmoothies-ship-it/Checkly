import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
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
      appBar: AppBar(title: const Text('Pending Campaigns')),
      body: StreamBuilder<List<PendingAssignmentVm>?>(
        stream: manager.watchActionRequired(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vms = snapshot.data;
          if (vms == null || vms.isEmpty) {
            return const ChecklyEmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'All Caught Up!',
              subtitle: 'No pending campaigns at this time.',
              emoji: '🎉',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final vm = vms[index];
              return UniversalListCard(
                title: vm.title,
                titleStyle: theme.textTheme.titleMedium?.merge(
                  AppFonts.displayStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => context.push('/programs/${vm.id}'),
                leading: const Icon(
                  Icons.assignment_late_outlined,
                  color: AppColors.flamingo,
                ),
                badges: const [
                  PillChip(label: 'ACTION REQUIRED', type: PillChipType.yellow),
                ],
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.flamingo,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
