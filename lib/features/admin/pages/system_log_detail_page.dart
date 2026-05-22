import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/level_badge.dart';
import 'system_pivot_logs_page.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';

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
              LevelBadge(level: level),
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
            StrokeCard(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
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
            SystemPivotLogsPage(title: title, search: search, traceId: traceId),
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

// ─── Shared widgets ───

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
