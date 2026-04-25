<latent_space_scratchpad>
The ADR is mostly right, but the codebase proves the narrowest safe fix is smaller than the ADR's wording suggests. The source of truth is still the server handler in UpdateActionPlan.cs; the mobile client only queues a plain PATCH to pending_verify and the sync engine currently treats all action-plan drain failures as terminal. That means the core bug is not "offline merge" but "server accepts a forbidden terminal-state regression and mobile cannot classify the rejection cleanly." The plan should therefore keep database shape stable, add one machine-readable conflict contract, and consume that contract at the Dio adapter boundary so SyncEngine can dequeue deliberately without inventing a new queue framework. Anything beyond that - row versions, merge UI, partial acceptance of text on closed plans, failed-draft recovery - is product scope expansion.
</latent_space_scratchpad>

## Executive Summary & YAGNI
Track: B2.

Business value: prevent a stale offline evidence submission from moving a server-side `ActionPlan` from `closed` back to `pending_verify`, while keeping the existing offline queue healthy.

Winning shape:
- Enforce the terminal-state guard on the backend source of truth in [server/Features/ActionPlans/UpdateActionPlan.cs](C:/Users/HP/Documents/GitHub/Checkly/server/Features/ActionPlans/UpdateActionPlan.cs).
- Return RFC 9457 `ProblemDetails` with a stable machine-readable code such as `action_plan_already_closed`.
- Translate that exact server conflict into a typed Flutter exception at the `Dio` adapter boundary.
- Teach [lib/_shared/services/sync_engine.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/sync_engine.dart) to treat that typed stale-state conflict as non-retryable and dequeue the outbox row.

YAGNI / out of scope:
- No `RowVersion` or `xmin` on `ActionPlan`.
- No CRDTs, manual merge UI, or general offline collaboration model.
- No database schema changes to `action_plans` or `PendingActionPlanUpdates`.
- No partial acceptance of evidence text into a closed plan without explicit product approval.
- No failed-mutation recovery UX in this slice.

Strict Implementation Constraints & Human Reminders
- The backend remains the source of truth for terminal-state legality.
- The mobile queue must not string-match arbitrary error text if a stable code can be parsed from `ProblemDetails`.
- Notification side effects for successful status transitions must remain unchanged.
- A stale offline payload must not reopen the plan and must not poison the remaining sync batch.

## 4-State Matrix
| State | System condition | Expected behavior |
|---|---|---|
| Success | Plan is not terminal and request is a legal transition or field update | Backend returns `200 OK`; audit trail and existing notifications behave exactly as today; sync queue removes the row after success. |
| Error | Persisted plan is `closed` and incoming payload tries `status = pending_verify` | Backend returns `409 ProblemDetails` with stable code `action_plan_already_closed`; plan remains `closed`; rejected attempt is audit-logged; mobile queue classifies as non-retryable and removes the row. |
| Empty | No pending action-plan outbox rows | Sync engine skips action-plan drain phase with no behavior change. |
| Loading | Sync engine is draining pending action-plan evidence after reconnect | Each row is processed FIFO; stale-state conflicts are drained intentionally; unrelated later rows are still allowed to proceed. |

## Test Contracts
| ID | Exact Text | State Matrix | Why RED |
|---|---|---|---|
| BE-AP-409-01 | `UpdateActionPlan_WhenPersistedPlanIsClosed_AndRequestAttemptsPendingVerify_Returns409ProblemDetailsCodeActionPlanAlreadyClosed` | Error | Current handler writes `plan.Status = request.Status` with no terminal-state guard, so stale reopen is accepted. |
| BE-AP-409-02 | `UpdateActionPlan_WhenStalePendingVerifyIsRejected_DoesNotMutateStatus_AndWritesAuditLog` | Error | Current handler updates status, saves, and logs `action_plan_updated`; there is no rejected-attempt audit path to prove forensic visibility. |
| BE-AP-409-03 | `UpdateActionPlan_WhenOpenPlanMovesToPendingVerify_StillReturns200AndSetsEvidenceMetadata` | Success | Guards against over-blocking normal store-manager evidence submission while adding the stale-state check. |
| FE-SYNC-AP-409-01 | `SyncEngine_WhenActionPlanApiThrowsActionPlanAlreadyClosedException_RemovesOutboxEntry_AndContinuesBatch` | Error | Current sync engine marks every action-plan drain failure exhausted and returns early, creating a poison-pill batch stop. |
| FE-SYNC-AP-409-02 | `ActionPlanApiAdapter_WhenServerReturns409ProblemDetailsCodeActionPlanAlreadyClosed_ThrowsTypedActionPlanAlreadyClosedException` | Error | Current adapter exposes raw `DioException` only; there is no typed classification boundary for stale-state handling. |

## JIT Harness & Verification
[ACTIVE_SKILLS]
- `mobile-offline-support`
- `error-handling`
- `testing-strategy`

Terminal validation commands
- `dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~UpdateActionPlan"`
- `flutter test test/features/action_plans`
- `flutter test test/sync_engine_test.dart`

