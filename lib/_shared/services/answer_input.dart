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
