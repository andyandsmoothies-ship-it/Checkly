import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/widgets/checkly_fab.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../manager/history_manager.dart';
import '../model/submission_dto.dart';

final _di = GetIt.instance;

/// Audits page — search, filter chips, grouped by store.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _search = '';
  String _filter = 'all'; // all, draft, in_progress, completed, overdue
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _di<HistoryManager>().loadHistory();
    });
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

    // Filter by status
    if (_filter != 'all') {
      items = items.where((s) => s.status == _filter).toList();
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

  int _countByStatus(String status) {
    final all = _di<HistoryManager>().submissions.value;
    if (status == 'all') return all.length;
    return all.where((s) => s.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = _di<HistoryManager>();

    return Scaffold(
      appBar: AppBar(title: const Text('Audits')),
      floatingActionButton: ChecklyFab(
        label: 'AUDIT',
        onPressed: () => context.push('/templates'),
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
                      label: 'Draft',
                      count: _countByStatus('draft'),
                      selected: _filter == 'draft',
                      onTap: () => setState(() => _filter = 'draft'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'In Progress',
                      count: _countByStatus('in_progress'),
                      selected: _filter == 'in_progress',
                      onTap: () => setState(() => _filter = 'in_progress'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Submitted',
                      count: _countByStatus('completed'),
                      selected: _filter == 'completed',
                      onTap: () => setState(() => _filter = 'completed'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ..._grouped.entries.map(
                              (entry) => _StoreGroup(
                                storeName: entry.key,
                                submissions: entry.value,
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

  const _StoreGroup({required this.storeName, required this.submissions});

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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoal.withValues(alpha: 0.4),
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
        children: submissions.map((s) => _AuditCard(submission: s)).toList(),
      ),
    );
  }
}

// ── Audit Card ──

class _AuditCard extends StatelessWidget {
  final SubmissionDto submission;
  const _AuditCard({required this.submission});

  Color _scoreColor(double? score, ThemeData theme) {
    if (score == null) return theme.colorScheme.onSurfaceVariant;
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.warning;
    return theme.colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(submission.totalScore, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Score circle (Apothecary: primary/10 bg, no border)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  submission.totalScore != null
                      ? submission.totalScore!.toStringAsFixed(0)
                      : '—',
                  style: AppFonts.serifStyle(fontSize: 16, color: color),
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
                    _formatDate(submission.completedAt ?? submission.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: submission.status == 'completed'
                    ? AppTheme.success.withAlpha(20)
                    : AppTheme.oatmeal.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                submission.status.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: submission.status == 'completed'
                      ? AppTheme.success
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
