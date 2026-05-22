import 'package:flutter/material.dart';

import 'level_badge.dart';
import '../../../../_shared/widgets/primitives/stroke_card.dart';

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

    return StrokeCard(
      margin: const EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LevelBadge(level: level),
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
