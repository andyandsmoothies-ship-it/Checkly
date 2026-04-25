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
  // Global Risk flag: if true, score is forced to 0 regardless of answers.
  // Set by AuditManager when the auditor triggers at least one GlobalRisk.
  final bool hasGlobalRisk;

  const ScoringInput({
    required this.sections,
    required this.answers,
    this.progressiveRepeatPenalty = false,
    this.scoringMode = ScoringMode.penalty, // backward compat
    this.hasGlobalRisk = false, // backward compat — existing callers unaffected
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
