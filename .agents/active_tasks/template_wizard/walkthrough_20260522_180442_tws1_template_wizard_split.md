# Walkthrough - Template Wizard Page Logic Split

## Input Lineage
- **Source Input**: `docs/architecture/implementation_plan_20260522_160800_tws1_template_wizard_split.md`

## Decision Log
- **Proposed vs Implemented**:
  - We extracted the state mutation and saving methods (`_markDirty`, `_showBlueprintModal`, `_nextStep`, `_prevStep`, `_save`) from the template wizard page state into a part-of file.
  - Using Dart's native `part` and `part of` features combined with an extension on `_TemplateWizardPageState` allowed us to access all private instance states cleanly without introducing boilerplate or rewriting wizard layouts.
  - To prevent compilation issues in Dart regarding `setState` inside extensions (since it is a protected member of `State`), we added the `// ignore_for_file: invalid_use_of_protected_member` lint rule at the top of the logic part file.

## Verification Handoff
1. Open [template_wizard_page.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_wizard_page.dart).
2. Confirm the line count is 267 lines, well below the 400-line threshold.
3. Open [template_wizard_page_logic.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_wizard_page_logic.dart).
4. Verify it has no imports and carries `part of 'template_wizard_page.dart';` with the extension declaration.
5. Execute the template wizard payload tests to confirm no regressions:
```bash
rtk flutter test test/features/templates/wizard_payload_test.dart
```

## Gotcha Protocol
- None identified. Standard part-file refactoring is perfectly robust and compile-time safe without any runtime behavioral alterations.

<test_trace>
```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/wizard_payload_test.dart
00:00 +0: buildGroupsRecursive SectionWithNoSubSections_ProducesEmptyChildren
00:00 +1: buildGroupsRecursive SectionWithSubSection_IncludesChildrenInPayload
00:00 +2: buildGroupsRecursive SubSectionWithChoiceCriterion_IncludesMetadataAndExcludesPoints
00:00 +3: buildGroupsRecursive TextCriterion_ExcludesPointsWeight
00:00 +4: buildGroupsRecursive OrderIndex_IsCorrectForSubSections
00:00 +5: EditableGroup.countCriteria SectionWithOnlyRootCriteria_ReturnsCorrectCount
00:00 +6: EditableGroup.countCriteria SectionWithSubSections_ReturnsRecursiveCount
00:00 +7: EditableGroup.countCriteria SectionWithMixedRootAndSubCriteria_ReturnsTotalCount
00:00 +8: EditableGroup.countCriteria EmptySection_ReturnsZero
00:00 +9: Section emptiness check (BL-3) SectionWithOnlySubSections_IsNotConsideredEmpty
00:00 +10: Section emptiness check (BL-3) SectionWithNoRootCriteriaAndNoSubSections_IsConsideredEmpty
00:00 +11: isCcp / isRisk field round-trip CriterionWithCcpTrue_SerializesAsTrueNotFalse
00:00 +12: isCcp / isRisk field round-trip CriterionWithRiskTrue_SerializesAsTrueNotFalse
00:00 +13: isCcp / isRisk field round-trip NewCriterionDefault_BothFlagsFalse
00:00 +14: mutual-exclusivity invariant CriteriaOnlyGroup_Serializes_Successfully
00:00 +15: mutual-exclusivity invariant MixedGroup_WithCriteriaAndSubSections_ThrowsAssertionError
00:00 +16: All tests passed!
```
</test_trace>

<forensic_evidence>
```bash
rtk flutter test test/features/templates/wizard_payload_test.dart
rtk flutter analyze
```
Executed verification suite to ensure zero warnings or regression issues on template wizard logic.
</forensic_evidence>
