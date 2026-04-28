import 'section_score.dart';

/// Result from the scoring engine.
class ScoringResult {
  /// Total audit score 0.00 – 100.00, rounded to 2 decimal places.
  /// Null when scoring mode is 'survey' (no-score data collection).
  final double? totalScore;

  /// Per-section score breakdown.
  final Map<String, SectionScore> sectionScores;

  /// Whether the audit has any RISK failure (total → 0).
  final bool hasRiskFailure;

  const ScoringResult({
    required this.totalScore,
    this.sectionScores = const {},
    this.hasRiskFailure = false,
  });
}
