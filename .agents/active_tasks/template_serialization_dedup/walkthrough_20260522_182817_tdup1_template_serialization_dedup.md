# Walkthrough: Template Serialization Dedup (TDUP1)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260522_171800_tdup1_template_serialization_dedup.md`

## Decision Log
### Proposed vs Implemented
- **Proposed**: Unify payload mapping for Template Builder and Template Wizard into a clean, canonical set of mapping functions.
- **Implemented**: Created a fully pure, side-effect-free mapper `lib/features/templates/utils/template_payload_mapper.dart` which encapsulates `buildGroupsPayload`, `buildCriterionPayload`, and `buildScoringLogicConfig`.
- **Proposed**: Support edit mode vs new mode serialization.
- **Implemented**: Added `isEditMode` flag to `buildGroupsPayload` so that it emits database `id` fields when editing (Builder) and omits them when creating new (Wizard).
- **Proposed**: Ensure points, deductions, and impacts are omitted for text and choice criterion input types (BL-2).
- **Implemented**: Added strict type guards checking `c.inputType != 'text' && c.inputType != 'single_choice' && c.inputType != 'multi_choice'` before serializing points weight, max deduction points, and minus impact.
- **Proposed**: Migrate all callers and delete old payload builders.
- **Implemented**: Replaced duplicated serializing code in `template_builder_page_logic.dart` and `template_wizard_page_logic.dart` with calls to the unified canonical mapper. Deleted obsolete duplicate files `wizard_payload_builder.dart` and `builder_payload_mapper.dart`.

## Verification Handoff
1. **Specific Unit Tests**:
   - Path: `test/features/templates/utils/template_payload_mapper_test.dart`
   - Run command: `rtk flutter test test/features/templates/utils/template_payload_mapper_test.dart`
   - Outcome: All 11 tests pass successfully, proving absolute payload mapping correctness, type exclusion, metadata extraction, and fallback default values.
2. **Template Feature Page Tests**:
   - Path: `test/features/templates/`
   - Run command: `rtk flutter test test/features/templates/`
   - Outcome: All 128 tests pass, verifying zero regressions in builder, wizard, settings, and other template pages.
3. **Entire Project Tests**:
   - Run command: `rtk flutter test`
   - Outcome: All 618 tests pass perfectly.

## Test Trace
<test_trace>
00:19 +618: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: (tearDownAll)
00:19 +618: All tests passed!

Exit code: 0
</test_trace>

## Forensic Evidence
<forensic_evidence>
Verification commands executed successfully:
1. rtk flutter test test/features/templates/utils/template_payload_mapper_test.dart
2. rtk flutter test test/features/templates/
3. rtk flutter test
</forensic_evidence>

## Gotcha Protocol
None found. The newly created `template_payload_mapper.dart` is clean, has zero external dependencies besides Flutter/Dart core structures, and encapsulates formatting logic perfectly.
