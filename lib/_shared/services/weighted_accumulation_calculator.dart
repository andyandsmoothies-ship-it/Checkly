import 'dart:math';

import 'answer_input.dart';
import 'scoring_input.dart';
import 'scoring_result.dart';
import 'section_score.dart';
import 'scoring_helpers.dart';
import 'accumulation_calculator.dart';

class WeightedAccumulationCalculator {
  // ── Weighted Accumulation Mode (Shape B) ──────────────────────
  // Algorithm: Start at 0, earn points forward.
  // Weighted: Σ(sectionEarned/sectionPossible × weight) × 100
  // CCP: section with CCP fault → section score = 0%, but weight STILL counts in denominator!
  // Fallback to AccumulationCalculator when totalWeight == 0
  static ScoringResult calculate(
    ScoringInput input,
    Map<String, AnswerInput> answerMap,
    bool hasRiskFailure,
  ) {
    final sectionScores = <String, SectionScore>{};

    final totalWeight = input.sections.fold<double>(
      0.0,
      (sum, s) => sum + s.weight,
    );
    final isWeighted = totalWeight > 0;

    if (!isWeighted) {
      // Fallback: no weights → unweighted accumulation
      return AccumulationCalculator.calculate(input, answerMap, hasRiskFailure);
    }

    final sectionResults = <({double ratio, double weight})>[];

    for (final section in input.sections) {
      final allCriteria = [
        ...section.criteria,
        ...section.subsections.expand((sub) => sub.criteria),
      ];

      // CCP / Risk check
      bool ccpTriggered = false;
      bool riskInSection = false;
      for (final c in allCriteria) {
        final answer = answerMap[c.id];
        final isAnswerCcp = answer?.isCcp ?? false;
        final isAnswerRisk = answer?.isRisk ?? false;
        final hasFaults =
            answer != null && ScoringHelpers.hasFault(c, answer);
        final isTemplateCcp = c.isCcp && hasFaults;
        final isTemplateRisk = c.isRisk && hasFaults;

        if (isAnswerCcp || isTemplateCcp) ccpTriggered = true;
        if (isAnswerRisk || isTemplateRisk) riskInSection = true;
      }

      double sectionPossible = 0.0;
      double sectionEarned = 0.0;

      for (final c in allCriteria) {
        sectionPossible += c.pointsWeight;
        final answer = answerMap[c.id];
        if (answer == null) continue;

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

      if (sectionPossible == 0) continue;

      if (ccpTriggered) {
        sectionEarned = 0.0;
        sectionScores[section.id] = SectionScore(
          sectionId: section.id,
          maxPoints: sectionPossible,
          deductions: sectionPossible,
          score: 0.0,
          hasCcpFailure: true,
          hasRiskFailure: riskInSection,
        );
        sectionResults.add((ratio: 0.0, weight: section.weight));
        continue;
      }

      final sectionRatio = sectionEarned / sectionPossible;
      sectionResults.add((ratio: sectionRatio, weight: section.weight));

      sectionScores[section.id] = SectionScore(
        sectionId: section.id,
        maxPoints: sectionPossible,
        deductions: sectionPossible - sectionEarned,
        score: sectionEarned,
        hasCcpFailure: false,
        hasRiskFailure: riskInSection,
      );
    }

    // Normalize weights and compute final score
    final participatingWeight = sectionResults.fold<double>(
      0.0,
      (sum, r) => sum + r.weight,
    );

    var finalScore = 0.0;
    if (participatingWeight > 0) {
      for (final r in sectionResults) {
        finalScore += r.ratio * (r.weight / participatingWeight);
      }
    }

    final score = finalScore * 100.0;
    final totalScore = hasRiskFailure ? 0.0 : ScoringHelpers.round2(score);

    return ScoringResult(
      totalScore: totalScore,
      sectionScores: sectionScores,
      hasRiskFailure: hasRiskFailure,
    );
  }
}
