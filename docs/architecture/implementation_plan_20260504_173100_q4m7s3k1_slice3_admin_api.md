<latent_space_scratchpad>
Slice 3 must remove S10 "one area manager per area" and introduce virtual-area fan-out into ProfileStoreAssignments on admin user update. Current code still enforces S10 in UpdateUser/CreateUser via RoleAssignmentGuard.FindExistingAreaManager and returns 409 on occupied area. That conflicts with epic target.

Request-shape decision: keep backward compatibility for existing Flutter (`areaId`) while adding explicit `virtualAreaId` + `assignedStoreIds`. For update endpoint, safest logic is:
1) if role != area_manager -> clear any area-manager-only assignment intents;
2) if virtualAreaId provided -> resolve store ids by area and union with assignedStoreIds;
3) apply idempotent upsert semantics (composite PK avoids dupes);
4) for area_manager with explicit empty assignedStoreIds and no virtualAreaId, allow clearing all assignments intentionally.

Critical mismatch discovered: user creation endpoint also enforces S10 today. If Slice 3 only edits UpdateUser, admin can still be blocked creating AM in occupied area. This should be either included in this slice or explicitly deferred with risk warning.

Because Slice 2 is already implemented, AM auth paths read ProfileStoreAssignments; therefore missing assignment writes in admin API now causes lockout/empty scope for AMs. This raises priority of robust write semantics and tests.
</latent_space_scratchpad>

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\analysis_epic_20260503_215500_2b21e338_area_override.md` (Slice 3)

## Executive Summary & Out of Scope
Implement Slice 3 by changing Admin user-assignment API from area-FK ownership to direct store-assignment ownership:
- Remove S10 enforcement from update flow.
- Add virtual-area assignment contract (area shortcut expands to concrete store IDs).
- Persist AM store access in `profile_store_assignments` with idempotent upsert semantics.

Out of scope:
- Profile sync payload (`assignedStoreIds`) and Flutter local persistence schema changes (Slice 4).
- Admin UI redesign for area-as-shortcut messaging (Slice 5).
- Deleting `Profile.AreaId` column or historical area reporting paths.
- Bulk migration changes (already in Slice 1).

## Risk Assessment
> **Risk Warning:** Slice 2 auth already depends on `ProfileStoreAssignments`. If Slice 3 write paths are incomplete, newly edited AMs can lose access immediately.

| Risk | Severity | Mitigation |
|---|---|---|
| `UpdateUser` changed but `CreateUser` still enforces S10 | High | Include `CreateUser` parity in this slice or document as immediate follow-up micro-step with tests. |
| Partial payload ambiguity (`areaId` vs `virtualAreaId` vs `assignedStoreIds`) | High | Define deterministic precedence and explicit validation errors in request contract tests. |
| Duplicate assignment inserts | Medium | Use set-union in memory + PK-safe insert guard (`Any`/`Contains`) before add. |
| Clearing assignments unintentionally on role change | Medium | Gate clears behind explicit AM role transitions and covered boundary tests. |

## System Context
- **Environment:** Live API (ASP.NET Core Minimal API), EF Core/PostgreSQL.
- **RBAC Gate:** Endpoint remains `UsersManage` capability at `/api/admin/users/{id}`.
- **Auth Dependency:** AM runtime access now derives from `profile_store_assignments`; admin write flow is authoritative source.
- **Logging:** Reuse existing `SystemLog` write in update flow; adjust message to reflect virtual assignment path.

## Lifecycle Context
| State | Admin Edit User behavior |
|---|---|
| Success | 200 with updated role/store/area + assignment summary fields; AM can access assigned stores immediately. |
| Error | 400 for invalid role/store/area/payload conflicts; 404 for missing user/profile/role; 403 non-admin. |
| Empty | `virtualAreaId` maps to zero stores -> valid no-op or explicit warning field (decision in execution slice). |
| Loading | Existing UI spinner/submit states unchanged; API remains synchronous request-response. |

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-3.1 | Updating AM with `virtualAreaId=X` creates assignments for all active stores in area X | Success + Boundary (many stores) | UpdateUser currently only writes `profile.AreaId` |
| TC-3.2 | Updating AM with `assignedStoreIds=[A,B]` upserts direct assignments and does not duplicate existing rows | Success + Boundary (idempotent) | No assigned-store payload support exists |
| TC-3.3 | S10 removed: update to `area_manager` with occupied legacy area does not return 409 | Error-regression | Current S10 guard returns conflict |
| TC-3.4 | Mixed payload union: `virtualAreaId` + extra `assignedStoreIds` results in union set | Success + Boundary (cross-area extra store) | Merge logic absent |
| TC-3.5 | Invalid `assignedStoreIds` containing unknown store returns 400 with clear error | Error | Validation not implemented |
| TC-3.6 | Non-admin update still forbidden even with new payload fields | Error (auth) | Guard unchanged but required regression |
| TC-3.7 | (Parity) CreateUser for AM no longer fails S10 when area occupied, if this slice includes CreateUser | Success-regression | CreateUser still calls FindExistingAreaManager |

## Test Fixture & Payloads
Required fixture state:
- Bootstrap admin token + at least 1 existing AM.
- Two areas, multiple stores per area, one store outside target area.
- Existing `ProfileStoreAssignments` rows to test idempotent upsert.

Request payloads:
```json
{
  "role": "area_manager",
  "virtualAreaId": "11111111-1111-1111-1111-111111111111",
  "assignedStoreIds": [
    "22222222-2222-2222-2222-222222222222",
    "33333333-3333-3333-3333-333333333333"
  ]
}
```

Expected response example:
```json
{
  "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "role": "area_manager",
  "areaId": "11111111-1111-1111-1111-111111111111",
  "assignedStoreIds": [
    "22222222-2222-2222-2222-222222222222",
    "33333333-3333-3333-3333-333333333333"
  ],
  "transferred": false
}
```

## Tools & Commands
Skills to load for builder:
- `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\tdd\SKILL.md`
- `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\testing-strategy\SKILL.md`
- `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\ef-core\SKILL.md`

Verification commands:
- `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~UpdateUserTests|FullyQualifiedName~StoreAuthorizationTests|FullyQualifiedName~IdorGuardTests"`
- `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~AdminUserManagementTests"` (if CreateUser parity included)

