# Executed Tests: SyncEngine Transactional Fracture (TDD Red Phase)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260502_112521_5badbf76_fix_sync_transactional_fracture.md`

## Test Output

```text
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/sync_engine_backoff_test.dart
00:00 +0: AC4: SyncEngine_FirstFailure_SetsRetryCountOneAndNextRetryAt2s
00:00 +1: AC5: SyncEngine_ThirdFailure_SetsNextRetryAt60s
00:00 +2: AC6: SyncEngine_FourthFailure_SetsStatusExhausted
00:00 +3: AC-409: _drainRisks_409Conflict_TreatedAsSuccess_RecordRemoved
00:00 +4: AC-FATAL: _drainSubmissions_400FatalError_MarkedExhausted_NoRetry
00:00 +5: AC-CHECKPOINT: drainSubmissions_PushSucceeds_WritesCheckpointBeforeDelete
00:00 +5 -1: AC-CHECKPOINT: drainSubmissions_PushSucceeds_WritesCheckpointBeforeDelete [E]
  MethodNotFound: markSynced is missing from OutboxDao
  package:matcher                                           fail
  test\shared\services\sync_engine_backoff_test.dart 373:7  main.<fn>
  
00:00 +5 -1: AC-SWEEP: requestSync_StartupSweep_DeletesOrphanedSyncedSubmissions
00:00 +5 -2: AC-SWEEP: requestSync_StartupSweep_DeletesOrphanedSyncedSubmissions [E]
  Expected: empty
    Actual: WhereIterable<PendingSubmission>:[
              PendingSubmission:PendingSubmission(id: sub-sweep, templateId: t1, storeId: s1, clientScore: 100.0, sectionScores: null, notes: null, gpsLat: null, gpsLng: null, idempotencyKey: sub-sweep, syncStatus: submission_synced, syncError: null, retryCount: 0, nextRetryAt: null, createdAt: 2026-05-02 11:38:12.000, targetSubmissionId: null)
            ]
  Startup sweep should delete orphaned submission_synced rows
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\shared\services\sync_engine_backoff_test.dart 396:5  main.<fn>
  
00:00 +5 -2: AC-SWEEP-NOPUSH: startupSweep_DoesNotPushAlreadySyncedRows
00:00 +5 -3: AC-SWEEP-NOPUSH: startupSweep_DoesNotPushAlreadySyncedRows [E]
  Expected: empty
    Actual: WhereIterable<PendingSubmission>:[
              PendingSubmission:PendingSubmission(id: sub-sweep-nopush, templateId: t1, storeId: s1, clientScore: 100.0, sectionScores: null, notes: null, gpsLat: null, gpsLng: null, idempotencyKey: sub-sweep-nopush, syncStatus: submission_synced, syncError: null, retryCount: 0, nextRetryAt: null, createdAt: 2026-05-02 11:38:13.000, targetSubmissionId: null)
            ]
  
  package:matcher                                           expect
  package:flutter_test/src/widget_tester.dart 473:18        expect
  test\shared\services\sync_engine_backoff_test.dart 423:5  main.<fn>
  
00:00 +5 -3: Some tests failed.
```
