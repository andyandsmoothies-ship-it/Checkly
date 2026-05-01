<latent_space_scratchpad>
- The code proves two separate facts: the server query is unbounded, and the mobile sync adapter assumes one full-list response. Fixing only the server with pagination would break sync; fixing only the server with `Take(100)` would silently drop valid assignments once a store crosses the cap.
- The safest shape is backend pagination plus client-side page aggregation inside `service_adapters.dart`, while preserving `SyncApi.pullProgramAssignments(): Future<List<dynamic>>` so `SyncEngine`, Drift cache, and UI code stay unchanged.
- Do not invent status filtering in this slice. The repo does not prove that `submitted` or `verified` rows are safe to suppress from the sync payload, and full-replace cache semantics make that a product decision, not a technical guess.
- Use deterministic ordering for pagination: `Deadline ASC`, then `Assignment.Id ASC`. `Deadline` alone is unstable when multiple assignments share the same timestamp.
</latent_space_scratchpad>

## Input Lineage
- `C:\Users\HP\.gemini\antigravity\brain\371654b0-a620-4bc8-bb54-83d89ab07e62\audit_infra_report_20260501_122611_371654b0-a620-4bc8-bb54-83d89ab07e62_programs_backend.md.resolved`

## Executive Summary & Out of Scope
Track: B2.

Goal: remove the unbounded `GetMyAssignments` materialization in `server/Features/Programs/GetMyAssignments.cs` without breaking the existing offline full-replace sync path used by store managers.

Recommended shape:
- Convert `GET /api/programs/assignments/my` to the project-standard paged envelope `PagedResult<AssignmentSummaryDto>`.
- Keep the mobile abstraction stable by making `lib/_shared/services/service_adapters.dart` fetch all pages and still return one aggregated `List<dynamic>` to `SyncEngine`.
- Leave the cache, DAO, and UI contracts unchanged in this slice.

Why this is the winning shape:
- It bounds server memory and response size.
- It avoids the silent correctness failure of a hard `Take(100)` cap.
- It aligns the endpoint with `server/GEMINI.md`, which requires list endpoints to use `PagedResult<T>`.
- It limits the mobile blast radius to the shared sync adapter rather than the whole offline stack.

Out of scope:
- No status filtering such as “recent only” or “active only”.
- No database migration or new index in this slice.
- No changes to `SyncEngine`, Drift tables, or DAO full-replace behavior unless the adapter abstraction proves insufficient during implementation.
- No new public endpoint; reuse `GET /api/programs/assignments/my`.
- No UI work on Flutter pages or widgets.

## Logs & Audits
- No `AuditLogger` change is required. `GetMyAssignments` is a read-only endpoint and should remain side-effect free.
- Existing ASP.NET request logs are sufficient to observe page count, latency, and status code behavior.
- No database audit trail change is planned for this issue.

## 4-State Matrix
| State | System Condition | Expected Behavior |
|---|---|---|
| Success | Store manager has one or more assignments and backend paging succeeds | Backend returns `200 PagedResult<AssignmentSummaryDto>`; mobile adapter aggregates all pages and returns a full in-memory list to the existing sync drain. |
| Error | Auth failure, network failure, or later page request fails | Backend returns `401/403` as today, or adapter rethrows transport failure so existing sync error behavior remains intact. |
| Empty | `Profile.StoreId` is null or the store has zero assignments | Backend returns `200` with `items: []`, `total: 0`, `page`, `pageSize`; mobile adapter returns an empty list and cache full-replace clears stale rows. |
| Loading | Sync engine is pulling assignment pages during reconnect | Adapter requests page `1..N`, aggregates results, then hands one full list to the unchanged cache replacement flow. |

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| BE-GMA-BOUND-01 | `GetMyAssignments_WhenStoreHas201Assignments_DefaultRequest_ReturnsFirst50ItemsAndTotal201` | Success | Current handler calls `ToListAsync()` directly and returns all rows in one envelope with no `total`, `page`, or `pageSize`. |
| BE-GMA-BOUND-02 | `GetMyAssignments_WhenPageSizeExceeds200_ClampsTo200` | Success | Current handler does not parse `pageSize` at all. |
| BE-GMA-BOUND-03 | `GetMyAssignments_WhenRequestedPageOverflows_ReturnsEmptyItemsWithTotal` | Empty | Current handler has no overflow guard and no paging contract. |
| BE-GMA-BOUND-04 | `GetMyAssignments_WhenProfileHasNoStore_ReturnsEmptyPagedResult` | Empty | Current handler returns `AssignmentsListResponse([])` instead of the standard paged envelope. |
| FE-GMA-BOUND-01 | `PullProgramAssignments_WhenBackendReturnsMultiplePages_AggregatesAllItemsIntoSingleList` | Success | Current adapter issues exactly one GET and assumes the backend returns a full list. |
| FE-GMA-BOUND-02 | `PullProgramAssignments_WhenLaterPageFails_RethrowsAndDoesNotInventPartialSuccess` | Error | Current adapter has no pagination loop, so it cannot prove safe failure semantics across pages. |

