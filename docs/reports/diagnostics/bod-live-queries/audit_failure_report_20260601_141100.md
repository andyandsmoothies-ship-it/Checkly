# Audit Failure Report: BOD Live Queries
Workflow: /catch-flops | Track: C

## Input Lineage
- **Source Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\analysis_epic_20260601_140600.md`
- **Source Code**: `C:\Users\HP\Documents\GitHub\Checkly\server\Features\Analytics\GetBodReport.cs`

## Verdict
**Brittle**. The proposed transition to live queries contains two critical database performance flaws that will cause significant production degradation if implemented exactly as planned.

## Discovered Flops

### 🔴 Flop 1: Global `IN` Clause Explosion (Database Performance)
**Description:** If `GetBodReport.cs` is naively refactored to remove the `province` check but keep the `filteredStoreIds` logic for the global path, it will fetch all active stores (thousands) and inject them into 6 massive `WHERE store_id IN (...)` queries. This bypasses indexes, bloats the query plan, and degrades performance. 
**Impact:** Severe query slowdown and potential SQL parameter limit exceptions.
**Actionable Fix:** In Slice 3, refactor `GetBodReport.cs` so that if `province == null` (Global Path), it **completely skips** the `filteredStoreIds.Contains(...)` filter for all 6 aggregate queries.

### 🔴 Flop 2: COALESCE Index Defeat (Database Performance)
**Description:** The epic plan proposes adding a composite index on `submissions(status, completed_at)`. However, `GetBodReport.cs` currently filters using the expression `(s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo`. PostgreSQL cannot utilize a standard B-Tree index on a column wrapped in a `COALESCE` function, meaning the new index will be completely ignored and trigger a full table scan.
**Impact:** The global dashboard will scan the entire `submissions` table, violating the < 3s load time requirement.
**Actionable Fix:** In Slice 3, rewrite the query filters in `GetBodReport.cs` to strictly use `s.CompletedAt.HasValue && s.CompletedAt >= start30DaysAgo` (which matches the exact behavior of the old `BodReportWorker`). This guarantees the new composite index is utilized.

### 🟡 Flop 3: Historical Inactive Store Exclusion (Calculation Drift)
**Description:** The current filtered path in `GetBodReport.cs` only gathers `Store.IsActive == true`. If the global path is forced through this same logic, it will unexpectedly filter out historical audits from stores that were active at the time but are currently deactivated. The old `BodReportWorker` did not do this.
**Impact:** Global BOD averages and historical trends will drift and change when stores are deactivated.
**Actionable Fix:** Implementing the fix for Flop 1 (skipping `filteredStoreIds` for the global path) automatically resolves this calculation drift by querying all historical submissions regardless of current store status.

### 🟡 Flop 4: Thundering Herd Cache Stampede (Concurrency Risk)
**Description:** When the 60s `IMemoryCache` on the global path expires, if 10 concurrent requests arrive at the same millisecond, all 10 will execute the 6 heavy aggregate queries simultaneously before the first query finishes and populates the cache.
**Impact:** Occasional CPU spikes on the database every 60 seconds.
**Actionable Fix:** If load testing shows database spikes, wrap the global cache miss logic in an async `SemaphoreSlim` to ensure only the first request runs the queries while the others await the cached result.

---

## Action Plan for the Builder

The epic plan is structurally sound in its goal, but the implementation logic needs these adjustments:

1. **Slice 1**: Proceed as planned (Delete worker and snapshot infra).
2. **Slice 2**: Proceed as planned (Add composite indexes).
3. **Slice 3**: When rewriting `GetBodReport.cs`, you **MUST**:
   - Strip out `?? s.CreatedAt` and use `s.CompletedAt.HasValue && s.CompletedAt >= ...` everywhere.
   - Use conditional `IQueryable` chaining: `if (isFilteredPath) query = query.Where(s => filteredStoreIds.Contains(s.StoreId.Value));` so that the global path avoids the `IN` clause entirely.

## Handoff Block
- **Audit Verdict**: Brittle
- **Failure Report Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\reports\diagnostics\bod-live-queries\audit_failure_report_20260601_141100.md`
- **Next Steps**: The Builder can now begin implementing the Epic (starting with Slice 1), but must incorporate the fixes defined in Flops 1 and 2 during Slice 3 to ensure database stability.
