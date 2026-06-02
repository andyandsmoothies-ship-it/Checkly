---
ConversationID: 99faccbc-6112-4ccd-aea4-306dbdfd3452
---
# SRE Hostile Architecture Review: Checkly Core System
*Prepared by Chief Architect / SRE*

```text
[Client Sync Trigger]
        |
        v
  [SyncEngine] (Delayed reconnects leak / ignore dispose)
        |
        v
  [PhotoQueueService] (Bypasses backoff nextRetryAt, hammers API)
        |
        v  (POST /api/submissions)
  [CreateSubmission / FinalizeSubmission]
        |
        +---> [Execution Strategy Retry] (Tracker collision / Duplicate Action Plans)
        |
        +---> [SectionScoreExploder] (Duplicate database rows on retry/re-insert)
        |
        +---> [DistributedLockManager] (Non-idempotent criticalSection retry)
```

---

## 1. Executive Summary
This architecture audit interrogates the concurrency, transactional integrity, background sync engines, and locking mechanisms of the Checkly platform across both the Flutter client and the ASP.NET Core (.NET 10) backend. 

The review has uncovered **three Fatal bugs** and **two Brittle design patterns** that will trigger severe production issues under load, including:
1. Complete bypass of network backoff delays on mobile devices (DDoS-ing the photo upload API during connection flapping).
2. Database data corruption through duplicate `submission_section_scores` and duplicate `action_plans` under transaction retry conditions.
3. System crashes (tracking key collisions) when EF Core attempts to retry transactions under lock contention.

---

## 2. Hostile Critic Interrogation (@@SCAN)

### Critic 1: The Zombie (Stateless Illusion)
*   **Long-Lived Connections**: 
    *   *Analysis*: `SyncEngine` listens to `_connectivity.onConnectivityChanged` stream. If the platform stream closes permanently (e.g. OS background killer, service restart), it activates `_startConnectivityPollFallback` which polls every 30 seconds. This is a highly resilient fallback.
    *   *Bug*: When connection changes trigger a reconnect, `SyncEngine` schedules a delayed task: `Future.delayed(Duration(milliseconds: jitterMs), requestSync)`. However, if the `SyncEngine` is disposed, this future is **never cancelled**. The delayed callback executes after disposal, which causes state updates on a disposed engine, causing crashes or memory leaks during widget testing and app lifecycle swaps.
*   **Cache Rebuilds**: 
    *   *Analysis*: There are no massive stateless O(N) cache rebuild locks observed in the local database or memory caches. Submissions retrieval utilizes index-backed keyset pagination.

### Critic 2: The Split-Brain (State & Sync)
*   **Clock Drift**:
    *   *Analysis*: When finalization occurs, the server assigns its own timestamp to `CompletedAt` (`DateTimeOffset.UtcNow`). Client-side clocks are not trusted for transaction status changes. However, client-side timestamps are stored as `CreatedAt` for user sorting. Keyset delta sync in `SyncSubmissions.cs` uses `s.UpdatedAt` (server-side timestamp) which prevents clock-drift data corruption during sync pulls.
*   **Transactional Fracture**:
    *   *Analysis*: Logically bound items (Submissions, Answers, and Photos) are persisted locally in Drift in a single database transaction. During sync, they are pushed in two phases (Phase 1: Submission data sync, Phase 2: Photo upload). If Phase 2 fails, the submission is already registered on the server, and the outbox flags photos as `pending` to retry. However, this split-phase operation creates a brittle state where a submission has incomplete media indefinitely if the queue is blocked.

### Critic 3: The 2 AM Landmine (Resilience & Observability)
*   **The Poison Pill**:
    *   *Bug*: `PhotoQueueService.drainQueue` retrieves all photos for a submission and filters by `syncStatus == 'pending'`. When an upload fails, it calculates `nextRetryAt` and updates SQLite. However, `drainQueue` **completely ignores `nextRetryAt`**. When a sync cycle triggers, *any* photo with status `'pending'` is uploaded immediately, completely bypassing exponential backoff delays. If a device has intermittent connection drops or flutters, the engine will aggressively hammer the photo API without waiting.
