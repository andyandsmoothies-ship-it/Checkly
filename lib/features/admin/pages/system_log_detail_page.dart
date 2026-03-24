import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';

final _di = GetIt.instance;

/// Full-page detail view for a single system log entry.
/// Supports "Quick Pivot" navigation — tap 🔍 to filter list by TraceId or UserEmail.
class SystemLogDetailPage extends StatelessWidget {
  final Map<String, dynamic> log;

  const SystemLogDetailPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = log['level'] as String? ?? 'info';
    final action = log['action'] as String? ?? '';
    final category = log['category'] as String? ?? '';
    final message = log['message'] as String?;
    final path = log['path'] as String?;
    final userId = log['userId'] as String?;
    final userEmail = log['userEmail'] as String?;
    final entityType = log['entityType'] as String?;
    final entityId = log['entityId'] as String?;
    final traceId = log['traceId'] as String?;
    final createdAt = log['createdAt'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Detail'),
        actions: [
          IconButton(
            tooltip: 'Copy raw data',
            icon: const Icon(Icons.copy),
            onPressed: () => _copyRaw(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              _LevelBadge(level: level),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (category.isNotEmpty)
                      Text(
                        category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Pivotable fields
          _PivotRow(
            label: 'Trace ID',
            value: traceId,
            onPivot: traceId != null
                ? () => _pushPivot(context, 'Trace: $traceId', traceId: traceId)
                : null,
          ),
          _PivotRow(
            label: 'User Email',
            value: userEmail,
            onPivot: userEmail != null
                ? () =>
                      _pushPivot(context, 'User: $userEmail', search: userEmail)
                : null,
          ),

          // Static fields
          _DetailRow(label: 'User ID', value: userId),
          _DetailRow(label: 'Entity Type', value: entityType),
          _DetailRow(label: 'Entity ID', value: entityId),
          _DetailRow(label: 'Path', value: path),
          _DetailRow(label: 'Timestamp', value: _fmt(createdAt)),

          // Payload
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Message',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(message, style: theme.textTheme.bodyMedium),
            ),
          ],

          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Raw Data'),
            onPressed: () => _copyRaw(context),
          ),
        ],
      ),
    );
  }

  void _copyRaw(BuildContext context) {
    Clipboard.setData(ClipboardData(text: log.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Raw data copied to clipboard')),
    );
  }

  void _pushPivot(
    BuildContext context,
    String title, {
    String? search,
    String? traceId,
  }) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            _PivotLogsPage(title: title, search: search, traceId: traceId),
      ),
    );
  }

  static String _fmt(String? raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final l = dt.toLocal();
    return '${l.year}-${_p(l.month)}-${_p(l.day)} '
        '${_p(l.hour)}:${_p(l.minute)}:${_p(l.second)}';
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}

// ─── Quick Pivot page ───

class _PivotLogsPage extends StatefulWidget {
  final String title;
  final String? search;
  final String? traceId;

  const _PivotLogsPage({required this.title, this.search, this.traceId});

  @override
  State<_PivotLogsPage> createState() => _PivotLogsPageState();
}

class _PivotLogsPageState extends State<_PivotLogsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = _di<Dio>();
      final params = <String, dynamic>{'page': 1, 'pageSize': 100};
      if (widget.search != null) params['search'] = widget.search;
      if (widget.traceId != null) params['traceId'] = widget.traceId;

      final response = await dio.get('/admin/logs', queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _logs = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _logs.isEmpty
          ? Center(
              child: Text(
                'No logs found.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _logs.length,
              itemBuilder: (ctx, i) => _CompactLogCard(log: _logs[i]),
            ),
    );
  }
}

// ─── Compact log card for pivot view ───
class _CompactLogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _CompactLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = log['level'] as String? ?? 'info';
    final action = log['action'] as String? ?? '';
    final message = log['message'] as String? ?? '';
    final createdAt = log['createdAt'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _LevelBadge(level: level),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (createdAt != null)
                    Text(
                      _fmtTime(createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')} '
        '${l.day}/${l.month}/${l.year}';
  }
}

// ─── Shared widgets ───

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

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value!, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PivotRow extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback? onPivot;
  const _PivotRow({required this.label, this.value, this.onPivot});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value!, style: theme.textTheme.bodyMedium),
          ),
          if (onPivot != null)
            GestureDetector(
              onTap: onPivot,
              child: Tooltip(
                message: 'Filter by this $label',
                child: Icon(
                  Icons.filter_list,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
