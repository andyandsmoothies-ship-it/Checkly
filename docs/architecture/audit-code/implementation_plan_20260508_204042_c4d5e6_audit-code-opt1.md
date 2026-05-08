# Task: OPT-1 Extract StorePicker
Workflow: /analyze-feature | Track: B1

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit-code\audit_code_report_20260508_183708_4cf3f41a_audit-code.md` (OPT-1)

## Executive Summary & Out of Scope
**Goal**: DRY up the codebase by extracting the duplicated "Store Picker" and "Area Manager Checkbox List" UI components from `user_create_sheet_body.dart` and `user_edit_sheet_body.dart` into a single shared widget (`lib/features/admin/widgets/shared/store_picker.dart`). 

**Out of Scope**:
- Modifying the parent API fetching logic (`loadStores`). We will keep `_loadStores()` inside the parent Stateful widgets because they must handle `setState` and their respective `mounted` contexts.
- Altering any network, validation, or lifecycle behavior.

## System Context
- **Layer**: Presentation / UI (Admin Feature).
- **Architecture**: `StorePicker` will be a pure `StatelessWidget`. It will accept state variables (`assignableStores`, `selectedRole`, etc.) and bubble user actions up via `ValueChanged` callbacks.

## Lifecycle Context
- **Empty**: No stores assigned or active.
- **Loading**: Parent passes `isLoadingStores = true` to display the `CircularProgressIndicator`.
- **Success**: Displays the list of checkboxes (for area managers) or the `DropdownCard` (for store managers).

## Risk Assessment
**Risk Level**: Low.
This is a standard React-style component extraction. We are replacing 80 lines of identical UI code in two files with a single widget. The primary risk is a parameter mismatch (e.g., forgetting to map `onStoreSelectionChanged` correctly), which will be caught immediately by static analysis (`flutter analyze`) and manual testing.

## Test Contracts

| ID | Description | Initial State | Trigger | Expected Outcome |
|---|---|---|---|---|
| TC-1 | Conditional Rendering (SM) | `selectedRole` = 'store_manager' | Widget mounts | Only `DropdownCard` is rendered |
| TC-2 | Conditional Rendering (AM) | `selectedRole` = 'area_manager' | Widget mounts | Only `SwitchListTile` and `ListView` are rendered |
| TC-3 | Subtitle logic unifies | `assignableStores` contains a store with `managerName` | Widget mounts | `DropdownCard` subtitle shows 'SM: [Name]' (fixes missing feature in Create Sheet) |
| TC-4 | Bubbling Checkbox | User taps a store checkbox | Checkbox tap | `onStoreSelectionChanged(id, checked)` is fired |

## Verification Plan
Run `flutter analyze lib/features/admin/widgets/` after extraction. Zero errors = pass. Manually open both the Create User and Edit User bottom sheets in the running app to confirm the form renders and toggles correctly.

## Test Fixture & Payloads
- **Fixture**: N/A — pure structural UI extraction.
- **Command**: `flutter analyze lib/features/admin/widgets/`

## Tools & Commands
- `flutter analyze`

## Proposed Changes
- `[NEW]` `lib/features/admin/widgets/shared/store_picker.dart`: Create a new `StatelessWidget` that handles rendering both the single `DropdownCard` and the multi-select `ListView` based on `selectedRole`.
- `[MOD]` `lib/features/admin/widgets/user_create_sheet_body.dart`: Replace the inline store picker logic with `<StorePicker(...)>`.
- `[MOD]` `lib/features/admin/widgets/user_edit_sheet_body.dart`: Replace the inline store picker logic with `<StorePicker(...)>`.

## Concept Diagram
```text
[UserCreateSheetBody] ---\
                          v
                    [StorePicker] -> renders Dropdown or ListView
                          ^
[UserEditSheetBody] -----/
```

## Execution Phase
**Summary**: Extract the duplicated store picker UI into a shared `StorePicker` widget.
**Value Delivered**: Reduces WET (Write Everything Twice) code. Fixes an inconsistency where `UserCreateSheet` was missing the `SM: Manager Name` subtitle in its dropdown.
**Entry State**: `user_create_sheet_body.dart` and `user_edit_sheet_body.dart` have ~80 lines of duplicated logic.
**Exit State**: Shared widget is used by both.
**Scope**: Presentation refactoring.
**Acceptance Criteria**:
- `lib/features/admin/widgets/shared/store_picker.dart` is created.
- Both body widgets use the shared `StorePicker`.
- `flutter analyze` returns zero issues.

**Complexity**: Low. Simple UI extraction.

## Handoff Block
```markdown
@[/implement] Execute build for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_204042_c4d5e6_audit-code-opt1.md
```
