import 'dart:convert';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';

/// Serialises [EditableCriterion] to the server's expected shape.
/// BL-2 / Gotcha #11: excludes pointsWeight for text/choice types at ALL depths.
Map<String, dynamic> buildCriterion(
  EditableCriterion c,
  int ci,
  bool confirmCorrect,
) {
  final bool isChoiceType =
      c.inputType == 'single_choice' || c.inputType == 'multi_choice';
  final bool isScaleType = c.inputType == 'scale';
  return <String, dynamic>{
    'label': c.labelCtrl.text,
    if (c.descCtrl.text.isNotEmpty) 'description': c.descCtrl.text,
    'inputType': c.inputType,
    if (!isChoiceType && c.inputType != 'text')
      'pointsWeight': double.tryParse(c.pointsCtrl.text),
    if (!isChoiceType &&
        c.inputType != 'text' &&
        c.minusImpactCtrl.text.isNotEmpty)
      'minusImpact': double.tryParse(c.minusImpactCtrl.text),
    if (!isChoiceType &&
        c.inputType != 'text' &&
        c.maxDeductionCtrl.text.isNotEmpty)
      'maxDeductionPoints': double.tryParse(c.maxDeductionCtrl.text),
    'isCcp': c.isCcp,
    'isRisk': c.isRisk,
    'orderIndex': ci,
    if (c.isRequired || confirmCorrect) 'isRequired': true,
    if (isChoiceType && c.choiceOptions.isNotEmpty)
      'metadata': json.encode({'options': c.choiceOptions}),
    if (isScaleType && c.scaleOptions.isNotEmpty)
      'metadata': json.encode({'scaleOptions': c.scaleOptions}),
  };
}

/// Recursively serialises a [List<EditableGroup>] into the server's group shape.
/// BL-1: matches `template_builder_page.dart` shape — {title, orderIndex, children, criteria}.
List<Map<String, dynamic>> buildGroupsRecursive(
  List<EditableGroup> groups,
  bool confirmCorrect,
) {
  return groups.asMap().entries.map((e) {
    final i = e.key;
    final s = e.value;
    // P2: Mutual-exclusivity invariant — a group must NOT contain both flat
    // criteria AND nested sub-sections. The UI enforces this; this assert
    // guards against corrupted payloads that bypass the UI guard.
    assert(
      s.criteria.isEmpty || s.subSections.isEmpty,
      'Group "${s.titleCtrl.text}" violates mutual-exclusivity: '
      'has ${s.criteria.length} criteria AND ${s.subSections.length} sub-sections.',
    );
    return <String, dynamic>{
      'title': s.titleCtrl.text,
      if (s.descCtrl.text.isNotEmpty) 'description': s.descCtrl.text,
      'orderIndex': i,
      'children': buildGroupsRecursive(s.subSections, confirmCorrect),
      'criteria': s.criteria
          .asMap()
          .entries
          .map((ce) => buildCriterion(ce.value, ce.key, confirmCorrect))
          .toList(),
    };
  }).toList();
}

List<Map<String, dynamic>> buildGroups(
  List<EditableGroup> sections,
  bool confirmCorrect,
) {
  return buildGroupsRecursive(sections, confirmCorrect);
}

String buildScoringLogicConfig({
  required String scoringMode,
  required bool ccpOverride,
  required bool riskOverride,
  required bool weightedDensity,
  required bool progressiveRepeat,
  required bool confirmCorrect,
  required String deadlineDays,
  required String reminderDays,
}) {
  return json.encode({
    'scoringMode': scoringMode,
    'ccpOverride': ccpOverride,
    'riskOverride': riskOverride,
    'weightedDensity': weightedDensity,
    'progressiveRepeat': progressiveRepeat,
    'confirmCorrect': confirmCorrect,
    'deadlineDays': int.tryParse(deadlineDays) ?? 7,
    'reminderDays': int.tryParse(reminderDays) ?? 2,
  });
}
