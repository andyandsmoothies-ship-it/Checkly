import 'dart:math';

// ============================================================
// Data Models — match the test file's expected API exactly.
// ============================================================

/// A single criterion (question) in a section.
class CriterionInput {
  final String id;
  final String groupId;
  final double pointsWeight;
  final bool isCcp;
  final bool isRisk;
  final double? minusImpact; // C4: overrides pointsWeight for deduction

  const CriterionInput({
    required this.id,
    required this.groupId,
    required this.pointsWeight,
    required this.isCcp,
    required this.isRisk,
    this.minusImpact,
  });
}

/// A subsection (child group) containing criteria.
class SubsectionInput {
  final String id;
  final String title;
  final double maxPoints;
  final List<CriterionInput> criteria;

  const SubsectionInput({
    required this.id,
    required this.title,
    required this.maxPoints,
    required this.criteria,
  });
}

/// A section (group) containing subsections and/or flat criteria.
class SectionInput {
  final String id;
  final double weight;
  final double? maxDeductionPoints; // For backward compat if applied to section
  final List<SubsectionInput> subsections;
  final List<CriterionInput> criteria;

  const SectionInput({
    required this.id,
    required this.weight,
    this.maxDeductionPoints,
    this.subsections = const [],
    this.criteria = const [],
  });
}

/// An answer for a criterion.
class AnswerInput {
  final String criteriaId;
  final double? numericValue;
  final String? value;
  final int repeatedFaults;
  final bool isCcp; // answer-level CCP override
  final bool isRisk; // answer-level RISK override

  const AnswerInput({
    required this.criteriaId,
    this.numericValue,
    this.value,
    this.repeatedFaults = 0,
    this.isCcp = false,
    this.isRisk = false,
  });
}

/// Input to the scoring engine.
class ScoringInput {
  final List<SectionInput> sections;
  final List<AnswerInput> answers;
  final bool progressiveRepeatPenalty; // C3: enable n² repeat penalty

  const ScoringInput({
    required this.sections,
    required this.answers,
    this.progressiveRepeatPenalty = false,
  });
}

/// Per-section score breakdown.
class SectionScore {
  final String sectionId;
  final double maxPoints;
  final double deductions;
  final double score; // maxPoints - deductions, or 0 if CCP triggered
  final bool hasCcpFailure;
  final bool hasRiskFailure;

  const SectionScore({
    required this.sectionId,
    required this.maxPoints,
    required this.deductions,
    required this.score,
    required this.hasCcpFailure,
    required this.hasRiskFailure,
  });
}

