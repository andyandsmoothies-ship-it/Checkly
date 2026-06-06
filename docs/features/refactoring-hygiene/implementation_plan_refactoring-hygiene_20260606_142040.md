---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
---

<latent_space_scratchpad>
Edge cases and risks:
1. When refactoring program_dashboard_page.dart:
   - Need to make sure import paths in the newly created widgets/dropdown_filter_pill.dart and widgets/program_assignment_status_filter_sheet.dart are correct and resolved relative to their new folder depth.
   - DropdownFilterPill and showProgramAssignmentStatusFilterSheet must not reference private members of _ProgramDashboardPageState. All inputs (value, active, onTap, counts, currentFilter, onSelected) must be passed as constructor arguments or parameters, which they already are!
2. When refactoring sync_engine.dart:
   - In _runModuleSyncCycle, if the loop runs through all modules, it must execute pull and push for each. If executePull fails, we should skip executePush for that specific module to avoid duplicate errors, but we MUST proceed to the next module.
   - At the end of the loop, if errors list is not empty, we throw a combined Exception.
   - The test TC-PLUGIN-3 in test/_shared/services/sync_engine_plugin_test.dart expects execution to halt at module 20. Under the new rules, it should execute module 30. We must modify TC-PLUGIN-3 to assert that module 30 runs, but the engine still returns SyncState.error.
</latent_space_scratchpad>

## Input Lineage
- Source files:
  - `lib/features/programs/pages/program_dashboard_page.dart`
  - `lib/_shared/services/sync_engine.dart`
  - `test/_shared/services/sync_engine_plugin_test.dart`

## Executive Summary & Out of Scope
This plan refactors the codebase to adhere to code hygiene rules (Gotcha 36 and Gotcha 37):
1. Decompose `program_dashboard_page.dart` to reduce its file length below the 400-line limit by extracting `DropdownFilterPill` and `showProgramAssignmentStatusFilterSheet` helper widgets/methods.
2. Refactor `SyncEngine`'s execution loop so that a failure in one sync module does not halt or abort subsequent modules in the loop. Errors will be collected and thrown at the end of the cycle.

**Out of Scope**:
- Modifying other sync modules or APIs.
- Re-architecting `SyncEngine`'s retry backoff mechanism.
- Modifying UI components other than the Campaign Dashboard Page.

## First Principles Gate
1. **Physics & Limit**:
   - *UI Decomposition*: Developer cognitive load and file length limits (static analysis at 400 lines). Large files are harder to verify and prone to edit conflicts.
   - *Sync Resilience*: Network/API availability. A timeout or failure in a lower-priority endpoint must not starve high-priority background uploads. The source of truth for unsynced data is the SQLite DB (`OutboxDao`).
2. **Simplicity Check**:
   - The simplest fix is keeping the code as-is. We reject this because it violates the 400-line file cap (Gotcha 36) and blocks progress on unrelated modules (Gotcha 37).
3. **Blast Radius**:
   - If the UI refactoring fails: The dashboard filter dropdown won't open, or filter options won't apply.
   - If the Sync refactoring fails: Sync cycle crashes entirely, or hangs, or fails to report error states correctly, breaking offline-sync.
4. **Observability**:
   - We will observe through standard console/debug logs (`debugPrint('[SyncEngine] ...')`).
   - We will verify using existing and modified unit tests: `test/sync_engine_test.dart` and `test/_shared/services/sync_engine_plugin_test.dart`.

## System Context
- **Offline/Online**: `SyncEngine` listens to connectivity state. If offline, it switches to `SyncState.offline` and halts loop execution.
- **Capabilities**: No new capabilities or API contracts are introduced.

## Lifecycle Context
- `ProgramDashboardPage` 4-State Matrix:
  - **Success**: Renders KPIs and the list of program assignments matching the filter.
  - **Loading**: Renders `CircularProgressIndicator`.
  - **Error**: Renders cloud off icon, error text, and a "Try Again" reload button.
  - **Empty**: Renders "No assignments match this filter." in body center.

