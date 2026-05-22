import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../../../_shared/widgets/warm_chip.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import '../manager/action_plan_manager.dart';
import '../model/action_plan_dto.dart';
import '../widgets/store_group.dart';

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
      appBar: AppBar(
        title: const Text('Action Plans'),
        actions: [
          ListenableBuilder(
            listenable: _manager,
            builder: (context, _) {
              if (_countByStatus('all') == 0) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Action Plans',
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: 'newest',
                    checked: _sort == 'newest',
                    child: const Text('Newest First'),
                  ),
                  CheckedPopupMenuItem(
                    value: 'urgent',
                    checked: _sort == 'urgent',
                    child: const Text('Urgent First'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, _) {
          if (_manager.isLoading && _manager.actionPlans.value.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_manager.error != null && _manager.actionPlans.value.isEmpty) {
            return ChecklyEmptyState(
              emoji: '🔌',
              title: "Let's get reconnected!",
              subtitle:
                  'We had trouble reaching the server. Please check your network connection.',
              actionButton: FilledButton.icon(
                onPressed: _manager.loadActionPlans,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            );
          }

          return Column(
            children: [
              if (_manager.error != null)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.errorContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    _manager.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                    ? ChecklyEmptyState(
                        emoji: _filter == 'all'
                            ? '📋'
                            : (_filter == 'closed' ? '✅' : '🎯'),
                        title: _filter == 'all'
                            ? 'All clear here!'
                            : 'No ${_filterLabel(_filter)} plans found',
                        subtitle: _filter == 'all'
                            ? 'Action plans appear when audits flag improvements. Start an audit to check in!'
                            : 'Try changing your status filters to discover other plans.',
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
                                (entry) => StoreGroup(
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
