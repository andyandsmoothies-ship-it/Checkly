import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/widgets/checkly_empty_state.dart';
import 'system_log_detail_page.dart';

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

  static const _levels = ['all', 'info', 'warn', 'error'];

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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search email, message, entity ID…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          // ── Date range + level chips ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _dateRange == null
                        ? 'Date Range'
                        : '${_fmt(_dateRange!.start)} – ${_fmt(_dateRange!.end)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: _pickDateRange,
                ),
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Clear dates',
                    onPressed: _clearDateRange,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const Spacer(),
                ..._levels.map(
                  (level) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: FilterChip(
                      label: Text(
                        level.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      selected: _levelFilter == level,
                      onSelected: (_) => _onLevelChanged(level),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
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
            Text('Failed to load logs', style: theme.textTheme.titleMedium),
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
        icon: Icons.receipt_long_outlined,
        title: 'No logs found',
        subtitle: 'Try adjusting your filters or date range.',
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
          return _LogCard(log: log, onTap: () => _showLogDetail(log));
        },
      ),
    );
  }
}

// ─── Log Card ───

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onTap;

  const _LogCard({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = log['level'] as String? ?? 'info';
    final action = log['action'] as String? ?? '';
    final category = log['category'] as String? ?? '';
    final message = log['message'] as String? ?? '';
    final createdAt = log['createdAt'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LevelBadge(level: level),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action + category
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            action,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    // Message (truncated)
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Timestamp
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')} '
        '${local.day}/${local.month}/${local.year}';
  }
}

// ─── Level Badge ───

class _LevelBadge extends StatelessWidget {
  final String level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg, IconData icon) = switch (level) {
      'error' => (theme.colorScheme.errorContainer, theme.colorScheme.error, Icons.error),
      'warn' => (
        AppTheme.warning.withValues(alpha: 0.15),
        AppTheme.warning,
        Icons.warning_amber,
      ),
      _ => (
        AppTheme.info.withValues(alpha: 0.15),
        AppTheme.info,
        Icons.info_outline,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: fg),
    );
  }
}
