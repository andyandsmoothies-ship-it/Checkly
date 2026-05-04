<latent_space_scratchpad>
Slice 1 delivered `ProfileStoreAssignment` + migration backfill; AM security must stop using `Profile.AreaId` for authorization in the paths the epic names, but grep shows additional AM `AreaId` checks in `GetStoreDashboard`, `ListActionPlans`, `GetActionPlan`, and `ReminderService` — leaving them unchanged would create inconsistent access (e.g. junction allows `ListStores` but dashboard still compares `store.AreaId` to `profile.AreaId`).

`ResourceScope` supports `AreaId`-only calls from `SyncSubmissions` (`GET /api/sync/submissions?areaId=...`). Replacing `profile.AreaId` with junction-only logic must not grant area-wide sync when the AM only has a subset of stores in that area (data leak vs. query filter). Safest rule: for `AreaId`-only scopes, authorize only if **every store in that area** has a junction row for the user (equivalent to “virtual full area” assignment). Single-store areas then require one assignment row — matches existing tests once fixtures insert rows.

Between Slice 2 and Slice 3, `PUT /api/admin/users` may still only set `Profile.AreaId` without inserting junction rows — tests and local admin flows must seed assignments in arrange (or Slice 3 must land immediately after). Plan calls this out as delivery risk.

EF: use `ProfileStoreAssignments` / `profile_store_assignments` table; prefer `AnyAsync` / subquery `Contains` patterns consistent with existing EF style; consider index on `(profile_id)` if query plans regress (optional follow-up).
</latent_space_scratchpad>

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\analysis_epic_20260503_215500_2b21e338_area_override.md` (Slice 2: Auth Guard Rewrite)
- Parent decision: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260503_214850_synth_store_area_consolidation.md`

## Executive Summary & Out of Scope
**Summary:** Shift Area Manager authorization from `Profile.AreaId` + `Store.AreaId` joins to **`profile_store_assignments`** as the single source of truth for “which stores this AM may touch,” in `ResourceAccessGuard`, `OwnershipScopeFilter` (submissions listing scope), and `ListStores`. Align **dashboard and action-plan list/get** guards that currently still compare `profile.AreaId` so store-level visibility matches junction data (recommended scope expansion vs. epic’s three-file list — see Risk Assessment).

**Out of scope (this slice — defer to Epic Slices 3–5):**
- Removing or repurposing `Profile.AreaId` columns on entities (data may remain for legacy/reporting/UI until later).
- Admin API batch insert for “virtual area” (`virtualAreaId` / `assignedStoreIds`) — Slice 3.
- Profile sync DTO `assignedStoreIds` and Flutter `CachedProfile` — Slice 4.
- Admin Flutter “virtual area” UX — Slice 5.
- Changing `SyncSubmissions` **query shape** beyond authorization (authorization fix only here).

## Risk Assessment

> **Risk Warning (blast radius)**  
> This rewires **core authorization** (`ResourceAccessGuard`, submission row scoping, store listing). A mistake causes IDOR or false lockout. **`GET /api/sync/submissions?areaId=`** must use a junction rule that matches the **area-wide** result set (see Test Contracts: area-wide vs partial assignment).

| Risk | Severity | Mitigation |
|------|----------|------------|
| Epic lists 3 files but other handlers still use `profile.AreaId` for AM | **High** | Expand slice to `GetStoreDashboard`, `ListActionPlans`, `GetActionPlan` (same store-set rule). Track `ReminderService` separately. |
| Slice 2 before Slice 3: admin `areaId` update does not yet mirror junction rows | **High** | Update test helpers / fixture seeding to insert `ProfileStoreAssignment` rows; or land Slice 3 in the same PR train. |
| `areaId`-only scope authorizes too much (partial AM) | **High** | Use “all stores in area assigned” rule for `AreaId`-only; document in plan and tests. |
| EF subquery performance | Low–Med | Composite PK on junction exists; add non-clustered index on `profile_id` only if profiling shows need. |

## System Context
- **Runtime:** Online ASP.NET Core API; EF Core + PostgreSQL (table `profile_store_assignments`).
- **Auth:** JWT role claim `area_manager`; capabilities unchanged this slice.
- **RBAC:** No new permissions; behavior change for how AM scope is computed.
- **Logs:** No new observability required for this slice.

## Lifecycle Context (AM-facing behaviors)
| State | Behavior |
|-------|----------|
| **Loading** | Unchanged (handlers already async). |
| **Success** | AM sees only stores present in junction; submissions/action plans/dashboard align with that store set. |
| **Empty** | AM with **no** junction rows → empty lists / 403 on scoped resources — **Breaking vs old `AreaId`-only profiles** until Slice 3/API seeds assignments. |
| **Error** | Standard ProblemDetails/FORBIDDEN patterns unchanged. |

## Test Contracts

