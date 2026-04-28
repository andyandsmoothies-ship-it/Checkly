/// A single criterion (question) in a section.
class CriterionInput {
  final String id;
  final String groupId;
  final double pointsWeight;
  final bool isCcp;
  final bool isRisk;
  final double? minusImpact; // C4: overrides pointsWeight for deduction
  final double? maxDeductionPoints; // Phase 1A: per-criterion deduction cap
  final String inputType; // 'numeric', 'pass_fail', 'scale'

  const CriterionInput({
    required this.id,
    required this.groupId,
    required this.pointsWeight,
    required this.isCcp,
    required this.isRisk,
    this.minusImpact,
    this.maxDeductionPoints,
    this.inputType = 'numeric',
  });
}
