import 'package:flutter/material.dart';

import '../../../_shared/utils/score_utils.dart';
import '../../../_shared/services/scoring_engine.dart';

// ============================================================
// Live Score HUD
// ============================================================

class AuditScoreHud extends StatelessWidget {
  final double? score;
  final Map<String, SectionScore> sectionScores;
  const AuditScoreHud({
    super.key,
    required this.score,
    required this.sectionScores,
  });

  Color _scoreColor(ThemeData theme) => scoreColor(score, theme);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(theme);

    // Calculate total points from section scores
    final totalMax = sectionScores.values.fold(
      0.0,
      (sum, s) => sum + s.maxPoints,
    );
    final totalEarned = sectionScores.values.fold(
      0.0,
      (sum, s) => sum + s.score,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Score',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                score != null
                    ? '${totalEarned.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)} pts'
                    : 'Survey — No Score',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (score != null)
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                value: score! / 100,
                strokeWidth: 5,
                color: color,
                backgroundColor: color.withAlpha(30),
              ),
            ),
        ],
      ),
    );
  }
}

class AuditCollapsedScoreHud extends StatelessWidget {
  final double? score;
  final Map<String, SectionScore> sectionScores;
  const AuditCollapsedScoreHud({
    super.key,
    required this.score,
    required this.sectionScores,
  });

  Color _scoreColor(ThemeData theme) => scoreColor(score, theme);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(theme);

    // Calculate total points from section scores
    final totalMax = sectionScores.values.fold(
      0.0,
      (sum, s) => sum + s.maxPoints,
    );
    final totalEarned = sectionScores.values.fold(
      0.0,
      (sum, s) => sum + s.score,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.speed, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            score != null
                ? '${totalEarned.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)} pts'
                : 'Survey — No Score',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          Icon(Icons.keyboard_arrow_down, color: color),
        ],
      ),
    );
  }
}

class AuditScoreChip extends StatelessWidget {
  final double? score;
  const AuditScoreChip({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        score != null ? '${score!.toStringAsFixed(1)}%' : 'Survey',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}
