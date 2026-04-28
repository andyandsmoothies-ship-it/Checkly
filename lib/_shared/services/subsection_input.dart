import 'criterion_input.dart';

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
