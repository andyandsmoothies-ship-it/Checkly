import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/utils/score_utils.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/checkly_fab.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../../admin/pages/schedule_audit_page.dart';
import '../../auth/manager/auth_manager.dart';
import '../manager/history_manager.dart';
import '../model/submission_dto.dart';

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
                              (entry) => _StoreGroup(
                                storeName: entry.key,
                                submissions: entry.value,
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
                                          content: Text('Failed to start: $e'),
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

// ── Store Group (collapsible) ──

class _StoreGroup extends StatelessWidget {
  final String storeName;
  final List<SubmissionDto> submissions;
  final void Function(SubmissionDto)? onStartAudit;

  const _StoreGroup({
    required this.storeName,
    required this.submissions,
    this.onStartAudit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Text(
              storeName.toUpperCase(),
              style: AppFonts.displayStyle(
                fontSize: Theme.of(context).textTheme.labelSmall?.fontSize,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${submissions.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: submissions
            .map(
              (s) => _AuditCard(
                submission: s,
                onStartAudit: (s.status == 'scheduled' && !s.isOverdue) ||
                        s.status == 'draft'
                    ? () => onStartAudit?.call(s)
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Audit Card ──

class _AuditCard extends StatelessWidget {
  final SubmissionDto submission;
  final VoidCallback? onStartAudit;
  const _AuditCard({required this.submission, this.onStartAudit});

  Color _scoreColor(double? score, ThemeData theme) => scoreColor(score, theme);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = submission.isOverdue;
    final isVoided = submission.isVoided;
    final isScheduled = submission.status == 'scheduled' && !isOverdue;
    final isDraft = submission.status == 'draft';
    final color = isVoided
        ? theme.colorScheme.onSurfaceVariant
        : _scoreColor(submission.totalScore, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    : color.withValues(alpha: 0.1),   // Synchronized: bg tint tracks score-semantic color
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
                    : Text(
                        submission.totalScore != null
                            ? submission.totalScore!.toStringAsFixed(0)
                            : '—',
                        style: AppFonts.serifStyle(
                            fontSize: Theme.of(context).textTheme.titleMedium?.fontSize ?? 16,
                            color: color,
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
                ],
              ),
            ),

            // Action: Start / Resume button OR status badge
            if ((isScheduled || isDraft) && onStartAudit != null) ...[
               FilledButton(
                onPressed: onStartAudit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: const Size(64, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isDraft ? 'Resume' : 'Start',
                  style: AppFonts.displayStyle(
                    fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              _statusBadge(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ThemeData theme) {
    final isOverdue = submission.isOverdue;
    final status = isOverdue ? 'EXPIRED' : submission.status.toUpperCase();

    Color bg;
    Color fg;
    if (isOverdue) {
      bg = theme.colorScheme.error.withAlpha(20);
      fg = theme.colorScheme.error;
    } else if (submission.status == 'completed' &&
        submission.totalScore == null) {
      // Survey mode — no score
      bg = theme.colorScheme.tertiary.withAlpha(20);
      fg = theme.colorScheme.tertiary;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'SURVEY',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      );
    } else {
      switch (submission.status) {
        case 'completed':
          bg = AppTheme.success.withAlpha(20);
          fg = AppTheme.success;
        case 'draft':
          bg = AppTheme.warning.withAlpha(20);
          fg = AppTheme.warning;
        case 'scheduled':
          bg = theme.colorScheme.primary.withAlpha(20);
          fg = theme.colorScheme.primary;
        case 'voided':
          bg = theme.colorScheme.surfaceContainerHighest;
          fg = theme.colorScheme.onSurfaceVariant;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'VOIDED',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
          );
        default:
          bg = AppTheme.oatmeal.withValues(alpha: 0.5);
          fg = theme.colorScheme.onSurfaceVariant;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) => DateFormat('dd MMM yyyy HH:mm:ss').format(date.toLocal());
}
