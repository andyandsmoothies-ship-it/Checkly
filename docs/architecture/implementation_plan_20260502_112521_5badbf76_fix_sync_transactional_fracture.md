# Fix A-01 Transactional Fracture — SyncEngine Push/Delete

<latent_space_scratchpad>
The key insight: we CANNOT wrap a network call inside a Drift SQLite transaction (holds a write lock during a potentially slow HTTP call). The correct pattern for this class of problem is the "checkpoint before delete" two-phase approach:

Phase 1 (in _processQueue, after push succeeds): 
  - Write syncStatus = 'submission_synced' to SQLite. 
  - This is a single, fast SQLite write. If app crashes after this, the row survives with status 'submission_synced'.
Phase 2 (onSuccess callback, already exists): 
  - Delete the row.
Startup Sweep (new, in SyncEngine.requestSync):
  - Query all rows with status 'submission_synced'. 
  - Delete them immediately without re-pushing. 
  - These are rows confirmed by the server (the network already returned 200) that were left behind by a crash between Phase 1 and Phase 2.

The `_processQueue` helper needs an optional `onPushSucceeded` callback parameter. Only `_drainSubmissions` needs to pass this; other drains (risks, program evidence, photos) are server-idempotent or don't have the same crash risk.

Alternative: Add a `markSynced` method to OutboxDao that atomically updates syncStatus='submission_synced'. This is a single SQLite write and is safe.

The startup sweep can simply call: `_outboxDao.sweepSyncedSubmissions()` — a new DAO method that deletes all rows with syncStatus='submission_synced'.

CRITICAL: The existing tests (AC4, AC5, AC6, AC-FATAL) use a FailingApi, so they NEVER hit the push-then-delete path. The new test must use a SuccessApi to verify that:
  1. After push succeeds: syncStatus is 'submission_synced' (checkpoint written)
  2. After onSuccess: row is deleted
  3. On startup sweep: orphaned 'submission_synced' rows are deleted without re-pushing

Test file to modify: test/shared/services/sync_engine_backoff_test.dart — add a SuccessApi fake and new test cases.

Blast radius: sync_engine_drains.dart (add onPushSucceeded call), outbox_dao.dart (add markSynced + sweepSyncedSubmissions), sync_engine.dart (add startup sweep call), test file (add AC-CHECKPOINT tests).
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\5badbf76-fcd9-4eb7-8566-2f6faa9d4396\audit_arch_report_20260501_235325_5badbf76_sync_engine.md`

## Risk Assessment
> [!WARNING]
> **RISK WARNING:** This fix changes the `_processQueue` helper's internal flow, which is called by 4 drain methods. The change is additive (adding an optional `onPushSucceeded` hook), so existing drain calls that don't pass the hook are unaffected. The startup sweep is a new `requestSync` step that only removes rows — it cannot corrupt data. Risk: **Low**. ROI: **High** (prevents phantom duplicate audit submissions after app crash).

## Executive Summary & Out of Scope

**Goal**: Implement a two-phase checkpoint pattern in `_processQueue` to eliminate the crash window between a successful API push and the SQLite delete of the outbox row.

**Pattern**:
```
push(item) → mark 'submission_synced' → onSuccess/delete
                                   ↑
              If app crashes here, startup sweep deletes the orphan
              without re-pushing (server already has it)
```

**Out of Scope**:
- We will NOT wrap the network call inside a Drift SQLite transaction (would hold a write lock during HTTP).
- We will NOT change the DB schema — `syncStatus` and `submission_synced` already exist in `tables.dart:169`.
- We will NOT add the checkpoint to `_drainRisks` or `_drainProgramEvidence` — their server endpoints are already idempotent (risks use natural keys; programs use `assignmentId`). Only `_drainSubmissions` has a real crash risk.

## Logs & Audits
- No new audit fields needed. The `submission_synced` status in the existing `syncStatus` column IS the audit trail — it records exactly which submissions survived a crash between server confirmation and local deletion.

## 4-State Matrix
| State | Behavior |
|---|---|
| **Loading** | `_drainSubmissions` processes outbox rows. Each row transitions through `pending` → `submission_synced` → (deleted). No UI change visible during this. |
| **Empty** | Startup sweep finds no `submission_synced` rows. No action taken. Normal boot. |
| **Error** | API push fails. Row stays `pending` (backoff path unchanged). No checkpoint written. |
| **Success** | Push returns 200. Checkpoint written. Row deleted. Submission confirmed as non-duplicate on server. |

## Test Contracts

| ID | Exact Test Name | State | Why it fails first (RED) |
|---|---|---|---|
| AC-CHECKPOINT | `drainSubmissions_PushSucceeds_WritesCheckpointBeforeDelete` | Success | `markSynced` doesn't exist yet. Test will fail to compile. |
| AC-SWEEP | `requestSync_StartupSweep_DeletesOrphanedSyncedSubmissions` | Empty | `sweepSyncedSubmissions()` doesn't exist yet. |
| AC-SWEEP-NOPUSH | `startupSweep_DoesNotPushAlreadySyncedRows` | Success | Need to verify the sweep path skips the API call entirely. |
| AC-NOREGRESS-RETRY | Existing AC4 `SyncEngine_FirstFailure_SetsRetryCountOneAndNextRetryAt2s` | Error | Must still pass — the optional hook must not break the error path. |

## Test Fixture & Payloads
- `SuccessApi` fake — a `SyncApi` stub where `pushSubmission` returns normally (no throw).
- Seed a `pending` row, call `requestSync()`, assert:
  1. Row is gone (deleted)
  2. (For AC-CHECKPOINT only): Intercept between push and delete to verify the `submission_synced` checkpoint — this requires a `SlowSuccessApi` with a controlled future.

## Tools & Commands
- **Skills**: `tdd`
- **Test file**: `test/shared/services/sync_engine_backoff_test.dart`
- **Commands**:
  - `cmd /c rtk flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded`

## Proposed Changes
| Action | File | Reason |
|---|---|---|
| `[MOD]` | `lib/_shared/database/dao/outbox_dao.dart` | Add `markSynced(String id)` and `sweepSyncedSubmissions()` methods |
| `[MOD]` | `lib/_shared/services/sync_engine_drains.dart` | Add optional `onPushSucceeded` to `_processQueue`; pass `markSynced` in `_drainSubmissions` |
| `[MOD]` | `lib/_shared/services/sync_engine.dart` | Call `sweepSyncedSubmissions()` at the top of `_requestSyncInternal` before any drain |
| `[MOD]` | `test/shared/services/sync_engine_backoff_test.dart` | Add `SuccessApi` fake + 3 new AC-CHECKPOINT / AC-SWEEP test cases |

## Concept Diagram
```text
App boot / requestSync()
     │
     ▼