## Constraint Traceability
| Constraint | Target File | Test Contract ID | Description |
|---|---|---|---|
| Gotcha 36 | `program_dashboard_page.dart` | TC-UI-DECOMP | Extract helper widgets to pages/widgets/ folder. |
| Gotcha 37 | `sync_engine.dart` | TC-SYNC-RESILIENCE | Multi-module loop must execute subsequent modules on failure. |

## Test Contracts
- **TC-UI-DECOMP**: Ensure `program_dashboard_page.dart` compiles and the extracted widgets correctly pass variables and callbacks without state leaks.
- **TC-SYNC-RESILIENCE**: In `sync_engine_plugin_test.dart`, update `TC-PLUGIN-3` to assert that:
  - Module 10 (succeeds), Module 20 (fails on pull), and Module 30 (succeeds) all get execution calls.
  - The final engine state is `SyncState.error`.
  - The log list contains `['pull-10', 'push-10', 'pull-20', 'pull-30', 'push-30']`.

## Test Fixture & Payloads
- No API payloads are modified. We utilize the existing `_StubSyncModule` fixture in `sync_engine_plugin_test.dart`.

## Tools & Commands
- **Required Skill**: `flutter-architecture`, `tdd`
- **Execution Command**: `rtk proxy flutter test test/_shared/services/sync_engine_plugin_test.dart`
- **Global Verify Command**: `rtk proxy flutter test test/sync_engine_test.dart`

## Proposed Changes
| File | Action | Description |
|---|---|---|
| `lib/features/programs/pages/widgets/dropdown_filter_pill.dart` | `[NEW]` | Contains `DropdownFilterPill` stateless widget. |
| `lib/features/programs/pages/widgets/program_assignment_status_filter_sheet.dart` | `[NEW]` | Contains `showProgramAssignmentStatusFilterSheet` helper function. |
| `lib/features/programs/pages/program_dashboard_page.dart` | `[MOD]` | Remove extracted classes, import them from `widgets/`. |
| `lib/_shared/services/sync_engine.dart` | `[MOD]` | Refactor `_runModuleSyncCycle` to accumulate exceptions and throw a single combined exception. |
| `test/_shared/services/sync_engine_plugin_test.dart` | `[MOD]` | Update `TC-PLUGIN-3` and corresponding stub behaviors to verify non-blocking execution. |

## Concept Diagram
```
[Campaign Dashboard Page] ──> Imports ──> [DropdownFilterPill] (widgets/ folder)
                          ──> Imports ──> [ProgramAssignmentStatusFilterSheet]

[SyncEngine] ──> Loop modules ──> try/catch block ──> Accumulate errors ──> Throw combined error
```

## Execution Slices

### Slice 1: UI Decomposition (Gotcha 36)
- **Summary**: Extract `DropdownFilterPill` and status filter sheet from the dashboard page.
- **Entry State**: `program_dashboard_page.dart` contains 456 lines.
- **Exit State**: `program_dashboard_page.dart` is under 300 lines, compiles cleanly.
- **Acceptance Criteria**: App compiles, code structure obeys Gotcha 36.

### Slice 2: Sync Engine Resilience (Gotcha 37)
- **Summary**: Refactor the sync module execution loop to catch and accumulate errors.
- **Entry State**: Single module error terminates `_runModuleSyncCycle` loop immediately.
- **Exit State**: Failures are isolated per module. Loop runs to completion and throws combined error if any module failed.
- **Acceptance Criteria**: Engine state is set to `error` if any module fails, but all modules execute.

### Slice 3: Verification & Test Updates
- **Summary**: Modify the `sync_engine_plugin_test.dart` to assert resilient execution, run all tests.
- **Entry State**: `TC-PLUGIN-3` asserts that execution halts.
- **Exit State**: `TC-PLUGIN-3` asserts execution continues and all tests pass 100%.

## Handoff Block
Next Step: **Build Step** for [Slice 1]. Input: `docs/features/refactoring-hygiene/implementation_plan_refactoring-hygiene_20260606_142040.md`
Please execute slices **ONE AT A TIME**.
