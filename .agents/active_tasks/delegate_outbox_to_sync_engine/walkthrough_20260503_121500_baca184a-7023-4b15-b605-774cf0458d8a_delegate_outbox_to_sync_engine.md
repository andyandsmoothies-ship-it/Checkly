# Delegate Outbox to SyncEngine: Implementation Walkthrough

## Executive Summary
This implementation successfully enforced the architectural boundary between the UI and the Data Layer by delegating `OutboxDao` interactions to the `SyncEngine`. UI components no longer depend directly on the database layer.

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_113000_380021a1_delegate_outbox_to_sync_engine.md`
- **TDD Gate**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260503_113459_2c7e5b91-4fdb-45a7-a391-785cb62c7fe0_syncengine_outbox.md`

## Changes Made
1. **SyncEngine Enhancement**:
   - Injected `OutboxDao? _outboxDao` into the `SyncEngine` constructor. We made this optional (`?`) to preserve backward compatibility with the existing test suite, which constructs `SyncEngine` frequently.
   - Added 5 proxy methods: `watchExhaustedCount()`, `discardExhausted()`, `requeueExhausted()`, `syncableCount()`, and `exhaustedCount()`.
   - Used null-assertion (`!`) inside these methods so they fail fast if called without DI wiring in production.

2. **Dependency Injection**:
   - Wired `OutboxDao` into the `SyncEngine` registration in `locator.dart`.

3. **UI Decoupling**:
   - Refactored `main_shell.dart` and `sign_out_tile.dart`. Both previously imported and queried `OutboxDao` directly.
   - Replaced direct DAO calls with `_di<SyncEngine>().[method]()` calls.

4. **Test Adjustments**:
   - Fixed `profile_page_test.dart` which broke after `sign_out_tile.dart` switched to using `SyncEngine`. We registered `SyncEngine` into GetIt for that specific test environment.

## Decision Log
- **Optional Constructor Parameter**: Made `OutboxDao? outboxDao` nullable in the `SyncEngine` constructor. This avoided breaking 6+ integration test files that construct `SyncEngine` manually while retaining the strict contract (via `!`) for production.

## Verification Handoff
All implementation requirements have been fulfilled. The data boundary is strictly enforced.

<forensic_evidence>
Searched outbox usages across UI via grep. Refactored files verified.
</forensic_evidence>

<test_trace>
406/406 tests passed.
All tests passed!
Exit code: 0
</test_trace>

## Quality Metrics

- **Tests**: All 8 outbox proxy tests and all 406 suite tests passing (100% regression green).
- **Static Analysis**: `flutter analyze` reported 0 issues (after fixing a minor unused variable warning).
- **Architectural Check**: `OutboxDao` is no longer imported anywhere in the UI (`lib/features/.../widgets/` or `lib/_shared/router/`).

### Verification Loop Report

| Phase | Status | Details |
|-------|--------|---------|
| 1. Build / Analyze | PASS | 0 issues found after resolving unused `engine` variable. |
| 4. Tests | PASS | 8 passing tests for SyncEngine Outbox Delegation, 406 total suite. |
| 7. Diff Review | PASS | 5 files changed (`main_shell.dart`, `sync_engine.dart`, `sign_out_tile.dart`, `locator.dart`, `profile_page_test.dart`), all matching task scope with no unrelated bleed. |

**Verdict**: **PASS**

## Conclusion
The slice is 100% complete and fully verified. The architectural integrity of the data layer boundaries has been restored, and `SyncEngine` acts as the strict gateway to outbox queries for the UI layer.
