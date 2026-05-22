import 'package:flutter/material.dart';

import '../../../_shared/widgets/primitives/quest_progress_bar.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../model/survey_result_dto.dart';

class SurveyQuestionCard extends StatelessWidget {
  final SurveyQuestionResult result;

  const SurveyQuestionCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question label
          Text(
            result.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.totalResponses} response${result.totalResponses == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          // Option bars
          ...result.options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionBar(
                label: opt.value,
                count: opt.count,
                percentage: opt.percentage,
                maxPercentage: result.options.isNotEmpty
                    ? result.options.first.percentage
                    : 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionBar extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final double maxPercentage;

  const _OptionBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.maxPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barFraction = maxPercentage > 0 ? percentage / maxPercentage : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        QuestProgressBar(value: barFraction.clamp(0.0, 1.0), height: 12),
      ],
    );
  }
}
