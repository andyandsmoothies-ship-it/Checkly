# Task: OPT-1 Extract StorePicker
Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_204042_c4d5e6_audit-code-opt1.md`

## Decision Log
- **Proposed**: Extract the duplicated "Store Picker" UI code from `user_create_sheet_body.dart` and `user_edit_sheet_body.dart` into `lib/features/admin/widgets/shared/store_picker.dart`.
- **Implemented**: Created `StorePicker` component. Updated both sheets to consume it. Fixed the inconsistency in the "Create User" sheet by sharing the `subtitle` rendering logic (`managerName`) that was previously only present in the "Edit User" sheet. Also unified the parameter order for `onStoreSelectionChanged`.
- **Status**: Completed without regressions.

## Verification Handoff
1. Open the app and navigate to **Admin -> Users**.
2. Tap "Add User" (creates `UserCreateSheet`).
3. Change Role to "Store Manager" -> observe the "ASSIGNED STORE" dropdown showing Manager Names as subtitles.
4. Change Role to "Area Manager" -> observe the "DIRECT STORE ASSIGNMENTS" list with toggle.
5. Edit an existing user to observe the exact same UI component.

## Gotcha Protocol
- No new gotchas identified during this extraction.

<test_trace>
All tests passed! (449 tests)
Exit code: 0
</test_trace>

<forensic_evidence>
cmd /c "flutter analyze & flutter test"
</forensic_evidence>
