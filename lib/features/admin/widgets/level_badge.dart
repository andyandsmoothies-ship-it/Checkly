import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';

/// Shared severity badge — used by [SystemLogDetailPage] and [SystemPivotLogsPage].
class LevelBadge extends StatelessWidget {
  final String level;
  const LevelBadge({required this.level, super.key});

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