## Proposed Changes
| Status | File | Why |
|---|---|---|
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Admin\UpdateUser.cs` | Remove S10, add `virtualAreaId`/`assignedStoreIds` request handling, write junction assignments, update response fields. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Admin\Dtos.cs` | Extend admin DTO contract for assignment payload/response consistency. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Admin\UpdateUserTests.cs` | Add RED/GREEN acceptance cases for virtual-area fan-out and S10 deletion. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Admin\CreateUser.cs` | **Recommended parity**: remove S10 conflict check for AM creation path. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\services\admin_api_service.dart` | Optional immediate compatibility for new request fields (if backend contract changes now). |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\manager\admin_user_manager.dart` | Optional passthrough for new fields (if backend contract changes now). |

## Concept Diagram
`[Admin edits AM] --> [PUT /api/admin/users/{id}] --> [virtualAreaId -> resolve stores] + [assignedStoreIds] --> [union + validate] --> [upsert profile_store_assignments] --> [AM scope works immediately]`

## Execution Slices
### Phase A: Backend API contract + assignment write path (Complexity: Medium)
- Add request semantics in `UpdateUser`.
- Remove S10 conflict branch.
- Implement virtual area expansion + assignment upsert.
- **Pros:** Delivers slice value directly.  
- **Cons:** Needs precise validation to avoid ambiguity.

### Phase B: Test-first enforcement (Complexity: Medium)
- Write failing tests for TC-3.1..TC-3.6.
- Implement until green.
- **Pros:** protects auth/write regressions under Slice 2 runtime rules.  
- **Cons:** Existing test suite has unrelated noise; keep filtered run first.

### Phase C: CreateUser parity (Complexity: Low, decision required)
- Option 1 (recommended): include `CreateUser` S10 removal in same change.
- Option 2: defer to micro-slice immediately after.
- **Pros (include):** closes behavioral gap.  
- **Cons (include):** slightly wider blast radius than epic text.

**Decision required before coding:** include Phase C now (`CreateUser` parity) or keep strict epic scope (`UpdateUser` + DTO only).

## Verification Plan
1. RED: Add TC-3.1 and TC-3.3 first; confirm fail reason is missing virtual assignment/S10 removal.
2. GREEN: Implement UpdateUser request parsing + assignment upsert.
3. RED/GREEN: Add TC-3.2/TC-3.4/TC-3.5 boundary tests.
4. Run filtered tests, then broader admin/auth regression tests.
5. Confirm no new analyzer/lint issues in touched files.

## Handoff Block
Slice 3 plan is ready and scoped to Admin API assignment rewrite after Slice 2.

Run next step one at a time:
`@[/atdd] Execute specs for Slice 3 (Admin API — Virtual Area Assignment & S10 Deletion): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_173100_q4m7s3k1_slice3_admin_api.md`

Concurrency:
- Slice 4 and Slice 5 must wait for Slice 3 backend contract finalization.
- If Phase C is deferred, treat it as immediate sequential micro-slice before UI rollout.

<command_logs>
- ReadFile `.agents/workflows/analyze-feature.md`
- ReadFile epic analysis doc
- ReadFile `GEMINI.md` + `server/GEMINI.md`
- rg search: `virtualAreaId|assignedStoreIds|ProfileStoreAssignment|FindExistingAreaManager`
- ReadFile `server/Features/Admin/UpdateUser.cs`
- ReadFile `server/Features/Admin/CreateUser.cs`
- ReadFile `server/Features/Admin/Dtos.cs`
- ReadFile `server/tests/Checkly.Api.Tests/Features/Admin/UpdateUserTests.cs`
- ReadFile `lib/features/admin/services/admin_api_service.dart`
- ReadFile `lib/features/admin/manager/admin_user_manager.dart`
</command_logs>

<forensic_evidence>
- `UpdateUser.cs` still enforces S10 through `RoleAssignmentGuard.FindExistingAreaManager` and writes only `profile.AreaId`, no junction write path for AM updates.
- `CreateUser.cs` also enforces S10 conflict for AM creation, creating parity risk if only update path is changed.
- `RoleAssignmentGuard.cs` still documents and implements S10 (`FindExistingAreaManager`).
- Flutter admin API/manager contracts currently only send `storeId`/`areaId`/`forceReassign`; no `virtualAreaId`/`assignedStoreIds`.
- Existing tests already seed and rely on `ProfileStoreAssignments` in auth flows, proving Slice 2 dependency is active and Slice 3 writes are now critical.
</forensic_evidence>
