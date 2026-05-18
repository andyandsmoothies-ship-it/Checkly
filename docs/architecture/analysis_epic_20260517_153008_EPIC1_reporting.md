<latent_space_scratchpad>
## Critical Finding: The Requirements Missed a Hidden Dependency

The requirements document (REQ1) describes the backend returning `ActionableInsight` objects
and the frontend rendering them. This is correct in theory.

However, fresh codebase inspection reveals:
- `AnalyticsManager.dart` (265 lines) runs ALL its computations from **local Drift** (SQLite).
  It reads `cachedSubmissions`, `cachedStores`, `cachedTemplates`, `cachedActionPlans` locally.
- The `/api/analytics` backend endpoint is NOT currently called by the main Analytics Dashboard.
  `AnalyticsApiService.dart` wraps the API call, but `AnalyticsManager` never imports or uses it.
- This means the requirements' Slice 3 ("Flutter renders insights") will fail if we just update
  the backend DTO without also rewiring `AnalyticsManager` to call the API.

This is a **BLOCKING prerequisite** that MUST be added as Slice 0:
"Rewire AnalyticsManager to call the API for insights instead of computing locally from Drift."

After Slice 0, the manager must still use Drift for the offline fallback path.

## Architecture Decision
- Shape B (Event-Driven Cache) is confirmed as the winner.
- The `StoreAnalyticsUpdater.cs` already maintains a `StoreAnalyticsSnapshot` per store.
  We EXTEND this (not replace it) to add a `AreaBenchmarkSnapshot` table calculated by a
  IHostedService (native .NET background service — NO Hangfire install needed).
- The `InsightGeneratorService` is a pure static/domain class — no HttpContext, no PBAC roles.
  The endpoint passes `bool includeAreaBenchmarks` and `int auditCount` as simple booleans.
- Radar chart stays in `fl_chart`. A `RadarChart` widget already exists in fl_chart v0.66+.

## Persona Scores
- DB Architect: 8/10. New `AreaBenchmarkSnapshot` table needs indexed on `(AreaId, CalculatedAt)`.
  Risk: if the background service fails silently, the table goes stale. Needs a `LastCalculatedAt`
  column and a health check dashboard warning if stale > 2 hours.
- Security Auditor: 9/10. PBAC roles do NOT enter the domain layer. Endpoint passes primitive booleans.
  The `StoreId` IDOR guard in `GetAnalytics.cs` already exists and must not be removed.
- Junior Dev: 7/10. The data flow pivot (Drift→API) in `AnalyticsManager` is the hardest part.
  Clear documentation needed. Risk of developer using the wrong data source in offline fallback.
</latent_space_scratchpad>

# Epic Analysis: Insight-Driven Analytics Dashboard

