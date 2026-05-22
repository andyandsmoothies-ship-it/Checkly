# Executed Tests - Template Wizard Page Logic Split

## Automated Test Suites
- **Payload & Model Suite**: `test/features/templates/wizard_payload_test.dart`

## Executed Log Output
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
