import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';
import '../../../../_shared/constants/review_status.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../../../audit/model/submission_dto.dart';
import '../../../audit/utils/score_formatter.dart';

/// A card widget that displays a single audit submission for review.
/// Extracted from AuditApprovalPage to be independently testable.
/// Refactored to utilize the [UniversalListCard] primitive.
class ReviewCard extends StatelessWidget {
  final SubmissionDto item;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const ReviewCard({
    super.key,
    required this.item,
    this.showActions = false,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreStr = () {
      final s = ScoreFormatter.format(
        scoringMode: item.scoringMode,
        rawEarned: item.rawEarnedPoints,
        rawMax: item.rawMaxPoints,
        totalScore: item.totalScore,
        isWeighted: item.isWeighted,
      );
      return s.isEmpty ? '—' : s;
    }();
    final scoreColor = item.totalScore != null
        ? (item.totalScore! >= 80
              ? AppTheme.success
              : item.totalScore! >= 60
              ? AppTheme.warning
              : theme.colorScheme.error)
        : theme.colorScheme.onSurfaceVariant;

    return UniversalListCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            scoreStr,
            style: AppFonts.serifStyle(
              fontSize: theme.textTheme.bodyMedium?.fontSize,
              fontWeight: FontWeight.w700,
              color: scoreColor,
            ),
          ),
        ),
      ),
      title: item.storeName ?? 'Unknown Store',
      subtitle: item.templateTitle ?? 'Audit',
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          // Metadata row
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.auditorName ?? '—',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.calendar_today,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                formatDateShort(item.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // Review metadata for approved/rejected
          if (item.reviewStatus != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  item.reviewStatus == ReviewStatus.approved
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 13,
                  color: item.reviewStatus == ReviewStatus.approved
                      ? AppTheme.success
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.reviewStatus == ReviewStatus.approved ? "Approved" : "Rejected"}'
                    '${item.approverName != null ? " by ${item.approverName}" : ""}'
                    '${item.approvedAt != null ? " • ${formatDateShort(item.approvedAt!)}" : ""}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.reviewStatus == ReviewStatus.approved
                          ? AppTheme.success
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Actions for pending
          if (showActions) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: BubblyButton(
                    label: 'Reject',
                    color: theme.colorScheme.error,
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: onReject,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BubblyButton(
                    label: 'Approve',
                    color: AppTheme.success,
                    icon: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: onApprove,
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
