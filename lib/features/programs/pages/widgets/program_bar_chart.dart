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
    if (summary.total == 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
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
                buildSegment(summary.verified, Colors.green.shade700),
                buildSegment(summary.submitted, Colors.blue),
                buildSegment(summary.needsRevision, Colors.red),
                buildSegment(summary.pending, Colors.grey.shade400),
                buildSegment(summary.overdue, Colors.orange),
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
              color: Colors.green.shade700,
              label: 'Verified (${summary.verified})',
            ),
            _LegendItem(
              color: Colors.blue,
              label: 'Submitted (${summary.submitted})',
            ),
            _LegendItem(
              color: Colors.red,
              label: 'Needs Rev (${summary.needsRevision})',
            ),
            _LegendItem(
              color: Colors.orange,
              label: 'Overdue (${summary.overdue})',
            ),
            _LegendItem(
              color: Colors.grey.shade400,
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
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
