import 'package:flutter/material.dart';
import '../../../_shared/utils/date_format_utils.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/database/database_service.dart';
import '../../../_shared/theme/app_theme.dart';

final _di = GetIt.instance;

/// Activity History page — shows user's own recent submissions.
class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  List<_ActivityItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    final db = _di<DatabaseService>().db;
    final subs = await db.select(db.cachedSubmissions).get();
    setState(() {
      _items =
          subs
              .map(
                (s) => _ActivityItem(
                  id: s.id,
                  storeName: s.storeName ?? 'Unknown Store',
                  templateTitle: s.templateTitle ?? 'Audit',
                  status: s.status,
                  score: s.totalScore,
                  date: s.createdAt,
                ),
              )
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Activity')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(child: Text('No activity yet'))
          : RefreshIndicator(
              onRefresh: _loadActivity,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _ActivityCard(item: item);
                },
              ),
            ),
    );
  }
}

class _ActivityItem {
  final String id;
  final String storeName;
  final String templateTitle;
  final String status;
  final double? score;
  final DateTime date;

  _ActivityItem({
    required this.id,
    required this.storeName,
    required this.templateTitle,
    required this.status,
    this.score,
    required this.date,
  });
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityCard({required this.item});

  Color _statusColor(BuildContext context) => switch (item.status) {
    'completed' => AppTheme.success,
    'draft' => Theme.of(context).colorScheme.onSurfaceVariant,
    'in_progress' => AppTheme.info,
    _ => AppTheme.warning,
  };

  IconData _statusIcon() => switch (item.status) {
    'completed' => Icons.check_circle,
    'draft' => Icons.edit_note,
    'in_progress' => Icons.play_circle,
    _ => Icons.schedule,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context);
    final scoreStr = item.score != null
        ? '${item.score!.toStringAsFixed(1)}%'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_statusIcon(), color: color),
        ),
        title: Text(
          item.templateTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.storeName} · ${formatDate(item.date)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: scoreStr.isNotEmpty
            ? Text(
                scoreStr,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              )
            : null,
      ),
    );
  }
}