## Verification Plan
1. Write the backend integration tests first and verify RED on the stale `closed -> pending_verify` path.
2. Implement the server guard plus machine-readable `ProblemDetails` and verify GREEN on the backend slice.
3. Add the Flutter adapter classification test and sync-engine dequeue test, then verify RED.
4. Implement typed stale-state handling in the adapter and sync engine, then verify GREEN.
5. Run the focused backend and Flutter commands again to prove no regression on the allowed path.

## Proposed Changes
- [MOD] [server/Features/ActionPlans/UpdateActionPlan.cs](C:/Users/HP/Documents/GitHub/Checkly/server/Features/ActionPlans/UpdateActionPlan.cs)
  Structural blueprint: before mutating fields, detect `oldStatus == "closed"` with `request.Status == "pending_verify"`, return `TypedResults.Problem(...)` with `statusCode: 409`, stable `type`, and extension `code = "action_plan_already_closed"`, then write a rejected-attempt audit log entry.
- [NEW] [server/tests/Checkly.Api.Tests/Features/ActionPlans/UpdateActionPlan_StaleStateConflict_Tests.cs](C:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/ActionPlans/UpdateActionPlan_StaleStateConflict_Tests.cs)
  Structural blueprint: dedicated integration tests for stale-state rejection, unchanged persisted status, audit-log creation, and allowed-path regression coverage.
- [MOD] [lib/features/action_plans/manager/action_plan_manager.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/manager/action_plan_manager.dart)
  Structural blueprint: add a typed `ActionPlanAlreadyClosedException` near the existing action-plan exception family so adapter and sync engine share a narrow domain contract.
- [MOD] [lib/_shared/services/service_adapters.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/service_adapters.dart)
  Structural blueprint: catch `DioException`, inspect `response.statusCode == 409` plus parsed `ProblemDetails` code, throw `ActionPlanAlreadyClosedException` for the exact stale-state case, otherwise rethrow the original transport error.
- [MOD] [lib/_shared/services/sync_engine.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/sync_engine.dart)
  Structural blueprint: in the action-plan drain phase, catch `ActionPlanAlreadyClosedException`, remove the row, continue the batch, and reserve `markExhausted(...)` for true unexpected failures.
- [NEW] [test/features/action_plans/sync_engine_action_plan_stale_state_test.dart](C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/sync_engine_action_plan_stale_state_test.dart)
  Structural blueprint: focused Flutter test file covering typed adapter classification and sync-engine dequeue-on-stale behavior without editing the broad generic sync test file.

## Risk Assessment
1. Contract drift risk: if the backend returns a 409 without a stable `code`, the mobile side will fall back to opaque transport errors and the queue will still exhaust. Mitigation: make the stable `code` part of the backend test contract and adapter test contract.
2. Over-blocking risk: a poorly placed guard could reject legitimate field-only updates or normal `open -> pending_verify` transitions. Mitigation: keep the predicate exact to `oldStatus == "closed"` and `request.Status == "pending_verify"`, and retain a success-path regression test.
3. Queue starvation risk: a handled stale-state conflict must not abort the rest of the batch. Mitigation: use `continue`, not `return`, after removing the stale row; this follows the local SyncEngine gotcha.
4. Audit semantics risk: reusing `action_plan_updated` for a rejected attempt muddies forensics. Mitigation: use a distinct audit action such as `action_plan_update_rejected` or an explicit rejection message and verify it in the backend test.

## Concept Diagram
`[Offline store manager queue] -> [SyncEngine drain] -> [ActionPlanApiAdapter] -> [PUT /api/action-plans/{id}] -> [terminal-state guard] -> [409 ProblemDetails code=action_plan_already_closed] -> [typed Flutter exception] -> [dequeue stale row and continue batch]`

## Execution Slices
### Slice 1 - Backend Source-of-Truth Guard [BLOCKING]
Scope
- [server/Features/ActionPlans/UpdateActionPlan.cs](C:/Users/HP/Documents/GitHub/Checkly/server/Features/ActionPlans/UpdateActionPlan.cs)
- [server/tests/Checkly.Api.Tests/Features/ActionPlans/UpdateActionPlan_StaleStateConflict_Tests.cs](C:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/ActionPlans/UpdateActionPlan_StaleStateConflict_Tests.cs)

Structural blueprint
- Add a pre-mutation stale-state predicate based on persisted `oldStatus`.
- Return `409 ProblemDetails` with stable `code`.
- Add a dedicated rejected-attempt audit log entry.
- Prove the normal success path still works.

Trade-offs / Pros & Cons
- Pros: fixes the real integrity hole at the source of truth; no schema migration; preserves existing PATCH model.
- Cons: rejected offline evidence is dropped rather than preserved for user recovery.
- Rejected alternative: generic optimistic concurrency with `RowVersion/xmin`.
  Why rejected now: larger blast radius across DTOs, DB config, outbox, and UX without evidence of real collaborative editing requirements.

