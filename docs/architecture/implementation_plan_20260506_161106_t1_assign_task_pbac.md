<latent_space_scratchpad>
The goal is to migrate the 'Assign Task' action in ChecklyFab from a hardcoded RBAC check (`role == 'admin'`) to a PBAC check (`PolicyManager.can(AppCapabilities.programsCreate)`).
The backend `CreateProgram.HandleAsync` already requires `ProgramsCreate`.
`ChecklyFab` is used in `DashboardPage` and `HistoryPage`.
I will update the `ChecklyFab` class to take `canAssignTask` instead of `isAdmin`.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: User Request to migrate "Assign Task" button to PBAC.

## Executive Summary & Out of Scope
Migrate the "Assign Task" floating action button (FAB) option to use the new Policy-Based Access Control (PBAC) capability `programs:create`. 
**Out of Scope**: 
- Migrating "Void Audit" to PBAC (requires a new capability definition).
- Migrating "Template Edit/Delete" to PBAC (will be handled in a separate slice/task).

## System Context
- **Environment**: Flutter Frontend UI.
- **RBAC/PBAC**: Checking `PolicyManager.can(AppCapabilities.programsCreate)`.
- **Backend API**: The backend endpoint `POST /api/programs` already enforces `AppCapabilities.ProgramsCreate`.

## Risk Assessment
- **Risk Level**: Low.
- **Why**: This is purely a UI visibility change. The backend already enforces PBAC for the actual endpoint `CreateProgram`. If the UI check is somehow bypassed, the backend will still reject the request.

## Verification Plan
- **Verification Steps**: After making the change, run `flutter test` to ensure no tests fail. If needed, manually confirm with a user role that has `programs:create` but is not `admin`.

## Lifecycle Context
- **Success**: The "Assign Task" FAB option appears if the user has the `programs:create` capability, regardless of their strict role name.
- **Error**: If they lack the capability but try to access the route manually, they will be blocked by route guards or backend 403s.
- **Empty/Loading**: FAB handles empty states correctly (hides itself if no options are available).

## Test Contracts
| ID | Expected Behavior | Matrix State | Why It Fails First |
|---|---|---|---|
| T1 | Area Manager with `programs:create` capability sees "Assign Task" in FAB | Success | The UI currently enforces `role == 'admin'`, blocking Area Managers even if they have the capability. |
| T2 | Store Manager without capability does NOT see "Assign Task" | Empty | Ensures the button remains hidden for unauthorized users. |

## Test Fixture & Payloads
- **UI State**: Requires a logged-in user with `programs:create` enabled in their PBAC profile.

## Tools & Commands
- **Flutter Test**: `flutter test`

## Proposed Changes
- `[MOD]` `lib/_shared/widgets/checkly_fab.dart`
  - Rename `isAdmin` to `canAssignTask`.
  - Update `build` and `_showMenu` to check `canAssignTask`.
- `[MOD]` `lib/features/dashboard/pages/dashboard_page.dart`
  - Pass `canAssignTask: _di<PolicyManager>().can(AppCapabilities.programsCreate)` to `ChecklyFab`.
- `[MOD]` `lib/features/audit/pages/history_page.dart`
  - Pass `canAssignTask: _di<PolicyManager>().can(AppCapabilities.programsCreate)` to `ChecklyFab`.

## Concept Diagram
`[ChecklyFab] <-- (reads capability via PolicyManager) <-- [Dashboard/History Pages]`

## Execution Slices

### Execution Phase: Refactor ChecklyFab PBAC
- **Plain English Summary**: Update the FAB widget and its two parent pages to check PBAC capabilities instead of the hardcoded admin role.
- **Value Delivered**: Any role (like Area Manager) granted the 'Programs Create' permission will now see the Assign Task button.
- **Entry/Exit State**: Start with hardcoded `role == 'admin'`. End with dynamic `canAssignTask` flag.
- **Scope**: Frontend UI only.
- **Complexity**: Low. Simple variable rename and condition update.

## Handoff Block
The plan is ready to be executed via a simple UI-only refactoring.
