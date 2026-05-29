import 'dart:math';

import 'answer_input.dart';
import 'scoring_input.dart';
import 'scoring_result.dart';
import 'scoring_helpers.dart';
import 'section_score.dart';

class ChecklistCalculator {
  // ── Checklist Mode (Raw Deduction From 100) ──────────────
  // Algorithm: max(0, 100 - Σ(all deductions))
  // No weights, no sections — just raw deductions from 100.
  // Server formula: IDENTICAL — see server/Common/Scoring/ScoringVerifier.cs VerifyChecklist().
  // Server GEMINI.override.md locks this formula. Do NOT change to a ratio/division formula.
  static ScoringResult calculate(
    ScoringInput input,
    Map<String, AnswerInput> answerMap,
    bool hasRiskFailure,
  ) {
    final allCriteria = input.sections.expand(
      (s) => [...s.criteria, ...s.subsections.expand((sub) => sub.criteria)],
    );

    bool ccpTriggered = false;
    for (final c in allCriteria) {
      final answer = answerMap[c.id];
      final isAnswerCcp = answer?.isCcp ?? false;
      final isTemplateCcp =
          c.isCcp && answer != null && ScoringHelpers.hasFault(c, answer);
      if (isAnswerCcp || isTemplateCcp) {
        ccpTriggered = true;
        break;
      }
    }

    final totalDeductions = allCriteria.fold<double>(
      0.0,
      (sum, c) =>
          sum +
          ScoringHelpers.getDeduction(
            c,
            answerMap,
            input.progressiveRepeatPenalty,
          ),
    );
    double score = max(0.0, 100.0 - totalDeductions);

    if (ccpTriggered) {
      score = 0.0;
    }

    final sectionScores = <String, SectionScore>{};
    for (final section in input.sections) {
      final sectionCriteria = [
        ...section.criteria,
        ...section.subsections.expand((sub) => sub.criteria),
      ];

      if (sectionCriteria.isEmpty) continue;

      bool sectionCcp = false;
      bool sectionRisk = false;

      for (final c in sectionCriteria) {
        final answer = answerMap[c.id];
        final isAnswerCcp = answer?.isCcp ?? false;
        final isAnswerRisk = answer?.isRisk ?? false;
        final hasFaults = answer != null && ScoringHelpers.hasFault(c, answer);
        final isTemplateCcp = c.isCcp && hasFaults;
        final isTemplateRisk = c.isRisk && hasFaults;

        if (isAnswerCcp || isTemplateCcp) sectionCcp = true;
        if (isAnswerRisk || isTemplateRisk) sectionRisk = true;
      }

      final maxPoints = sectionCriteria.length.toDouble();
      final deductionsCount = sectionCriteria
          .where((c) {
            final answer = answerMap[c.id];
            return answer != null && ScoringHelpers.hasFault(c, answer);
          })
          .length
          .toDouble();

      final sectionScoreValue = max(0.0, maxPoints - deductionsCount);

      sectionScores[section.id] = SectionScore(
        sectionId: section.id,
        maxPoints: maxPoints,
        deductions: deductionsCount,
        score: sectionScoreValue,
        hasCcpFailure: sectionCcp,
        hasRiskFailure: sectionRisk,
      );
    }

    return ScoringResult(
      totalScore: hasRiskFailure ? 0.0 : ScoringHelpers.round2(score),
      sectionScores: sectionScores,
      hasRiskFailure: hasRiskFailure,
    );
  }
}
