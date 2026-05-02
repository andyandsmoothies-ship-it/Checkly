# Walkthrough: SyncEngine Transactional Fracture (TDD Red Phase)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260502_112521_5badbf76_fix_sync_transactional_fracture.md`

## Testing Summary
I have successfully implemented the RED phase for the Transactional Fracture fix.

**Added Fake:**
- `SuccessApi`: A stub implementation of `SyncApi` where `pushSubmission` returns instantly without throwing, allowing us to test the successful completion pipeline (checkpoint and delete).

**Added Tests:**
1. `AC-CHECKPOINT: drainSubmissions_PushSucceeds_WritesCheckpointBeforeDelete`
   - Verifies the checkpoint logic. Because `markSynced` doesn't exist on `OutboxDao` yet, it uses `dynamic` invocation to purposefully trigger a `NoSuchMethodError`.
2. `AC-SWEEP: requestSync_StartupSweep_DeletesOrphanedSyncedSubmissions`
   - Injects a manually constructed orphaned `submission_synced` record. It currently fails because the startup sweep does not delete it yet, leaving the record stranded in the database.
3. `AC-SWEEP-NOPUSH: startupSweep_DoesNotPushAlreadySyncedRows`
   - Also injects an orphaned `submission_synced` record but explicitly runs against `FailingApi`. If the sweep mistakenly tries to re-push the row instead of just deleting it, it will crash. It currently fails because the row is just left alone, not deleted.

## Instructions for Builder (@Forge)
You are now cleared for the **Green Phase** (Implementation).
To run the tests after implementing the `outboxDao` sweep and checkpoint methods, run:

```bash
cmd /c rtk flutter test test/shared/services/sync_engine_backoff_test.dart
```
