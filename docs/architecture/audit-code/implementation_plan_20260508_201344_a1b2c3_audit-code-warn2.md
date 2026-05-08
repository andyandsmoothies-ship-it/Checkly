# Task: WARN-2 File Split (user_edit_sheet.dart)
Workflow: /analyze-feature | Track: B1

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit-code\audit_code_report_20260508_183708_4cf3f41a_audit-code.md` (WARN-2)

## Executive Summary & Out of Scope
**Goal**: Split the oversized `user_edit_sheet.dart` (376 lines) into two files: a stateful shell (`user_edit_sheet.dart`) and a stateless presentation body (`user_edit_sheet_body.dart`). This directly mirrors the recent split of `user_create_sheet.dart` and satisfies the WARN-2 file size limits.

**Out of Scope**:
- Extracting the shared `_StorePicker` widget (this is OPT-1, to be addressed *after* both sheets are split to ensure symmetrical starting points).
- Altering any network, validation, or lifecycle behavior.

## System Context
- **Layer**: Presentation / UI (Admin Feature).
- **Architecture**: The stateful shell retains all logic (`loadStores`, `markDirty`), and passes state/callbacks down to the stateless body.

## Lifecycle Context
- **Empty**: User info loads initially from the passed-in `user` map.
- **Loading**: When role changes to area/store manager, `_isLoadingStores` triggers a loading spinner in the store list.
- **Error**: API failures show a SnackBar; handled by the shell.
- **Success**: Saving triggers the callback to the parent page.

## Risk Assessment
**Risk Level**: Low.
This is a purely structural refactor that extracts a `build` method into a separate stateless widget without altering any underlying logic, state management, or network interactions. Given that this identical pattern was successfully deployed for `user_create_sheet.dart`, the primary risk is simply wiring up callbacks incorrectly, which will be caught immediately by static analysis (`flutter analyze`) and manual testing. ROI is high as it fulfills WARN-2 constraints and sets the stage for OPT-1.

## Test Contracts

| ID | Description | Initial State | Trigger | Expected Outcome |
|---|---|---|---|---|
| TC-1 | Shell passes full name down | Shell has `user['fullName']` | Body mounts | TextField shows correct initial name |
| TC-2 | Body triggers dirty state | User types in Name field | `onChange` fired | `onMarkDirty` callback hits shell, `isDirty` = true |
| TC-3 | Role change lazy-loads stores | Role = Admin | User selects "Store Manager" | `onRoleChanged` triggers `loadStores` in shell |

## Verification Plan
Run `flutter analyze lib/features/admin/widgets/` after the split. Zero errors = pass. Manually open the Edit User bottom sheet in the running app to confirm the form renders correctly.

## Test Fixture & Payloads
- **Fixture**: N/A — pure structural split, no new behavior.
- **Command**: `flutter analyze lib/features/admin/widgets/`

## Tools & Commands
- `flutter analyze`
- `flutter test`

## Proposed Changes
- `[NEW]` `lib/features/admin/widgets/user_edit_sheet_body.dart`: Create a new `StatelessWidget` that takes all necessary display states and callbacks.
- `[MOD]` `lib/features/admin/widgets/user_edit_sheet.dart`: Replace the massive 242-line `build()` method with a 5-line delegation to `UserEditSheetBody`.

## Concept Diagram
```text
[UserEditSheet] (Stateful, holds selectedRole, _isLoadingStores, _markDirty)
      |
      | passes state & callbacks down
      v
[UserEditSheetBody] (Stateless, pure UI tree)
```

## Execution Phase
**Summary**: Extract the `build()` method of `user_edit_sheet.dart` into `user_edit_sheet_body.dart`.
**Value Delivered**: File size drops below 400-line mandatory limit, matching the architecture of the `Create` sheet.
**Entry State**: `user_edit_sheet.dart` is 376 lines.
**Exit State**: Both files are under 250 lines. Behavior is unchanged.
**Scope**: Presentation refactoring.
**Acceptance Criteria**:
- `user_edit_sheet_body.dart` contains no manager/API logic.
- `user_edit_sheet.dart` `build()` method just returns `UserEditSheetBody(...)`.
- `flutter analyze` returns zero issues.

**Complexity**: Low. This is a direct copy-paste extraction using a proven pattern from WARN-1.

## Handoff Block
```markdown
@[/implement] Execute build for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_201344_a1b2c3_audit-code-warn2.md
```
