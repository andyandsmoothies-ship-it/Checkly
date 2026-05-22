import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/constants/submission_actions.dart';
import '../../../../_shared/exceptions/app_error.dart';
import '../../../../_shared/services/error_display_service.dart';
import '../../../../_shared/services/policy_manager.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../../../audit/model/submission_dto.dart';
import '../../../audit/pages/audit_preview_sheet.dart';
import '../../../audit/services/draft_service.dart';
import '../../../audit/utils/score_formatter.dart';
import '../../../auth/manager/auth_manager.dart';
import '../../manager/dashboard_manager.dart';

/// Single submission row in the feed.
/// Standardized to utilize the [UniversalListCard] primitive.
@visibleForTesting
class SubmissionRow extends StatefulWidget {
  final SubmissionDto submission;
  final BuildContext context;

  const SubmissionRow({
    required this.submission,
    required this.context,
    super.key,
  });

  @override
  State<SubmissionRow> createState() => _SubmissionRowState();
}

class _SubmissionRowState extends State<SubmissionRow> {
  final _di = GetIt.instance;

  Future<void> _discardDraft() async {
    final sub = widget.submission;
    final tId = sub.templateId;
    final sId = sub.storeId;
    if (tId == null || sId == null) return;

    final userId = _di<AuthManager>().currentUser?.userId ?? 'anon';
    final draftKey = '$tId:$sId:$userId';

    try {
      await _di<DraftService>().deleteDraft(draftKey);
      await _di<DashboardManager>().loadStats();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Draft discarded')));
      }
    } on DioException catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'unknown',
            message:
                'We hit a snag removing this item. If it remains stuck on your screen, please restart the app.',
          ),
        );
      }
    }
  }

  Future<void> _voidAudit() async {
    final sub = widget.submission;
    final ctx = widget.context;

    // Show reason dialog
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Void Audit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently void "${sub.templateTitle ?? 'this audit'}". The auditor will no longer see it as an active task.',
              style: Theme.of(dialogCtx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for voiding',
                hintText: 'e.g. Store was closed, task reassigned...',
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Void Audit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      _di<ErrorDisplayService>().show(
        const AppError(
          code: 'validation_error',
          message: 'A void reason is required.',
        ),
      );
      return;
    }

    try {
      await _di<DashboardManager>().voidAudit(sub.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audit voided.')));
      }
    } on DioException catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (e) {
      if (mounted) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'unknown',
            message:
                'We hit a snag removing this item. If it remains stuck on your screen, please restart the app.',
          ),
        );
      }
    }
  }

  void _resumeDraft() {
    final sub = widget.submission;
    final tId = sub.templateId;
    final sId = sub.storeId;
    if (tId == null || sId == null) return;
    widget.context.push(
      '/audit?templateId=$tId&storeId=$sId&autoResume=true&submissionId=${sub.id}',
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    final sub = widget.submission;
    final score = sub.totalScore;
    final isDraft = sub.status == 'draft';
    final scoreText = ScoreFormatter.format(
      scoringMode: sub.scoringMode,
      rawEarned: sub.rawEarnedPoints,
      rawMax: sub.rawMaxPoints,
      totalScore: sub.totalScore,
      isWeighted: sub.isWeighted,
    );

    final semanticColor = score != null
        ? (score >= 80
              ? AppColors.featherGreen
              : score >= 60
              ? AppColors.fox
              : AppColors.cardinal)
        : AppColors.wolf;

    return UniversalListCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: isDraft
          ? _resumeDraft
          : () {
              if (sub.id.startsWith('local_outbox_')) {
                ScaffoldMessenger.of(widget.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'This audit is syncing. Please wait a moment.',
                    ),
                  ),
                );
                return;
              }
              showModalBottomSheet(
                context: widget.context,
                isScrollControlled: true,
                useSafeArea: true,
                useRootNavigator: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => AuditPreviewSheet(submissionId: sub.id),
              );
            },
      title: sub.templateTitle ?? 'Audit',
      subtitleWidget: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          () {
            final isOverdue = sub.isOverdue;
            final isScheduled = sub.status == 'scheduled' && !isOverdue;
            if (isScheduled || isOverdue) {
              return '${sub.storeName ?? 'Unknown'} · Scheduled ${formatDate(sub.scheduledAt ?? sub.createdAt)}';
            }
            if (sub.status == 'draft') {
              return '${sub.storeName ?? 'Unknown'} · Started ${formatDate(sub.createdAt)}';
            }
            return '${sub.storeName ?? 'Unknown'} · ${timeAgo(sub.completedAt ?? sub.createdAt)}';
          }(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.wolf,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: isDraft
          ? PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.swan, width: 2),
              ),
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onSelected: (value) {
                if (value == 'resume') Future.microtask(_resumeDraft);
                if (value == 'discard') Future.microtask(_discardDraft);
                if (value == 'void') Future.microtask(_voidAudit);
              },
              itemBuilder: (_) {
                // Hybrid PBAC check: use server-computed allowedActions
                // when online; fall back to JWT capability when offline.
                final canVoid = sub.allowedActions != null
                    ? sub.allowedActions!.contains(SubmissionActions.voidAction)
                    : _di<PolicyManager>().can(
                        AppCapabilities.submissionsReview,
                      );
                return [
                  const PopupMenuItem(
                    value: 'resume',
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Resume Audit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'discard',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Discard Draft'),
                      ],
                    ),
                  ),
                  if (canVoid)
                    const PopupMenuItem(
                      value: 'void',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 18),
                          SizedBox(width: 8),
                          Text('Void Audit'),
                        ],
                      ),
                    ),
                ];
              },
            )
          : (scoreText.isNotEmpty
                ? (scoreText == '—'
                      ? const PillChip(
                          label: 'SURVEY',
                          type: PillChipType.purple,
                        )
                      : Text(
                          scoreText,
                          style: AppFonts.displayStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: semanticColor,
                          ),
                        ))
                : Builder(
                    builder: (_) {
                      final isOverdue = sub.isOverdue;
                      final label = isOverdue
                          ? 'EXPIRED'
                          : sub.status.toUpperCase();
                      final chipType = isOverdue
                          ? PillChipType.red
                          : PillChipType.yellow;
                      return PillChip(label: label, type: chipType);
                    },
                  )),
    );
  }
}
