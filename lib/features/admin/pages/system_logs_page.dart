import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import 'system_log_detail_page.dart';
import '../widgets/log_card.dart';


final _di = GetIt.instance;

/// Admin: System Logs — read-only log viewer with level filter and pagination.
class SystemLogsPage extends StatefulWidget {
  const SystemLogsPage({super.key});

  @override
  State<SystemLogsPage> createState() => _SystemLogsPageState();
}

class _SystemLogsPageState extends State<SystemLogsPage> {
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  int _totalCount = 0;
  String _levelFilter = 'all';
  String _searchQuery = '';
  DateTimeRange? _dateRange;
  Timer? _debounce;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLogs(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _logs.length < _totalCount) {
      _loadLogs(reset: false);
    }
  }

  Future<void> _loadLogs({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _logs = [];
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final params = <String, dynamic>{'page': _page, 'pageSize': 50};
      if (_levelFilter != 'all') params['level'] = _levelFilter;
      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
      if (_dateRange != null) {
        params['startDate'] = _dateRange!.start.toIso8601String();
        params['endDate'] = _dateRange!.end
            .add(const Duration(days: 1))
            .toIso8601String();
      }

      final response = await _di<Dio>().get(
        '/admin/logs',
        queryParameters: params,
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        if (reset) {
          _logs = items;
        } else {
          _logs.addAll(items);
        }
        _totalCount = data['totalCount'] as int? ?? 0;
        _page++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onLevelChanged(String level) {
    setState(() => _levelFilter = level);
    _loadLogs(reset: true);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = value);
      _loadLogs(reset: true);
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadLogs(reset: true);
    }
  }

  void _clearDateRange() {
    setState(() => _dateRange = null);
    _loadLogs(reset: true);
  }

  static String _fmt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showLogDetail(Map<String, dynamic> log) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => SystemLogDetailPage(log: log)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      body: Column(
        children: [
          // ── Investigate Toolbar: search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                color: AppColors.eel,
              ),
              decoration: InputDecoration(
                hintText: 'Search email, message, entity ID…',
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppColors.wolf,
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.wolf),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.wolf),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.swan, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.featherGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // ── Date range + level chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownFilterPill(
                    label: 'Date',
                    value: _dateRange == null
                        ? 'All'
                        : '${_fmt(_dateRange!.start)} – ${_fmt(_dateRange!.end)}',
                    active: _dateRange != null,
                    onTap: () => showLogDateFilterSheet(
                      context: context,
                      currentRange: _dateRange,
                      onPickRange: _pickDateRange,
                      onClear: _clearDateRange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownFilterPill(
                    label: 'Level',
                    value: _levelFilter == 'all' ? 'All' : _levelFilter.toUpperCase(),
                    active: _levelFilter != 'all',
                    onTap: () => showLogLevelFilterSheet(
                      context: context,
                      currentFilter: _levelFilter,
                      onSelected: _onLevelChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Content ──
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load the latest data. Please check your internet connection and refresh.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => _loadLogs(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_logs.isEmpty) {
      return const ChecklyEmptyState(
        emoji: '🪵',
        title: 'The logs are nice and quiet!',
        subtitle: 'No system logs matched your search or filters at this time.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLogs(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _logs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _logs.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final log = _logs[index];
          return LogCard(log: log, onTap: () => _showLogDetail(log));
        },
      ),
    );
  }
}


class DropdownFilterPill extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const DropdownFilterPill({
    super.key,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.featherGreen : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.featherGreen : AppColors.swan,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ).copyWith(
                color: active ? Colors.white : AppColors.eel,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.eel,
            ),
          ],
        ),
      ),
    );
  }
}

void showLogLevelFilterSheet({
  required BuildContext context,
  required String currentFilter,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final levels = [
        {'id': 'all', 'label': 'All Levels', 'color': AppColors.eel},
        {'id': 'info', 'label': 'INFO', 'color': AppColors.macaw},
        {'id': 'warn', 'label': 'WARN', 'color': AppColors.fox},
        {'id': 'error', 'label': 'ERROR', 'color': AppColors.cardinal},
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Log Level',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.eel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...levels.map((lvl) {
                final isSelected = currentFilter == lvl['id'];
                return InkWell(
                  onTap: () {
                    onSelected(lvl['id'] as String);
                    Navigator.maybePop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.featherGreen.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.featherGreen : AppColors.swan,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lvl['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: lvl['color'] as Color,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.featherGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

void showLogDateFilterSheet({
  required BuildContext context,
  required DateTimeRange? currentRange,
  required VoidCallback onPickRange,
  required VoidCallback onClear,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Date',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.eel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.maybePop(ctx);
                  onPickRange();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: currentRange != null ? AppColors.featherGreen.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentRange != null ? AppColors.featherGreen : AppColors.swan,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentRange == null
                            ? 'Select Date Range'
                            : 'Change Date Range',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.eel,
                        ),
                      ),
                      const Icon(
                        Icons.date_range_rounded,
                        color: AppColors.featherGreen,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (currentRange != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.maybePop(ctx);
                    onClear();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardinal,
                        width: 2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Clear Date Filter',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cardinal,
                          ),
                        ),
                        Icon(
                          Icons.delete_sweep_rounded,
                          color: AppColors.cardinal,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
