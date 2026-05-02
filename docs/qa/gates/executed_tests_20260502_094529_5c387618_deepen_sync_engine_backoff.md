# Executed Tests: SyncEngine Backoff (AC-409 & AC-FATAL)

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_231745_380021a1_deepen_sync_engine_backoff.md`

## Test Output Logs

```text
00:00 +0: AC4: SyncEngine_FirstFailure_SetsRetryCountOneAndNextRetryAt2s
00:00 +1: AC5: SyncEngine_ThirdFailure_SetsNextRetryAt60s
00:00 +2: AC6: SyncEngine_FourthFailure_SetsStatusExhausted
00:00 +3: AC-409: _drainRisks_409Conflict_TreatedAsSuccess_RecordRemoved
00:00 +4: AC-FATAL: _drainSubmissions_400FatalError_MarkedExhausted_NoRetry
00:00 +5: All tests passed!

Exit code: 0
```

> **Note**: The tests passed immediately because the logic for handling 409 Conflicts in `_drainRisks` and 400 Fatal Errors in `_drainSubmissions` is already present in the pre-refactored `sync_engine_drains.dart` code. These tests successfully capture the current correct behavior and will serve as regression gates during the `_processQueue` refactoring phase.
