import 'answer_input.dart';
import 'scoring_mode.dart';
import 'section_input.dart';

/// Input to the scoring engine.
class ScoringInput {
  final List<SectionInput> sections;
  final List<AnswerInput> answers;
  final bool progressiveRepeatPenalty; // C3: enable n² repeat penalty
  final ScoringMode scoringMode; // NEW: explicit scoring mode
  // Global Risk flag: if true, score is forced to 0 regardless of answers.
  // Set by AuditManager when the auditor triggers at least one GlobalRisk.
  final bool hasGlobalRisk;
  final bool isWeighted; // NEW: enable weighted scoring (Slice 1)

  const ScoringInput({
    required this.sections,
    required this.answers,
    this.progressiveRepeatPenalty = false,
    this.scoringMode = ScoringMode.penalty, // backward compat
    this.hasGlobalRisk = false, // backward compat — existing callers unaffected
    this.isWeighted = false, // backward compat — defaults to false (unweighted)
  });
}