## Test Fixture & Payloads
Backend fixture requirements:
- Authenticated `store_manager` client with `programs:assignments_my` capability already seeded by `TestWebApplicationFactory`.
- `Profile.StoreId` linked to one store.
- One seeded `ChecklyProgram`.
- At least `201` `ProgramAssignment` rows for the linked store to force multi-page behavior.
- Deterministic deadlines with at least some duplicate deadlines, so the implementation must use a stable secondary sort key.

Backend request example:
```http
GET /api/programs/assignments/my?page=1&pageSize=50
Authorization: Bearer <store_manager_jwt>
```

Backend response example:
```json
{
  "items": [
    {
      "id": "9a5e2eb7-1a8b-4f95-94b3-4b2fbbff41d6",
      "programId": "e20d31c5-cfd4-4d97-93da-c4d4c6db39ea",
      "programTitle": "May Compliance Program",
      "category": "Testing",
      "deadline": "2026-05-10T00:00:00Z",
      "status": "pending",
      "createdAt": "2026-05-01T06:00:00Z"
    }
  ],
  "total": 201,
  "page": 1,
  "pageSize": 50
}
```

Overflow response example:
```json
{
  "items": [],
  "total": 201,
  "page": 999,
  "pageSize": 50
}
```

Mobile adapter fixture requirements:
- Mocked `Dio` client returning paged envelopes from `/programs/assignments/my`.
- Page 1 returns `50` rows, page 2 returns `50`, final page returns the remainder.
- No `SyncEngine` or Drift DB mutation is required for the adapter slice if the public return type stays `List<dynamic>`.

## Risk Assessment
| Risk | Severity | Mitigation |
|---|---|---|
| Silent truncation if Builder chooses backend-only `Take(100)` | High | Keep the recommended path as backend paging plus adapter aggregation; require explicit user approval for the hotfix alternative. |
| Duplicate or skipped rows across pages if sort order is unstable | High | Use `OrderBy(Deadline).ThenBy(Id)` and cover duplicate-deadline fixtures in backend tests. |
| Mobile sync breakage if the adapter does not hide the new paged envelope | High | Preserve `SyncApi.pullProgramAssignments(): Future<List<dynamic>>` and test multi-page aggregation at the adapter boundary. |
| Shared test file collision by editing `Program_Slice2A_Tests.cs` | Medium | Add a new dedicated test file under `Features/Programs` instead of modifying the 293-line legacy file. |

## Verification Plan
1. Write the backend paging tests first and confirm RED against the current unbounded handler.
2. Implement Slice 1 and run:
   - Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
   - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~GetMyAssignments"`
3. Write the adapter aggregation tests and confirm RED with the current single-request implementation.
4. Implement Slice 2 and run:
   - Workdir `C:\Users\HP\Documents\GitHub\Checkly`
   - `rtk flutter test test/_shared/services/program_assignments_sync_api_test.dart`
5. Run the existing program execution regression slice to confirm the original `items` contract still behaves:
   - Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
   - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~Program_Slice2A"`

## Tools & Commands
Builder skills:
- `backend-architect`
- `ef-core`
- `testing-strategy`
- `mobile-offline-support`

Verification commands:
- Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
  - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~GetMyAssignments"`
- Workdir `C:\Users\HP\Documents\GitHub\Checkly`
  - `rtk flutter test test/_shared/services/program_assignments_sync_api_test.dart`

Optional regression command after both slices:
- Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
  - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~Program_Slice2A"`

