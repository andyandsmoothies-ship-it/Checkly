import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../model/activity_item.dart';

class ActivityCard extends StatelessWidget {
  final ActivityItem item;

  const ActivityCard({super.key, required this.item});

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
        ? item.score!.toStringAsFixed(1)
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