## Input Lineage
- Requirements: `c:\Users\HP\Documents\GitHub\Checkly\docs\product\requirements_20260517_125659_REQ1_reporting.md`
- ADR: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260517_120515_SYN1_reporting.md`

## Executive Summary
The current Analytics Dashboard is fully computed from local Drift SQLite data and never calls the backend API. This works for offline-first but means the backend `/api/analytics` endpoint is effectively unused by the main dashboard. This epic adds a **Regional Benchmark Cache** (via a .NET `IHostedService`), an **`InsightGeneratorService`** (pure domain logic, no PBAC coupling), and a **Flutter AnalyticsManager rewrite** that calls the API for online insights while gracefully falling back to local Drift data when offline.

The epic has **4 slices** (Slice 0 is the hidden prerequisite):
- **Slice 0** *(BLOCKING)*: Rewire `AnalyticsManager` to call the API (unlocks everything)
- **Slice 1** *(BLOCKING)*: Backend `AreaBenchmarkSnapshot` entity + background worker
- **Slice 2** *(SEQUENTIAL, after Slice 1)*: `InsightGeneratorService` + DTO update
- **Slice 3** *(SEQUENTIAL, after Slice 2)*: Flutter UI — Insight Cards + Radar Chart

---

## Decision Matrix

| Requirement | Shape A: Procedural (On-the-Fly) | Shape B: Cached Worker + Rules Engine |
|---|:---:|:---:|
| R1: Live store score (up to the second) | ✅ | ✅ |
| R2: Actionable narrative insight cards | ✅ | ✅ |
| R3: Prevent N+1 DB crash under load | ❌ | ✅ |
| R4: Suppress false alarms (< 3 audits) | ❌ | ✅ |
| R5: Offline graceful degradation | ❌ | ✅ |
| R6: Zero new package dependencies | ✅ | ✅ |
| R7: PBAC-clean Domain layer | ❌ | ✅ |

**Winner: Shape B. Shape A fails on 4/7 requirements.**

---

## Risk Assessment

| Risk | Impact | Mitigation |
|---|---|---|
| Background worker silently stops producing data | HIGH — stale insights shown | Add `LastCalculatedAt` field; surface warning in dashboard if stale > 2h |
| Radar chart data is sparse (< 3 categories) | MEDIUM — visual looks broken | Suppress Radar section if `radarData.categories.length < 3` |
| `AnalyticsManager` rewire breaks offline mode | HIGH — crashes in airplane mode | Keep Drift fallback path explicitly in `load()` error handler |
| `GetMyStats` still runs live aggregate queries | LOW — no change to endpoint | Out of scope for this epic |
| EF Core migration fails in `_test` DB | LOW | Run `dotnet test` before marking Slice 1 complete |

---

## Visual & Functional Context

```text
+-----------------------------------------------+
|  Analytics Dashboard (Redesigned)             |
+-----------------------------------------------+
|  [ONLINE] Executive Summary (Insight Cards)   |
|  ⚠️ Safety dropped 12% vs Regional Avg        |
|  💡 You're Top 10% in Inventory               |
|  → Tap card → routes to /activity?filter=cat  |
+-----------------------------------------------+
|  KPI Row (with delta vs last period)          |
|  Score: 85% ⬆️2%  | Audits: 14 | OAPs: 3      |
+-----------------------------------------------+
|  Category Radar Chart (fl_chart RadarChart)   |
|  -- Store polygon vs Region polygon           |
|  -- Suppressed if < 3 categories              |
+-----------------------------------------------+
|  6-Month Historical Trend (Line Chart)         |
|  -- Target threshold line overlay             |
+-----------------------------------------------+
|  [OFFLINE] Insight cards + Radar HIDDEN        |
|  "⚠️ Insights require internet connection."   |
|  KPIs from local Drift                         |
+-----------------------------------------------+

Overflow / Routing Table:
| Widget          | Max Items | Overflow Route                 |
|-----------------|-----------|--------------------------------|
| Insight Cards   | 3         | Suppressed (no pagination)     |
| Radar Axes      | 8         | Group extras as "Other"        |
| KPI row         | 5         | Fixed (no scroll)              |
| Trend points    | 6 months  | Fixed window                   |
```

---

## System Context

| Dimension | Details |
|---|---|
| **RBAC / PBAC** | `analytics:view` (auditor, store_manager), `analytics:area` (area_manager), `analytics:admin` (admin). Endpoint enforces data tenancy. Domain layer receives `bool includeAreaBenchmarks` only. |
| **Offline / Online** | `AnalyticsManager.load()`: try API first → on error/offline, fall back to Drift local queries. Insight cards and Radar hidden when offline. |
| **API Contract** | `GET /api/analytics` response extends `AnalyticsResponse` with `List<ActionableInsight> Insights` and `RadarData? RadarData`. |
| **Cache TTL** | `AreaBenchmarkSnapshot` recalculated every 15-30 minutes by `AreaBenchmarkWorker` (`IHostedService`). |

---

## Lifecycle Context

| State | Handling |
|---|---|
| **Empty (< 3 audits)** | Backend returns `[{"type":"info","text":"Complete 3 audits to unlock..."}]`. UI renders single info card. Radar hidden. |
| **Offline** | `AnalyticsManager` catches `DioException` → loads from Drift → sets `isOffline = true`. UI shows banner, hides insight section. |
| **Worker Stale (> 2h)** | `LastCalculatedAt` checked in `GetAnalytics`. If stale, endpoint returns `insightsStale: true` flag. UI shows subtle "Data may be outdated" note. |
| **Error state** | `AnalyticsManager.error` is set. UI shows `ChecklyEmptyState` with retry button. |
| **Rollback** | `AreaBenchmarkSnapshot` migration adds only new columns/table. If rolled back, `GetAnalytics` falls through to basic mode (no insights). Zero risk to existing `StoreAnalyticsSnapshot`. |

---

## Data Context

### New Entity: `AreaBenchmarkSnapshot`
```
AreaBenchmarkSnapshot
├── AreaId (Guid, FK → Areas.Id)
├── CategoryAverages (jsonb) — map of SectionTitle → AvgScore
├── OverallAvgScore (decimal)
├── StdDeviation (decimal)
├── TotalAuditCount (int)
├── LastCalculatedAt (DateTimeOffset)
└── CreatedAt (DateTimeOffset)
```

### Updated DTO: `AnalyticsResponse`
```csharp
// NEW fields added to existing AnalyticsResponse record
List<ActionableInsight> Insights      // max 3, empty list when sparse
RadarData? RadarData                  // null when offline or sparse
bool InsightsStale                    // true if benchmark > 2h old
```

### New DTO: `ActionableInsight`
```csharp
record ActionableInsight(
    string Id,          // "ins_safety_drop"
    string Type,        // "warning" | "info" | "positive"
    string Text,        // natural language sentence
    string? ActionRoute // "/activity?filter=safety" or null
);
```

### EF Migration
1 new migration: `AddAreaBenchmarkSnapshot` — creates `area_benchmark_snapshots` table.

---

## Architecture Flow

```text
[WRITE PATH — every 15-30 mins]
AreaBenchmarkWorker (IHostedService)
  → Groups SubmissionSectionScores by AreaId
  → Computes AvgScore + StdDev per Category per Area
  → Upserts AreaBenchmarkSnapshot

