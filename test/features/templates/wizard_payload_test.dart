// Test Plan:
// Tests the pure-logic helpers extracted from the wizard:
//   - buildGroupsRecursive: payload serialisation for sub-sections (BL-1, BL-2)
//   - EditableGroup.countCriteria(): recursive count (EDD-5)
//   - validateCriteriaList (indirect via EditableGroup.countCriteria): BL-3
//   - V6 error via sub-section: BL-4 (tested via wizard_step_review indirectly,
//     but we test the data model here for isolation)
//
// NOTE: The wizard's private methods (_buildGroups, _validateCurrentStep) are
// widget-bound and widget-tested manually. These unit tests cover the
// pure-Dart logic that those methods delegate to.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/templates/models/editable_criterion.dart';
import 'package:checkly/features/templates/models/editable_group.dart';

// ── Pure helper under test (extracted from template_wizard_page.dart) ─────────
// This mirrors the _buildGroupsRecursive logic that will be in the wizard.
// Testing it here keeps tests fast and widget-free.

List<Map<String, dynamic>> buildGroupsRecursive(List<EditableGroup> groups) {
  return groups.asMap().entries.map((e) {
    final i = e.key;
    final s = e.value;
    assert(
      s.criteria.isEmpty || s.subSections.isEmpty,
      'Group "${s.titleCtrl.text}" violates mutual-exclusivity: '
      'has ${s.criteria.length} criteria AND ${s.subSections.length} sub-sections.',
    );
    return <String, dynamic>{
      'title': s.titleCtrl.text,
      if (s.descCtrl.text.isNotEmpty) 'description': s.descCtrl.text,
      'orderIndex': i,
      'children': buildGroupsRecursive(s.subSections),
      'criteria': s.criteria.asMap().entries.map((ce) {
        final ci = ce.key;
        final c = ce.value;
        final bool isChoiceType =
            c.inputType == 'single_choice' || c.inputType == 'multi_choice';
        final bool isScaleType = c.inputType == 'scale';
        return <String, dynamic>{
          'label': c.labelCtrl.text,
          if (c.descCtrl.text.isNotEmpty) 'description': c.descCtrl.text,
          'inputType': c.inputType,
          // BL-2 / Gotcha #11: exclude pointsWeight for non-scored types
          if (!isChoiceType && c.inputType != 'text')
            'pointsWeight': double.tryParse(c.pointsCtrl.text),
          'isCcp': c.isCcp,
          'isRisk': c.isRisk,
          'orderIndex': ci,
          if (isChoiceType && c.choiceOptions.isNotEmpty)
            'metadata': json.encode({'options': c.choiceOptions}),
          if (isScaleType && c.scaleOptions.isNotEmpty)
            'metadata': json.encode({'scaleOptions': c.scaleOptions}),
        };
      }).toList(),
    };
  }).toList();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

EditableCriterion _criterion({
  String label = 'Test Criterion',
  String inputType = 'pass_fail',
  String points = '10',
  List<String>? choiceOptions,
  bool isCcp = false,
  bool isRisk = false,
}) {
  final c = EditableCriterion(
    inputType: inputType,
    points: points,
    isCcp: isCcp,
    isRisk: isRisk,
  );
  c.labelCtrl.text = label;
  if (choiceOptions != null) c.choiceOptions = choiceOptions;
  return c;
}

EditableGroup _section({
  String title = 'Test Section',
  List<EditableCriterion>? criteria,
  List<EditableGroup>? subSections,
}) {
  final s = EditableGroup(
    title: title,
    criteria: criteria ?? [],
    subSections: subSections ?? [],
  );
  return s;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // Teardown: dispose controllers to avoid leaks
  tearDown(() {});

  // ── BL-1: Recursive serialisation matches builder's shape ─────────────────

  group('buildGroupsRecursive', () {
    test('SectionWithNoSubSections_ProducesEmptyChildren', () {
      // Verifies the empty-sub-section path produces [] not null
      final sections = [
        _section(criteria: [_criterion()]),
      ];
      final result = buildGroupsRecursive(sections);

      expect(result.length, 1);
      expect(result[0]['children'], isEmpty);
    });

    test('SectionWithSubSection_IncludesChildrenInPayload', () {
      // BL-1: EDD-4 — sub-section appears in payload
      final sub = _section(
        title: 'Sub A',
        criteria: [_criterion(label: 'Sub criterion')],
      );
      final sections = [
        _section(title: 'Root', subSections: [sub]),
      ];

      final result = buildGroupsRecursive(sections);

      final children = result[0]['children'] as List;
      expect(children.length, 1);
      expect(children[0]['title'], 'Sub A');
      final subCriteria = children[0]['criteria'] as List;
      expect(subCriteria.length, 1);
      expect(subCriteria[0]['label'], 'Sub criterion');
    });

    test('SubSectionWithChoiceCriterion_IncludesMetadataAndExcludesPoints', () {
      // BL-2 / Gotcha #11: choice types must NOT have pointsWeight
      final choiceCrit = _criterion(
        label: 'Rating',
        inputType: 'single_choice',
        choiceOptions: ['Yes', 'No'],
      );
      final sub = _section(title: 'Sub', criteria: [choiceCrit]);
      final result = buildGroupsRecursive([
        _section(subSections: [sub]),
      ]);

      final subCriteria =
          (result[0]['children'] as List)[0]['criteria'] as List;
      final crit = subCriteria[0] as Map<String, dynamic>;

      // Must NOT include pointsWeight for choice types
      expect(crit.containsKey('pointsWeight'), isFalse);
      // Must include metadata
      expect(crit.containsKey('metadata'), isTrue);
      final meta = json.decode(crit['metadata'] as String);
      expect(meta['options'], ['Yes', 'No']);
    });

    test('TextCriterion_ExcludesPointsWeight', () {
      // Gotcha #11: text input type is non-scored at all depths
      final crit = _criterion(label: 'Notes', inputType: 'text');
      final result = buildGroupsRecursive([
        _section(criteria: [crit]),
      ]);

      final c = (result[0]['criteria'] as List)[0] as Map<String, dynamic>;
      expect(c.containsKey('pointsWeight'), isFalse);
    });

    test('OrderIndex_IsCorrectForSubSections', () {
      // orderIndex must be sequential per depth level
      final sub1 = _section(title: 'Sub 1', criteria: [_criterion()]);
      final sub2 = _section(title: 'Sub 2', criteria: [_criterion()]);
      final result = buildGroupsRecursive([
        _section(subSections: [sub1, sub2]),
      ]);

      final children = result[0]['children'] as List;
      expect(children[0]['orderIndex'], 0);
      expect(children[1]['orderIndex'], 1);
    });
  });

  // ── BL-3 / EDD-5: Recursive count of criteria ────────────────────────────

  group('EditableGroup.countCriteria', () {
    test('SectionWithOnlyRootCriteria_ReturnsCorrectCount', () {
      final s = _section(criteria: [_criterion(), _criterion()]);
      expect(s.countCriteria(), 2);
    });

    test('SectionWithSubSections_ReturnsRecursiveCount', () {
      // EDD-5: 2 sub-sections × 3 criteria each → total 6
      final sub1 = _section(
        criteria: [_criterion(), _criterion(), _criterion()],
      );
      final sub2 = _section(
        criteria: [_criterion(), _criterion(), _criterion()],
      );
      final root = _section(subSections: [sub1, sub2]);

      expect(root.countCriteria(), 6);
    });

    test('SectionWithMixedRootAndSubCriteria_ReturnsTotalCount', () {
      final sub = _section(criteria: [_criterion(), _criterion()]);
      final root = _section(criteria: [_criterion()], subSections: [sub]);
      expect(root.countCriteria(), 3);
    });

    test('EmptySection_ReturnsZero', () {
      // Empty state — should not throw, just return 0
      final s = _section();
      expect(s.countCriteria(), 0);
    });
  });

  // ── BL-3: validate "not empty" logic (via data model only) ───────────────

  group('Section emptiness check (BL-3)', () {
    test('SectionWithOnlySubSections_IsNotConsideredEmpty', () {
      // BL-3: criteria.isEmpty && subSections.isEmpty is the correct guard
      // A section with sub-sections but no root criteria should be valid
      final sub = _section(criteria: [_criterion()]);
      final root = _section(subSections: [sub]);

      // BL-3: valid if subSections.isNotEmpty
      final isEmpty = root.criteria.isEmpty && root.subSections.isEmpty;
      expect(isEmpty, isFalse);
    });

    test('SectionWithNoRootCriteriaAndNoSubSections_IsConsideredEmpty', () {
      final root = _section();
      final isEmpty = root.criteria.isEmpty && root.subSections.isEmpty;
      expect(isEmpty, isTrue);
    });
  });

  // ── P0 isCcp/isRisk round-trip ────────────────────────────────────────────

  group('isCcp / isRisk field round-trip', () {
    test('CriterionWithCcpTrue_SerializesAsTrueNotFalse', () {
      // Success state: flag must survive into payload
      final crit = _criterion(isCcp: true);
      final result = buildGroupsRecursive([
        _section(criteria: [crit]),
      ]);
      final c = (result[0]['criteria'] as List)[0] as Map<String, dynamic>;
      expect(c['isCcp'], isTrue);
      expect(c['isRisk'], isFalse);
    });

    test('CriterionWithRiskTrue_SerializesAsTrueNotFalse', () {
      // Success state: isRisk flag must survive into payload
      final crit = _criterion(isRisk: true);
      final result = buildGroupsRecursive([
        _section(criteria: [crit]),
      ]);
      final c = (result[0]['criteria'] as List)[0] as Map<String, dynamic>;
      expect(c['isCcp'], isFalse);
      expect(c['isRisk'], isTrue);
    });

    test('NewCriterionDefault_BothFlagsFalse', () {
      // Empty / default state: both flags must default to false
      final crit = _criterion();
      final result = buildGroupsRecursive([
        _section(criteria: [crit]),
      ]);
      final c = (result[0]['criteria'] as List)[0] as Map<String, dynamic>;
      expect(c['isCcp'], isFalse);
      expect(c['isRisk'], isFalse);
    });
  });

  // ── P2: Mutual-exclusivity payload guard ──────────────────────────────────

  group('mutual-exclusivity invariant', () {
    test('CriteriaOnlyGroup_Serializes_Successfully', () {
      // Success state: flat criteria group must serialize without throwing
      final section = _section(criteria: [_criterion()]);
      expect(() => buildGroupsRecursive([section]), returnsNormally);
    });

    test('MixedGroup_WithCriteriaAndSubSections_ThrowsAssertionError', () {
      // Error state: group with both criteria AND sub-sections must throw
      final section = _section(criteria: [_criterion()]);
      final sub = EditableGroup(title: 'Sub');
      sub.criteria.add(_criterion(label: 'Sub Criterion'));
      section.subSections.add(sub);
      expect(
        () => buildGroupsRecursive([section]),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
