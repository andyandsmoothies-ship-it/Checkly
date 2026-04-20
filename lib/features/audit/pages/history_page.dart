import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/constants/app_capabilities.dart';
import '../../../_shared/services/policy_manager.dart';
import '../../../_shared/widgets/checkly_fab.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../../admin/pages/schedule_audit_page.dart';
import '../../auth/manager/auth_manager.dart';
import '../manager/history_manager.dart';
import '../model/submission_dto.dart';
import '../pages/audit_preview_sheet.dart';
import '../utils/category_utils.dart';
import '../widgets/store_group.dart';

final _di = GetIt.instance;

/// Audits page — search, filter chips, grouped by store.
class HistoryPage extends StatefulWidget {
  final String? initialMonth; // e.g. '2026-03' from trend chart drill-down
  final String? initialFilter; // e.g. 'submitted' from KPI drilldown

  const HistoryPage({super.key, this.initialMonth, this.initialFilter});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _search = '';
  String _filter = 'all'; // all, todo, doing, submitted, overdue
  String _categoryFilter = 'all'; // all, or any templateType value
  final _scrollController = ScrollController();

  static const _validFilters = {'all', 'todo', 'doing', 'submitted', 'overdue'};

  @override
  void initState() {
    super.initState();
    _filter = _validFilters.contains(widget.initialFilter)
        ? widget.initialFilter!
        : 'all';
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _di<HistoryManager>().loadHistory();
    });
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _filter = _validFilters.contains(widget.initialFilter)
            ? widget.initialFilter!
            : 'all';
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= max * 0.8) {
      final manager = _di<HistoryManager>();
      if (manager.hasMore && !manager.isLoadingMore) {
        manager.loadMore();
      }
    }
  }

  List<SubmissionDto> get _filtered {
    final manager = _di<HistoryManager>();
    var items = manager.submissions.value;

    // Filter by status tab (matching PWA TAB_STATUS_MAP)
    switch (_filter) {
      case 'todo':
        items = items
            .where((s) => s.status == 'scheduled' && !s.isOverdue)
            .toList();
        break;
      case 'doing':
        items = items.where((s) => s.status == 'draft').toList();
        break;
      case 'submitted':
        items = items.where((s) => s.status == 'completed').toList();
        break;
      case 'overdue':
        items = items.where((s) => s.isOverdue).toList();
        break;
    }

    // Filter by category (templateType)
    if (_categoryFilter != 'all') {
      items = items.where((s) => s.templateType == _categoryFilter).toList();
    }

    // Filter by search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      items = items
          .where(
            (s) =>
                (s.storeName ?? '').toLowerCase().contains(q) ||
                (s.templateTitle ?? '').toLowerCase().contains(q),
          )
          .toList();
    }

    // Filter by month (from trend chart drill-down)
    if (widget.initialMonth != null) {
      final parts = widget.initialMonth!.split('-');
      if (parts.length == 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (y != null && m != null) {
          items = items
              .where((s) => s.createdAt.year == y && s.createdAt.month == m)
              .toList();
        }
      }
    }

    return items;
  }

  Map<String, List<SubmissionDto>> get _grouped {
    final map = <String, List<SubmissionDto>>{};
    for (final sub in _filtered) {
      final store = sub.storeName ?? 'Unknown Store';
      map.putIfAbsent(store, () => []).add(sub);
    }
    return map;
  }

  /// Returns the unique set of templateType values present in the current
  /// (status-filtered) submission list. Used to build the category chip row.
  List<String> get _availableCategories {
    final manager = _di<HistoryManager>();
    final types = manager.submissions.value
        .map((s) => s.templateType)
        .whereType<String>()
        .toSet()
        .toList()
        ..sort();
    return types;
  }

  int _countByStatus(String filter) {
    final all = _di<HistoryManager>().submissions.value;
    switch (filter) {
      case 'all':
        return all.length;
      case 'todo':
        return all.where((s) => s.status == 'scheduled' && !s.isOverdue).length;
      case 'doing':
        return all.where((s) => s.status == 'draft').length;
      case 'submitted':
        return all.where((s) => s.status == 'completed').length;
      case 'overdue':
        return all.where((s) => s.isOverdue).length;
      default:
        return 0;
    }
  }

  void _showScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Assign Task',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ScheduleAuditForm(onSuccess: () => Navigator.pop(sheetContext)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<HistoryManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Audits')),
      floatingActionButton: ChecklyFab(
        isAdmin: _di<AuthManager>().currentUser?.role == 'admin',
        canCreateSubmission: _di<PolicyManager>().can(AppCapabilities.submissionsCreate),
        onNewAudit: () => context.push('/templates'),
        onAssignTask: () => _showScheduleSheet(context),
      ),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          if (manager.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (manager.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(manager.error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => manager.loadHistory(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search stores or audits...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    WarmChip(
                      label: 'All',
                      count: _countByStatus('all'),
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Todo',
                      count: _countByStatus('todo'),
                      selected: _filter == 'todo',
                      onTap: () => setState(() => _filter = 'todo'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Doing',
                      count: _countByStatus('doing'),
                      selected: _filter == 'doing',
                      onTap: () => setState(() => _filter = 'doing'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Submitted',
                      count: _countByStatus('submitted'),
                      selected: _filter == 'submitted',
                      onTap: () => setState(() => _filter = 'submitted'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Overdue',
                      count: _countByStatus('overdue'),
                      selected: _filter == 'overdue',
                      onTap: () => setState(() => _filter = 'overdue'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Category filter chips (only shown when >1 type is in the list)
              if (_availableCategories.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      WarmChip(
                        label: 'All categories',
                        selected: _categoryFilter == 'all',
                        onTap: () => setState(() => _categoryFilter = 'all'),
                      ),
                      ..._availableCategories.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: WarmChip(
                            label: formatCategory(type),
                            selected: _categoryFilter == type,
                            onTap: () => setState(() => _categoryFilter = type),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Cloud Archive Banner (GC Pillar A) ──
              ValueListenableBuilder<bool>(
                valueListenable: manager.hasArchivedRecords,
                builder: (context, hasArchived, _) {
                  if (!hasArchived) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Some older audits were archived to save space.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => manager.searchCloudArchive(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Search archive'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Grouped list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withAlpha(80),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No audits found',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => manager.loadHistory(),
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          children: [
                            ..._grouped.entries.map(
                              (entry) => StoreGroup(
                                storeName: entry.key,
                                submissions: entry.value,
                                onPreviewAudit: (submission) {
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
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (_) => AuditPreviewSheet(
                                      submissionId: submission.id,
                                    ),
                                  );
                                },
                                onVoidAudit: _di<AuthManager>().currentUser?.role == 'admin'
                                    ? (submission) async {
                                        final reasonController =
                                            TextEditingController();
                                        final confirmed =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (dialogCtx) => AlertDialog(
                                            title: const Text('Void Audit'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'This will permanently void "${submission.templateTitle ?? 'this audit'}". The auditor will no longer see it as an active task.',
                                                  style: Theme.of(dialogCtx)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                                const SizedBox(height: 16),
                                                TextField(
                                                  controller:
                                                      reasonController,
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Reason for voiding',
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
                                                    Navigator.of(dialogCtx)
                                                        .pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.of(dialogCtx)
                                                        .pop(true),
                                                child:
                                                    const Text('Void Audit'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed != true) return;
                                        final reason =
                                            reasonController.text.trim();
                                        if (reason.isEmpty) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'A void reason is required.',
                                                ),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                        try {
                                          await manager.voidAudit(
                                            submission.id,
                                            reason,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Audit voided.'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
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
                                      final isLocalOnly = submission.id
                                          .startsWith('local_draft_');
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
                                    final updated =
                                        await manager.startScheduledAudit(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('We couldn\'t start this process right now. Please check your internet connection.'),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.error,
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
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            if (!manager.hasMore && _filtered.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'All audits loaded',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
