# Infrastructure Audit Report — Analytics Backend
**Target**: Analytics Feature Backend (GetAnalytics, AreaBenchmarkWorker, InsightGeneratorService)
**Date**: 2026-05-18
**Auditor**: Sentinel (Read-Only)

<latent_space_scratchpad>
Audit scope: 14 files — Analytics endpoint, worker, calculator, insight generator, EF entity + config, migration, and test files.

Key questions answered:
1. Unbounded queries? → AreaBenchmarkCalculator L33: `StoreAnalyticsSnapshots.Where(...).ToListAsync()` with no limit. Risk if areas have many stores.
2. Missing indexes? → `SubmissionSectionScores` filter in AreaBenchmarkCalculator uses `s.Submission!.Store!.AreaId` — a 2-join navigation chain. No covering index on (submission_id → store_id → area_id) path in section scores. The existing index `(store_id, section_title)` partially helps but the area-level join is an EF Include chain, not a direct column filter.
3. Delete strategy aligned? → Area → AreaBenchmarkSnapshot is Cascade. Correct.
4. Auth guards? → store_manager and area_manager are explicitly scoped. Admin is implicitly unrestricted (by design, undocumented).
5. Insights DTO mismatch: Dtos.cs defines `ActionableInsight(Id, Type, Title, Description)` — 4 fields. But Flutter `analytics_data.dart` only parses `id`, `type`, `text`, `actionRoute` — the field `title` and `description` are separate on the server but are parsed as `text` on the client. This is a DTO field name contract drift.
6. InsightGeneratorService.cs: no logging on any path. The service is pure-static, which is fine, but callers in GetAnalytics.cs do not log insight generation results either.
7. SaveChangesAsync in AreaBenchmarkCalculator.cs is called once at the end — good. Avoids N SaveChanges.
8. No pagination needed on GetAnalytics — it returns scalar KPIs + aggregated arrays, not raw entity lists.
9. Program.cs PBAC seeds: multiple `await pbacCache.InitializeAsync(app.Services)` calls in sequence. These are idempotent but the cache is reloaded 8 times on startup. Minor inefficiency but not a security issue.
</latent_space_scratchpad>

<forensic_evidence>
Files read during this audit:
1. `GetAnalytics.cs` (243 lines) — role tenancy enforcement, query chain, insights integration
2. `Dtos.cs` (42 lines) — ActionableInsight has Title + Description fields
3. `InsightGeneratorService.cs` (105 lines) — pure static, no logger injection
4. `AreaBenchmarkWorker.cs` (72 lines) — BackgroundService with DistributedLockManager
5. `AreaBenchmarkCalculator.cs` (98 lines) — unbounded StoreAnalyticsSnapshots query on L33
6. `AppDbContext.cs` (50 lines) — AreaBenchmarkSnapshots registered
7. `AreaBenchmarkSnapshot.cs` (20 lines) — entity, AreaId is PK
8. `AreaBenchmarkSnapshotConfiguration.cs` (28 lines) — Cascade delete, no extra indexes beyond PK
9. `SubmissionSectionScoreConfiguration.cs` (36 lines) — index on (store_id, section_title) but no (area) compound index
10. `SubmissionConfiguration.cs` (89 lines) — index coverage reviewed for CreatedAt, StoreId, Status
11. `Program.cs` (482 lines) — auth middleware, PBAC seeding pattern, Worker registration

grep_search executed:
- Searched for `SaveChangesAsync` in AreaBenchmarkCalculator → 1 result (L95, after the foreach — correct single-save pattern)
- Searched for `ToListAsync` in AreaBenchmarkCalculator → 2 results (L16 `areaIds`, L31-33 `storeSnapshots`)
- Searched for `RequireAuthorization` on Analytics endpoint in Program.cs → `MapAnalyticsEndpoints()` called with no explicit role policy attached at map level (relies on handler-level claim check)
</forensic_evidence>

## Executive Summary

| Severity | Count |
|---|---|
| 🔴 Critical | 2 |
| 🟡 Warning | 3 |
| 🟢 Optimization | 1 |

---

## 🔴 Critical Findings

### C-01 — DTO Field Name Contract Drift: `title`+`description` vs `text`
- **Files**: `server/Features/Analytics/Dtos.cs` (L24–28) vs `lib/features/analytics/manager/analytics_data.dart` (L22–29)
- **Root Cause**: The server `ActionableInsight` record defines two separate fields:
  ```csharp
  public sealed record ActionableInsight(
      string Id, string Type, string Title, string Description);
  ```
  The Flutter client `ActionableInsight.fromJson` parses:
  ```dart
  text: json['text'] as String,
  actionRoute: json['actionRoute'] as String?,
  ```
  The Flutter side expects `text` and `actionRoute`. The server sends `title`, `description`, and **no** `actionRoute` field. This means the Flutter client's `text` field always deserializes as **null** in production — the JSON key `"text"` does not exist in the server response. The app currently works in tests because the mock JSON in tests uses the Flutter-expected keys directly, not the real server DTO.