## Proposed Changes
| Status | File Path | Change |
|---|---|---|
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\Features\Programs\GetMyAssignments.cs` | Replace the unbounded raw list query with project-standard pagination, overflow guard, and deterministic ordering; return `PagedResult<AssignmentSummaryDto>` instead of the custom list envelope. |
| `[NEW]` | `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Programs\GetMyAssignments_Pagination_Tests.cs` | Dedicated integration tests for page size defaults, max clamp, overflow guard, and empty-store behavior without enlarging `Program_Slice2A_Tests.cs` past its current 293-line footprint. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\services\service_adapters.dart` | Page through the new backend envelope internally and aggregate all `items` into one `List<dynamic>` so the sync engine contract stays stable. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\services\sync_api.dart` | Update the method comment for `pullProgramAssignments()` to document that it still returns a full aggregated list even though the backend is paginated. |
| `[NEW]` | `C:\Users\HP\Documents\GitHub\Checkly\test\_shared\services\program_assignments_sync_api_test.dart` | Focused Dart tests for multi-page aggregation and page-failure behavior in the shared adapter layer. |

## Concept Diagram
```text
[Store Manager Sync]
  -> [service_adapters.pullProgramAssignments()]
  -> [GET /api/programs/assignments/my?page=1&pageSize=50]
  -> [PagedResult<AssignmentSummaryDto>]
  -> [GET page 2..N until accumulated >= total]
  -> [aggregate all items in adapter]
  -> [SyncEngine full-replace cache write]
