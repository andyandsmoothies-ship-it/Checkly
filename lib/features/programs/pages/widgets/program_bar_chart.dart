import 'package:flutter/material.dart';

import '../../services/program_api_service.dart';

/// A horizontal segmented bar showing the distribution of assignment statuses.
///
/// When [ProgramSummaryResponse.total] is zero, renders a plain grey bar.
/// Used exclusively in [ProgramDashboardPage].
class ProgramSegmentedBarChart extends StatelessWidget {
  final ProgramSummaryResponse summary;

  const ProgramSegmentedBarChart({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (summary.total == 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    Widget buildSegment(int count, Color color) {
      if (count == 0) return const SizedBox.shrink();
      return Expanded(
        flex: count,
        child: Container(color: color),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                buildSegment(summary.verified, theme.colorScheme.primary),
                buildSegment(summary.submitted, theme.colorScheme.secondary),
                buildSegment(summary.needsRevision, theme.colorScheme.error),
                buildSegment(
                  summary.pending,
                  theme.colorScheme.surfaceContainerHighest,
                ),
                buildSegment(summary.overdue, theme.colorScheme.tertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _LegendItem(
              color: theme.colorScheme.primary,
              label: 'Verified (${summary.verified})',
            ),
            _LegendItem(
              color: theme.colorScheme.secondary,
              label: 'Submitted (${summary.submitted})',
            ),
            _LegendItem(
              color: theme.colorScheme.error,
              label: 'Needs Rev (${summary.needsRevision})',
            ),
            _LegendItem(
              color: theme.colorScheme.tertiary,
              label: 'Overdue (${summary.overdue})',
            ),
            _LegendItem(
              color: theme.colorScheme.surfaceContainerHighest,
              label: 'Pending (${summary.pending})',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
