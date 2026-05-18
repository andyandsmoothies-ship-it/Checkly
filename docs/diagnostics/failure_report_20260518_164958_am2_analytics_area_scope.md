# Failure Report: am2 Analytics 403 — Wrong Tenancy Scope

## Input Lineage
- **Source**: User report + server log `[16:39:07 INF] HTTP GET /api/analytics responded 403 in 2.3124 ms`
- **Affected user**: `am2@checkly.local` (role: `area_manager`)

---

## Root Cause

`GetAnalytics.cs` uses a **different and wrong tenancy model** for `area_manager` compared to every other endpoint in the project.

The endpoint guards AM access with:
```csharp
// GetAnalytics.cs — lines 58-68 (THE BUG)
if (profile?.AreaId is null)
    return TypedResults.Forbid();   // ← am2 always hits this

areaIdStr = profile.AreaId.Value.ToString(); // ← never reached
```

But the project's **actual AM scoping design** uses `ProfileStoreAssignment` — a junction table linking AMs directly to individual stores. The `AreaId` column on `Profile` is **intentionally left NULL** because it is not part of the AM workflow.

---

## Explicit Code Trace (Premises + Proof)

| # | Premise | Evidence |
|---|---|---|
| P1 | am2's `profile.AreaId` is NULL | `seed_users.sql` lines 28-29 insert Profiles without `area_id`. The `areas` table FK constraint still exists but AMs are **not assigned through it** by design. |
| P2 | `GetAnalytics.cs` line 58 returns 403 when `AreaId is null` | `server/Features/Analytics/GetAnalytics.cs:58-59` |
| P3 | **All other** AM-scoped endpoints use `ProfileStoreAssignments` junction | `ListActionPlans.cs:48-54`, `GetAreaCampaignProgress.cs:38-42`, `GetStoreDashboard.cs:55`, `SyncProfile.cs:37`, `GetActionPlan.cs:48` |
| P4 | `GetAnalytics.cs` is the ONLY endpoint using `AreaId` for AM scoping | `grep_search` found zero other `AreaId` guards in `Features/Analytics/` |

**Conclusion**: `GetAnalytics.cs` was written before the AM store-assignment model was finalized. It uses a stale/abandoned `AreaId` approach that the rest of the codebase has already migrated away from.

---

## Proposed Scope-Limited Fix

**Strategy**: Replace the AM block in `GetAnalytics.cs` (lines 54-69) with the canonical `ProfileStoreAssignment` pattern — identical to `ListActionPlans.cs`.

**The change:**
- **DELETE** the `profile.AreaId` guard (blocks legitimate AM users).
- **DELETE** the IDOR check on `areaIdStr` (no longer relevant — AM scope is store-list, not area).
- **ADD** a `ProfileStoreAssignments` query to resolve the AM's assigned stores.
- **ADD** a `storeId IN (assignedStoreIds)` filter on the main query.
- **KEEP** the `storeId` override for SM (unchanged).
- **KEEP** the downstream `resolvedAreaId` logic for insights — if the assigned stores happen to share an area, insights still load.

**Blast radius**: `GetAnalytics.cs` only. No schema changes. No Flutter changes.

### Trade-offs

| Factor | Note |
|---|---|
| ✅ Consistency | Matches ListActionPlans, GetAreaCampaignProgress — same pattern across 5+ endpoints |
| ✅ Correctness | am2 can now access analytics scoped to their assigned stores |
| ✅ Security | IDOR protection remains: AM can only see data for stores in their junction row set |
| ⚠️ Insights/Radar | If the AM is assigned stores from MULTIPLE areas, `resolvedAreaId` will be null → insights section will be blank. This is an acceptable limitation. |
| ⚠️ Area filter param | AM can no longer pass `?areaId=` to filter by area. This is correct — AM filters by store only. |

---

<forensic_evidence>
## Tools Executed

1. `view_file` → `server/Features/Analytics/GetAnalytics.cs` (full, 253 lines)
2. `grep_search` → `ProfileStoreAssignment` in `server/Features/Analytics/` → 0 results (confirmed the gap)
3. `grep_search` → `ProfileStoreAssignment` in `server/Features/` → 20+ usages in all other AM-scoped endpoints
4. `view_file` → `server/Features/ActionPlans/ListActionPlans.cs` (confirmed canonical AM pattern, lines 42-55)
5. `view_file` → `server/Features/Programs/GetAreaCampaignProgress.cs` (confirmed same pattern, lines 38-45)
6. `view_file` → `server/scripts/seed_users.sql` (confirmed AreaId is intentionally NULL in seed)
7. `run_command` → `psql query_areas.sql` (confirmed only 2 areas exist in DB, with hardcoded UUIDs)
</forensic_evidence>

---

## Handoff Block

**Diagnostic Verdict**: `GetAnalytics.cs` is the only AM-scoped endpoint that uses the stale `AreaId` tenancy model. All other endpoints have already been migrated to the `ProfileStoreAssignment` junction. The fix is a targeted swap of the AM block (~12 lines changed, zero schema changes).

**Required Fix**: In `server/Features/Analytics/GetAnalytics.cs`, replace the AM guard block (lines 54-69) with a `ProfileStoreAssignments` query — scoping the main submissions `query` to `storeId IN (assignedStoreIds)`.

**AI Agent Mission Brief**: The AM block in `GetAnalytics.cs` (lines 54-69) uses `profile.AreaId` for scoping but must use `ProfileStoreAssignment` junction table instead — matching the pattern in `ListActionPlans.cs:42-55`. Replace only those lines; leave SM block and everything after line 75 untouched.

## Execution Queue
- [ ] `@[/implement] docs/diagnostics/failure_report_20260518_164958_am2_analytics_area_scope.md`
