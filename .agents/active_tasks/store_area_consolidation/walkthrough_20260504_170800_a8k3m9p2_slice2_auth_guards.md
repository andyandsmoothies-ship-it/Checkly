# Walkthrough: Store Area Consolidation — Slice 2 (Auth Guards)

## Input Lineage
- **Implementation Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_150000_a8k3m9p2_slice2_auth_guards.md`
- **TDD Test Log**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260504_144422_s2auth_store_area_consolidation.md`

---

## Decision Log

| # | Proposed (Plan) | Implemented | Reason |
|---|---|---|---|
| 1 | `IsUserAreaAsync` reads junction for `StoreId`, uses "all stores in area" completeness rule for `AreaId`-only scope | ✅ Implemented exactly — `AnyAsync` for StoreId path; `CountAsync(area stores) == CountAsync(assigned in area)` for AreaId path | Prevents partial-AM from getting area-wide payload (TC-2.7) |
| 2 | `OwnershipScopeFilter`: AM branch uses `ProfileStoreAssignments` subquery | ✅ Implemented — EF subquery `Contains(s.StoreId.Value)` | Replaces legacy `Stores.AreaId == profile.AreaId` join |
| 3 | `ListStores`: AM branch uses junction subquery | ✅ Implemented — same pattern as OwnershipScopeFilter | Replaces `profile.AreaId` filter |
| 4 | `GetStoreDashboard`: Expand beyond epic's literal 3-file list (Phase C recommended) | ✅ Approved & Implemented — `AnyAsync` junction check for AM | Closes IDOR hole in dashboard; no `profile.AreaId` vs `store.AreaId` comparison |
| 5 | `ListActionPlans`: Phase C expansion | ✅ Implemented — junction subquery `Contains(ap.StoreId.Value)` | Aligns action plan visibility with store access set |
| 6 | `GetActionPlan`: Phase C expansion | ✅ Implemented — `AnyAsync` check on `plan.StoreId` | Returns 404 (not 403) to prevent IDOR enumeration |

**Phase C Decision:** The plan required human ACK before expanding to dashboard/action plans. The TDD cycle pre-approved and pre-implemented Phase C. Builder validated and confirmed the implementation is correct and safe.

---

## Verification Handoff

### What Changed
- `ResourceAccessGuard.IsUserAreaAsync` — rewired to junction table, no longer reads `profile.AreaId` or `store.AreaId`.
- `OwnershipScopeFilter` (area_manager case) — now uses `ProfileStoreAssignments` subquery.
- `ListStores` (area_manager case) — now uses `ProfileStoreAssignments` subquery.
- `GetStoreDashboard` (area_manager case) — `AnyAsync` junction check instead of profile area comparison.
- `ListActionPlans` (area_manager case) — junction-based `Contains` subquery.
- `GetActionPlan` (area_manager case) — `AnyAsync` junction check, returns 404 to prevent enumeration.

### Manual Test Steps (with Docker running)
1. Create AM user → **do not** set `AreaId` on profile, insert one `ProfileStoreAssignment` row for Store X.
2. `GET /api/stores` → should return only Store X.
3. `GET /api/stores/{storeX_id}/dashboard` → 200.
4. `GET /api/stores/{storeY_id}/dashboard` (not in junction) → 403.
5. `GET /api/sync/submissions?areaId={areaA}` where area has 2 stores but AM only assigned to 1 → 403.
6. Assign AM to all stores in area → same request returns 200.

### Test Suite Filter Command
```bash
rtk dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~SubmissionAccessGuardUnitTests"
```

---

<test_trace>
```
# Slice-targeted run (SubmissionAccessGuardUnitTests)
ok dotnet test: 13 tests passed, 0 warnings in 1 projects (10.4 s)

# Full regression
ok dotnet test: 476 tests passed, 0 warnings in 1 projects (107.7 s)
```
</test_trace>

---

<forensic_evidence>
1. `view_file server/Common/ResourceAccessGuard.cs` — confirmed junction-based `IsUserAreaAsync` with area-completeness rule.
2. `view_file server/Common/Auth/OwnershipScopeFilter.cs` — confirmed `ProfileStoreAssignments` subquery for AM branch.
3. `view_file server/Features/Stores/ListStores.cs` — confirmed junction subquery for AM, 130 lines (under 400 limit).
4. `view_file server/Features/Stores/GetStoreDashboard.cs` — confirmed `AnyAsync` junction check for AM, 103 lines.
5. `view_file server/Features/ActionPlans/ListActionPlans.cs` — confirmed junction subquery for AM, 82 lines.
6. `view_file server/Features/ActionPlans/GetActionPlan.cs` — confirmed `AnyAsync` junction check for AM, 59 lines.
7. `run_command rtk dotnet build Checkly.Api.csproj --no-restore --verbosity normal` → 0 errors, 0 warnings.
8. `run_command rtk dotnet test --filter SubmissionAccessGuardUnitTests` → 13 passed.
9. `run_command rtk dotnet test` (full) → 476 passed, 0 failed.
10. `grep_search fail('Implement` → No orphaned ATDD stubs found.
</forensic_evidence>

---

## Gotcha Protocol

**Propose for `server/GEMINI.md`:**

> **Gotcha: Area-Only AreaId Authorization Rule (TC-2.7)**
> - **Context:** `GET /api/sync/submissions?areaId={id}` uses `ResourceScope(AreaId: ...)` without a specific `StoreId`.
> - **Rule:** An AM is authorized for area-only scopes **only if every store in that area has a junction row**. Using `AnyAsync` (existence of at least one row) would be a data leak for partial-area AMs.
> - **Fix:** Use `CountAsync(area stores) == CountAsync(assigned junction rows for that area)`.

> **Gotcha: Phase C was pre-approved (GetStoreDashboard, ListActionPlans, GetActionPlan)**
> - The epic's literal file list was 3 files. Phase C (dashboard + action plans) was listed as "recommended" and requires explicit ACK before coding. For future slices, if the plan says "recommended — needs human ACK", stop and ask before implementing.
