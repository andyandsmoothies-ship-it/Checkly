import 'dart:convert';
import '../models/editable_criterion.dart';
import '../models/editable_group.dart';

/// Serializes [EditableCriterion] to the server's expected shape.
/// BL-2 / Gotcha #11: excludes pointsWeight, minusImpact, and maxDeductionPoints for text/choice types at ALL depths.
Map<String, dynamic> buildCriterionPayload({
  required EditableCriterion criterion,
  required int orderIndex,
  required bool confirmCorrect,
  required bool isEditMode,
}) {
  final bool isChoiceType =
      criterion.inputType == 'single_choice' ||
      criterion.inputType == 'multi_choice';
  final bool isScaleType = criterion.inputType == 'scale';

  final meta = <String, dynamic>{};
  if (criterion.isRequired || confirmCorrect) meta['isRequired'] = true;
  if (isScaleType && criterion.scaleOptions.isNotEmpty) {
    meta['scaleOptions'] = criterion.scaleOptions;
  }
  if (isChoiceType && criterion.choiceOptions.isNotEmpty) {
    meta['options'] = criterion.choiceOptions;
  }

  return <String, dynamic>{
    if (isEditMode && criterion.id.isNotEmpty) 'id': criterion.id,
    'label': criterion.labelCtrl.text,
    if (criterion.descCtrl.text.isNotEmpty)
      'description': criterion.descCtrl.text,
    'inputType': criterion.inputType,
    if (!isChoiceType && criterion.inputType != 'text')
      'pointsWeight': double.tryParse(criterion.pointsCtrl.text),
    if (!isChoiceType &&
        criterion.inputType != 'text' &&
        criterion.minusImpactCtrl.text.isNotEmpty)
      'minusImpact': double.tryParse(criterion.minusImpactCtrl.text),
    if (!isChoiceType &&
        criterion.inputType != 'text' &&
        criterion.maxDeductionCtrl.text.isNotEmpty)
      'maxDeductionPoints': double.tryParse(criterion.maxDeductionCtrl.text),
    'isCcp': criterion.isCcp,
    'isRisk': criterion.isRisk,
    'orderIndex': orderIndex,
    if (meta.isNotEmpty) 'metadata': json.encode(meta),
  };
}

/// Recursively serializes a [List<EditableGroup>] into the server's group shape.
List<Map<String, dynamic>> buildGroupsPayload({
  required List<EditableGroup> groups,
  required bool confirmCorrect,
  required bool isEditMode,
}) {
  return groups.asMap().entries.map((e) {
    final i = e.key;
    final s = e.value;
    // P2: Mutual-exclusivity invariant
    assert(
      s.criteria.isEmpty || s.subSections.isEmpty,
      'Group "${s.titleCtrl.text}" violates mutual-exclusivity: '
      'has ${s.criteria.length} criteria AND ${s.subSections.length} sub-sections.',
    );

    // Build metadata JSON for sub-section fields
    String? metadata;
    if (s.maxPointsCtrl.text.isNotEmpty ||
        s.minusPerFaultCtrl.text.isNotEmpty) {
      metadata = json.encode({
        if (s.maxPointsCtrl.text.isNotEmpty)
          'subsection_max_points': double.tryParse(s.maxPointsCtrl.text),
        if (s.minusPerFaultCtrl.text.isNotEmpty)
          'minus_per_fault': double.tryParse(s.minusPerFaultCtrl.text),
      });
    }

    return <String, dynamic>{
      if (isEditMode && s.id.isNotEmpty) 'id': s.id,
      'title': s.titleCtrl.text,
      if (s.descCtrl.text.isNotEmpty) 'description': s.descCtrl.text,
      if (double.tryParse(s.weightCtrl.text) != null)
        'weight': double.tryParse(s.weightCtrl.text),
      if (double.tryParse(s.maxPointsCtrl.text) != null)
        'maxDeductionPoints': double.tryParse(s.maxPointsCtrl.text),
      if (double.tryParse(s.minusPerFaultCtrl.text) != null)
        'minusPerFault': double.tryParse(s.minusPerFaultCtrl.text),
      'orderIndex': i,
      'metadata': metadata,
      'children': buildGroupsPayload(
        groups: s.subSections,
        confirmCorrect: confirmCorrect,
        isEditMode: isEditMode,
      ),
      'criteria': s.criteria
          .asMap()
          .entries
          .map(
            (ce) => buildCriterionPayload(
              criterion: ce.value,
              orderIndex: ce.key,
              confirmCorrect: confirmCorrect,
              isEditMode: isEditMode,
            ),
          )
          .toList(),
    };
  }).toList();
}

/// Serializes the scoring logic configuration into a JSON string.
String buildScoringLogicConfig({
  required String scoreDirection,
  required bool isWeighted,
  required bool ccpOverride,
  required bool riskOverride,
  required bool weightedDensity,
  required bool progressiveRepeat,
  required bool confirmCorrect,
  required String deadlineDays,
  required String reminderDays,
}) {
  final String scoringMode = scoreDirection == 'none'
      ? 'survey'
      : (scoreDirection == 'up'
          ? 'accumulation'
          : (isWeighted ? 'penalty' : 'checklist'));

  return json.encode({
    'scoreDirection': scoreDirection,
    'isWeighted': isWeighted,
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
