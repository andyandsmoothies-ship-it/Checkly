import 'dart:math';

// ============================================================
// Data Models — match the test file's expected API exactly.
// ============================================================

/// Scoring mode for the template.
enum ScoringMode { penalty, accumulation, checklist, survey }

/// A single criterion (question) in a section.
class CriterionInput {
  final String id;
  final String groupId;
  final double pointsWeight;
  final bool isCcp;
  final bool isRisk;
  final double? minusImpact; // C4: overrides pointsWeight for deduction
  final String inputType; // 'numeric', 'pass_fail', 'scale'

  const CriterionInput({
    required this.id,
    required this.groupId,
    required this.pointsWeight,
    required this.isCcp,
    required this.isRisk,
    this.minusImpact,
    this.inputType = 'numeric',
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
  final ScoringMode scoringMode; // NEW: explicit scoring mode

  const ScoringInput({
    required this.sections,
    required this.answers,
    this.progressiveRepeatPenalty = false,
    this.scoringMode = ScoringMode.penalty, // backward compat
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

// ============================================================
// Scoring Engine — supports Penalty, Accumulation, Checklist, Survey.
//
// CCP/RISK flags come from BOTH template criteria AND answer overrides.
// ============================================================
class ScoringEngine {
  /// Calculates the audit score based on the scoring mode.
  static ScoringResult calculate(ScoringInput input) {
    // Survey mode: no scoring at all — return immediately
    if (input.scoringMode == ScoringMode.survey) {
      return const ScoringResult(totalScore: null);
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
            c.isRisk && answer != null && _hasFault(c, answer);

        if (isAnswerRisk || isTemplateRisk) {
          hasRiskFailure = true;
        }
      }
    }

    // --- Dispatch to mode-specific calculator ---
    switch (input.scoringMode) {
      case ScoringMode.penalty:
        return _calculatePenalty(input, answerMap, hasRiskFailure);
      case ScoringMode.accumulation:
        return _calculateAccumulation(input, answerMap, hasRiskFailure);
      case ScoringMode.checklist:
        return _calculateChecklist(input, answerMap, hasRiskFailure);
      case ScoringMode.survey:
        return const ScoringResult(totalScore: null); // unreachable
    }
  }

  // ── Penalty Mode (Top-Down) ──────────────────────────────
  // Algorithm: Start at max, subtract faults.
  // Weighted: Σ(sectionAfter/sectionBefore × weight) × 100
  // CCP: section with CCP fault → section ratio = 0
  // Checklist fallback when totalWeight == 0
  static ScoringResult _calculatePenalty(
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
          final hasFaults = answer != null && _hasFault(c, answer);
          final isTemplateCcp = c.isCcp && hasFaults;
          final isTemplateRisk = c.isRisk && hasFaults;

          if (isAnswerCcp || isTemplateCcp) ccpTriggered = true;
          if (isAnswerRisk || isTemplateRisk) riskInSection = true;
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
      // No weights → checklist fallback (backward compat)
      return _calculateChecklist(input, answerMap, hasRiskFailure);
    }
  }

  // ── Accumulation Mode (Zero-to-Top) ──────────────────────
  // Algorithm: Start at 0, earn points for correct answers.
  // Score = (totalEarned / totalPossible) × 100
  // CCP: if triggered, section earned = 0
  // RISK: if triggered, total = 0
  static ScoringResult _calculateAccumulation(
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
        final hasFaults = answer != null && _hasFault(c, answer);
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
    final totalScore = hasRiskFailure ? 0.0 : _round2(score);

    return ScoringResult(
      totalScore: totalScore,
      sectionScores: sectionScores,
      hasRiskFailure: hasRiskFailure,
    );
  }

  // ── Checklist Mode (Pass/Fail Ratio) ─────────────────────
  // Algorithm: max(0, 100 - Σ(all deductions))
  // No weights, no sections — just raw deductions from 100.
  static ScoringResult _calculateChecklist(
    ScoringInput input,
    Map<String, AnswerInput> answerMap,
    bool hasRiskFailure,
  ) {
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

  /// Determines if a criterion's answer constitutes a fault.
  /// Scale inputs: numericValue is earned points (fault = 0 earned).
  /// Other inputs: numericValue is fault count (fault = count > 0).
  static bool _hasFault(CriterionInput c, AnswerInput answer) {
    if (answer.value?.toLowerCase() == 'non_conform') return true;
    if (answer.repeatedFaults > 0) return true;
    if (c.inputType == 'scale') {
      // Scale: fault = scored 0 out of possible points
      return answer.numericValue == 0;
    }
    // Numeric/pass_fail: fault = numericValue > 0 (fault count)
    return (answer.numericValue ?? 0) > 0;
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
