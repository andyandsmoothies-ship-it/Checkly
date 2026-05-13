# Architecture Audit: Action Plan Notifications & Transitions

**Target**: `server/Features/ActionPlans/UpdateActionPlan.cs`
**Date**: 2026-05-12
**Auditor**: Sentinel (Chief Architect / SRE)

## Verdict: 🟡 Brittle (Silent Data Loss & ThreadPool Starvation)

The architecture improperly couples core database transactions to synchronous 3rd-party network calls (Firebase Cloud Messaging). Under latency or failure conditions, it will orphan notifications and crash the web server via ThreadPool starvation.

---

## The Interrogation

### Critic 1: The Zombie (Stateless Illusion)
**Failure**: `await fcm.DispatchSyncNeededAsync(notif.UserId)` executes synchronously on the HTTP request thread. If FCM (Google) experiences an outage or a massive latency spike (e.g., holding connections open for 30s), the web server threads will lock up waiting for it. This will rapidly trigger ThreadPool starvation, crashing the entire Checkly API over a non-critical push notification.

### Critic 2: The Split-Brain (State & Sync)
**Failure**: **Transactional Fracture**.
1. Line 128: `await db.SaveChangesAsync()` (Action Plan updated)
2. Line 201: `db.Notifications.Add(...)`
3. Line 202: `await db.SaveChangesAsync()` (Notification updated)
4. Line 203: `await fcm.DispatchSyncNeededAsync(...)` (FCM called)

If the web server restarts or crashes between Step 1 and Step 2, the Action Plan is successfully updated, but the Notification is permanently lost.
Furthermore, if Step 4 (FCM) fails, the HTTP request returns a `500 Internal Server Error`. The mobile client will naturally retry the request. However, on the retry, `oldStatus == request.Status` will be true (because the DB *was* updated in Step 1). Therefore, the retry will effectively bypass the notification block, meaning the FCM push is swallowed forever.

### Critic 3: The 2 AM Landmine (Resilience & Observability)
**Failure**: **No Dead Letter Queue (DLQ)**. Because FCM is called inline, any failure just throws an exception to the caller. There is no automated retry for the push notification.

### Critic 4: The Brick (Boundary & Exploit Risk)
**Pass**: IDOR checks and transition validations via PBAC are solid. 

### Critic 5: Cognitive Debt (The Easy Button)
**Pass**: The code is sequential and understandable, but lacks the necessary distributed systems safety mechanics.

---

## Actionable Fix & Trade-offs

### 1. The Outbox Pattern
Merge the ActionPlan update, Notification insert, and an "OutboxMessage" insert into a single `db.SaveChangesAsync()` call. A background worker (e.g., .NET `BackgroundService` or Wolverine/MassTransit) then polls the Outbox table and safely dispatches the FCM messages asynchronously with Polly retries.
* **Complexity**: **Medium**. Requires defining an `OutboxMessage` entity, wrapping the updates in a transaction, and spinning up a BackgroundService to process the queue.
* **Trade-offs / Pros & Cons**: 
  * **Pro**: Perfect transactional integrity. The HTTP request returns instantly, immune to Google FCM outages. Web server ThreadPool is safe.
  * **Con**: Adds infrastructure overhead (a new table and background worker) and introduces a slight, negligible delay (seconds) to push notifications.

---

## Handoff Block

1. **Verdict**: 🟡 BRITTLE. `UpdateActionPlan.cs` has Transactional Fracture and synchronous 3rd-party IO, guaranteeing swallowed notifications and risking ThreadPool starvation during an FCM outage.
2. **2AM Landmines**: A sudden latency spike on Google's FCM servers will freeze all threads on Checkly API handling Action Plan updates.
3. **Mission Brief**: The Builder must refactor `UpdateActionPlan.cs` to eliminate synchronous FCM calls. Implement the Transactional Outbox pattern: save the plan change, the notification record, and an Outbox message in *one* database transaction. Move `fcm.DispatchSyncNeededAsync` to a background worker.
4. **Next Workflow**: `/analyze-epic` or `/implement`
