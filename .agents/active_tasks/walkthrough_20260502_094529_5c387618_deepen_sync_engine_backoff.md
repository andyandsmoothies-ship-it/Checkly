# TDD Walkthrough: SyncEngine Backoff Tests

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_231745_380021a1_deepen_sync_engine_backoff.md`

## What was done
1. Created two new mock APIs (`_409RiskApi` and `_FatalSubmissionApi`) in `sync_engine_backoff_test.dart` to simulate edge cases.
2. Implemented AC-409: `_drainRisks_409Conflict_TreatedAsSuccess_RecordRemoved`. Validated that a 409 error on pushing a risk triggers the success path, properly removing the pending record.
3. Implemented AC-FATAL: `_drainSubmissions_400FatalError_MarkedExhausted_NoRetry`. Validated that a fatal 400 error correctly skips retry math and marks the record exhausted immediately.
4. **Note:** The tests *passed* on execution, because the current un-refactored `_drainRisks` and `_drainSubmissions` already implement this behavior correctly. Therefore, these tests serve directly as a verified regression suite for the impending `_processQueue` refactor.

## Next Steps for Builder
Run the existing tests to confirm the behavior is captured, then proceed with the `_processQueue` implementation.
Command to run tests:
`cmd /c rtk flutter test test/shared/services/sync_engine_backoff_test.dart`
