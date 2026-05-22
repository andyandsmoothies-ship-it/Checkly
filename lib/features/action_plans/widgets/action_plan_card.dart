import 'package:flutter/material.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/primitives.dart';
import '../../../_shared/utils/date_format_utils.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';

/// Card widget representing an action plan item.
/// Refactored to utilize the [UniversalListCard] primitive.
class ActionPlanCard extends StatelessWidget {
  final ActionPlanDto plan;
  final VoidCallback onTap;

  const ActionPlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = ActionPlanManager.isOverdue(plan, now: DateTime.now());
    final statusColor = _statusColor(plan.status);

    return UniversalListCard(
      onTap: onTap,
      leading: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOverdue ? AppColors.cardinal : statusColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      title: plan.criteriaLabel,
      subtitle: 'Section: ${plan.groupTitle}',
      subtitleWidget: plan.sourceTitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_tree_rounded,
                    size: 12,
                    color: AppColors.wolf,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      plan.sourceTitle!,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.wolf,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : null,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PillChip(
            label: _statusLabel(plan.status),
            type: _chipType(plan.status),
          ),
          if (plan.deadline != null) ...[
            const SizedBox(height: 6),
            Text(
              'Due: ${formatDateShort(plan.deadline!)}',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: isOverdue ? AppColors.cardinal : AppColors.wolf,
                fontWeight: isOverdue ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'open' => AppColors.macaw,
    'pending_verify' => AppColors.macaw,
    'closed' => AppColors.featherGreen,
    _ => AppColors.wolf,
  };

  PillChipType _chipType(String status) => switch (status) {
    'open' => PillChipType.yellow,
    'pending_verify' => PillChipType.blue,
    'closed' => PillChipType.green,
    _ => PillChipType.purple,
  };

  String _statusLabel(String status) => switch (status) {
    'open' => 'OPEN',
    'pending_verify' => 'VERIFY',
    'closed' => 'DONE',
    _ => status.toUpperCase(),
  };
}
