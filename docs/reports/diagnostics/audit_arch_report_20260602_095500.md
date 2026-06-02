<latent_space_scratchpad>
Thinking through SRE critical edge cases and failure modes:
1. Zombie state in DistributedLockManager.cs:
   - pg_try_advisory_xact_lock locks transaction scope.
   - If criticalSection hangs, Postgres backend processes stay ACTIVE with high transaction wait times.
   - Thread pool on the client (ASP.NET Core) starves due to DbContext pool exhaustion.
   - Fix: Wrap task execution inside distributed locking in a timeout cancellation token (e.g. using a 30s cancellation source).
2. Split-Brain in PhotoQueueService:
   - photo_queue_service.dart runs synchronously within each submission context.
   - But if user taps upload or sync triggers twice, parallel drainQueue futures will run on the same outbox items.
   - Duplicate HTTP uploads will occur because status isn't locked/tracked globally before starting the loop.
   - Fix: Introduce a global active in-memory set to prevent concurrent uploading of the same submission ID.
3. Poison Pill in SyncEngine:
   - sync_engine.dart iterates modules. If module 1 throws, loop aborts, preventing subsequent critical modules (auth/submissions) from syncing.
   - Fix: Use structured try-catches around each individual sync module operation to guarantee downstream sync robustness.
4. Silent failures in SectionScoreExploder:
   - JsonException is swallowed silently without logging.
   - Fix: Inject ILogger to capture parsing issues and raise early alerts on schema mismatch.
</latent_space_scratchpad>

# SRE Architecture Audit Report
Workflow: /audit-arch | Track: C | Date: 2026-06-02

## 1. System Map & Core Topology

Below is the logical structure of Checkly's offline synchronization, background queuing, transaction-scoped locking, and scoring ingestion pipelines.

```
       [Flutter Client]                                  [ASP.NET Backend Core]
 ┌──────────────────────────┐                      ┌─────────────────────────────────┐
 │       SyncEngine         │                      │          SyncEndpoints          │
 │  (Delta Pull/Push Loop)  │                      │   (/api/sync/* Keyset Pages)    │
 └────────────┬─────────────┘                      └────────────────┬────────────────┘
              │ (Pull/Push Modules)                                 │
              ▼                                                     ▼
 ┌──────────────────────────┐                      ┌─────────────────────────────────┐
 │     PhotoQueueService    │                      │      SectionScoreExploder       │
 │   (FIFO Outbox Upload)   │                      │    (Raw JSON -> Score Tables)   │
 └──────────────────────────┘                      └────────────────┬────────────────┘
                                                                    │ (Db Context)
                                                                    ▼
                                                   ┌─────────────────────────────────┐
                                                   │     DistributedLockManager      │
                                                   │    (Postgres Advisory Locks)    │
                                                   └─────────────────────────────────┘
```

---

## 2. Threat Modeling & Critic Interrogation

### Critic 1: The Zombie (Stateless Illusion)
* **Status**: `🟡 Brittle`
* **SyncEngine Hang Vulnerability**:
  The `SyncEngine` sequential module sync loop (`_runModuleSyncCycle`) does not enforce a task-level timeout. If a single sync module's network call hangs indefinitely due to socket silent-dropping, the `_activeSync` Future will remain active forever, locking out any subsequent synchronization requests.
* **Advisory Lock Connection Drain**:
  In `DistributedLockManager.cs`, `TryExecuteInLockAsync` does not wrap the client-supplied critical section in a timeout guard. If the critical section hangs or is deadlocked, the connection pool will exhaust quickly, leading to total server lockup.

### Critic 2: The Split-Brain (State & Sync)
* **Status**: `🔴 Fatal`
* **Silent Scoring Drift**:
  `ScoringEngine._isPureAudit()` in Dart suppresses calculated scores if any measurable widget has a zero points weight. If this logic deviates even slightly from the backend C# implementation, the sync endpoint will mismatch.
* **Outbox Concurrency Collision**:
  `PhotoQueueService` has zero local concurrency guards. If multiple triggers call `drainQueue` concurrently, both execute concurrently on the same pending files, triggering redundant uploads and outbox status race conditions.

### Critic 3: The 2 AM Landmine (Resilience & Observability)
* **Status**: `🔴 Fatal`
* **Sync Engine Poison Pill**:
  An unhandled exception in *any* module's sync cycle immediately aborts the loop. If a single minor feature sync fails, the entire sync pipeline halts, preventing critical data like submissions and profiles from syncing.
* **Score Exploder Silent Failures**:
  `SectionScoreExploder.cs` catches `JsonException` and silently returns `Task.CompletedTask`. If a serialization format change or payload corruption occurs, section scores are silently omitted without logs or alerts.

### Critic 4: The Brick (Boundary & Exploit Risk)
* **Status**: `🟢 Resilient`
* **Tenant Isolation Safeguards**:
  `SyncSubmissions.cs` is robustly secured. Non-admin calls are checked against `ResourceAccessGuard.CanAccessAsync`. Auditors and Area Managers are securely scoped to their explicit profile mappings.

### Critic 5: Cognitive Debt (The Easy Button)
* **Status**: `🟢 Resilient`
* **Design Purity**:
  `DistributedLockManager.cs` correctly utilizes transactional advisory locks `pg_try_advisory_xact_lock` and computes keys with a stable FNV-1a hash rather than randomized standard string hashing.

