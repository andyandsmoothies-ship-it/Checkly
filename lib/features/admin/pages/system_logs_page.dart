import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';

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

  void _showLogDetail(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _LevelBadge(level: log['level'] as String? ?? 'info'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log['action'] as String? ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Detail rows
              _DetailRow(label: 'Category', value: log['category'] as String?),
              _DetailRow(label: 'Path', value: log['path'] as String?),
              _DetailRow(label: 'User ID', value: log['userId'] as String?),
              _DetailRow(
                label: 'Timestamp',
                value: _formatTimestamp(log['createdAt'] as String?),
              ),
              const SizedBox(height: 12),

              // Message (full)
              if (log['message'] != null) ...[
                Text(
                  'Message',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    log['message'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    return '${local.year}-${_pad(local.month)}-${_pad(local.day)} '
        '${_pad(local.hour)}:${_pad(local.minute)}:${_pad(local.second)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Logs')),
      body: Column(
        children: [
          // Level filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: _levels
                  .map(
                    (level) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(level.toUpperCase()),
                        selected: _levelFilter == level,
                        onSelected: (_) => _onLevelChanged(level),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Content
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
      return const Center(
        child: Text('No logs found', style: TextStyle(color: Colors.grey)),
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
                          fontSize: 10,
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
    final (Color bg, Color fg, IconData icon) = switch (level) {
      'error' => (Colors.red.withValues(alpha: 0.15), Colors.red, Icons.error),
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

// ─── Detail Row ───

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value!, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
