<latent_space_scratchpad>
This is an architectural fix. The `ActionRequiredWidget` directly reads from `app_database.dart` (Drift types) because it listens to the `ProgramOutboxDao.watchPendingAssignments()`.
We need to remove `app_database.dart` from the widget and create a ViewModel (`PendingAssignmentVm`) in `lib/features/programs/model/pending_assignment_vm.dart`.
Then we add a stream method in `DashboardManager` which returns `Stream<PendingAssignmentVm?>`.
The `ActionRequiredWidget` will use `DashboardManager().watchActionRequired()` instead.
Since the stream depends on `ProgramOutboxDao`, we inject it into `DashboardManager` via `GetIt`.
This removes the drift type dependency from the UI.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit-code\audit_code_report_20260508_183708_4cf3f41a_audit-code.md` (CRIT-3)

## Executive Summary & Out of Scope
The `ActionRequiredWidget` currently breaks the architecture layer contract by directly importing Drift generated database types (`CachedProgramAssignment`). We will extract a view model (`PendingAssignmentVm`) and move the data translation logic into `DashboardManager`.

**Out of Scope**:
- We will not modify the `ProgramOutboxDao` behavior.
- We will not modify the overall dashboard structure.

## System Context
- **Architecture**: Pragmatic Flutter Architecture (Page -> Manager -> DAO -> Database).
- **Offline**: The `watchPendingAssignments` stream from Drift continues to drive the UI instantly when offline.

## Lifecycle Context
- **Empty**: `count == 0`, widget returns `SizedBox.shrink()`.
- **Success**: `count > 0`, widget returns `HeroCard` with the count.

## Risk Assessment
The risk here is minimal because the widget solely displays a UI component derived from local SQLite. Moving the stream mapping into DashboardManager introduces no external API risk. Blast radius is confined to the manager layer.

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-1 | Widget renders correctly without Drift imports | N/A | Current implementation directly references `CachedProgramAssignment`. |

## Verification Plan
We will run `flutter analyze` to ensure no `app_database.dart` imports exist in the UI file, and manually verify the dashboard still renders without crashing.

## Test Fixture & Payloads
- **Fixture**: N/A (Standard Flutter Widget refactoring).

## Tools & Commands
- **Testing**: `flutter test`
- **Linting**: `flutter analyze`

## Proposed Changes
- `[NEW]` `lib/features/programs/model/pending_assignment_vm.dart`: Create `PendingAssignmentVm` data class.
- `[MOD]` `lib/features/dashboard/manager/dashboard_manager.dart`: Add `watchActionRequired()` returning `Stream<PendingAssignmentVm?>`.
- `[MOD]` `lib/features/dashboard/pages/widgets/action_required_widget.dart`: Update to consume `DashboardManager.watchActionRequired()` and use the VM instead of Drift types.

## Concept Diagram
`[ProgramOutboxDao (Drift Type)]` --> `[DashboardManager (Maps to VM)]` --> `[ActionRequiredWidget (Reads VM)]`

## Execution Slices

### Execution Phase: Extract VM and Update Widget
- **Plain English Summary**: Create the VM, map the DAO stream to the VM inside the DashboardManager, and update the widget to use the new stream.
- **Value Delivered**: Restores architectural purity. The UI layer no longer couples to database-generated classes.
- **Entry/Exit State**:
  - Entry: `ActionRequiredWidget` directly uses `CachedProgramAssignment`.
  - Exit: `ActionRequiredWidget` uses `PendingAssignmentVm`.
- **Scope**: `pending_assignment_vm.dart`, `dashboard_manager.dart`, `action_required_widget.dart`.
- **Acceptance Criteria**: `flutter analyze` passes, no `app_database.dart` imports in `action_required_widget.dart`.
- **Complexity**: Low. Simple DTO extraction.
- **Pros & Cons**: 
  - *Pro*: Decouples UI from DB.
  - *Con*: Requires a slight indirection through DashboardManager.

<command_logs>
- `grep_search` on `ProgramOutboxDao`
</command_logs>

## Handoff Block
The plan is ready to execute.
@[/implement] Execute build for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_185858_4cf3f41a_audit-code-crit3.md
