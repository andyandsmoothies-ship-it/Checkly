# Walkthrough: Audit Code CRIT-3 Resolution (PBAC / Drift Coupling)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_185858_4cf3f41a_audit-code-crit3.md`

## Decision Log
**Proposed**: Create `PendingAssignmentVm`, add `watchActionRequired()` to `DashboardManager` to map Drift types to UI-safe VM, and rewrite `ActionRequiredWidget` to consume this VM.
**Implemented**: Exactly as proposed. A significant technical detail discovered during implementation was that eagerly fetching `ProgramOutboxDao` from GetIt in the `DashboardManager` constructor caused existing tests (that don't register the DAO) to fail with a `Bad state` error. 
**Pivot**: The resolution of `ProgramOutboxDao` was moved inside the `watchActionRequired([ProgramOutboxDao? programOutboxDao])` method so that it evaluates lazily. Existing tests that do not invoke `watchActionRequired()` are thus unimpacted and pass smoothly.

## Verification Handoff
All tests passed. `flutter analyze` passes perfectly. The architecture layer violations detected in CRIT-3 have been fully scrubbed.

<test_trace>
Analyzing Checkly...
No issues found! (ran in 7.0s)

00:53 +449: All tests passed!
Exit code: 0
</test_trace>

<forensic_evidence>
- `flutter analyze`
- `flutter test`
</forensic_evidence>

## Gotcha Protocol
Added learning regarding lazily fetching dependencies for methods used by specific UI widgets (in Managers) to avoid breaking global testing environments that instantiate managers without registering full GetIt contexts. (No need to explicitly update `GEMINI.md` as this is a standard GetIt practice, but explicitly noted here).