- **Impact**: All `InsightCard` widgets show a blank/null text string in production. This is a silent data contract mismatch.
- **Complexity**: **Low** — Two options exist. See Trade-offs below.
- **Fix Option A (Align server to Flutter)**: Rename the server DTO fields to match Flutter's expectation:
  ```csharp
  // Dtos.cs
  public sealed record ActionableInsight(
      string Id,
      string Type,
      string Text,            // was: Title
      string? ActionRoute);   // was: Description (and add ActionRoute)
  ```
  And update `InsightGeneratorService.cs` to use `Text:` and `ActionRoute:` in all `new ActionableInsight(...)` constructors.
- **Fix Option B (Align Flutter to server)**: Keep the server DTO, update Flutter to parse `title` and `description` and drop `text`.
- **Trade-offs**:
  - Option A is simpler — fewer Flutter files change (only `analytics_data.dart`) but requires updating 5 `new ActionableInsight(...)` calls in `InsightGeneratorService.cs`.
  - Option B keeps the richer server model (separate title + description) but requires updating `InsightCard` to render both fields.
  - **Recommendation**: Option A. The Flutter card only shows one text line anyway; combining title+description into a single `text` string reduces complexity.
  - **Decision Required**: Your approval before implementation.

### C-02 — Unbounded `StoreAnalyticsSnapshots` Query in `AreaBenchmarkCalculator`
- **File**: `server/Features/Analytics/AreaBenchmarkCalculator.cs`, line 31–33
- **Code**:
  ```csharp
  var storeSnapshots = await db.StoreAnalyticsSnapshots
      .Where(s => s.Store!.AreaId == areaId)
      .ToListAsync(ct);
  ```
- **Root Cause**: This loads ALL store snapshots for an area into memory with no `.Take()` limit. For an area with 200+ stores (e.g. a national retail chain), this materializes hundreds of rows per area loop iteration.
- **Impact**: OOM risk as data grows. Runs inside a `foreach (var areaId in areaIds)` loop — the risk multiplies with the number of areas.
- **Complexity**: **Low** — The computation uses `.Average()` and `.Sum()` which can be pushed server-side to SQL.
- **Fix**: Replace the in-memory aggregation with a direct SQL aggregate query:
  ```csharp
  // Before: loads all rows into memory
  var storeSnapshots = await db.StoreAnalyticsSnapshots
      .Where(s => s.Store!.AreaId == areaId)
      .ToListAsync(ct);
  var overallAvgScore = storeSnapshots.Average(s => s.AvgScore30d);

  // After: SQL-level aggregation — zero rows in memory
  var aggregates = await db.StoreAnalyticsSnapshots
      .Where(s => s.Store!.AreaId == areaId)
      .GroupBy(_ => 1)
      .Select(g => new {
          Avg = g.Average(s => s.AvgScore30d),
          Variance = g.Average(s => (double)(s.AvgScore30d * s.AvgScore30d)) 
                     - Math.Pow((double)g.Average(s => s.AvgScore30d), 2),
          Count = g.Count()
      })
      .FirstOrDefaultAsync(ct);
  ```
  Note: EF Core may not translate `Math.Pow` in a projection. Simpler alternative: keep the query but add `.Take(500)` as a safety bound and add a TODO to migrate to raw SQL if store count exceeds threshold.
- **Trade-offs**:
  - Full SQL aggregate: ✅ Zero memory, ✅ Database-server-side math. ⚠️ More complex query, EF may not translate StdDev perfectly.
  - Safety `.Take(500)`: ✅ Low-risk minimal change, zero logic change. ⚠️ Not a permanent fix — just a guard.
  - **Recommendation**: Apply `.Take(500)` now as a safety guard. Plan a follow-up `/analyze-feature` to move StdDev to raw SQL.
  - **Decision Required**: Your approval before implementation.

---

## 🟡 Warning Findings

### W-01 — Missing Covering Index: `SubmissionSectionScores` Area-Level Benchmark Query
- **File**: `server/Common/Persistence/Configurations/SubmissionSectionScoreConfiguration.cs`
- **Root Cause**: `AreaBenchmarkCalculator` filters `SubmissionSectionScores` like this:
  ```csharp
  db.SubmissionSectionScores
      .Where(s => s.Submission!.Store!.AreaId == areaId && s.CreatedAt >= cutoff90d)
  ```
  This generates a JOIN on `submission_section_scores → submissions → stores` to reach `area_id`. The existing index `(store_id, section_title)` helps partially, but there is no index on `created_at` in `SubmissionSectionScores`. For a large dataset, this filter on `created_at >= cutoff90d` runs a full scan of matching rows.
