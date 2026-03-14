import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';

final _di = GetIt.instance;

/// Action Plans list page — search, filter chips, grouped by store.
class ActionPlansPage extends StatefulWidget {
  const ActionPlansPage({super.key});

  @override
  State<ActionPlansPage> createState() => _ActionPlansPageState();
}

class _ActionPlansPageState extends State<ActionPlansPage> {
  late final ActionPlanManager _manager;
  String _search = '';
  String _filter = 'all'; // all, open, pending_verify, closed

  @override
  void initState() {
    super.initState();
    _manager = _di<ActionPlanManager>();
    _manager.loadActionPlans();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

              // Grouped list
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No action plans found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
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
                                      context.push('/actions/${plan.id}'),
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: isOverdue ? theme.colorScheme.error : statusColor,
                  borderRadius: BorderRadius.circular(2),
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
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel(plan.status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
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
