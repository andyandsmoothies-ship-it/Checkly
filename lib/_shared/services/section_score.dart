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