| ID | Exact assertion / scenario | Matrix (Happy / Empty / Error / Boundary) | Why it fails first (RED driver) |
|----|----------------------------|---------------------------------------------|----------------------------------|
| TC-2.1 | `ResourceAccessGuard`: AM with junction row `(userId, storeId)` → `CanAccessAsync` true for scope with `StoreId` | Happy | Guard still reads `profile.AreaId` only |
| TC-2.2 | Same AM, **no** junction row → false for same `StoreId` | Empty | Guard ignores junction |
| TC-2.3 | AM with junction to store in **Area A**, `Profile.AreaId` = **Area B** → access **allowed** for that `StoreId` | Boundary | Proves `AreaId` on profile is not security input |
| TC-2.4 | `CanDelegateAsync` follows same store junction rule as `CanAccessAsync` for AM | Happy | Delegation still uses old area join |
| TC-2.5 | `OwnershipScopeFilter`: AM sees submissions only for `StoreId` values in their junction set | Happy | Filter still uses `Stores.AreaId == profile.AreaId` |
| TC-2.6 | `ListStores` as AM: response store IDs ⊆ assigned store IDs; count matches junction (respecting existing query filters) | Happy | ListStores still filters `s.AreaId == profile.AreaId` |
| TC-2.7 | `GET /api/sync/submissions?areaId={id}`: AM authorized iff **every** store with `Stores.AreaId == id` has a junction row for user; if one store missing → 403 | Boundary / Error | Naive `EXISTS(any store in area)` leaks area-wide payload |
| TC-2.8 | **If scope expanded:** `GetStoreDashboard` for store in junction but `profile.AreaId` differs → 200 | Boundary | Dashboard still compares `store.AreaId` to `profile.AreaId` |

## Test Fixture & Payloads
**Fixture state (typical integration test arrange):**
- Seeded `Areas`, `Stores`, `Profiles`, `AppUserRoles` (`area_manager`).
- For AM scenarios, insert `ProfileStoreAssignment` rows explicitly (mirror future Slice 3 behavior). Example pattern: for “full area” virtual assignment, insert one row per `Store` where `Store.AreaId == selectedAreaId`.

**API examples (illustrative):**
- `GET /api/stores` — no body; AM JWT; expect only assigned stores.
- `GET /api/sync/submissions?areaId={guid}` — AM JWT; expect 200 only when fixture assigned **all** stores in that area.

## Tools & Commands
**Skills (Builder):** `.agents/skills/tdd/SKILL.md`, `.agents/skills/testing-strategy/SKILL.md`, `.agents/skills/ef-core/SKILL.md`, `.agents/skills/dotnet-rbac-authorization/SKILL.md` (identity/scope context).

**Commands:**
- `dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~SubmissionAccessGuardUnitTests|FullyQualifiedName~OwnershipScopeFilter|FullyQualifiedName~StoreAuthorization|FullyQualifiedName~SyncSubmissions|FullyQualifiedName~ListActionPlans"`

## Proposed Changes
| Op | Path | Notes |
|----|------|--------|
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Common\ResourceAccessGuard.cs` | AM path: junction-based `IsUserAreaAsync`; define `AreaId`-only rule (see scratchpad). |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Common\Auth\OwnershipScopeFilter.cs` | AM: `StoreId` in junction subquery instead of `Stores.AreaId == profile.AreaId`. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Stores\ListStores.cs` | AM: filter stores by junction, not `profile.AreaId`. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Stores\GetStoreDashboard.cs` | **Recommended:** AM IDOR — `store.Id` must appear in junction (not `store.AreaId` vs `profile.AreaId`). |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\ActionPlans\ListActionPlans.cs` | **Recommended:** same store set as submissions scope. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\ActionPlans\GetActionPlan.cs` | **Recommended:** plan’s `StoreId` in junction. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\SubmissionAccessGuardUnitTests.cs` | Seed `ProfileStoreAssignment`; adjust area-mismatch scenario to assert junction wins. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\SyncSubmissionsEndpointTests.cs` | `LinkAreaManagerToAreaAsync` (or test) inserts junction row(s) per area rule. |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\StoreAuthorizationTests.cs` | After admin `Put` with `areaId`, fixture must match junction semantics **or** test seeds assignments via DB (until Slice 3). |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ListActionPlansTests.cs` | `CreateManagerClientAsync`: insert junction rows for area AM. |

*(Optional backlog, not Slice 2 minimum: `ReminderService.cs` AM filter migration.)*

## Concept Diagram

```
[AM JWT]
    --> [ResourceAccessGuard / OwnershipScopeFilter / ListStores (+ dashboard & action plans if expanded)]
        --> [EF: profile_store_assignments WHERE profile_id = userId]
            --> [Allowed StoreId set]
                --> [Submissions / Stores / Sync / Dashboard / Action plans]
```

## Execution Slices