[READ PATH — per user request]
GET /api/analytics
  → Endpoint resolves PBAC → sets bool includeAreaBenchmarks
  → GetAnalytics.HandleAsync
    ├── (existing) Live KPIs from Submissions (unchanged)
    ├── (existing) 6-month Trend (unchanged)
    ├── (NEW) Read AreaBenchmarkSnapshot for user's area
    └── (NEW) InsightGeneratorService.Generate(liveScore, benchmark, auditCount)
           → Returns List<ActionableInsight> (max 3)
  → Returns extended AnalyticsResponse

[FLUTTER — online path]
AnalyticsManager.load()
  → Calls AnalyticsApiService.getAnalytics(...)
  → Maps JSON → AnalyticsData (extended with insights, radarData)
  → Notifies listeners

[FLUTTER — offline path]
AnalyticsManager.load()
  → DioException caught
  → Falls back to Drift local queries (existing logic, unchanged)
  → Sets isOffline = true
  → Insight cards + Radar suppressed in AnalyticsPage
```

---

## Risk Review & Security

- **IDOR Protected**: `GetAnalytics` existing guard forces `store_manager` to their own store. Unchanged.
- **No PBAC in Domain**: `InsightGeneratorService` is a `static class` receiving only primitive types.
- **No New Packages**: `IHostedService` is native .NET. `fl_chart` `RadarChart` already in pubspec.
- **Blast Radius**: `[MEDIUM]` — touches `GetAnalytics.cs` (existing endpoint), `AnalyticsResponse` DTO (existing record), `AnalyticsManager.dart` (existing manager). All changes are additive.

---

## Logs & Audits
- `AreaBenchmarkWorker`: Log at `Information` level when each area recalculates (AreaId, duration, insight count).
- `InsightGeneratorService`: Log at `Debug` level when a sparsity guard suppresses an insight.

---

## Testing Expectations

| Slice | Test Type | Key Scenario |
|---|---|---|
| Slice 1 | Integration | Worker writes valid `AreaBenchmarkSnapshot` row after seeded submissions |
| Slice 2 | Integration | `GetAnalytics` returns 3 insight strings for a store > 3 audits |
| Slice 2 | Integration | `GetAnalytics` returns "Complete 3 audits..." for a store < 3 audits |
| Slice 2 | Integration | Stale benchmark (> 2h) sets `insightsStale: true` |
| Slice 3 | Widget | `AnalyticsPage` shows insight cards when API returns insights |
| Slice 3 | Widget | `AnalyticsPage` hides insight section and shows banner in offline mode |

---

<command_logs>
- grep_search: `GetAnalytics` in `server/Features/Analytics/` — found AnalyticsEndpoints.cs, GetAnalytics.cs
- grep_search: `RegionalBenchmark` in `server/` — NO RESULTS (entity does not exist yet, confirmed new work)
- grep_search: `IHostedService|BackgroundService|Hangfire` in `server/` — NO RESULTS (no existing worker infra)
- grep_search: `StoreAnalyticsSnapshot` in `server/` — found in StoreAnalyticsUpdater.cs, AppDbContext.cs, migrations
- grep_search: `analytics` in `lib/features/analytics/` — found AnalyticsManager.dart, AnalyticsApiService.dart
- view_file: `StoreAnalyticsUpdater.cs` — confirmed per-store snapshot writer pattern (reuse model for AreaBenchmark)
- view_file: `AnalyticsManager.dart` — **CRITICAL FINDING**: all queries run from Drift, never calls API
- view_file: `GetMyStats.cs` — confirmed live company avg query (unchanged in this epic)
</command_logs>

---

## Handoff Block

### Final Epic Decision
**Shape B (Event-Driven Cache + Rules Engine)** is approved. Artifact path:
`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md`

### Execution Slices

| # | Name | Order | Track | Workflow Route |
|---|---|---|---|---|
| **0** | Rewire `AnalyticsManager` to call API + offline fallback | `[BLOCKING]` — must run first alone | A | `/analyze-feature` → `/implement` |
| **1** | `AreaBenchmarkSnapshot` Entity + `AreaBenchmarkWorker` (IHostedService) | `[BLOCKING]` — needed before API can serve benchmarks | B | `/analyze-feature` → `/tdd` → `/implement` |
| **2** | `InsightGeneratorService` + DTO extension (`ActionableInsight`, `RadarData`) | `[SEQUENTIAL]` — after Slice 1 | B | `/analyze-feature` → `/tdd` → `/implement` |
| **3** | Flutter: Insight Cards + `fl_chart` RadarChart in `AnalyticsPage` | `[SEQUENTIAL]` — after Slice 2 | A | `/analyze-feature` → `/implement` |

### Next Steps
Start with Slice 0 (the hidden prerequisite): rewire `AnalyticsManager.dart` to call the backend API for its primary data source while keeping the Drift path as the offline fallback. This unblocks the rest of the epic.

### Handoff Roadmap

> **Important:** The Epic is broken into 4 slices. For **each slice**, you must complete the 2-step Software Development Life Cycle (SDLC) loop:
> 1. **Feature Analysis Phase:** Run the command provided below to generate the exact code plan.
> 2. **Implementation Phase:** At the end of the analysis, the AI will provide you with the next command (`[/implement]` or `[/tdd]`) to write the code.
> 
> Finish both phases for a slice completely before returning here for the next slice.

---

#### Slice 0: AnalyticsManager API Rewire (Start Here)

**1. Feature Analysis Phase:**
```bash
/analyze-feature c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md
```
*(Instruction for AI: Focus on Slice 0 — AnalyticsManager API Rewire)*

**2. Implementation Phase:**
*(Wait for the AI to generate the `[/implement]` command at the end of the analysis above)*

---

#### Slice 1: AreaBenchmarkSnapshot & Worker

**1. Feature Analysis Phase:**
```bash
/analyze-feature c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md
```
*(Instruction for AI: Focus on Slice 1 — AreaBenchmarkSnapshot & Worker)*

**2. TDD & Implementation Phase:**
*(Wait for the AI to generate the `[/tdd]` command at the end of the analysis above)*

---

#### Slice 2: InsightGeneratorService & DTOs

**1. Feature Analysis Phase:**
```bash
/analyze-feature c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md
```
*(Instruction for AI: Focus on Slice 2 — InsightGeneratorService & DTOs)*

**2. TDD & Implementation Phase:**
*(Wait for the AI to generate the `[/tdd]` command at the end of the analysis above)*

---

#### Slice 3: Flutter Insight Cards & Radar Chart

**1. Feature Analysis Phase:**
```bash
/analyze-feature c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md
```
*(Instruction for AI: Focus on Slice 3 — Flutter Insight Cards & Radar Chart)*

**2. Implementation Phase:**
*(Wait for the AI to generate the `[/implement]` command at the end of the analysis above)*
