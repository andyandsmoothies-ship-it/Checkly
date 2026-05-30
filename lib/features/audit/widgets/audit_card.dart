import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/utils/score_utils.dart';
import '../../../../_shared/widgets/action_guard.dart';
import '../../../../_shared/constants/submission_actions.dart';
import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../model/submission_dto.dart';
import '../utils/category_utils.dart';
import '../utils/score_formatter.dart';

/// Card widget representing an audit/submission.
/// Refactored to leverage the unified [UniversalListCard] layout primitive.
class AuditCard extends StatelessWidget {
  final SubmissionDto submission;
  final VoidCallback? onStartAudit;
  final VoidCallback? onVoidAudit;
  final VoidCallback? onPreviewAudit;

  const AuditCard({
    super.key,
    required this.submission,
    this.onStartAudit,
    this.onVoidAudit,
    this.onPreviewAudit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = submission.isOverdue;
    final isVoided = submission.isVoided;
    final isScheduled = submission.status == 'scheduled' && !isOverdue;
    final isDraft = submission.status == 'draft';
    final color = isVoided
        ? theme.colorScheme.onSurfaceVariant
        : scoreColor(submission.totalScore, theme);

    return UniversalListCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onPreviewAudit,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isVoided
              ? theme.colorScheme.surfaceContainerHighest
              : isOverdue
              ? theme.colorScheme.error.withValues(alpha: 0.1)
              : isScheduled
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : isDraft
              ? AppTheme.warning.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.1),
        ),
        child: Center(
          child: isVoided
              ? Icon(
                  Icons.block_flipped,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : isOverdue
              ? Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: theme.colorScheme.error,
                )
              : isScheduled
              ? Icon(Icons.schedule, size: 20, color: theme.colorScheme.primary)
              : isDraft
              ? Icon(Icons.edit_note, size: 20, color: AppTheme.warning)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    ScoreFormatter.format(
                      scoringMode: submission.scoringMode,
                      rawEarned: submission.rawEarnedPoints,
                      rawMax: submission.rawMaxPoints,
                      totalScore: submission.totalScore,
                      isWeighted: submission.isWeighted,
                      shortForm: true,
                    ),
                    style: AppFonts.serifStyle(
                      fontSize: theme.textTheme.bodyMedium?.fontSize ?? 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
        ),
      ),
      title: submission.templateTitle ?? 'Audit',
      subtitle: submission.templateType != null
          ? 'Category: ${formatCategory(submission.templateType!)}'
          : null,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if ((isScheduled || isDraft) && onStartAudit != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActionGuard(
                  actions: submission.allowedActions,
                  requiredAction: SubmissionActions.edit,
                  fallbackCapability: AppCapabilities.submissionsCreate,
                  child: SizedBox(
                    width: 90,
                    child: BubblyButton(
                      height: 38,
                      onPressed: onStartAudit,
                      child: Text(
                        isDraft ? 'Resume' : 'Start',
                        style: AppFonts.displayStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                if (onVoidAudit != null) ...[
                  const SizedBox(width: 4),
                  ActionGuard(
                    actions: submission.allowedActions,
                    requiredAction: SubmissionActions.voidAction,
                    fallbackCapability: AppCapabilities.submissionsReview,
                    child: IconButton.filledTonal(
                      onPressed: onVoidAudit,
                      tooltip: 'Void Audit',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.error.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      icon: Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            _statusBadge(theme),
          ],
          const SizedBox(height: 8),
          Text(
            isScheduled || isOverdue
                ? 'Due: ${formatDateShort(submission.scheduledAt ?? submission.createdAt)}'
                : isDraft
                ? 'Started: ${formatDateShort(submission.createdAt)}'
                : 'Done: ${formatDateShort(submission.completedAt ?? submission.createdAt)}',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: isOverdue ? AppColors.cardinal : AppColors.wolf,
              fontWeight: isOverdue ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ThemeData theme) {
    final isOverdue = submission.isOverdue;
    final status = isOverdue ? 'EXPIRED' : submission.status.toUpperCase();
    final type = isOverdue
        ? PillChipType.red
        : (submission.status == 'completed'
              ? PillChipType.green
              : (submission.status == 'draft'
                    ? PillChipType.yellow
                    : (submission.status == 'scheduled'
                          ? PillChipType.purple
                          : (submission.status == 'voided'
                                ? PillChipType.red
                                : PillChipType.blue))));

    return PillChip(label: status, type: type);
  }
}
