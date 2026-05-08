<latent_space_scratchpad>
Split strategy analysis:

The file has three conceptual chunks:
1. Lines 17–49:  Widget class declaration + constructor. Keep in user_create_sheet.dart (~50 lines).
2. Lines 51–196: State class + all logic (_submit, _loadStores, _markDirty, field vars). Extract to user_create_sheet_logic.dart as a StatefulWidget mixin or plain State methods. Actually we can't easily extract State methods without a mixin. Let's use a simple approach: create a UserCreateSheetController class that holds the state variables and logic, then the State class delegates to it. Actually, looking at schedule_audit_form_logic.dart the pattern there is a static utility class, not a controller. For _submit the state variables are tightly coupled (nameError, emailError, passwordError, isSubmitting, isDirty). We can't trivially extract them without introducing a ChangeNotifier controller. That adds complexity. Better option: just extract the build() body into private named widget methods or a separate UserCreateSheetBody StatelessWidget that receives all the state as parameters.

Actually looking more carefully:
- The State class lines 51-196 = field declarations + 3 logic methods (_loadStores, _markDirty, _submit) + dispose
- The build() lines 198-441 = one massive UI tree

The simplest + safest split (matching the audit report's suggestion):
File A: user_create_sheet.dart (~80 lines) - StatefulWidget + State shell with fields and lifecycle
File B: user_create_sheet_logic.dart (~100 lines) - Mixin with _submit, _loadStores, _markDirty logic  
File C: user_create_sheet_body.dart (~200 lines) - build() tree decomposed

But Flutter mixins on State are a bit tricky. Simpler: keep the State class in one file, just decompose the build() into private named widget methods or a UserCreateSheetBody widget that takes all the state vars as named parameters. This is the safest refactor.

Actually the SIMPLEST split that delivers real value and matches the audit report:
- user_create_sheet.dart: The StatefulWidget + _UserCreateSheetState header + logic methods (~200 lines)
- user_create_sheet_body.dart: A private body widget or just extracted sections via private Widget methods

Wait, that still keeps the main file at 200 lines which is fine. Actually the cleanest split that STAYS UNDER 400 lines each:

Option 1 (Simple - just extract build body):
- user_create_sheet.dart: everything except the build() tree (~200 lines)
- user_create_sheet_body.dart: the build body as a StatelessWidget that takes all state as params (~240 lines)

This is clean, simple, no mixin needed, no behavior changes.

For the area manager store list, that is the biggest UI block (lines 355-418). We can extract it as a private _AreaManagerStorePicker widget inside user_create_sheet_body.dart.

Let me map out the file split:
- user_create_sheet.dart: L1-196 + build() that just calls UserCreateSheetBody(...) = ~130 lines  
- user_create_sheet_body.dart: UserCreateSheetBody StatelessWidget = ~250 lines

The State passes all the needed state to UserCreateSheetBody via constructor parameters. 

Actually, the problem: the body needs callbacks (_markDirty, _loadStores, setState, _submit, etc.) AND needs to mutate state (selectedRole, selectedStoreId, etc.). These are too tightly coupled to trivially extract.

The REAL smartest move for this specific file: just break the build() into private Widget-returning methods on the State class itself:
- _buildHeader()
- _buildBasicFields()  
- _buildRolePicker()
- _buildStoreSection() 
- _buildSubmitButton()

This keeps everything in one file but breaks the 243-line build() into readable chunks. File stays around 443 lines though...

Given WARN-1 says the file is 441 lines with a 243-line build method, and the audit says to split it, I think the RIGHT recommendation is:

Split into TWO files using a StatelessWidget body with callback parameters:
1. user_create_sheet.dart: Widget + State (logic only) -- about 220 lines
2. user_create_sheet_body.dart: pure presentation StatelessWidget -- about 230 lines

The body widget receives: all display state as params, all callbacks as functions. This is a clean pattern.

Key risk: the body widget gets a LOT of parameters (8-10). That's acceptable since it's purely a body composition widget, not a reusable component.

Timeline: One slice, Route 2 (Direct Build), zero logic changes.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit-code\audit_code_report_20260508_183708_4cf3f41a_audit-code.md` (WARN-1)

## Executive Summary & Out of Scope

`user_create_sheet.dart` is 443 lines, exceeding the 400-line mandatory split rule. The 243-line `build()` method is the primary offender — it embeds the full UI tree inline in the State class. We will decompose this by extracting the `build()` tree into a dedicated `_UserCreateSheetBody` StatelessWidget in a new file, keeping the State class as the single owner of all fields and logic.

**Out of Scope**:
- We will NOT touch `user_edit_sheet.dart` in this slice.
- We will NOT build the shared `_StorePicker` extraction (OPT-1). That comes after both sheets are split.
- We will NOT change any submit logic, validation rules, or API callbacks.
- We will NOT move state variables out of the State class (no Controller/Mixin introduced).

## System Context
- **Architecture**: Flutter StatefulWidget. Online-only (Admin feature — requires live API for stores/user creation).
- **RBAC**: Admin-only. Opened from `UserManagementPage`.
- **One importer**: `user_management_page.dart` — no import paths change since the public class `UserCreateSheet` stays in `user_create_sheet.dart`.

## Lifecycle Context
| State | UI Behaviour |
|---|---|
| **Loading** | Submit button shows `CircularProgressIndicator`, `isSubmitting = true` |
| **Empty** | Store list shows "No active stores found." text |
| **Error** | Field-level `errorText` shown. 409 conflict triggers `UserManagementDialogs.confirmTransfer()` |
| **Success** | `Navigator.pop(true)` + SnackBar |

## Risk Assessment
**Low risk.** One importer. No API or logic changes. Blast radius is confined to two files within `lib/features/admin/widgets/`. The main regression risk is passing the wrong callback or missing a state variable in the body widget constructor — caught immediately by `flutter analyze`.

## Test Contracts
| ID | Constraint | Why it matters |
|---|---|---|
| TC-1 | `flutter analyze` reports zero errors after split | Verifies no missing parameters or broken imports |
| TC-2 | `UserCreateSheet` class name and constructor signature unchanged | The single importer in `user_management_page.dart` must require zero changes |
| TC-3 | All 3 error fields (`nameError`, `emailError`, `passwordError`) still display on their respective `TextField` | Error routing logic must not be severed by the extraction |
| TC-4 | `isSubmitting` spinner still renders in the Submit button | State variable must reach the body widget |
| TC-5 | Area Manager store checkbox list still updates on tap | `setState` callback must correctly bubble back to parent State |

## Verification Plan
Run `flutter analyze lib/features/admin/widgets/` after the split. Zero errors = pass. Manually open the Create User bottom sheet in the running app to confirm the form renders correctly.

## Test Fixture & Payloads
- **Fixture**: N/A — pure structural split, no new behavior.
- **Command**: `flutter analyze lib/features/admin/widgets/`

## Tools & Commands
- **Testing**: `flutter analyze`

## Proposed Changes
- `[MOD]` `lib/features/admin/widgets/user_create_sheet.dart` — Remove `build()` body (~200 lines cut). Keep: StatefulWidget declaration, all State fields, `_loadStores`, `_markDirty`, `_submit`, `dispose`. The `build()` method becomes a 5-line delegation to `_UserCreateSheetBody(...)`.
- `[NEW]` `lib/features/admin/widgets/user_create_sheet_body.dart` — `_UserCreateSheetBody` StatelessWidget. Receives all display state and callbacks as constructor parameters. Contains the extracted UI tree (~230 lines).

## Concept Diagram

```
user_create_sheet.dart (State owns all logic + fields)
  build() { return _UserCreateSheetBody(...) }  ← 5 lines
    ↓ passes all state + callbacks
user_create_sheet_body.dart (_UserCreateSheetBody)
  ├── Header
  ├── TextField: Full Name  (receives nameError, onChanged)
  ├── TextField: Email      (receives emailError, onChanged)
  ├── TextField: Password   (receives passwordError, onChanged)
  ├── Role Dropdown         (receives selectedRole, onRoleChanged)
  ├── Store Picker          (if store_manager, receives selectedStoreId)
  ├── AM Store Checklist    (if area_manager, receives _selectedStoreIds)
  └── Submit Button         (receives isSubmitting, onSubmit)
```

## Execution Slices

### Execution Phase: Extract build() to _UserCreateSheetBody

**Plain English Summary**: Create `user_create_sheet_body.dart`. Move the entire `build()` tree from the State class into a new `_UserCreateSheetBody` private StatelessWidget. The State's `build()` becomes a thin delegation call. No logic changes, no validation changes, no API changes.

**Value Delivered**: The main file drops from 443 lines to ~220 lines. The body file is ~230 lines. Both are well under the 400-line limit.

**Entry State Required**: `user_create_sheet.dart` exists at 443 lines.

**Exit State Guaranteed**: 
- `user_create_sheet.dart` ≤ 220 lines.
- `user_create_sheet_body.dart` ≤ 240 lines.
- `flutter analyze` reports zero issues.
- `user_management_page.dart` requires zero changes.

**Scope**: 2 files in `lib/features/admin/widgets/`.

**Acceptance Criteria**:
- `_UserCreateSheetBody` is a private class (underscore prefix).
- It receives ALL state it needs via constructor parameters — it does NOT call `GetIt`, reach into any DAO, or import any manager.
- The `build()` in `_UserCreateSheetState` returns `_UserCreateSheetBody(...)` and nothing else.
- `flutter analyze` passes cleanly.

**Complexity**: Low. Pure extraction. No behavior changes.

**Pros & Cons**:
- ✅ Pro: Both files are under the 400-line limit. Each has a single clear responsibility.
- ✅ Pro: `_UserCreateSheetBody` is easily visually-testable in isolation in the future.
- ⚠️ Con: Body widget constructor has ~10 parameters. This is acceptable for a body-composition widget but not a reusable one.

<command_logs>
- `view_file` on `user_create_sheet.dart` (full)
- `view_file` on `user_edit_sheet.dart` (full)
- `view_file` on `schedule_audit_form_logic.dart` (pattern reference)
- `grep_search` on `user_create_sheet.dart` for importers
- `run_command` dir on admin widgets folder
</command_logs>

## Handoff Block
The plan is ready to execute. This is a **Route 2: Direct Build** — pure structural extraction with no new logic.

@[/implement] Execute build for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_195837_e91b2c_audit-code-warn1.md
