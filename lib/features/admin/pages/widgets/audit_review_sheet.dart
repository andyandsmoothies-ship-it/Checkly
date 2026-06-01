import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../../audit/model/submission_dto.dart';
import '../../../../_shared/constants/review_status.dart';
import '../../../audit/utils/score_formatter.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';

void showAuditReviewSheet({
  required BuildContext context,
  required SubmissionDto item,
  required VoidCallback onApprove,
  required VoidCallback onReject,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) =>
        AuditReviewSheet(item: item, onApprove: onApprove, onReject: onReject),
  );
}

class AuditReviewSheet extends StatelessWidget {
  final SubmissionDto item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const AuditReviewSheet({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(item.createdAt);
    final scoreStr = () {
      final s = ScoreFormatter.format(
        scoringMode: item.scoringMode,
        rawEarned: item.rawEarnedPoints,
        rawMax: item.rawMaxPoints,
        totalScore: item.totalScore,
        isWeighted: item.isWeighted,
        shortForm: true,
      );
      return s.isEmpty ? '—' : s;
    }();
    final scoreColor = item.totalScore != null
        ? (item.totalScore! >= 80
              ? AppTheme.success
              : item.totalScore! >= 60
              ? AppTheme.warning
              : theme.colorScheme.error)
        : (item.isVoided
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurfaceVariant);

    final isVoided = item.isVoided;
    final isPending = item.reviewStatus == null && !isVoided;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Audit Review',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score circle
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  scoreStr,
                  style: AppFonts.serifStyle(
                    fontSize: theme.textTheme.headlineSmall?.fontSize,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata rows
          _metadataRow(context, Icons.store, 'Store', item.storeName ?? '—'),
          _metadataRow(
            context,
            Icons.description_outlined,
            'Template',
            item.templateTitle ?? '—',
          ),
          _metadataRow(
            context,
            Icons.person_outline,
            'Auditor',
            item.auditorName ?? '—',
          ),
          _metadataRow(context, Icons.calendar_today, 'Date', dateStr),
          if (item.notes != null && item.notes!.isNotEmpty)
            _metadataRow(context, Icons.notes, 'Notes', item.notes!),

          if (isVoided) ...[
            const SizedBox(height: 12),
            _metadataRow(context, Icons.block_flipped, 'Status', 'VOIDED'),
            if (item.voidReason != null)
              _metadataRow(
                context,
                Icons.info_outline,
                'Reason',
                item.voidReason!,
              ),
            if (item.voidedAt != null)
              _metadataRow(
                context,
                Icons.access_time,
                'Voided On',
                DateFormat('dd/MM/yyyy HH:mm').format(item.voidedAt!),
              ),
          ],

          // Review status badge
          if (item.reviewStatus != null) ...[
            const SizedBox(height: 12),
            _metadataRow(
              context,
              item.reviewStatus == ReviewStatus.approved
                  ? Icons.check_circle
                  : item.reviewStatus == ReviewStatus.rejected
                  ? Icons.cancel
                  : Icons.flag,
              'Status',
              '${item.reviewStatus!.substring(0, 1).toUpperCase()}${item.reviewStatus!.substring(1)}',
            ),
            if (item.approverName != null)
              _metadataRow(
                context,
                Icons.admin_panel_settings,
                'By',
                item.approverName!,
              ),
            if (item.approvedAt != null)
              _metadataRow(
                context,
                Icons.access_time,
                'On',
                DateFormat('dd/MM/yyyy HH:mm').format(item.approvedAt!),
              ),
          ],

          // Actions for pending items
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: BubblyButton(
                    label: 'Reject',
                    color: theme.colorScheme.error,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.maybePop(context);
                      onReject();
                    },
                    height: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BubblyButton(
                    label: 'Approve',
                    color: AppTheme.success,
                    icon: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.maybePop(context);
                      onApprove();
                    },
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

  Widget _metadataRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