---

## 3. Forensic Evidence

<forensic_evidence>
* **Files Located & Inspected**:
  * `lib/_shared/services/sync_engine.dart` (Validated Connectivity Stream Done/Error Handling & Jitter delays)
  * `lib/_shared/services/photo_queue_service.dart` (Verified FIFO outbox database updates)
  * `lib/_shared/services/scoring_engine.dart` (Audited purity scores and global overrides)
  * `server/Features/Sync/SyncEndpoints.cs` (Confirmed minimal api routing)
  * `server/Features/Submissions/SyncSubmissions.cs` (Inspected Keyset paging query limits and guards)
  * `server/Features/Submissions/SectionScoreExploder.cs` (Checked JSON score projection logic)
  * `server/Common/Persistence/DistributedLockManager.cs` (Validated FNV-1a custom 64-bit string hashing algorithm)
* **Grep Searches Executed**:
  * Found `DistributedLockManager` inside `server/Common/Persistence/DistributedLockManager.cs`
  * Found `SectionScoreExploder` inside `server/Features/Submissions/SectionScoreExploder.cs`
  * Found `SyncSubmissions` inside `server/Features/Submissions/SyncSubmissions.cs`
* **Database Alignment**:
  * Drift schemas and synchronization endpoints verified via `verify_workflow.py` contract checks with a perfect `SUCCESS` code exit status.
</forensic_evidence>

---

## 4. The Verdict Payload

### Summary of System Scopes & Statuses

| Module / Scope | Target File(s) | SRE Verdict | Key Vulnerability |
| --- | --- | --- | --- |
| **Offline Sync Engine** | `sync_engine.dart` | `🟡 Brittle` | Single module failure blocks all subsequent modules. No global request timeouts. |
| **Photo Upload Queue** | `photo_queue_service.dart` | `🔴 Fatal` | Concurrent execution race conditions on the same outbox batch. |
| **Scoring & Ingestion** | `scoring_engine.dart` / `SectionScoreExploder.cs` | `🟡 Brittle` | Malformed JSON fails silently on ingestion. Silent client/server scoring logic drift. |
| **Distributed Locking** | `DistributedLockManager.cs` | `🔴 Fatal` | No timeout on critical sections leads to Postgres connection pool exhaustion. |

---

## 5. Actionable Fixes & Strategic Redesigns

### Fix 1: Resilient Sync Engine Module Loop
* **Problem**: One module crash stops all other sync modules.
* **Proposed Solution**: Wrap individual module pull/push cycles in `try-catch` structures. Log individual errors and allow other independent sync modules to execute.
* **Complexity**: **Low**. Straightforward change to the loop in `sync_engine.dart`.
* **Pros/Cons**:
  * *Pro*: Prevents localized feature bugs from blocking global sync.
  * *Con*: Complex error tracking is needed to show which module failed.

### Fix 2: Concurrency Lock for Photo Uploads
* **Problem**: Simultaneous execution of `drainQueue` uploads duplicate files.
* **Proposed Solution**: Maintain a local active in-memory map of running submission uploads in `PhotoQueueService` to skip concurrent runs for the same ID.
* **Complexity**: **Low**. Uses a simple class-level Set of active submission IDs.
* **Pros/Cons**:
  * *Pro*: Eliminates double uploads and outbox race conditions.
  * *Con*: Must guarantee cleanup in `finally` blocks to avoid permanent locks.

### Fix 3: Critical Section Timeouts in DistributedLockManager
* **Problem**: Indefinite hanging in critical section blocks Npgsql connection pool.
* **Proposed Solution**: Enforce a strict connection timeout limit (e.g., 30s) or wrap the critical section in a timeout cancellation token inside `TryExecuteInLockAsync`.
* **Complexity**: **Medium**. Requires token combination using `CancellationTokenSource.CreateLinkedTokenSource`.
* **Pros/Cons**:
  * *Pro*: Safely releases connection pool back to database on deadlock.
  * *Con*: Critical sections must respect the cancellation token properly.

### Fix 4: Observable Ingestion in SectionScoreExploder
* **Problem**: Ingestion errors fail silently.
* **Proposed Solution**: Add structured semantic logging (`ILogger`) to log malformed JSON payloads.
* **Complexity**: **Low**. Just requires passing/injecting `ILogger` into the helper class.
* **Pros/Cons**:
  * *Pro*: Full visibility into schema drift or malformed client-submitted scores.
  * *Con*: Increases log volume if clients submit broken payloads consistently.

---

## Handoff Block

> [!IMPORTANT]
> **SRE Audit Status: RED ALERT**
> *   **Persistent Path**: `docs/reports/diagnostics/audit_arch_report_20260602_095500.md`
> *   **Primary 2 AM Landmines**:
>     1. No timeout on advisory locks allows hanging tasks to crash the backend connection pool.
>     2. Lack of concurrent upload protection inside `PhotoQueueService` causes duplicate image uploads.
>     3. Silent JSON exception swallowing in the backend scoring ingestion engine mask payload serialization drift.
>
> **AI Agent Mission Brief:**
> Implement target fixes for `DistributedLockManager` critical timeouts, wrap the `sync_engine` module iterations in isolated try-catches, and add class-level execution guards in `PhotoQueueService`.
>
> **Next Recommended Step**: `/research`
