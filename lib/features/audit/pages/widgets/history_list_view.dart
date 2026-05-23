import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';

import '../../../../_shared/constants/app_capabilities.dart';
import '../../../../_shared/exceptions/app_error.dart';
import '../../../../_shared/services/error_display_service.dart';
import '../../../../_shared/services/policy_manager.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';
import '../../manager/history_manager.dart';
import '../../model/submission_dto.dart';
import '../../widgets/audit_card.dart';
import '../audit_preview_sheet.dart';

final _di = GetIt.instance;

/// Renders the grouped submissions list for [HistoryPage].
///
/// Extracted to keep [HistoryPage] below the 400-line architectural limit.
/// Accesses [HistoryManager] and [PolicyManager] directly via [GetIt] —
/// consistent with the established Checkly pattern for child widgets.
class HistoryListView extends StatelessWidget {
  /// Pre-computed grouped map from [_HistoryPageState._grouped].
  final Map<String, List<SubmissionDto>> groupedSubmissions;

  /// Whether the current filtered list is empty.
  final bool isEmpty;

  /// Scroll controller wired to [_HistoryPageState._onScroll] for pagination.
  final ScrollController scrollController;

  const HistoryListView({
    super.key,
    required this.groupedSubmissions,
    required this.isEmpty,
    required this.scrollController,
  });

  // ---------------------------------------------------------------------------
  // Action handlers (extracted to keep build() readable and under limits)
  // ---------------------------------------------------------------------------

  static void _onPreviewAudit(BuildContext context, SubmissionDto submission) {
    if (submission.id.startsWith('local_outbox_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This audit is syncing. Please wait a moment.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AuditPreviewSheet(submissionId: submission.id),
    );
  }

  static Future<void> _onVoidAudit(
    BuildContext context,
    HistoryManager manager,
    SubmissionDto submission,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Void Audit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently void "${submission.templateTitle ?? 'this audit'}". '
              'The auditor will no longer see it as an active task.',
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
    if (confirmed != true) return;
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      if (context.mounted) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'validation_error',
            message: 'A void reason is required.',
          ),
        );
      }
      return;
    }
    try {
      await manager.voidAudit(submission.id, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audit voided.')));
      }
    } on DioException catch (e) {
      if (context.mounted) {
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (_) {
      if (context.mounted) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'unknown',
            message: 'Could not void this audit. Please try again.',
          ),
        );
      }
    }
  }

  static Future<void> _onStartAudit(
    BuildContext context,
    HistoryManager manager,
    SubmissionDto submission,
  ) async {
    // Draft → resume directly without a server call
    if (submission.status == 'draft') {
      final tId = submission.templateId;
      final sId = submission.storeId;
      if (tId == null || sId == null) {
        if (context.mounted) {
          _di<ErrorDisplayService>().show(
            const AppError(
              code: 'validation_error',
              message:
                  'Cannot resume — draft is missing template or store data.',
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        final isLocalOnly = submission.id.startsWith('local_draft_');
        final subParam = isLocalOnly ? '' : '&submissionId=${submission.id}';
        context.push(
          '/audit?templateId=$tId&storeId=$sId&autoResume=true$subParam',
        );
      }
      return;
    }
    // Scheduled → standard server-transition flow
    try {
      final updated = await manager.startScheduledAudit(submission.id);
      if (context.mounted) {
        final tId = updated.templateId;
        final sId = updated.storeId;
        if (tId != null && sId != null) {
          context.push(
            '/audit?templateId=$tId&storeId=$sId&autoResume=true&submissionId=${updated.id}',
          );
        }
      }
    } on DioException catch (e) {
      if (context.mounted) {
        _di<ErrorDisplayService>().show(AppError.fromDioException(e));
      }
    } catch (_) {
      if (context.mounted) {
        _di<ErrorDisplayService>().show(
          const AppError(
            code: 'network_error',
            message:
                "We couldn't start this process right now. Please check your internet connection.",
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<HistoryManager>();
    final canVoid = _di<PolicyManager>().can(AppCapabilities.submissionsReview);

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(80),
            ),
            const SizedBox(height: 12),
            Text('No audits found', style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => manager.loadHistory(),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        children: [
          ...groupedSubmissions.entries.map(
            (entry) => UniversalStoreGroup(
              storeName: entry.key,
              count: entry.value.length,
              children: entry.value
                  .map(
                    (s) => AuditCard(
                      submission: s,
                      onStartAudit:
                          ((s.status == 'scheduled' && !s.isOverdue) ||
                              s.status == 'draft')
                          ? () => _onStartAudit(context, manager, s)
                          : null,
                      onVoidAudit:
                          (canVoid &&
                              (s.status == 'draft' || s.status == 'scheduled'))
                          ? () => _onVoidAudit(context, manager, s)
                          : null,
                      onPreviewAudit:
                          (s.status == 'completed' || s.status == 'voided')
                          ? () => _onPreviewAudit(context, s)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
          if (manager.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (!manager.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'All audits loaded',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