/// Result from the scoring engine.
class ScoringResult {
  /// Total audit score 0.00 – 100.00, rounded to 2 decimal places.
  final double totalScore;

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

// ============================================================
// Scoring Engine — Dart port of PWA scoringEngine.ts.
//
// Algorithm (5 rules, executed in order):
// 1. Fault detection: numericValue > 0 OR value == "non_conform"
// 2. RISK override: any RISK criterion with faults → 0%
// 3. Weighted mode: Σ(sectionAfter/sectionBefore × weight/100) × 100
// 4. CCP override: section with CCP fault → section ratio = 0
// 5. Checklist fallback: max(0, 100 - Σ(all deductions))
//
// CCP/RISK flags come from BOTH template criteria AND answer overrides.
// ============================================================
class ScoringEngine {
  /// Calculates the audit score.
  static ScoringResult calculate(ScoringInput input) {
    final answerMap = <String, AnswerInput>{};
    for (final a in input.answers) {
      answerMap[a.criteriaId] = a;
    }

    final sectionScores = <String, SectionScore>{};

    // --- Check RISK at answer OR template level ---
    // RISK triggers even when just toggled (no faults required) - user requested
    bool hasRiskFailure = false;
    for (final section in input.sections) {
      final allCriteria = [
        ...section.criteria,
        ...section.subsections.expand((sub) => sub.criteria),
      ];
      for (final c in allCriteria) {
        final answer = answerMap[c.id];
        final isAnswerRisk = answer?.isRisk ?? false;
        final hasFaults =
            answer != null &&
            ((answer.numericValue ?? 0) > 0 ||
                answer.value?.toLowerCase() == 'non_conform' ||
                answer.repeatedFaults > 0);
        final isTemplateRisk = c.isRisk && hasFaults;

        if (isAnswerRisk || isTemplateRisk) {
          hasRiskFailure = true;
        }
      }
    }

    // --- Determine mode ---
    final totalWeight = input.sections.fold<double>(
      0.0,
      (sum, s) => sum + s.weight,
    );
    final isWeighted = totalWeight > 0;

    if (isWeighted) {
      // Weighted mode with CCP, per-section scores
      final sectionResults = <({double ratio, double weight})>[];

      for (final section in input.sections) {
        // CCP/RISK check across all criteria in section (flat + nested)
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
              answer != null &&
              ((answer.numericValue ?? 0) > 0 ||
                  answer.value?.toLowerCase() == 'non_conform' ||
                  answer.repeatedFaults > 0);

          final isTemplateCcp = c.isCcp && hasFaults;
          final isTemplateRisk = c.isRisk && hasFaults;

          if (isAnswerCcp || isTemplateCcp) {
            ccpTriggered = true;
          }
          if (isAnswerRisk || isTemplateRisk) {
            riskInSection = true;
          }
        }

        double sectionBefore = 0.0;
        double sectionDeductions = 0.0;

        // Process subsections (3-level hierarchy)
        for (final sub in section.subsections) {
          sectionBefore += sub.maxPoints;

          if (sub.maxPoints == 0) continue;

          var subDeductions = sub.criteria.fold<double>(
            0.0,
            (sum, c) =>
                sum +
                _getDeduction(c, answerMap, input.progressiveRepeatPenalty),
          );

          // Subsection cap
          subDeductions = min(subDeductions, sub.maxPoints);
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
                _getDeduction(c, answerMap, input.progressiveRepeatPenalty),
          );

          // Section-level cap for flat criteria (if provided)
          if (section.maxDeductionPoints != null) {
            flatDeductions = min(flatDeductions, section.maxDeductionPoints!);
          }
          sectionDeductions += flatDeductions;
        }

        if (sectionBefore == 0) continue;

        final sectionAfter = max(0.0, sectionBefore - sectionDeductions);
        final sectionRatio = ccpTriggered
            ? 0.0
            : (sectionAfter / sectionBefore);

        sectionResults.add((ratio: sectionRatio, weight: section.weight));

        sectionScores[section.id] = SectionScore(
          sectionId: section.id,
          maxPoints: sectionBefore,
          deductions: sectionDeductions,
          score: ccpTriggered ? 0.0 : sectionAfter,
          hasCcpFailure: ccpTriggered,
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
      final totalScore = hasRiskFailure ? 0.0 : _round2(score);
      return ScoringResult(
        totalScore: totalScore,
        sectionScores: sectionScores,
        hasRiskFailure: hasRiskFailure,
      );
    } else {
      // Checklist fallback
      final allCriteria = input.sections.expand(
        (s) => [...s.criteria, ...s.subsections.expand((sub) => sub.criteria)],
      );

      final totalDeductions = allCriteria.fold<double>(
        0.0,
        (sum, c) =>
            sum + _getDeduction(c, answerMap, input.progressiveRepeatPenalty),
      );
      final score = max(0.0, 100.0 - totalDeductions);
      return ScoringResult(
        totalScore: hasRiskFailure ? 0.0 : _round2(score),
        hasRiskFailure: hasRiskFailure,
      );
    }
  }

  /// Calculates deduction for a criterion.
  static double _getDeduction(
    CriterionInput criterion,
    Map<String, AnswerInput> answerMap,
    bool progressiveRepeatPenalty,
  ) {
    final answer = answerMap[criterion.id];
    if (answer == null) return 0.0;
    final impact = criterion.minusImpact ?? criterion.pointsWeight;
    final faults = answer.numericValue ?? 0;
    final baseDeduction = faults * impact;
    // progressive repeat penalty (n² × impact)
    if (progressiveRepeatPenalty && answer.repeatedFaults > 0) {
      final repeatDeduction =
          answer.repeatedFaults * answer.repeatedFaults * impact;
      return baseDeduction + repeatDeduction;
    }
    // Linear repeat penalty
    if (answer.repeatedFaults > 0) {
      return baseDeduction + (answer.repeatedFaults * impact);
    }
    return baseDeduction;
  }

  /// Rounds to 2 decimal places.
  static double _round2(double value) {
    return (value * 100).round() / 100.0;
  }
}
