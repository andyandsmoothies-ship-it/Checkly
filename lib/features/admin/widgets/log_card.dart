import 'package:flutter/material.dart';

import 'level_badge.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';

/// Card displaying structured system audit log entries.
/// Refactored to utilize the [UniversalListCard] primitive.
class LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onTap;

  const LogCard({super.key, required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = log['level'] as String? ?? 'info';
    final action = log['action'] as String? ?? '';
    final category = log['category'] as String? ?? '';
    final message = log['message'] as String? ?? '';
    final createdAt = log['createdAt'] as String?;

    return UniversalListCard(
      margin: const EdgeInsets.only(bottom: 6),
      onTap: onTap,
      leading: LevelBadge(level: level),
      title: action,
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            category,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
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
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
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
