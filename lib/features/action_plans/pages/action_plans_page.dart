import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';

final _di = GetIt.instance;

/// Action Plans list page — search, filter chips, grouped by store.
class ActionPlansPage extends StatefulWidget {
  final String? initialFilter;
  final String? initialSort;

  const ActionPlansPage({super.key, this.initialFilter, this.initialSort});

  @override
  State<ActionPlansPage> createState() => _ActionPlansPageState();
}

class _ActionPlansPageState extends State<ActionPlansPage> {
  late final ActionPlanManager _manager;
  String _search = '';
  String _filter = 'all'; // all, open, pending_verify, closed
  String _sort = 'newest'; // newest, urgent

  static const _validFilters = {'all', 'open', 'pending_verify', 'closed'};
  static const _validSorts = {'newest', 'urgent'};

  @override
  void initState() {
    super.initState();
    _manager = _di<ActionPlanManager>();
    _filter = _validFilters.contains(widget.initialFilter)
        ? widget.initialFilter!
        : 'all';
    _sort = _validSorts.contains(widget.initialSort)
        ? widget.initialSort!
        : 'newest';
    _manager.loadActionPlans();
  }

  @override
  void didUpdateWidget(covariant ActionPlansPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _filter = _validFilters.contains(widget.initialFilter)
            ? widget.initialFilter!
            : 'all';
      });
    }
    if (oldWidget.initialSort != widget.initialSort) {
      setState(() {
        _sort = _validSorts.contains(widget.initialSort)
            ? widget.initialSort!
            : 'newest';
      });
    }
  }

  List<ActionPlanDto> get _filtered {
    var items = _manager.actionPlans.value;

    // Filter by status
    if (_filter != 'all') {
      items = items.where((p) => p.status == _filter).toList();
    }

    // Filter by search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      items = items
          .where(
            (p) =>
                p.criteriaLabel.toLowerCase().contains(q) ||
                (p.storeName ?? '').toLowerCase().contains(q) ||
                p.groupTitle.toLowerCase().contains(q),
          )
          .toList();
    }

    // Sort
    if (_sort == 'urgent') {
      items.sort((a, b) {
        final da = a.deadline;
        final db = b.deadline;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    } else {
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return items;
  }

  Map<String, List<ActionPlanDto>> get _grouped {
    final map = <String, List<ActionPlanDto>>{};
    for (final plan in _filtered) {
      final store = plan.storeName ?? 'Unknown Store';
      map.putIfAbsent(store, () => []).add(plan);
    }
    return map;
  }

  int _countByStatus(String status) {
    if (status == 'all') return _manager.actionPlans.value.length;
    return _manager.actionPlans.value.where((p) => p.status == status).length;
  }

  String _filterLabel(String filter) => switch (filter) {
    'open' => 'open',
    'pending_verify' => 'pending verification',
    'closed' => 'completed',
    _ => filter,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Action Plans')),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by issue or store...',
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
                      label: 'Open',
                      count: _countByStatus('open'),
                      selected: _filter == 'open',
                      onTap: () => setState(() => _filter = 'open'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Verify',
                      count: _countByStatus('pending_verify'),
                      selected: _filter == 'pending_verify',
                      onTap: () => setState(() => _filter = 'pending_verify'),
                    ),
                    const SizedBox(width: 8),
                    WarmChip(
                      label: 'Done',
                      count: _countByStatus('closed'),
                      selected: _filter == 'closed',
                      onTap: () => setState(() => _filter = 'closed'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Sort selector — unified control row, hidden when no data exists
              if (_countByStatus('all') > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        'Sort:',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      WarmChip(
                        label: 'Newest',
                        selected: _sort == 'newest',
                        onTap: () => setState(() => _sort = 'newest'),
                      ),
                      const SizedBox(width: 8),
                      WarmChip(
                        label: 'Urgent',
                        selected: _sort == 'urgent',
                        onTap: () => setState(() => _sort = 'urgent'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Grouped list
              Expanded(
                child: _filtered.isEmpty
                    ? ChecklyEmptyState(
                        icon: Icons.assignment_outlined,
                        title: _filter == 'all'
                            ? 'No action plans yet'
                            : 'No ${_filterLabel(_filter)} action plans',
                        subtitle: _filter == 'all'
                            ? 'Action plans will appear here when audits flag issues.'
                            : 'Try changing the filter to see more.',
                        actionButton:
                            _filter == 'all' && _countByStatus('all') == 0
                            ? FilledButton.icon(
                                onPressed: () => context.go('/templates'),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Start an Audit'),
                              )
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: _manager.loadActionPlans,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: _grouped.entries
                              .map(
                                (entry) => _StoreGroup(
                                  storeName: entry.key,
                                  plans: entry.value,
                                  onTap: (plan) =>
                                      context.push('/plans/${plan.id}'),
                                ),
                              )
                              .toList(),
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
  final List<ActionPlanDto> plans;
  final ValueChanged<ActionPlanDto> onTap;

  const _StoreGroup({
    required this.storeName,
    required this.plans,
    required this.onTap,
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
                // WCAG: raised from 0.4 → 0.62 for readable low-opacity tracking text
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
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
                '${plans.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: plans
            .map(
              (plan) => _ActionPlanCard(plan: plan, onTap: () => onTap(plan)),
            )
            .toList(),
      ),
    );
  }
}

// ── Action Plan Card ──

class _ActionPlanCard extends StatelessWidget {
  final ActionPlanDto plan;
  final VoidCallback onTap;

  const _ActionPlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = ActionPlanManager.isOverdue(plan, now: DateTime.now());
    final statusColor = _statusColor(plan.status, theme);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 5,
                height: 48,
                decoration: BoxDecoration(
                  color: isOverdue ? theme.colorScheme.error : statusColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.criteriaLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.groupTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Right side: status + deadline
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(plan.status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        // WCAG fix: use dark charcoal for text instead of statusColor.
                        // statusColor over 0.1-alpha tint fails WCAG AA 4.5:1 contrast.
                        color: AppColors.charcoal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (plan.deadline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${plan.deadline!.day}/${plan.deadline!.month}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) => switch (status) {
    'open' => AppTheme.warning,
    'pending_verify' => AppTheme.info,
    'closed' => AppTheme.success,
    _ => theme.colorScheme.onSurfaceVariant,
  };

  String _statusLabel(String status) => switch (status) {
    'open' => 'OPEN',
    'pending_verify' => 'VERIFY',
    'closed' => 'DONE',
    _ => status.toUpperCase(),
  };
}