### Slice 2 - Mobile Classification and Safe Drain [BLOCKING]
Scope
- [lib/features/action_plans/manager/action_plan_manager.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/features/action_plans/manager/action_plan_manager.dart)
- [lib/_shared/services/service_adapters.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/service_adapters.dart)
- [lib/_shared/services/sync_engine.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/sync_engine.dart)
- [test/features/action_plans/sync_engine_action_plan_stale_state_test.dart](C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/sync_engine_action_plan_stale_state_test.dart)

Structural blueprint
- Define a typed stale-state exception in the action-plan domain boundary.
- Parse the backend `ProblemDetails` response in the `Dio` adapter.
- Dequeue and continue on the typed stale-state exception in SyncEngine.
- Keep all other action-plan failures exhausted/error as they are today.

Trade-offs / Pros & Cons
- Pros: narrow mobile change; no queue schema change; mirrors existing repo precedent for typed 409 handling.
- Cons: depends on a stable backend response contract; adds one more custom exception type to maintain.
- Rejected alternative: string-match `e.toString().contains("409")` in SyncEngine.
  Why rejected now: too brittle for a compliance-sensitive path and impossible to reason about reliably across transport changes.

### Slice 3 - Optional Recovery UX [PARALLEL, OUT OF SCOPE]
Scope
- No file work in this plan.

Structural blueprint
- If product later wants recovery of rejected offline notes, design a separate local failed-mutation surface and message pattern.

Trade-offs / Pros & Cons
- Pros: preserves user-authored offline text.
- Cons: expands user flows, persistence rules, and copy requirements; changes the semantics of "closed" workflows if done carelessly.
- Current decision: defer.

## Handoff Block
AI Agent Mission Brief
- Treat this as a terminal-state integrity fix, not a generalized conflict-resolution project.
- Backend must reject `closed -> pending_verify` before any mutation is applied.
- Mobile must dequeue this exact stale-state conflict instead of exhausting the row.
- Do not add schema tokens, merge UX, or silent partial acceptance.

Routing commands
- Run these one at a time. Finish each slice before starting the next.
- Slice 1 [BLOCKING]:
  `@[/tdd] Execute tests for Slice 1: C:\Users\HP\Documents\GitHub\Checkly\brain\20260425_synthesize_offline_conflict\implementation_plan_offline_conflict_20260425_synthesize_offline_conflict.md`
- Slice 2 [BLOCKING]:
  `@[/tdd] Execute tests for Slice 2: C:\Users\HP\Documents\GitHub\Checkly\brain\20260425_synthesize_offline_conflict\implementation_plan_offline_conflict_20260425_synthesize_offline_conflict.md`
- Slice 3 [PARALLEL, OPTIONAL, DO NOT START WITHOUT PRODUCT APPROVAL]:
  `@[/analyze-epic] Execute specs for Slice 3: C:\Users\HP\Documents\GitHub\Checkly\brain\20260425_synthesize_offline_conflict\implementation_plan_offline_conflict_20260425_synthesize_offline_conflict.md`

Decision required before implementation
- Approve or reject the product trade-off that stale offline evidence against a closed plan will be rejected and discarded from the queue without local recovery UX in this slice.

Plan ready for Builder to execute.

<forensic_evidence>
[x] grep_search via `rg -n "UpdateActionPlan|PendingActionPlanUpdates|ActionPlanApi|SyncEngine|pending_verify|closed|AuditLogger|ProblemDetails|RowVersion|xmin"` across `server`, `lib`, `test`, and the session `brain/` folder
[x] view_file via `Get-Content` on `server/Features/ActionPlans/UpdateActionPlan.cs`
[x] view_file via `Get-Content` on `server/Features/ActionPlans/ActionPlanEndpoints.cs`
[x] view_file via `Get-Content` on `server/Features/ActionPlans/Dtos.cs`
[x] view_file via `Get-Content` on `server/Common/Persistence/Entities/ActionPlan.cs`
[x] view_file via `Get-Content` on `server/Common/Persistence/Configurations/ActionPlanConfiguration.cs`
[x] view_file via `Get-Content` on `server/Common/Services/AuditLogger.cs`
[x] view_file via `Get-Content` on `lib/features/action_plans/manager/action_plan_manager.dart`
[x] view_file via `Get-Content` on `lib/_shared/services/service_adapters.dart`
[x] view_file via `Get-Content` on `lib/_shared/services/sync_engine.dart`
[x] view_file via `Get-Content` on `lib/_shared/database/dao/action_plan_outbox_dao.dart` and `lib/_shared/database/tables.dart`
[x] view_file via `Get-Content` on `lib/locator.dart`, `server/Checkly.Api.csproj`, and `pubspec.yaml`
[x] view_file via `Get-Content` on `server/tests/Checkly.Api.Tests/Features/ActionPlans/UpdateActionPlan_AuditTrail_Tests.cs`, `server/tests/Checkly.Api.Tests/SubmissionActionPlanTests.cs`, `test/features/action_plans/manager/action_plan_manager_test.dart`, `test/sync_engine_test.dart`, and `test/features/global_risks/sync_engine_global_risks_test.dart`
</forensic_evidence>
