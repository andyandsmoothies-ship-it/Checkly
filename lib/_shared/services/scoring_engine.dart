import 'answer_input.dart';
import 'scoring_input.dart';
import 'scoring_mode.dart';
import 'scoring_result.dart';
import 'scoring_helpers.dart';
import 'penalty_calculator.dart';
import 'accumulation_calculator.dart';
import 'checklist_calculator.dart';

// ============================================================
// Scoring Engine — supports Penalty, Accumulation, Checklist, Survey.
//
// CCP/RISK flags come from BOTH template criteria AND answer overrides.
// ============================================================
class ScoringEngine {
  // Widgets that CAN carry scoring points. All others are metadata (transparent to purity).
  static const _kMeasurableTypes = {
    'pass_fail',
    'numeric',
    'scale',
    'single_choice',
    'multi_choice',
  };

  /// Returns true if every measurable criterion in the template has a points weight > 0.
  /// Metadata widgets (text, signature, photo, header, date, image) are transparent — they
  /// do not cause score suppression even if pointsWeight is 0.
  static bool _isPureAudit(ScoringInput input) {
    for (final section in input.sections) {
      for (final c in section.criteria) {
        if (_kMeasurableTypes.contains(c.inputType) && c.pointsWeight <= 0) {
          return false;
        }
      }
      for (final sub in section.subsections) {
        for (final c in sub.criteria) {
          if (_kMeasurableTypes.contains(c.inputType) && c.pointsWeight <= 0) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Calculates the audit score based on the scoring mode.
  static ScoringResult calculate(ScoringInput input) {
    // Survey mode: no scoring at all — return immediately
    if (input.scoringMode == ScoringMode.survey) {
      return const ScoringResult(totalScore: null);
    }

    // Purity gate: if any measurable criterion has no points, suppress score.
    // Mirrors ScoringVerifier.IsPureAudit() on the server — both must agree.
    if (!_isPureAudit(input)) {
      return const ScoringResult(
        totalScore: null,
      ); // Mixed audit — score suppressed
    }

    // Global Risk short-circuit: if the auditor has flagged at least one global
    // risk, the total score is immediately forced to 0. This mirrors the server's
    // SubmissionRisk check which runs before the ScoringVerifier math.
    // Gotcha 22: this MUST run after the purity gate but before the answer loop.
    if (input.hasGlobalRisk) {
      return const ScoringResult(totalScore: 0.0, hasRiskFailure: true);
    }

    final answerMap = <String, AnswerInput>{};
    for (final a in input.answers) {
      answerMap[a.criteriaId] = a;
    }

    // --- Check RISK at answer OR template level ---
    bool hasRiskFailure = false;
    for (final section in input.sections) {
      final allCriteria = [
        ...section.criteria,
        ...section.subsections.expand((sub) => sub.criteria),
      ];
      for (final c in allCriteria) {
        final answer = answerMap[c.id];
        final isAnswerRisk = answer?.isRisk ?? false;
        final isTemplateRisk =
            c.isRisk && answer != null && ScoringHelpers.hasFault(c, answer);

        if (isAnswerRisk || isTemplateRisk) {
          hasRiskFailure = true;
        }
      }
    }

    // --- Dispatch to mode-specific calculator ---
    switch (input.scoringMode) {
      case ScoringMode.penalty:
        return PenaltyCalculator.calculate(input, answerMap, hasRiskFailure);
      case ScoringMode.accumulation:
        return AccumulationCalculator.calculate(
          input,
          answerMap,
          hasRiskFailure,
        );
      case ScoringMode.checklist:
        return ChecklistCalculator.calculate(input, answerMap, hasRiskFailure);
      case ScoringMode.survey:
        return const ScoringResult(totalScore: null); // unreachable
    }
  }
}
