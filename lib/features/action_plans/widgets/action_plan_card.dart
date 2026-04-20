import 'package:flutter/material.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_theme.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';

class ActionPlanCard extends StatelessWidget {
  final ActionPlanDto plan;
  final VoidCallback onTap;

  const ActionPlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = ActionPlanManager.isOverdue(plan, now: DateTime.now());
    final statusColor = _statusColor(plan.status, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                            color: isOverdue ? theme.colorScheme.error : statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan.criteriaLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.groupTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Right side: status + deadline
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(plan.status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        // WCAG fix: use dark charcoal for text instead of statusColor.
                        // statusColor over 0.1-alpha tint fails WCAG AA 4.5:1 contrast.
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (plan.deadline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Due: ${plan.deadline!.day}/${plan.deadline!.month}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) => switch (status) {
    'open' => AppTheme.warning,
    'pending_verify' => AppTheme.info,
    'closed' => AppTheme.success,
    _ => theme.colorScheme.onSurfaceVariant,
  };

  String _statusLabel(String status) => switch (status) {
    'open' => 'OPEN',
    'pending_verify' => 'VERIFY',
    'closed' => 'DONE',
    _ => status.toUpperCase(),
  };
}
