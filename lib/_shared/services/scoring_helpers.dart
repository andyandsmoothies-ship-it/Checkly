import 'dart:math';

import 'answer_input.dart';
import 'criterion_input.dart';

class ScoringHelpers {
  /// Determines if a criterion's answer constitutes a fault.
  /// Scale inputs: numericValue is earned points (fault = 0 earned).
  /// Other inputs: numericValue is fault count (fault = count > 0).
  static bool hasFault(CriterionInput c, AnswerInput answer) {
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
  static double getDeduction(
    CriterionInput criterion,
    Map<String, AnswerInput> answerMap,
    bool progressiveRepeatPenalty,
  ) {
    final answer = answerMap[criterion.id];
    if (answer == null) return 0.0;
    // Mirror of ScoringVerifier.GetDeduction(): conform/na → no deduction, regardless of numericValue.
    final v = answer.value?.toLowerCase();
    if (v == 'conform' || v == 'na') return 0.0;
    final impact = criterion.minusImpact ?? criterion.pointsWeight;
    final faults = answer.numericValue ?? 0;
    final baseDeduction = faults * impact;

    double totalDeduction = baseDeduction;
    // progressive repeat penalty (n² × impact)
    if (progressiveRepeatPenalty && answer.repeatedFaults > 0) {
      final repeatDeduction =
          answer.repeatedFaults * answer.repeatedFaults * impact;
      totalDeduction = baseDeduction + repeatDeduction;
    } else if (answer.repeatedFaults > 0) {
      // Linear repeat penalty
      totalDeduction = baseDeduction + (answer.repeatedFaults * impact);
    }

    if (criterion.maxDeductionPoints != null) {
      return min(totalDeduction, criterion.maxDeductionPoints!);
    }
    return totalDeduction;
  }

  /// Rounds to 2 decimal places.
  static double round2(double value) {
    return (value * 100).round() / 100.0;
  }
}
