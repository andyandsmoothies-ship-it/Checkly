import 'answer_input.dart';
import 'scoring_input.dart';
import 'scoring_result.dart';
import 'section_score.dart';
import 'scoring_helpers.dart';

class AccumulationCalculator {
  // ── Accumulation Mode (Zero-to-Top) ──────────────────────
  // Algorithm: Start at 0, earn points for correct answers.
  // Score = (totalEarned / totalPossible) × 100
  // CCP: if triggered, section earned = 0
  // RISK: if triggered, total = 0
  static ScoringResult calculate(
    ScoringInput input,
    Map<String, AnswerInput> answerMap,
    bool hasRiskFailure,
  ) {
    final sectionScores = <String, SectionScore>{};
    double totalPossible = 0.0;
    double totalEarned = 0.0;

    for (final section in input.sections) {
      final allCriteria = [
        ...section.criteria,
        ...section.subsections.expand((sub) => sub.criteria),
      ];

      // CCP check
      bool ccpTriggered = false;
      bool riskInSection = false;
      for (final c in allCriteria) {
        final answer = answerMap[c.id];
        final isAnswerCcp = answer?.isCcp ?? false;
        final isAnswerRisk = answer?.isRisk ?? false;
        final hasFaults = answer != null && ScoringHelpers.hasFault(c, answer);
        final isTemplateCcp = c.isCcp && hasFaults;
        final isTemplateRisk = c.isRisk && hasFaults;

        if (isAnswerCcp || isTemplateCcp) ccpTriggered = true;
        if (isAnswerRisk || isTemplateRisk) riskInSection = true;
      }

      // Sum points possible and earned
      double sectionPossible = 0.0;
      double sectionEarned = 0.0;

      for (final c in allCriteria) {
        sectionPossible += c.pointsWeight;
        final answer = answerMap[c.id];
        if (answer == null) continue;

        // Correct = no faults AND not non_conform
        if (c.inputType == 'scale' && answer.numericValue != null) {
          // Scale: numericValue IS the earned points (partial credit)
          sectionEarned += answer.numericValue!;
        } else {
          // Binary: full points if no faults, 0 if any fault
          final faults = answer.numericValue ?? 0;
          final isNonConform = answer.value?.toLowerCase() == 'non_conform';
          if (faults == 0 && !isNonConform && answer.repeatedFaults == 0) {
            sectionEarned += c.pointsWeight;
          }
        }
      }

      totalPossible += sectionPossible;

      if (ccpTriggered) {
        sectionEarned = 0.0;
      }
      totalEarned += sectionEarned;

      if (sectionPossible > 0) {
        sectionScores[section.id] = SectionScore(
          sectionId: section.id,
          maxPoints: sectionPossible,
          deductions: sectionPossible - sectionEarned,
          score: sectionEarned,
          hasCcpFailure: ccpTriggered,
          hasRiskFailure: riskInSection,
        );
      }
    }

    final score = totalPossible > 0
        ? (totalEarned / totalPossible) * 100.0
        : 100.0;
    final totalScore = hasRiskFailure ? 0.0 : ScoringHelpers.round2(score);

    return ScoringResult(
      totalScore: totalScore,
      sectionScores: sectionScores,
      hasRiskFailure: hasRiskFailure,
    );
  }
}
