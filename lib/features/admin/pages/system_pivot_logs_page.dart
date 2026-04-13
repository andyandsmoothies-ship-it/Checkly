import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../widgets/level_badge.dart';

final _di = GetIt.instance;

/// Filtered log list page — accessed via Quick Pivot from [SystemLogDetailPage].
/// Filters by TraceId or UserEmail, making it easy to correlate related logs.
///
/// NOTE: This page calls [Dio] directly as it is a thin diagnostic viewer with
/// no offline requirement. A full [SystemLogsService] extraction is deferred
/// (YAGNI — this feature is admin-only and rarely used).
class SystemPivotLogsPage extends StatefulWidget {
  final String title;
  final String? search;
  final String? traceId;

  const SystemPivotLogsPage({
    required this.title,
    this.search,
    this.traceId,
    super.key,
  });

  @override
  State<SystemPivotLogsPage> createState() => _SystemPivotLogsPageState();
}

class _SystemPivotLogsPageState extends State<SystemPivotLogsPage> {
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
            LevelBadge(level: level),
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
