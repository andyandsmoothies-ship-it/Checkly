# Walkthrough: Section Card Sweep and Visual Parity Refactor
Workflow: /implement | Track: B1

## Input Lineage
- **Absolute Path to Source File**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260522_233100_uxe5_section_card_sweep.md`

## Decision Log
### Proposed vs Implemented
- **Slice 1: Fix TypeSection Group Header**
  - *Proposed*: Replace hardcoded `TextStyle` and manual green badge in `TypeSection` widget with `UniversalStoreGroup` (already built and robust).
  - *Implemented*: Modified `lib/features/templates/widgets/type_section.dart` to clean imports, delete hardcoded properties/ExpansionTile layout, and return `UniversalStoreGroup` directly.
- **Slice 2: Migrate Programs List Cards**
  - *Proposed*: Migrate inline list cards in Programs module to `UniversalListCard`, and raw `Center(Text)` empty/error states to `ChecklyEmptyState`.
  - *Implemented*: 
    - Migrated `ProgramListPage`, `AreaCampaignListPage`, and `ProgramAssignmentListPage` to use `UniversalListCard`.
    - Integrated `ChecklyEmptyState` to handle loading failures and empty lists.
    - Wrote comprehensive widget tests in `test/features/programs/pages/program_list_pages_ui_test.dart` and implemented a capabilities stub `_StubAuthManager` to pass `PermissionGuard` capabilities verification checks.
- **Slice 3: Fix AuditSectionCard Title Typography**
  - *Proposed*: Change typography of `AuditSectionCard` title to use `AppFonts.displayStyle`.
  - *Implemented*: Modified `lib/features/audit/widgets/audit_section_card.dart` to import and apply `AppFonts.displayStyle` on the title widget, matching `SectionCard` precisely.

## Verification Handoff
### Manual QA Steps
1. **Templates Header Parity**:
   - Navigate to the **Templates** tab.
   - Verify category headers use standard high-contrast uppercase Nunito theme and standard `PillChip` layout.
2. **Programs List Parity**:
   - Navigate to the **Programs** lists (ProgramListPage, AreaCampaignListPage, ProgramAssignmentListPage).
   - Verify all list items render using unified layout, correct trailing progress bars/badges, and standardized leading icons.
   - Trigger offline/error mode and verify `ChecklyEmptyState` displays the standard retry button and blend aesthetics.
3. **Audit Card Title Parity**:
   - Open an active **Audit** form.
   - Verify the Section Title typography perfectly matches the typography of `SectionCard` in the Template Preview screen.

### Automated Test Trace
<test_trace>
- Running `rtk flutter test test/features/programs/pages/program_list_pages_ui_test.dart`: PASS
- Running `rtk flutter test test/features/programs/`: PASS (All 19 programs tests pass)
- Running `rtk flutter test` (Global Sweep): PASS (All 649 tests pass successfully)
</test_trace>

<forensic_evidence>
Verification commands:
- Checked for any hardcoded `TextStyle` literals in `lib/features/templates/widgets/type_section.dart` (None remain).
- Verified relative imports resolving correctly.
- Ran `rtk flutter analyze` (Clean - 0 issues found).
</forensic_evidence>

## Gotcha Protocol
No new local sub-folder Gotchas found. The migration cleanly leverages existing shared primitives (`UniversalStoreGroup`, `UniversalListCard`, `ChecklyEmptyState`).
