import 'dart:math';

import 'answer_input.dart';
import 'scoring_input.dart';
import 'scoring_result.dart';
import 'section_score.dart';
import 'scoring_helpers.dart';
import 'checklist_calculator.dart';

class PenaltyCalculator {
  // ── Penalty Mode (Top-Down) ──────────────────────────────
  // Algorithm: Start at max, subtract faults.
  // Weighted: Σ(sectionAfter/sectionBefore × weight) × 100
  // CCP: section with CCP fault → section ratio = 0
  // Checklist fallback when totalWeight == 0
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

    if (isWeighted) {
      final sectionResults = <({double ratio, double weight})>[];

      for (final section in input.sections) {
        final allCriteria = [
          ...section.criteria,
          ...section.subsections.expand((sub) => sub.criteria),
        ];

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

        double sectionBefore = 0.0;
        double sectionDeductions = 0.0;

        // Process subsections (3-level hierarchy)
        // subBefore = sum of actual criteria weights — matches server ScoringVerifier.VerifyPenalty().
        // sub.maxPoints is a DEDUCTION CAP only, never the denominator.
        for (final sub in section.subsections) {
          final subBefore = sub.criteria.fold<double>(
            0.0,
            (sum, c) => sum + c.pointsWeight,
          );
          sectionBefore += subBefore;
          if (subBefore == 0) continue;

          var subDeductions = sub.criteria.fold<double>(
            0.0,
            (sum, c) =>
                sum +
                ScoringHelpers.getDeduction(
                  c,
                  answerMap,
                  input.progressiveRepeatPenalty,
                ),
          );
          // Apply cap: explicit maxPoints cap if set, otherwise cap at subBefore
          final cap = sub.maxPoints > 0 ? sub.maxPoints : subBefore;
          subDeductions = min(subDeductions, cap);
          sectionDeductions += subDeductions;
        }

        // Process flat criteria (backward compatibility / 2-level hierarchy)
        if (section.criteria.isNotEmpty) {
          final flatBefore = section.criteria.fold<double>(
            0.0,
            (sum, c) => sum + c.pointsWeight,
          );
          sectionBefore += flatBefore;

          var flatDeductions = section.criteria.fold<double>(
            0.0,
            (sum, c) =>
                sum +
                ScoringHelpers.getDeduction(
                  c,
                  answerMap,
                  input.progressiveRepeatPenalty,
                ),
          );
          if (section.maxDeductionPoints != null) {
            flatDeductions = min(flatDeductions, section.maxDeductionPoints!);
          }
          sectionDeductions += flatDeductions;
        }

        if (sectionBefore == 0) continue;

        // CCP triggered: section score is 0%, but MUST keep its weight in the denominator!
        // Previously this used `continue` which excluded it from the total entirely,
        // causing artificially high scores even when critical failures occurred.
        if (ccpTriggered) {
          sectionScores[section.id] = SectionScore(
            sectionId: section.id,
            maxPoints: sectionBefore,
            deductions: sectionBefore,
            score: 0.0,
            hasCcpFailure: true,
            hasRiskFailure: riskInSection,
          );
          sectionResults.add((ratio: 0.0, weight: section.weight));
          continue;
        }

        final sectionAfter = max(0.0, sectionBefore - sectionDeductions);
        final sectionRatio = sectionAfter / sectionBefore;

        sectionResults.add((ratio: sectionRatio, weight: section.weight));

        sectionScores[section.id] = SectionScore(
          sectionId: section.id,
          maxPoints: sectionBefore,
          deductions: sectionDeductions,
          score: sectionAfter,
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
    } else {
      // No weights → checklist fallback (backward compat)
      return ChecklistCalculator.calculate(input, answerMap, hasRiskFailure);
    }
  }
}
