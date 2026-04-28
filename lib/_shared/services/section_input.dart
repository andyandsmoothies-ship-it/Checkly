import 'criterion_input.dart';
import 'subsection_input.dart';

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