- **Complexity**: **Low** — A single `HasIndex` line in the configuration.
- **Fix**: Add a `created_at` index to `SubmissionSectionScoreConfiguration.cs`:
  ```csharp
  e.HasIndex(x => x.CreatedAt); // Added for AreaBenchmarkCalculator time-range filter
  ```
  Then generate a migration: `rtk dotnet ef migrations add AddSectionScoreCreatedAtIndex --project server`
- **Trade-offs**:
  - ✅ **Pro**: Eliminates full sequential scan on time-range filter. Critical for tables that grow proportionally with audit volume.
  - ⚠️ **Con**: Slightly slower INSERT speed on `submission_section_scores` (index maintenance overhead). Negligible at current scale.

### W-02 — `AreaBenchmarkCalculator` Emits No Per-Area Telemetry Log
- **File**: `server/Features/Analytics/AreaBenchmarkCalculator.cs`, lines 25–28
- **Root Cause**: When an area has fewer than 3 audits, the loop silently `continue`s. There is no log line for skipped areas, no log for how many areas were processed vs skipped, and no log for the final `SaveChangesAsync` call.
- **Impact**: When investigating slow analytics or missing insights, the on-call engineer has no log trail to know which areas were computed and which were skipped in the last worker run.
- **Complexity**: **Low** — Add structured log calls.
- **Fix**:
  ```csharp
  // AreaBenchmarkCalculator needs a logger injected or passed in.
  // Because it is a static class, pass ILogger as a parameter to RunForAllAreasAsync:
  public static async Task RunForAllAreasAsync(AppDbContext db, CancellationToken ct, ILogger? logger = null)
  {
      // ...
      if (totalAudits30d < 3)
      {
          logger?.LogDebug("AreaBenchmark: AreaId={AreaId} skipped — only {Count} audits in 30d", areaId, totalAudits30d);
          continue;
      }
      // ... after upsert:
      logger?.LogInformation("AreaBenchmark: AreaId={AreaId} upserted. OverallAvg={Avg}", areaId, overallAvgScore);
  }
  ```
  The `AreaBenchmarkWorker` already holds `_logger` — pass it through at the call site.
- **Trade-offs**:
  - ✅ **Pro**: Full observability for the benchmark cycle. Enables alerting if all areas are skipped.
  - ⚠️ **Con**: Modifies the method signature slightly. Low risk.

### W-03 — `GetAnalytics` Admin Access is Implicitly Unrestricted (Undocumented)
- **File**: `server/Features/Analytics/GetAnalytics.cs`, lines 24–65
- **Root Cause**: The role guard only applies to `store_manager` and `area_manager`. An `admin` user can pass any `storeId` or `areaId` query parameter and receive full data for that entity with no validation or audit trail.
- **Impact**: Not a bug — admin cross-entity access is intentional. But it is undocumented and untested. If an `auditor` role were ever added to the bypass condition, this would become a leakage path.
- **Complexity**: **Low** — Add a XML doc comment and an integration test assertion.
- **Fix**: Add a doc comment to the guard block:
  ```csharp
  // Note: admin role is explicitly unrestricted by design.
  // Admins can query any store/area for system-wide reporting.
  // Any role added here MUST be fully scoped to their own entity.
  ```
- **Trade-offs**:
  - ✅ **Pro**: Future engineers modifying this block will understand the intent. Prevents accidental scope bypass when adding new roles.
  - ⚠️ **Con**: None.

---

## 🟢 Optimization Findings

### O-01 — PBAC Cache Reloaded 8 Times on Startup in `Program.cs`
- **File**: `server/Program.cs`, lines 312–412
- **Root Cause**: `await pbacCache.InitializeAsync(app.Services)` is called after every single `ExecuteSqlRawAsync` seed block — 8 separate calls on startup. Each call likely reads the full `role_capabilities` table.
- **Impact**: Adds ~8 extra DB round-trips on every cold start. In production with a managed DB, this adds latency. Not a security issue, purely a startup performance drag.
- **Complexity**: **Low** — Batch all seeds into a single `ExecuteSqlRawAsync`, then call `InitializeAsync` once.
- **Trade-offs**:
  - ✅ **Pro**: Reduces startup time. Cleaner code.
  - ⚠️ **Con**: Slightly larger SQL block to review. Low risk since all seeds use `ON CONFLICT DO NOTHING`.

---

## Routing

| Finding | Severity | Routing |
|---|---|---|
| C-01 (DTO contract drift) | 🔴 | Route to `/implement` after your approval |
| C-02 (Unbounded query) | 🔴 | Route to `/implement` after your approval |
| W-01 (Missing index) | 🟡 | Route to `/implement` directly |
| W-02 (Missing telemetry) | 🟡 | Route to `/implement` directly |
| W-03 (Undocumented admin access) | 🟡 | Route to `/implement` directly |
| O-01 (8x cache reload) | 🟢 | Batch with next `/implement` run |

> [!IMPORTANT]
> **C-01 and C-02 require your executive approval before Forge can implement them.**
> Pass this report to Builder agent (@Forge) for `/implement (Track B)` once approved.
