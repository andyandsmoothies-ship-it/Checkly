# Walkthrough: SL-4 — Purge areaId Fallback from ResourceAccessGuard & SyncSubmissions

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260520_071500_f4b03545_sl4_pbac_purge.md`
- **TDD Test Evidence (RED)**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260520_071708_a8c2d9f4_tdd_sl4_pbac_purge.md`
- **Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\area_deprecation\task_20260520_072800_f4b03545_sl4_pbac_purge.md`

## Decision Log

| Decision Point | Proposed | Implemented | Rationale |
|---|---|---|---|
| `IsUserAreaAsync` signature | Remove `areaId` param entirely | ✅ Done | Only storeId is needed for junction check |
| `CanAccessAsync` caller | Pass `scope.StoreId` only | ✅ Done | `scope.AreaId` no longer consulted |
| `CanDelegateAsync` caller | Pass `scope.StoreId` only | ✅ Done | Same purge |
| `ResourceScope.AreaId` field | Considered removing | NOT removed | Other code may read it; scope is minimal-impact |
| Rule 1 scope guard | area_manager gets unbounded sync | ✅ Done | Removed `areaId = profile.AreaId` fallback |
| Rule 2 IDOR guard | Only run if `storeId.HasValue` | ✅ Done | area_manager unbounded sync bypasses IDOR |
| Query filter (unbounded AM) | Junction table fetch | ✅ Done | `ProfileStoreAssignments` WHERE ProfileId = amUserId |
| `areaId` param on HandleAsync | Keep in signature | ✅ Kept | Prevents API contract break; internally unused now |

## Files Modified

| File | Change |
|---|---|
| `server/Common/ResourceAccessGuard.cs` | `IsUserAreaAsync` — removed `areaId` param and the 16-line areaId fallback block |
| `server/Features/Submissions/SyncSubmissions.cs` | Rule 1, Rule 2, and query filter all purged of areaId logic |

## Verification Handoff

Steps for QA to verify:
1. Run `rtk dotnet build server/Checkly.Api.csproj` — expect 0 errors, 0 warnings.
2. Run `rtk dotnet test --filter SyncSubmissionsEndpointTests` — expect all 12 GREEN.
3. Run `rtk dotnet test --filter SubmissionAccessGuardUnitTests` — expect all 15 GREEN.
4. Manual: create an area_manager with a junction row and call `GET /api/sync/submissions` (no storeId, no areaId) — expect 200 with only assigned-store submissions.
5. Manual: call `GET /api/sync/submissions?storeId={unassigned}` as area_manager — expect 403.

<test_trace>
=== SyncSubmissionsEndpointTests ===
Command: rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter SyncSubmissionsEndpointTests
Result: ok dotnet test: 12 tests passed, 0 warnings in 1 projects (6.8 s)

=== SubmissionAccessGuardUnitTests ===
Command: rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter SubmissionAccessGuardUnitTests
Result: ok dotnet test: 15 tests passed, 0 warnings in 1 projects (5.1 s)
</test_trace>

<forensic_evidence>
Build verify:
  Command: rtk dotnet build server/Checkly.Api.csproj --no-incremental
  Result: ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:10.28)

areaId reference check (ResourceAccessGuard.cs):
  grep_search query: "areaId" in server/Common/ResourceAccessGuard.cs
  Result: No results found ✅

areaId reference check (SyncSubmissions.cs):
  grep_search query: "areaId" in server/Features/Submissions/SyncSubmissions.cs
  Result: No results found ✅
</forensic_evidence>

## Gotcha Protocol

No new gotchas discovered. Existing GEMINI.md gotcha confirmed:
> "Strict 1-to-M Store Assignment Unique Constraint — `ProfileStoreAssignment` places a unique index on `StoreId`. Do not write test cases assuming multiple profiles can share a store."

This slice correctly scopes area_manager sync by listing ALL their assigned stores, not by filtering on a single store — consistent with this constraint.
