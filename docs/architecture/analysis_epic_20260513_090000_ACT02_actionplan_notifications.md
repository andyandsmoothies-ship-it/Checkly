<latent_space_scratchpad>
Goal: Fix Split-Brain and ThreadPool starvation in `UpdateActionPlan.cs` by introducing the Transactional Outbox pattern.
Options:
- Shape A: Custom `OutboxMessage` table and a `.NET BackgroundService`.
- Shape B: External queuing infrastructure like Quartz.NET, Wolverine, or MassTransit.
Tradeoffs: The project does not currently use Wolverine or MassTransit. Adding a simple `OutboxMessage` entity and a custom `BackgroundService` is the lowest overhead and natively guarantees atomicity with the same EF Core `DbContext`.
Slices:
1. Backend: Scaffold the `OutboxMessage` entity, EF config, and Migration.
2. Backend: Implement the `OutboxBackgroundService` worker to poll the table and dispatch FCM messages.
3. Backend: Refactor `UpdateActionPlan.cs` to wrap the update, notification, and outbox insertion into a single transaction (or relying on a single `SaveChangesAsync` if sharing the same DbContext scope).
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_arch_report_20260512_200000_ACT02_actionplan_notifications.md`

## Executive Summary
The `UpdateActionPlan` endpoint currently updates an Action Plan, saves it, inserts a Notification, saves it, and then synchronously calls Firebase Cloud Messaging (FCM). This creates two catastrophic flaws: Transactional Fracture (Split-Brain) and ThreadPool starvation (Zombie). This Epic will refactor the system to use the Transactional Outbox pattern, guaranteeing that DB updates and push notifications are atomic and decoupled.

## Decision Matrix

| Requirement | Shape A: Custom EF Outbox + BackgroundService | Shape B: Heavy Queuing Framework (MassTransit) |
|-------------|:---:|:---:|
| **R1: Zero Missed Notifications (Atomicity)** | ✅ | ✅ |
| **R2: Prevent ThreadPool Starvation (Async Dispatch)** | ✅ | ✅ |
| **R3: Minimal Architectural Overhead** | ✅ | ❌ |

**Decision**: **Shape A** is chosen. A custom `OutboxMessage` entity with a simple `.NET BackgroundService` provides exactly-once or at-least-once dispatch guarantees natively using EF Core without requiring new heavy dependencies like MassTransit or RabbitMQ.

## Risk Assessment
- **Background Worker Crash**: If the background worker fails, it will stop processing notifications. We must ensure the worker catches all exceptions and continues polling.
- **Duplicate Notifications (At-Least-Once Delivery)**: FCM might be successfully called but the process crashes before the `OutboxMessage` is marked as processed. Mobile clients must handle duplicate push notifications idempotently.

## Visual & Functional Context
- **UI Impacts**: None. This is a purely backend infrastructural task.

## System Context
- **Resilience**: The background service will use Polly to handle transient FCM failures (e.g., 503s from Google).
- **Atomicity**: The Action Plan, Notification, and OutboxMessage will all be attached to the same `DbContext` and committed via a single `await db.SaveChangesAsync(ct)`, preventing Split-Brain.

## Lifecycle Context
- **Edge Cases**: FCM limits or dead-letter queuing. The outbox processor should mark messages as `Failed` after 3 retries rather than blocking the queue indefinitely.

## Data Context
- **Database Migrations**: A new `OutboxMessages` table must be created with columns: `Id`, `Type`, `Payload` (JSON), `CreatedAt`, `ProcessedAt`, `Error`.

## Architecture Flow
1. **HTTP Request**: Client calls `PUT /api/action-plans/{id}`.
2. **Atomic Commit**: The backend updates the ActionPlan, adds a Notification, and adds an `OutboxMessage` (Payload: `{ UserId, NotificationId }`). All are saved via a single `SaveChanges`. Endpoint returns `200 OK` instantly.
3. **Background Processing**: The `OutboxBackgroundService` polls the DB every few seconds for unprocessed messages.
4. **Dispatch**: The worker calls `fcm.DispatchSyncNeededAsync` using Polly retries.
5. **Completion**: Worker marks the message as `ProcessedAt = UTC`.

## Risk Review & Security
- **Security Auditor**: 10/10. (IDOR rules remain untouched).
- **DB Architect**: 9/10. (Eliminates transactional fractures. Minimal indexing needed on `ProcessedAt`).
- **Junior Dev**: 8/10. (Outbox pattern introduces async concepts, but is well-contained and documented).

## Logs & Audits
- We must log FCM dispatch failures in the `OutboxMessage.Error` column for observability.

## Testing Expectations
- **Backend Tests**: Verify that `UpdateActionPlan` successfully inserts an `OutboxMessage` and succeeds even if FCM is unavailable.

## Handoff Block

1. **Epic Plan**: `docs/architecture/analysis_epic_20260513_090000_ACT02_actionplan_notifications.md`
2. **Slices**:
   - **Slice 1 | Outbox Infrastructure** `[BLOCKING]`: Scaffold the `OutboxMessage` entity, DB configuration, and the `OutboxBackgroundService` worker with basic Polly retries.
   - **Slice 2 | UpdateActionPlan Refactor** `[SEQUENTIAL]`: Modify `UpdateActionPlan.cs` to remove synchronous `fcm` calls and instead write an `OutboxMessage` in the same `SaveChanges` transaction.
3. **Next Steps**: The Builder must implement Slice 1 to establish the foundational Outbox infrastructure.
4. **Next Workflow**: `/implement`

<forensic_evidence>
Executed `grep_search` to find `OutboxMessage`, `BackgroundService`, `Wolverine`, and `MassTransit` in `server/`. None were found, verifying that no existing Outbox infrastructure exists.
Executed `view_file` on `server/Features/ActionPlans/UpdateActionPlan.cs` to confirm the double-`SaveChanges` and synchronous `fcm.DispatchSyncNeededAsync` issues.
</forensic_evidence>
