import 'package:flutter/material.dart';

import '../../../_shared/utils/score_utils.dart';
import '../../../_shared/services/section_score.dart';

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
    final isSurvey = score == null;

    if (isSurvey) {
      final surveyColor = const Color(0xFF7B1FA2);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              surveyColor.withAlpha(25),
              surveyColor.withAlpha(10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surveyColor.withAlpha(60), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: surveyColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment, color: surveyColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Survey Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: surveyColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Questions are not scored',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: surveyColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'SURVEY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
    final isSurvey = score == null;

    if (isSurvey) {
      final surveyColor = const Color(0xFF7B1FA2);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surveyColor.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surveyColor.withAlpha(60), width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.assignment, color: surveyColor, size: 24),
            const SizedBox(width: 12),
            Text(
              'Survey Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: surveyColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: surveyColor),
          ],
        ),
      );
    }

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
        score != null ? score!.toStringAsFixed(1) : 'Survey',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: Theme.of(context).textTheme.labelLarge?.fontSize,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}
