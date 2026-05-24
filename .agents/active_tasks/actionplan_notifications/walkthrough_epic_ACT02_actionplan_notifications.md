# Epic Walkthrough: Action Plan Notifications (Transactional Outbox)

## Input Lineage
- **Epic Analysis**: `docs\architecture\analysis_epic_20260513_090000_ACT02_actionplan_notifications.md`
- **Objective**: Remediate transactional fractures and thread pool starvation in the Action Plan notification system by migrating from a synchronous dispatch flow to an asynchronous Transactional Outbox pattern.

---

## 1. Slice 1: Infrastructure & Background Worker
**Objective**: Scaffold the foundational entities and background services required to support the outbox pattern.

### Decisions & Implementation:
- **Entity Setup**: 
  - Created the `OutboxMessage` entity to act as the persistent queue for messages.
  - Added the `OutboxMessages` `DbSet` to `AppDbContext`.
  - Configured `OutboxMessageConfiguration` with an optimized, filtered index on `processed_at IS NULL` to ensure efficient polling by the background worker.
- **Background Worker**: 
  - Scaffolded `OutboxBackgroundService` implementing `BackgroundService`.
  - Integrated **Polly** `ResiliencePipeline` to provide Exponential Backoff and Jitter to gracefully handle transient network or FCM failures without losing messages.
- **Migration**: 
  - Generated and verified the EF Core migration `AddOutboxMessage` to apply the schema changes safely.
- **Verification**: 
  - Successfully verified the application container and EF Core models via `dotnet test`.

---

## 2. Slice 2: UpdateActionPlan Refactor
**Objective**: Decouple the `UpdateActionPlan` endpoint from the synchronous FCM service, achieving atomic database consistency.

### Decisions & Implementation:
- **Dependency Cleanup**: 
  - Removed the `IFcmDispatchService` injection parameter from the `UpdateActionPlan.HandleAsync` endpoint, completely separating the HTTP pipeline from external network calls.
- **Transactional Consistency**:
  - Eliminated the split double-commit (calling `await db.SaveChangesAsync(ct)` multiple times).
  - Consolidated the saving of the Action Plan state, the creation of the `Notification` audit record, and the creation of the new `OutboxMessage` payload.
- **Outbox Insertion**:
  - Inserted the `OutboxMessage` (of type `Notification` with JSON payload) synchronously into the database context.
  - Commits to the database atomically at the very end of the request (`await db.SaveChangesAsync(ct)`). If the transaction fails, neither the Action Plan status nor the Outbox message is saved, eliminating the "split-brain" state.
- **Verification**:
  - Re-ran the global `rtk dotnet test` suite to prove that removing the dependency from the Minimal API signature didn't corrupt the routing or integration test factories. All tests passed.

---

## 3. Slice 3: Frontend Synchronization & Polling Stability
**Objective**: Stabilize the frontend test suite following synchronization module refactors and tune the outbox processor.

### Decisions & Implementation:
- **Outbox Polling Tuning**: 
  - Verified the `OutboxBackgroundService` utilizes a 5-second polling interval for processing queued notifications.
- **Sync Module Refactoring**:
  - The `ActionPlanSyncModule` constructor was simplified to offload redundant dependencies (`authManager`, `profileDao`, `submissionDao`) into the `SyncEngine` infrastructure, focusing strictly on its domain boundaries.
- **Test Suite Health**:
  - Mass-migrated the `flutter test` suites (`sync_engine_global_risks_test.dart`, `sync_engine_backoff_test.dart`, `sync_engine_hardening_test.dart`, `sync_engine_push_test.dart`) to conform to the new module signatures.
  - Successfully achieved zero-regression stability across the entire 495+ test suite.

---

## Conclusion & Handoff
The backend fully embraces the Transactional Outbox pattern for action plan notifications, neutralizing the risk of thread pool starvation and guaranteeing reliable delivery of push notifications even under transient FCM downtime. The frontend synchronization layers and test suites are now verified to be clean and fully aligned with the production architecture. 

**Next Steps**:
- Implement a monitoring endpoint for the `OutboxBackgroundService` in the .NET backend to alert on high queue depths before production rollout.

<forensic_evidence>
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Executed tests against the entire project to ensure endpoint mapping or integration tests were not regressed.
</forensic_evidence>