[Startup Sweep]
sweepSyncedSubmissions()
→ deletes orphaned 'submission_synced' rows (no API call)
     │
     ▼
[_drainSubmissions]
  for each 'pending' row:
     │
     ├──▶ push(item)  [network call — outside any SQLite lock]
     │       │
     │       ▼ (200 OK)
     │    onPushSucceeded → markSynced(id)   ← CHECKPOINT
     │       │
     │       ▼
     │    onSuccess → removeSubmission(id)
     │
     └──▶ (push throws) → backoff / exhaust path [UNCHANGED]
```

## Execution Slices

### Execution Phase
**Complexity**: Low — additive changes only. No schema migration. No existing tests change.

**Step 1 — RED**: Add 3 new failing tests to `sync_engine_backoff_test.dart`:
- `SuccessApi` fake (pushSubmission does nothing)
- `AC-CHECKPOINT`: seed 1 row → `requestSync()` → row is deleted → FAILS because `markSynced` not yet called
- `AC-SWEEP`: manually insert a `submission_synced` row → `requestSync()` → row is deleted
- `AC-SWEEP-NOPUSH`: `AC-SWEEP` but with a `FailingApi` — proves sweep doesn't call the API

**Step 2 — GREEN**: Implement the three production changes:
1. `OutboxDao`: Add `markSynced(String id)` (writes `syncStatus='submission_synced'`). Add `sweepSyncedSubmissions()` (deletes all `submission_synced` rows).
2. `_processQueue<T>`: Add optional `Future<void> Function(T item)? onPushSucceeded` parameter. Call it **after** `await push(item)` and **before** `await onSuccess(item)`.
3. `_drainSubmissions`: Pass `onPushSucceeded: (dbRow) => _outboxDao.markSynced(dbRow.id)`.
4. `SyncEngine._requestSyncInternal`: Call `await _outboxDao.sweepSyncedSubmissions()` as the very first step.

**Step 3 — VERIFY**: Run all tests in `sync_engine_backoff_test.dart`. All 8 tests must pass.

**Pros**: Minimal blast radius. No schema changes. No existing test breaks. The `submission_synced` column was designed for exactly this.
**Cons**: The checkpoint write is a separate SQLite write from the delete — there's a tiny window between them, but a crash in this window simply leaves a `submission_synced` row that the next startup sweep deletes harmlessly.

<command_logs>
- grep_search: `_processQueue` in `lib/` — found in `sync_engine_drains.dart` (4 call sites + definition)
- grep_search: `removeSubmission` in `lib/` — found in `sync_engine_drains.dart:55` (onSuccess) and `outbox_dao.dart:96,114`
- grep_search: `withTransaction` in `lib/` — none found (no existing transaction wrappers in services)
- grep_search: `submission_synced` in `lib/` — found in `tables.dart:169`, `outbox_dao.dart:243,248`
- view_file: `sync_engine_drains.dart` — confirmed _processQueue signature and onSuccess flow
- view_file: `outbox_dao.dart` — confirmed markSynced hook does not exist, sweepSyncedSubmissions does not exist
- view_file: `sync_engine_backoff_test.dart` — confirmed test structure, FailingApi, SuccessApi missing
- view_file: `tables.dart:155-185` — confirmed `submission_synced` is a documented valid status
</command_logs>

## Verification Plan
1. Run `flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded`.
2. Confirm all 8 tests pass (5 existing + 3 new AC-CHECKPOINT/SWEEP).
3. Run full suite: `flutter test` — all 389+ tests must pass.

## Handoff Block

> [!IMPORTANT]
> **Action:** Run the following command ONE step at a time.
>
> **Route 1: Logic/Standard (Unit Tests First)**
> `@[/tdd] Execute tests for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260502_112521_5badbf76_fix_sync_transactional_fracture.md`
>
> **Concurrency**: None. Single slice.
