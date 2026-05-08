import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../_shared/services/policy_manager.dart';
import '../../../../_shared/constants/app_capabilities.dart';
import '../../manager/history_manager.dart';
import '../../model/submission_dto.dart';
import '../audit_preview_sheet.dart';
import '../../widgets/store_group.dart';

final _di = GetIt.instance;

/// Renders the grouped submissions list for [HistoryPage].
///
/// Extracted to keep [HistoryPage] below the 400-line architectural limit.
/// Accesses [HistoryManager] and [AuthManager] directly via [GetIt] —
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
            (entry) => StoreGroup(
              storeName: entry.key,
              submissions: entry.value,
              onPreviewAudit: (submission) {
                if (submission.id.startsWith('local_outbox_')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This audit is syncing. Please wait a moment.',
                      ),
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) =>
                      AuditPreviewSheet(submissionId: submission.id),
                );
              },
              onVoidAudit: canVoid
                  ? (submission) async {
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
                                'This will permanently void "${submission.templateTitle ?? 'this audit'}". The auditor will no longer see it as an active task.',
                                style: Theme.of(dialogCtx).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: reasonController,
                                decoration: const InputDecoration(
                                  labelText: 'Reason for voiding',
                                  hintText:
                                      'e.g. Store was closed, task reassigned...',
                                ),
                                maxLines: 2,
                                autofocus: true,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogCtx).pop(true),
                              child: const Text('Void Audit'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('A void reason is required.'),
                            ),
                          );
                        }
                        return;
                      }
                      try {
                        await manager.voidAudit(submission.id, reason);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audit voided.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'We hit a snag removing this item. If it remains stuck on your screen, please restart the app.',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                            ),
                          );
                        }
                      }
                    }
                  : null,
              onStartAudit: (submission) async {
                // Draft → resume directly without a server call
                if (submission.status == 'draft') {
                  final tId = submission.templateId;
                  final sId = submission.storeId;
                  if (tId == null || sId == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cannot resume — draft is missing template or store data.',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  if (context.mounted) {
                    // Guard against sending fake SQLite-only IDs.
                    final isLocalOnly = submission.id.startsWith(
                      'local_draft_',
                    );
                    final subParam = isLocalOnly
                        ? ''
                        : '&submissionId=${submission.id}';
                    context.push(
                      '/audit?templateId=$tId&storeId=$sId&autoResume=true$subParam',
                    );
                  }
                  return;
                }
                // Scheduled → standard server-transition flow
                try {
                  final updated = await manager.startScheduledAudit(
                    submission.id,
                  );
                  if (context.mounted) {
                    final tId = updated.templateId;
                    final sId = updated.storeId;
                    if (tId != null && sId != null) {
                      context.push(
                        '/audit?templateId=$tId&storeId=$sId&autoResume=true&submissionId=${updated.id}',
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "We couldn't start this process right now. Please check your internet connection.",
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