### Phase A: Junction-based guards (backend) — Complexity: **Medium**
- **Goal:** Implement TC-2.1–TC-2.4 in `ResourceAccessGuard`; RED→GREEN unit/integration tests (`SubmissionAccessGuardUnitTests`).
- **Pros:** Centralizes IDOR semantics; unblock delegates & all `ResourceScope` call sites.
- **Cons:** `AreaId`-only semantics require careful definition (area-wide completeness rule).

### Phase B: Query scoping (`OwnershipScopeFilter`, `ListStores`) — Complexity: **Medium**
- **Goal:** TC-2.5–TC-2.6; update or add targeted tests (`OwnershipScopeFilterTests` extensions if needed, `StoreAuthorizationTests`).
- **Pros:** Submission list & store picker align with junction.
- **Cons:** Touches hot queries; validate SQL/subquery shapes on PostgreSQL.

### Phase C (recommended): Dashboard & action plans — Complexity: **Low–Medium**
- **Goal:** TC-2.8; remove `profile.AreaId`/`store.AreaId` mismatch holes (`GetStoreDashboard`, `ListActionPlans`, `GetActionPlan`).
- **Pros:** Eliminates contradictory AM UX; fewer security surprises.
- **Cons:** Slightly exceeds epic’s literal three-file list — **needs explicit human ACK** vs strict epic scope.

### Phase D: Test harness alignment — Complexity: **Low**
- **Goal:** Helpers (`SyncSubmissionsEndpointTests`, `ListActionPlansTests`, API-driven tests) insert junction rows consistent with Phase A `areaId` rule.

**Human decision before coding:** Approve **Phase C** (recommended) or insist on epic-minimal three files and accept inconsistent dashboard/action-plan behavior until a follow-up micro-slice.

## Verification Plan
1. **RED:** Add or adjust one failing test that proves AM relies on junction (submission guard or list stores) before changing production guard.
2. **GREEN:** Implement Phases A–D per approved scope; keep diffs localized (no unrelated formatting).
3. **Regression:** Run filtered `dotnet test` command above; then full `dotnet test` on API test project if time permits.
4. **Manual (optional):** AM login → list stores and open one dashboard only for assigned store.

## Handoff Block
Slice 1 (`ProfileStoreAssignment` + migration) is **done**. This plan implements **Slice 2** — junction-based AM authorization — and **recommends** extending the epic’s file list to dashboard/action plans to avoid split-brain security.

**Next step (test-first, security boundary):**  
`@[/tdd] Execute tests for Store area consolidation Slice 2 (Auth guards): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_150000_a8k3m9p2_slice2_auth_guards.md`

**Concurrency:** Slice 3 (Admin API junction writes) should follow immediately or ship in parallel only if fixtures always seed junction in tests — otherwise AMs lose access between merges.

---

<command_logs>

```bash
# Repository scans (conceptual equivalents: ripgrep / read_file)
# grep pattern: IsUserAreaAsync|OwnershipScopeFilter|ProfileStoreAssignment  under server/
# grep pattern: ResourceScope\(  under server/
# grep pattern: area_manager.*AreaId|AreaId.*area_manager under server/
# read: server/Common/ResourceAccessGuard.cs
# read: server/Common/Auth/OwnershipScopeFilter.cs
# read: server/Features/Stores/ListStores.cs
# read: server/tests/Checkly.Api.Tests/SubmissionAccessGuardUnitTests.cs
# read: server/tests/Checkly.Api.Tests/StoreAuthorizationTests.cs (area manager scenarios)
# read: server/Features/Submissions/SyncSubmissions.cs (+ SyncSubmissionsEndpointTests helpers)
```

</command_logs>

<forensic_evidence>
grep_search (server scope): Located `ProfileStoreAssignment` in `AppDbContext`, migrations, and tests; confirmed `ResourceAccessGuard.IsUserAreaAsync` still gates AM via `profile.AreaId` + `Store.AreaId` join (`server/Common/ResourceAccessGuard.cs`).
grep_search `ResourceScope\(` — identified `SyncSubmissions` passes `StoreId` and `AreaId` into guard; area-only sync path requires explicit junction semantics.
grep_search AM + `AreaId` — surfaced `GetStoreDashboard`, `ListActionPlans`, `GetActionPlan`, `ReminderService` as additional `profile.AreaId` consumers beyond epic’s three-file slice.
view_file: `OwnershipScopeFilter` area_manager branch still builds `Stores.Where(s => s.AreaId == amProfile.AreaId)` subquery (`server/Common/Auth/OwnershipScopeFilter.cs`).
view_file: `ListStores` area_manager branch still filters `query.Where(s => s.AreaId == profile.AreaId.Value)` (`server/Features/Stores/ListStores.cs`).
view_file: `StoreAuthorizationTests` assigns AM via `Put ... areaId` only — junction not populated until Slice 3 unless tests seed assignments (`server/tests/Checkly.Api.Tests/StoreAuthorizationTests.cs`).
</forensic_evidence>