*   **The Thundering Herd**:
    *   *Analysis*: `SyncEngine` introduces random jitter (0 to `_maxReconnectJitterMs`) before starting sync on reconnect. `PhotoQueueService` also applies a 0-15s initial random jitter once per batch before processing photos. This successfully mitigates reconnect stampedes.
    *   *Bug (Transactional Retry Corruption)*: In both `CreateSubmission.cs` and `FinalizeSubmission.cs`, the handlers wrap database updates in `strategy.ExecuteAsync()`. If a transient exception occurs (e.g., database deadlock or transaction rollback) and EF Core retries the block:
        1.  In `CreateSubmission`, `db.Submissions.Add` is called inside `ExecuteAsync`. Upon retry, this will throw an `InvalidOperationException` because the submission entity is already tracked by the Change Tracker.
        2.  In `FinalizeSubmission`, the deletion of old answers and additions of new answers are done **outside** the `ExecuteAsync` block. If the transaction fails and retries, the answers in the change tracker are out of sync, leading to DB constraint violations.
        3.  `ActionPlanService.AutoCreateAsync` is executed inside the retry block. It performs `.AddRange` to add new Action Plans to the DbContext. On each retry, it adds a *new set* of identical Action Plans. If the transaction retries 3 times and then succeeds, **triplicate action plans are written to the database**, causing massive duplicate data corruption.
        4.  `SectionScoreExploder.ExplodeAsync` does not delete existing records before executing its `Add` loop. If the finalization transaction retries after the first flush succeeds (or the request is retried by the outbox), duplicate section scores are inserted into `submission_section_scores`.

### Critic 4: The Brick (Boundary & Exploit Risk)
*   **The "Root" Suicide**:
    *   *Analysis*: Not applicable; user authorization is gated by PBAC capabilities and role scopes.
*   **Contextual Illusion (IDOR)**:
    *   *Analysis*: `SyncSubmissions.cs` has robust IDOR checks. It restricts non-admins to their assigned store via `ResourceAccessGuard.CanAccessAsync`. Auditors are strictly constrained to sync only their own submissions (`s.AuditorId == auditorUserId`).

### Critic 5: Cognitive Debt (The Easy Button)
*   **Hasty Abstractions**:
    *   *Analysis*: The transaction lock manager `DistributedLockManager.cs` relies on transaction-scoped advisory locks which auto-release on commit/rollback. However, running the caller's critical section inside `strategy.ExecuteAsync` means that any transient query failure inside the critical section will cause the *entire* critical section to re-execute. Callers must be explicitly made aware of this, or non-idempotent side effects must be extracted.

---

## 3. The Severity Matrix & Actionable Fixes

### 🔴 Issue 1: Mobile Photo Upload Queue Bypasses Backoff Delays
*   **Location**: `lib/_shared/services/photo_queue_service.dart`
*   **Severity**: `🔴 Fatal` (API flooding, drains device battery, fails offline backoff contract).
*   **Impact**: When a photo upload fails, it updates SQLite with `nextRetryAt` in the future. However, `drainQueue` pulls all photos with `syncStatus == 'pending'` and uploads them immediately without checking `nextRetryAt`. Any subsequent trigger (manual sync, other submission uploads, or network transitions) completely bypasses the backoff timer.
*   **Actionable Fix**: Update the filtering logic in `drainQueue` to only execute uploads for photos whose `nextRetryAt` is null or in the past.
*   **Complexity**: `Low` — Requires adding a simple DateTime filter on the list inside `drainQueue`.
*   **Trade-offs**: 
    *   *Pro*: Preserves device battery, respects SRE rate limits, and obeys exponential backoff.
    *   *Con*: Photos that fail will wait for the full backoff period even if the network recovers immediately (acceptable SRE trade-off).

---

### 🔴 Issue 2: Duplicate Section Scores Ingested Under Retries or Re-submissions
*   **Location**: `server/Features/Submissions/SectionScoreExploder.cs`
*   **Severity**: `🔴 Fatal` (Data corruption in analytics, dashboard reports double-count scores).
*   **Impact**: `SectionScoreExploder.ExplodeAsync` loops through section scores and performs `db.SubmissionSectionScores.Add`. It does not clear pre-existing scores for the same `submissionId`. Since there is no unique constraint on `(submission_id, section_title)`, duplicate rows are inserted if the submission creation/finalization is retried or re-sent.
*   **Actionable Fix**: Prior to inserting new scores inside `ExplodeAsync`, run a bulk delete for any existing scores linked to the target `submissionId`.
    ```csharp
    await db.SubmissionSectionScores
        .Where(x => x.SubmissionId == submissionId)
        .ExecuteDeleteAsync(ct);
    ```
*   **Complexity**: `Low` — Simple addition of a single fast EF Core `ExecuteDeleteAsync` query.
*   **Trade-offs**: 
    *   *Pro*: Absolute idempotency for section score generation; guarantees report aggregates remain correct under retries.
    *   *Con*: Minor overhead of an extra delete query (negligible due to index matching on `submission_id`).

---

