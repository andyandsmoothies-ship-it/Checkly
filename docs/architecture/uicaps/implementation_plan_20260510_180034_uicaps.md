<latent_space_scratchpad>
The backend and frontend are offline-first.
PBAC capabilities limit which buttons/actions are shown.
S0 updates PermissionGuard to support `showAsDisabled` and the loading flash fix. It also creates a python lint script.
S1-S4 wrap various UI elements with PermissionGuard and dynamic checks.
I actually already implemented S3 and the test fix for S1 in previous runs, but I am formalizing the plan here.
</latent_space_scratchpad>

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\decision_record_20260510_173420_15a74aa9_uicaps.md`

## Executive Summary & Out of Scope
**Executive Summary:**
Implement proactive capability-based access control (PBAC) on the UI. The UI will hide or disable actions (like FABs, buttons, and tabs) based on the user's specific capabilities using `PermissionGuard` rather than hardcoded roles. The backend will enforce the same via API, and we will update `PermissionGuard` to handle loading states and disabled visual states. A Python script will be created to ensure no unguarded buttons slip through.

**Out of Scope:**
- Creating new backend capability enforcement logic (the existing `AuthManager` and `PolicyManager` will be used).
- Modifying offline sync behavior.
- Replacing the backend 403 authorization logic.

## Risk Assessment
**Risk Level**: Low
- **Tradeoffs**: Requires manual discipline for future developers to wrap new buttons. The backend remains the source of truth, so missing a wrapper only results in a bad UX (403), not a security breach.
- **Blast Radius**: Isolated to UI rendering logic for specific FABs and buttons. No changes to business or domain logic.

## System Context
- **Environment**: Offline-first Flutter app with C# ASP.NET Core backend.
- **RBAC/PBAC**: Strict capability-based checking.
- **Constraints**: Cannot use server-driven UI layouts because it breaks offline-first.

## Lifecycle Context
- **Loading**: `PermissionGuard` will hide the child or show a loading indicator while `AuthManager` is initializing.
- **Success**: The user has the capability; the widget is fully visible and interactive.
- **Empty/Unauthorized**: The user lacks the capability; the widget is either hidden entirely or rendered as disabled with a tooltip (if `showAsDisabled` is true).
- **Error**: N/A for UI gating, but offline sync queues actions if the network drops.

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-PBAC-01 | `PermissionGuard` shows disabled widget when capability missing and `showAsDisabled` is true | Missing Cap -> Disabled UI | `PermissionGuard` doesn't support `showAsDisabled` currently. |
| TC-PBAC-02 | `PermissionGuard` hides widget when capability missing | Missing Cap -> Hidden UI | Widget is currently rendered for all users. |
| TC-PBAC-03 | Submissions FAB is hidden if lacking `submissions:create` | Missing `submissions:create` -> Hidden | Submissions screen FAB is unguarded. |
| TC-PBAC-04 | "Assign Auditor" dropdown lists only users with `submissions:execute` | Has Cap -> In List | Dropdown uses hardcoded `role == auditor` frontend logic. |

## Test Fixture & Payloads
- `MockAuthManager` configured with `ValueNotifier({'submissions:create'})` for authorized tests.
- `MockAuthManager` configured with `ValueNotifier({})` for unauthorized tests.

## Tools & Commands
- **Skills needed**: `flutter-architecture`, `tdd`
- **Commands**:
  - `flutter test`
  - `python .agents/scripts/verify_pbac_ui.py`
  - `cmd /c rtk dotnet format analyzers`

## Verification Plan
1. **Automated Testing**: Ensure all `TC-PBAC-*` Test Contracts are covered by unit and widget tests. Run `flutter test` and confirm `audit_form_page_required_test.dart` passes.
2. **Static Analysis**: Run `python .agents/scripts/verify_pbac_ui.py` to ensure no orphaned buttons exist in feature directories.
3. **Manual Flow**: Verify UI behavior manually when logged in as an auditor vs. store manager, ensuring hidden widgets behave appropriately and do not crash navigation.

## Proposed Changes
- `[MOD]` `lib/_shared/widgets/permission_guard.dart`
- `[NEW]` `.agents/scripts/verify_pbac_ui.py`
- `[MOD]` `lib/features/submissions/pages/submissions_page.dart`
- `[MOD]` `lib/features/templates/pages/templates_page.dart`
- `[MOD]` `lib/features/programs/pages/programs_page.dart`
- `[MOD]` `lib/features/shell/pages/shell_page.dart`
- `[MOD]` `server/Features/Users/SearchUsers.cs` (completed)
- `[MOD]` `lib/features/admin/manager/admin_audit_manager.dart` (completed)

## Concept Diagram
`[User loads page] --> [PermissionGuard checks AuthManager] --> [Capability Present?] --(Yes)--> [Render Widget]`
`                                                                                 \--(No)--> [Hide or Disable Widget]`

## Execution Slices

### Phase A: Core Infrastructure & Admin (S0 & S3)
- **Plain English Summary:** Upgrade `PermissionGuard` to handle disabled states and loading flashes, write the `verify_pbac_ui.py` script, and transition the "Assign Auditor" dropdown to use backend filtering.
- **Value Delivered:** Foundation for the rest of the UI gating; immediate security fix for the admin assignment flow.
- **Entry/Exit State:** Entry: Basic `PermissionGuard` and hardcoded auditor dropdown. Exit: Upgraded `PermissionGuard` and backend-filtered dropdown.
- **Scope:** `lib/_shared/widgets/permission_guard.dart`, `.agents/scripts/verify_pbac_ui.py`, `AdminAuditManager`, `SearchUsers.cs`.
- **Acceptance Criteria:** `PermissionGuard` supports `showAsDisabled`. The Python script flags unguarded buttons. Auditor dropdown only shows users with `submissions:execute`.
- **Complexity:** Medium (touches backend and requires writing a custom Python AST/regex script).
- **Pros & Cons:** Pro: Solves the most glaring security gap first. Con: Requires backend and frontend coordination.

### Phase B: Feature Screens Gating (S1 & S2)
- **Plain English Summary:** Apply the upgraded `PermissionGuard` to the Submissions and Templates screens.
- **Value Delivered:** Hides the "Start Audit", "New Template", "Edit Template", and "Delete Template" actions from unauthorized roles.
- **Entry/Exit State:** Entry: Unguarded FABs. Exit: Guarded FABs and context menus.
- **Scope:** `submissions_page.dart`, `templates_page.dart`.
- **Acceptance Criteria:** Submissions FAB requires `submissions:create`. Template actions require `templates:create/update/delete`.
- **Complexity:** Low (purely declarative UI wrapping).
- **Pros & Cons:** Pro: Fast to implement. Con: Could break UI tests if they don't mock `AuthManager` properly.

### Phase C: Shell Navigation (S4)
- **Plain English Summary:** Make the bottom navigation tabs dynamic based on capabilities.
- **Value Delivered:** Users won't even see the "Templates" or "Programs" tabs if they don't have read access.
- **Entry/Exit State:** Entry: Hardcoded 4-tab shell. Exit: Dynamic 2-4 tab shell.
- **Scope:** `lib/features/shell/pages/shell_page.dart`.
- **Acceptance Criteria:** Tabs are dynamically computed via a getter using `AuthManager.capabilities`. `currentIndex` is clamped.
- **Complexity:** Low (state management updates for the shell).
- **Pros & Cons:** Pro: Ultimate capability hiding (entire modules disappear). Con: Might require slight refactoring of the router if it assumes all tabs exist.

## Handoff Block
> **Route 1: Logic/Standard (Unit Tests First)**
> @[/tdd] Execute tests for Phase A: Core Infrastructure & Admin: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\implementation_plan_20260510_180034_uicaps.md
>
> **Route 2: Visuals/Simple (Direct Build)**
> @[/implement] Execute build for Phase B: Feature Screens Gating: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\implementation_plan_20260510_180034_uicaps.md
> 
> **Route 2: Visuals/Simple (Direct Build)**
> @[/implement] Execute build for Phase C: Shell Navigation: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\implementation_plan_20260510_180034_uicaps.md
>
> **Concurrency:** Phase A must be completed before Phase B and Phase C. Phase B and Phase C can be completed concurrently.
