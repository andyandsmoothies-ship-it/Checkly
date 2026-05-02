# Walkthrough: Action Plan Sync

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_code_report_20260502_161200_sentinel_pr_batch.md` (BUG-1: Migrate ActionPlanSyncModule.executePush)

## Decision Log
- **Proposed**: Replace the manual loop in `ActionPlanSyncModule.executePush()` with `BaseSyncModule.processQueue()` to enable exponential backoff.
- **Implemented**: 
  - Added `retryCount` and `nextRetryAt` columns to `PendingActionPlanUpdates`.
  - Incremented `schemaVersion` to 24 and wrote the migration script.
  - Implemented `updateRetry()` in `ActionPlanOutboxDao` and mock implementations.
  - Successfully mapped `ActionPlanSyncModule` to `processQueue()`.
  - Caught `ActionPlanAlreadyClosedException` inside the `push` loop and threw it with a '409' marker to correctly route to `onConflict`, preserving the staleness state logic without crashing the batch.

## Verification Handoff
1. Simulate network failure during evidence upload. Observe the item backoff schedule via logs or debug inspecting `PendingActionPlanUpdates.nextRetryAt`.
2. Concurrently close a plan on the server and submit evidence on the client. Verify that the client updates the sync state to `StaleConflict` instead of repeatedly retrying.

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/sync_engine_action_plan_stale_state_test.dart
00:00 +0: SyncEngine ActionPlan Stale State Tests (Slice 2) FE-SYNC-AP-409-01: SyncEngine_WhenActionPlanApiThrowsActionPlanAlreadyClosedException_RemovesOutboxEntry_AndContinuesBatch
00:00 +1: SyncEngine ActionPlan Stale State Tests (Slice 2) FL-SYNC-SC-01: SyncEngine_WhenActionPlanAlreadyClosed_MarksStaleConflict_AndContinuesBatch
00:00 +2: ActionPlanApiAdapter Stale State Tests (Slice 2) FE-SYNC-AP-409-02: ActionPlanApiAdapter_WhenServerReturns409ProblemDetailsCodeActionPlanAlreadyClosed_ThrowsTypedActionPlanAlreadyClosedException
00:00 +3: ActionPlanApiAdapter Stale State Tests (Slice 2) ActionPlanApiAdapter_WhenServerReturnsGeneric409_ThrowsDioException
00:00 +4: All tests passed!

<truncated 390 global tests>

00:44 +396: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)
00:44 +396: All tests passed!
</test_trace>

<forensic_evidence>
cmd /c "rtk flutter analyze"
Analyzing Checkly...
No issues found! (ran in 3.4s)

cmd /c "rtk flutter test"
396/396 tests passing.
</forensic_evidence>

## Gotcha Protocol
- **Gotcha**: When using `processQueue()`, you must explicitly route domain-specific staleness exceptions (like `ActionPlanAlreadyClosedException`) to the `onConflict` branch by throwing a generic `Exception` that contains the string `'409'`, unless you choose to parse HTTP responses directly in the module. Wrapping the specific exception is an acceptable and highly compatible approach.