### 🔴 Issue 3: Duplicate Action Plans & Key Collisions Under EF Core Transaction Retries
*   **Location**: `server/Features/Submissions/CreateSubmission.cs` & `server/Features/Submissions/FinalizeSubmission.cs`
*   **Severity**: `🔴 Fatal` (Duplicated database records, runtime transaction crashes under load).
*   **Impact**: 
    1.  In `CreateSubmission`, `db.Submissions.Add` is within the `strategy.ExecuteAsync` block. If the block retries due to a database deadlock or timeout, calling `Add` again causes a tracking conflict in EF Core.
    2.  In `FinalizeSubmission`, the deletion of old answers and additions of new answers are outside `strategy.ExecuteAsync`, which prevents the change tracker from correctly resetting on retries.
    3.  `ActionPlanService.AutoCreateAsync` is inside the retry block. It adds Action Plans directly to the tracker. On each transaction retry, it duplicates these entities in memory, resulting in multiple duplicate Action Plan rows saved to the database.
*   **Actionable Fix**: 
    *   Move all DbContext Change Tracker mutations (such as `Add`, `Remove`, `AddRange`) **inside** the execution strategy block.
    *   Before adding or modifying entities inside the retry block, clear the change tracker or check if the entities are already tracked to guarantee absolute idempotency.
    ```csharp
    db.ChangeTracker.Clear(); // Clears pre-existing tracked modifications on retry start
    ```
*   **Complexity**: `Medium` — Requires reorganization of change tracking setup inside endpoints to ensure absolute idempotency.
*   **Trade-offs**:
    *   *Pro*: Fully resolves the EF Core retry tracker bug, guaranteeing no crashes and zero duplicate action plan generation.
    *   *Con*: Requires careful state handling to ensure we don't clear unrelated tracked items (safe here since the DbContext is scoped to this request).

---

### 🟡 Issue 4: Non-Idempotent Critical Section Retry in Distributed Locks
*   **Location**: `server/Common/Persistence/DistributedLockManager.cs`
*   **Severity**: `🟡 Brittle` (Potential duplicate side-effects).
*   **Impact**: `TryExecuteInLockAsync` runs the caller-provided `criticalSection` inside `strategy.ExecuteAsync`. If a transient exception occurs during the execution strategy, the critical section is re-run. If the caller has non-idempotent operations (such as publishing messages or making external API calls), they will execute multiple times.
*   **Actionable Fix**: Document and enforce that any critical section passed to `DistributedLockManager` MUST be fully idempotent, or provide a separate non-retrying option for tasks with external side effects.
*   **Complexity**: `Low` — Requires developer documentation and code review validation.
*   **Trade-offs**:
    *   *Pro*: Clear guidance prevents developers from writing unsafe non-idempotent locked logic.
    *   *Con*: Places the responsibility of idempotency on the caller.

---

### 🟡 Issue 5: SyncEngine Disposed Future Leak
*   **Location**: `lib/_shared/services/sync_engine.dart`
*   **Severity**: `🟡 Brittle` (Resource leak).
*   **Impact**: Reconnect transitions schedule a delayed sync trigger using `Future.delayed`. If the engine is disposed, the future continues to execute, causing state transitions and operations on a disposed instance.
*   **Actionable Fix**: Store the reconnect delayed trigger in a nullable `Timer` field, and cancel it in `dispose()`.
*   **Complexity**: `Low` — Simple field tracking and cancellation.
*   **Trade-offs**:
    *   *Pro*: Eliminates leaks and prevents widget test crashes.
    *   *Con*: None.

---

## 4. Architectural Verification Plan
Before any code changes are implemented, SRE mandates the following validation paths:

```text
[Code Correction] --> [Local Compile check] --> [ATDD / Unit Tests Verification]
```

1.  **Unit Testing for Photo Queue**: Write tests in `test/photo_queue_service_test.dart` asserting that a photo whose `nextRetryAt` is in the future is bypassed by `drainQueue`, and is only processed after the backoff delay elapses.
2.  **Concurrency Retry Testing for Submissions**: Write an integration test that simulates a transaction failure during `CreateSubmission` and `FinalizeSubmission` (e.g. by using a transient DB exception throw on first save) and verify that:
    - The engine successfully retries.
    - No tracking key collision crashes occur.
    - No duplicate Action Plans are generated.
    - No duplicate `SubmissionSectionScores` exist in the database on final success.

---

## ## Handoff Block
1. **Final SRE Verdict**: `🔴 FATAL`
   - *Report Persistent Path*: `docs/reports/diagnostics/audit_arch_report_20260602_030000.md`
2. **Summary of 2AM Landmines found**:
   - Aggressive photo upload backoff bypass under unstable networks (API DDoS).
   - Duplicate section score records and duplicate action plan records created on retry / re-submission.
   - Tracker collision crashes on EF Core retry execution blocks during high database lock contention.
3. **AI Agent Mission Brief**: 
   The next builder agent must execute code modifications in `photo_queue_service.dart`, `SectionScoreExploder.cs`, `CreateSubmission.cs`, `FinalizeSubmission.cs`, and `sync_engine.dart` to enforce database transaction retry safety, correct backoff filters, and eliminate database duplication.
4. **Next Workflow Command**: `/analyze-feature`
