# Walkthrough: Refactoring Hygiene - Slice 1: UI Decomposition

Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `lib/features/programs/pages/program_dashboard_page.dart`
- **Implementation Plan**: `docs/features/refactoring-hygiene/implementation_plan_refactoring-hygiene_20260606_142040.md`

## Decision Log
- **Proposed Design**: Extract `DropdownFilterPill` and `showProgramAssignmentStatusFilterSheet` to widgets under the same page scope.
- **Implemented Design**: Extracted `DropdownFilterPill` to `lib/features/programs/pages/widgets/dropdown_filter_pill.dart` and `showProgramAssignmentStatusFilterSheet` to `lib/features/programs/pages/widgets/program_assignment_status_filter_sheet.dart`. Updated `program_dashboard_page.dart` to import these widgets. This reduces the file length from 456 lines to 276 lines, which is well below the 400-line cap.

## Verification Handoff
To manually verify:
1. Open the Campaign Dashboard page in Checkly.
2. Verify the Status Filter Pill is displayed.
3. Tap on the Filter Pill and verify that the status filter modal bottom sheet opens correctly.
4. Select a status and verify that the assignments list is filtered correctly.

## Gotcha Protocol
Refined Gotcha 19 and checked compliance with Gotcha 36 (no files > 400 lines). No additions needed for local `GEMINI.md`.

## Forensic Evidence
<forensic_evidence>
Ran the following checkly verification scripts:
- PBAC UI scan: `cmd /c python .agents/scripts/verify_pbac_ui.py --advisory` (Advisory success)
- DB/API sync contract scan: `cmd /c python .agents/scripts/verify_sync_contracts.py` (Success)
- Flutter analyze: `rtk proxy flutter analyze lib/features/programs` (Success - No issues found)
</forensic_evidence>

## Test Trace
<test_trace>
```text
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/hq_program_dashboard_test.dart
00:00 +0: HQ Program Dashboard ATDD ProgramListPage exists and can be imported
00:00 +1: HQ Program Dashboard ATDD ProgramDashboardPage exists and can be imported
00:00 +2: HQ Program Dashboard ATDD ProgramApiService exists and has getProgramAssignments method
00:00 +3: All tests passed!
```
</test_trace>
