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

  const CriterionInput({
    required this.id,
    required this.groupId,
    required this.pointsWeight,
    required this.isCcp,
    required this.isRisk,
  });
}

/// A section (group) containing criteria.
class SectionInput {
  final String id;
  final double weight;
  final double? maxDeductionPoints;
  final List<CriterionInput> criteria;

  const SectionInput({
    required this.id,
    required this.weight,
    this.maxDeductionPoints,
    required this.criteria,
  });
}

/// An answer for a criterion.
class AnswerInput {
  final String criteriaId;
  final double? numericValue;
  final String? value;

  const AnswerInput({required this.criteriaId, this.numericValue, this.value});
}

/// Input to the scoring engine.
class ScoringInput {
  final List<SectionInput> sections;
  final List<AnswerInput> answers;

  const ScoringInput({required this.sections, required this.answers});
}

/// Result from the scoring engine.
class ScoringResult {
  /// Total audit score 0.00 – 100.00, rounded to 2 decimal places.
  final double totalScore;

  const ScoringResult({required this.totalScore});
}

// ============================================================
// Scoring Engine — Dart port of C# ScoringVerifier.
//
// Algorithm (5 rules, executed in order):
// 1. Fault detection: numericValue > 0 OR value == "non_conform"
// 2. RISK override: any RISK criterion with faults → 0%
// 3. Weighted mode: Σ(sectionAfter/sectionBefore × weight/100) × 100
// 4. CCP override: section with CCP fault → section ratio = 0
// 5. Checklist fallback: max(0, 100 - Σ(all deductions))
// ============================================================
class ScoringEngine {
  /// Calculates the audit score matching the C# ScoringVerifier.
  static ScoringResult calculate(ScoringInput input) {
    final allCriteria = input.sections.expand((s) => s.criteria).toList();

    // --- Rule 1+2: RISK override ---
    final riskTriggered = allCriteria
        .where((c) => c.isRisk)
        .any((c) => _hasFaults(c, input.answers));

    if (riskTriggered) {
      return const ScoringResult(totalScore: 0.00);
    }

    // --- Determine mode ---
    final totalWeight = input.sections.fold<double>(
      0.0,
      (sum, s) => sum + s.weight,
    );
    final isWeighted = totalWeight > 0;

    if (isWeighted) {
      // --- Rule 3+4: Weighted mode with CCP and MaxDeductionPoints ---
      // Two-pass: first identify participating sections, then normalize weights.

      // Pass 1: Collect section results (skip empty and CCP-triggered sections)
      final sectionResults = <({double ratio, double weight})>[];

      for (final section in input.sections) {
        final criteria = section.criteria;

        // Rule 4: CCP override — if any CCP criterion has faults, section = 0
        final ccpTriggered = criteria
            .where((c) => c.isCcp)
            .any((c) => _hasFaults(c, input.answers));

        if (ccpTriggered) {
          // CCP: section ratio = 0 but it DOES participate in weighting
          sectionResults.add((ratio: 0.0, weight: section.weight));
          continue;
        }

        final sectionBefore = criteria.fold<double>(
          0.0,
          (sum, c) => sum + c.pointsWeight,
        );

        // Skip empty sections — they don't participate in weighting
        if (sectionBefore == 0) continue;

        var sectionDeductions = criteria.fold<double>(
          0.0,
          (sum, c) => sum + _getDeduction(c, input.answers),
        );

        // MaxDeductionPoints cap
        if (section.maxDeductionPoints != null) {
          sectionDeductions = min(
            sectionDeductions,
            section.maxDeductionPoints!,
          );
        }

        final sectionAfter = max(0.0, sectionBefore - sectionDeductions);
        final sectionRatio = sectionAfter / sectionBefore;

        sectionResults.add((ratio: sectionRatio, weight: section.weight));
      }

      // Pass 2: Normalize weights and compute final score
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
      return ScoringResult(totalScore: _round2(score));
    } else {
      // --- Rule 5: Checklist fallback ---
      final totalDeductions = allCriteria.fold<double>(
        0.0,
        (sum, c) => sum + _getDeduction(c, input.answers),
      );
      final score = max(0.0, 100.0 - totalDeductions);
      return ScoringResult(totalScore: _round2(score));
    }
  }

  // ----------------------------------------------------------
  // Private helpers
  // ----------------------------------------------------------

  /// Rule 1: Fault detection.
  /// A criterion has faults if numericValue > 0 OR value == "non_conform".
  static bool _hasFaults(CriterionInput criterion, List<AnswerInput> answers) {
    final answer = answers
        .where((a) => a.criteriaId == criterion.id)
        .firstOrNull;
    if (answer == null) return false;
    return (answer.numericValue ?? 0) > 0 ||
        answer.value?.toLowerCase() == 'non_conform';
  }

  /// Calculates deduction for a criterion: faults × pointsWeight.
  static double _getDeduction(
    CriterionInput criterion,
    List<AnswerInput> answers,
  ) {
    final answer = answers
        .where((a) => a.criteriaId == criterion.id)
        .firstOrNull;
    if (answer == null) return 0.0;
    final faults = answer.numericValue ?? 0;
    return faults * criterion.pointsWeight;
  }

  /// Rounds to 2 decimal places: (score * 100).round() / 100.0
  static double _round2(double value) {
    return (value * 100).round() / 100.0;
  }
}
