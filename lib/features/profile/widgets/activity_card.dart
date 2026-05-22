import 'package:flutter/material.dart';

import '../../../../_shared/widgets/primitives/primitives.dart';
import '../../../../_shared/utils/date_format_utils.dart';
import '../model/activity_item.dart';

/// Card showing recent user activity.
/// Refactored to utilize the [UniversalListCard] primitive.
class ActivityCard extends StatelessWidget {
  final ActivityItem item;

  const ActivityCard({super.key, required this.item});

  Color _statusColor(BuildContext context) => switch (item.status) {
    'completed' => Theme.of(context).colorScheme.primary,
    'draft' => Theme.of(context).colorScheme.onSurfaceVariant,
    'in_progress' => Theme.of(context).colorScheme.secondary,
    _ => Theme.of(context).colorScheme.error,
  };

  IconData _statusIcon() => switch (item.status) {
    'completed' => Icons.check_circle,
    'draft' => Icons.edit_note,
    'in_progress' => Icons.play_circle,
    _ => Icons.schedule,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final scoreStr = item.score != null ? item.score!.toStringAsFixed(1) : '';

    return UniversalListCard(
      margin: const EdgeInsets.only(bottom: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(_statusIcon(), color: color, size: 20),
      ),
      title: item.templateTitle,
      subtitle: '${item.storeName} · ${formatDate(item.date)}',
      trailing: scoreStr.isNotEmpty
          ? Text(
              scoreStr,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontFamily: 'Nunito',
                fontSize: 14,
              ),
            )
          : null,
    );
  }
}