```

## Execution Slices
### Slice 1 - Backend Paging Contract [BLOCKING]
Complexity: Medium. Reason: network + auth + database query contract change on a live offline sync endpoint.

Structural blueprint:
- Modify `GetMyAssignments.HandleAsync` to accept `HttpContext`.
- Parse `page` default `1` and `pageSize` default `50`, max `200`, matching `server/GEMINI.md`.
- Compute `total` before materializing rows.
- Add overflow guard: if `skip >= total`, return empty `PagedResult<AssignmentSummaryDto>`.
- Keep the existing store scoping rule from `Profile.StoreId`.
- Use deterministic order: `Program.Deadline ASC`, then `Assignment.Id ASC`.
- Preserve the current overdue projection logic exactly.
- Remove the nested `AssignmentsListResponse` record if `PagedResult<T>` replaces it.
- Add a new dedicated integration test file instead of editing the 293-line `Program_Slice2A_Tests.cs`.

Pros & Cons:
- Pros: eliminates the unbounded server materialization; aligns with list endpoint standard; preserves response `items` property so old happy-path tests still make sense.
- Cons: changes the wire contract by adding `total/page/pageSize` and therefore requires a client-side companion update.
- Rejected alternative: server-only `Take(100)` hotfix.
  Why rejected as default: fastest patch, but it silently truncates a full-replace sync feed and creates correctness drift once a store legitimately exceeds the cap.

### Slice 2 - Mobile Page Aggregation Behind Stable Sync API [BLOCKING]
Complexity: Low. Reason: bounded client loop in one adapter plus focused tests; no DB or UI shape change if the abstraction is preserved.

Structural blueprint:
- Keep `SyncApi.pullProgramAssignments()` returning `Future<List<dynamic>>`.
- In `service_adapters.dart`, request page 1, read `items/total/page/pageSize`, and continue until the adapter has collected `total` rows or the backend returns no more items.
- Re-throw later page failures so existing sync error handling stays honest.
- Do not change `sync_engine_drains.dart`, `ProgramOutboxDao`, or Drift tables if the adapter fully hides pagination.
- Add a small Dart test file for successful aggregation and failure-on-later-page behavior.

Pros & Cons:
- Pros: preserves the existing offline full-replace sync contract; avoids touching shared cache/write logic; keeps blast radius under 2 files of production code.
- Cons: adds one more loop at the client boundary and slightly increases adapter complexity.
- Rejected alternative: push pagination awareness into `SyncEngine`.
  Why rejected now: unnecessary blast radius; the adapter is the correct boundary for transport-shape translation.

### Slice 3 - Decision Gate Before Build
Complexity: Low. Reason: this is a product/architecture trade-off, not a coding problem.

Decision the user must approve before Builder starts:
- Recommended: implement Slice 1 + Slice 2 together.
- Fallback hotfix: apply a backend-only `Take(100)` cap if the user explicitly accepts silent truncation risk for stores with more than 100 assignments.

Pros & Cons:
- Pros of recommended path: safe, standards-aligned, no silent data loss.
- Cons of recommended path: spans backend and mobile shared service layers.
- Pros of fallback hotfix: one-file patch, fastest production containment.
- Cons of fallback hotfix: violates sync correctness under growth and does not actually solve the contract mismatch.

## Strict Implementation Constraints & Human Reminders
- Treat this endpoint as an offline sync feed, not a normal screen list. Correctness matters more than the smallest diff.
- Do not invent status filters, archival windows, or “recent assignments only” behavior without an explicit product rule.
- Preserve `items` in the response JSON; add `total/page/pageSize` via `PagedResult<T>`.
- Keep `SyncApi.pullProgramAssignments()` stable so `SyncEngine` and Drift cache logic do not need a concurrent refactor.
- Do not expand `Program_Slice2A_Tests.cs`; use a new dedicated test file per the repo’s test slicing rules.
- Respect the existing server-wins sync model: backend defines the authoritative page boundaries, client only aggregates.

<command_logs>
- `Get-Content -Raw .agents/persona/scout_persona.md`
- `Get-Content -Raw .agents/workflows/analyze-feature.md`
- `Get-Content -Raw C:\Users\HP\.gemini\antigravity\brain\371654b0-a620-4bc8-bb54-83d89ab07e62\audit_infra_report_20260501_122611_371654b0-a620-4bc8-bb54-83d89ab07e62_programs_backend.md.resolved`
- `Get-Content -Raw .agents/rules/orchestration-standards.md`
- `Get-Content -Raw GEMINI.md`
- `Get-Content -Raw server\GEMINI.md`
- `Get-Content -Raw server\tests\GEMINI.md`
- `Get-Content -Raw lib\GEMINI.md`
- `Get-Content -Raw lib\_shared\GEMINI.md`
- `Get-Content -Raw lib\_shared\services\GEMINI.md`
- `Get-Content -Raw .agents/skills/backend-architect/SKILL.md`
- `Get-Content -Raw .agents/skills/ef-core/SKILL.md`
- `Get-Content -Raw .agents/skills/testing-strategy/SKILL.md`
- `Get-Content -Raw .agents/skills/mobile-offline-support/SKILL.md`
- `rg -n "GetMyAssignments|ListPrograms|ProgramAssignments|assignments/my|CachedProgramAssignments|ProgramApiService" ...`
- `Get-Content server\Features\Programs\GetMyAssignments.cs`
- `Get-Content server\Features\Programs\ListPrograms.cs`
- `Get-Content server\Features\Programs\ProgramDtos.cs`
- `Get-Content server\Features\Programs\ProgramEndpoints.cs`
- `Get-Content server\Common\Persistence\AppDbContext.cs`
- `Get-Content server\Common\Persistence\Entities\ProgramAssignment.cs`
- `Get-Content server\Common\PagedResult.cs`
- `Get-Content server\tests\Checkly.Api.Tests\Program_Slice2A_Tests.cs`
- `Get-Content server\tests\Checkly.Api.Tests\TestWebApplicationFactory.cs`
- `Get-Content lib\_shared\services\sync_api.dart`
- `Get-Content lib\_shared\services\service_adapters.dart`
- `Get-Content lib\_shared\services\sync_engine_drains.dart`
- `Get-Content lib\_shared\database\tables.dart`
- `Get-Content lib\_shared\database\dao\program_outbox_dao.dart`
</command_logs>

## Handoff Block
Mission summary:
- Fix the `GetMyAssignments` scalability bug without breaking the offline assignment sync contract.
- Recommended implementation is backend pagination plus adapter-side aggregation, not silent server truncation.
- Keep DAO, cache, and UI layers out of scope unless implementation evidence proves otherwise.

Run these one at a time:

Slice 1:
`@[/atdd] Execute specs for Slice 1: C:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_135901_371654b0_getmyassignments_unbounded_query.md`

Slice 2:
`@[/tdd] Execute tests for Slice 2: C:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_135901_371654b0_getmyassignments_unbounded_query.md`

Concurrency:
- Slice 2 must wait for Slice 1 to lock the backend paging contract.
- Do not run both slices in the same prompt cycle.

Decision required before implementation:
- Approve the recommended end-to-end paging shape, or explicitly accept the backend-only `Take(100)` hotfix and its silent truncation risk.

Plan ready for Builder to execute.
