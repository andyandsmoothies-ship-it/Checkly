import 'package:flutter/material.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';

class ActionPlanCard extends StatelessWidget {
  final ActionPlanDto plan;
  final VoidCallback onTap;

  const ActionPlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOverdue = ActionPlanManager.isOverdue(plan, now: DateTime.now());
    final statusColor = _statusColor(plan.status);

    return StrokeCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Status indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOverdue ? AppColors.cardinal : statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.criteriaLabel,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.eel,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Section: ${plan.groupTitle}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.wolf,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (plan.sourceTitle != null) ...[
                    const SizedBox(height: 2),
                    Row(
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
                  ],
                ],
              ),
            ),

            // Right side: status + deadline
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PillChip(
                  label: _statusLabel(plan.status),
                  type: _chipType(plan.status),
                ),
                if (plan.deadline != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Due: ${plan.deadline!.day}/${plan.deadline!.month}',
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
          ],
        ),
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
