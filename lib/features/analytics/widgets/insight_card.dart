import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../manager/analytics_data.dart';

/// Renders a single actionable insight as a Card with a 3px left accent
/// border coloured by [ActionableInsight.type].
///
/// Types:
///   - 'warning'  → [AppTheme.warning]  + Icons.warning_amber_rounded
///   - 'positive' → [AppTheme.success]  + Icons.check_circle_outline
///   - 'info'     → [AppTheme.info]     + Icons.info_outline
class InsightCard extends StatelessWidget {
  final ActionableInsight insight;

  const InsightCard({super.key, required this.insight});

  Color _accentColor() {
    return switch (insight.type) {
      'warning' => AppTheme.warning,
      'positive' => AppTheme.success,
      _ => AppTheme.info,
    };
  }

  IconData _icon() {
    return switch (insight.type) {
      'warning' => Icons.warning_amber_rounded,
      'positive' => Icons.check_circle_outline,
      _ => Icons.info_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentColor();

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent border
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(_icon(), color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            insight.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            insight.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
