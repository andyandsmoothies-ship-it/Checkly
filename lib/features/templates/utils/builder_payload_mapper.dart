import 'dart:convert';
import '../models/editable_group.dart';

/// Converts the live UI state (EditableGroups) into a raw JSON map
/// ready for transmission to the backend.
List<Map<String, dynamic>> buildGroupsPayload({
  required List<EditableGroup> groups,
  required bool confirmCorrect,
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
      if (s.id.isNotEmpty) 'id': s.id,
      'title': s.titleCtrl.text,
      if (s.descCtrl.text.isNotEmpty) 'description': s.descCtrl.text,
      if (double.tryParse(s.weightCtrl.text) != null)
        'weight': double.tryParse(s.weightCtrl.text),
      if (double.tryParse(s.maxPointsCtrl.text) != null)
        'maxDeductionPoints': double.tryParse(s.maxPointsCtrl.text),
      if (double.tryParse(s.minusPerFaultCtrl.text) != null)
        'minusPerFault': double.tryParse(s.minusPerFaultCtrl.text),
      'orderIndex': i,
      'metadata': ?metadata,
      'children': buildGroupsPayload(
        groups: s.subSections,
        confirmCorrect: confirmCorrect,
      ),
      'criteria': s.criteria.asMap().entries.map((ce) {
        final ci = ce.key;
        final c = ce.value;

        final meta = <String, dynamic>{};
        if (c.isRequired || confirmCorrect) meta['isRequired'] = true;
        if (c.inputType == 'scale' && c.scaleOptions.isNotEmpty) {
          meta['scaleOptions'] = c.scaleOptions;
        }
        if ((c.inputType == 'single_choice' || c.inputType == 'multi_choice') &&
            c.choiceOptions.isNotEmpty) {
          meta['options'] = c.choiceOptions;
        }

        return <String, dynamic>{
          if (c.id.isNotEmpty) 'id': c.id,
          'label': c.labelCtrl.text,
          if (c.descCtrl.text.isNotEmpty) 'description': c.descCtrl.text,
          'inputType': c.inputType,
          if (c.inputType != 'text' &&
              c.inputType != 'single_choice' &&
              c.inputType != 'multi_choice')
            'pointsWeight': double.tryParse(c.pointsCtrl.text),
          if (c.inputType != 'text' &&
              c.inputType != 'single_choice' &&
              c.inputType != 'multi_choice' &&
              c.minusImpactCtrl.text.isNotEmpty)
            'minusImpact': double.tryParse(c.minusImpactCtrl.text),
          if (c.inputType != 'text' &&
              c.inputType != 'single_choice' &&
              c.inputType != 'multi_choice' &&
              c.maxDeductionCtrl.text.isNotEmpty)
            'maxDeductionPoints': double.tryParse(c.maxDeductionCtrl.text),
          'isCcp': c.isCcp,
          'isRisk': c.isRisk,
          'orderIndex': ci,
          if (meta.isNotEmpty) 'metadata': json.encode(meta),
        };
      }).toList(),
    };
  }).toList();
}
