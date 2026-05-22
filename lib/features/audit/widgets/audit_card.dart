import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/utils/score_utils.dart';
import '../../../../_shared/widgets/action_guard.dart';
import '../../../../_shared/constants/submission_actions.dart';
import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../../_shared/widgets/primitives/bubbly_button.dart';
import '../../../../_shared/widgets/primitives/pill_chip.dart';
import '../model/submission_dto.dart';
import '../utils/category_utils.dart';
import '../utils/score_formatter.dart';

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

    return StrokeCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      onTap: onPreviewAudit,
      child: Row(
        children: [
          // Score circle or status icon
          Container(
            width: 48,
            height: 48,
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
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : isOverdue
                  ? Icon(
                      Icons.warning_amber_rounded,
                      size: 22,
                      color: theme.colorScheme.error,
                    )
                  : isScheduled
                  ? Icon(
                      Icons.schedule,
                      size: 22,
                      color: theme.colorScheme.primary,
                    )
                  : isDraft
                  ? Icon(Icons.edit_note, size: 22, color: AppTheme.warning)
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        ScoreFormatter.format(
                          scoringMode: submission.scoringMode,
                          rawEarned: submission.rawEarnedPoints,
                          rawMax: submission.rawMaxPoints,
                          totalScore: submission.totalScore,
                          isWeighted: submission.isWeighted,
                        ),
                        style: AppFonts.serifStyle(
                          fontSize:
                              Theme.of(
                                context,
                              ).textTheme.titleMedium?.fontSize ??
                              16,
                          color: color,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  submission.templateTitle ?? 'Audit',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isScheduled || isOverdue
                      ? 'Scheduled at ${_formatDateTime(submission.scheduledAt ?? submission.createdAt)}'
                      : isDraft
                      ? 'Started at ${_formatDateTime(submission.createdAt)}'
                      : 'Completed at ${_formatDateTime(submission.completedAt ?? submission.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOverdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (submission.templateType != null) ...[
                  const SizedBox(height: 6),
                  _categoryBadge(submission.templateType!, theme),
                ],
              ],
            ),
          ),

          // Action: Start / Resume button OR status badge
          if ((isScheduled || isDraft) && onStartAudit != null) ...[
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
            // Admin-only void button
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
          ] else ...[
            _statusBadge(theme),
          ],
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

  String _formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy HH:mm:ss').format(date.toLocal());

  Widget _categoryBadge(String type, ThemeData theme) {
    return PillChip(label: formatCategory(type), type: PillChipType.blue);
  }
}
