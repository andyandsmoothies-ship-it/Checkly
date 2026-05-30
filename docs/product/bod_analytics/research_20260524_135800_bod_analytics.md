# Research: BOD-Grade Analytics System for Checkly Large-Chain Reporting

**Date**: 2026-05-24  
**Author**: Architect Agent  
**ID**: bod_analytics  
**Status**: Complete — Handoff Ready

---

## [ORIGIN_IDEA]

> The user wants to replace the current simple number-based analytics cards with a comprehensive, multi-role, actionable analytics system suitable for Board-of-Directors (BOD) presentations in a large retail/F&B chain context. The system must go beyond KPI cards to include visual charts, trend analysis, benchmarks, risk signals, and role-specific views. The chart-visualization skill (26 chart types) is the visual engine.

---

<latent_space_scratchpad>
## Internal Reasoning & Architectural Debate

### STEP 1: Label the Pattern

This is a **Reporting & Observability Ledger** system, not a transactional one.

Characteristics:
- Read-heavy, write-infrequent
- Aggregated historical data (not live)
- Multiple audience personas (Admin/BOD, Area Manager, Store Manager, Auditor)
- Pre-computed snapshots are the right tool (not real-time joins)
- Each role sees a different "lens" on the same underlying data

Pattern: **Multi-Tenant Observability Ledger with Role-Projected Views**

### STEP 2: Current State Reality Assessment

**What EXISTS today (confirmed via grep_search + view_file):**

Backend (server/Features/Analytics/):
- `GetAnalytics.cs` — Main endpoint. Computes KPIs (total, avg score, openAPs, overdueAPs, completionRate), 6-month trend, section breakdown, province benchmark insights, radar data. Role-tenanted (admin/store_manager/area_manager; auditors are FORBIDDEN).
- `GetMyStats.cs` — Auditor personal stats (monthly count, avg score given, company avg).
- `GetTopFailures.cs` — Per-template top-20 failed criteria with fail rate %.
- `InsightGeneratorService.cs` — 5 rules: score drop, top performer, category weak/strong, overdue APs. Capped at 3 insights.
- `ProvinceBenchmarkCalculator.cs` — Background worker computing province-level benchmarks (avg, std dev, category averages) from active stores.
- `AreaBenchmarkWorker.cs` — Scheduled background worker calling the calculator.
- DTOs: `AnalyticsKpis`, `TrendPoint`, `SectionScore`, `ActionableInsight`, `RadarData`, `AnalyticsResponse`.

Frontend (lib/features/analytics/):
- `AnalyticsManager` — Calls API with filters (store, type, province, auditor, status, date range). Falls back to Drift offline.
- `AnalyticsData` — 5 KPIs + trend + categoryScores + storeNames/types/provinces + insights + radarData.
- Charts: `TrendChart` (fl_chart line chart), `InsightsRadarChart` (fl_chart radar), `CategoryHeatmap` (2×2 colored cells).
- `AnalyticsKpiCard` — Simple icon + big number + label.
- Filters: store, province, type, date range (30/90/180/custom/all).

**Existing GAPS identified:**
1. Only 1 time-series chart (6-month trend). No YoY, no weekly cadence, no decomposition.
2. Category heatmap is a 2×2 grid — not a real heatmap. No visual encoding of intensity across time or geography.
3. No store-vs-store ranking (leaderboard). No "worst performers" list.
4. No geospatial visualization (province-level choropleth or pin map).
5. Insight rules are shallow (5 rules, 3 max shown). No ML/statistical scoring beyond simple averages.
6. No auditor performance view (GetMyStats exists but is not surfaced in analytics UI — it goes to dashboard only).
7. No action plan aging curve or resolution funnel.
8. No program/campaign progress visualization.
9. `GetTopFailures` endpoint exists but has NO Flutter UI consumer — completely dark.
10. No BOD-level summary slide/export capability.
11. No drill-down: the trend chart taps to activity list, but there's no "province → stores → audits" drill-down hierarchy.
12. No comparative period analysis (this month vs last month delta).

### STEP 3: Role-Specific Requirements

**Admin / BOD View:**
- Enterprise-wide: all stores, all provinces
- Top-level KPIs with delta vs previous period
- Geographic distribution map (pin map by province)
- Store leaderboard (ranked bar chart)
- Category weakness heatmap across chain
- AP aging funnel
- Program compliance rate

**Area Manager:**
- Scoped to assigned stores
- Store-vs-store comparison (grouped bar chart)
- Weekly trend (not just monthly)
- Auditor performance within territory
- Top failures per territory

**Store Manager:**
- My store vs province average
- Staff productivity (audits per auditor)
- Category-level radar with history
- AP resolution timeline

**Auditor:**
- Personal stats (already GetMyStats)
- This-month vs last-month comparison
- Top criteria I failed (personal top-failures)

### STEP 4: Architecture Decision

**Pattern**: Hierarchical Ledger with Materialized Views (pre-computed snapshots)

The right approach is NOT to add more real-time SQL aggregations to the main GetAnalytics endpoint — it's already at the complexity ceiling. Instead, introduce:
1. A new `AnalyticsSnapshot` materialized entity (per-store, per-period)
2. New dedicated endpoints per role-context (thin query projections)
3. A server-side scheduled worker that pre-computes all heavy aggregations
4. A new `BodAnalyticsPage` on Flutter that is separate from the current `AnalyticsPage` (which serves store managers)
5. Keep `GetAnalytics.cs` for store-manager/AM scope; add `GetBodReport.cs` for admin-only BOD view

This matches the existing `ProvinceBenchmarkCalculator` + `AreaBenchmarkWorker` pattern already in the codebase — it is proven and should be extended, not replaced.

### STEP 5: Visual Strategy (chart-visualization skill)

| Section | Chart Type | Rationale |
|---|---|---|
| Chain-wide score trend | `generate_area_chart` (dual axes) | Filled area shows volume, line shows score. Better than bare line. |
| Province performance | `generate_column_chart` (grouped) | Province bars grouped by period for comparison. |
| Store leaderboard | `generate_bar_chart` (horizontal) | Ranked list — horizontal bars naturally rank stores. |
| Category weakness map | `generate_radar_chart` | Multi-category comparison — already in use, extend. |
| AP aging funnel | `generate_funnel_chart` | Open → Overdue → Escalated → Resolved — natural funnel. |
| Geographic distribution | `generate_pin_map` / `generate_district_map` | Province-level color coding or pin density by store count. |
| Auditor productivity | `generate_scatter_chart` | Volume (x-axis) vs Score (y-axis) — reveals who is fast but sloppy. |
| Top failures | `generate_bar_chart` (horizontal, sorted) | Top 10 failed criteria with fail rate %. GetTopFailures already exists. |
| Period-over-period KPIs | `generate_spreadsheet` | BOD-style summary table with delta arrows. |
| Program compliance | `generate_liquid_chart` | Filled progress gauge for each active program. |
| Score distribution | `generate_histogram_chart` | Distribution of scores across stores — reveals bimodal patterns. |

### STEP 6: Blind Spots

1. **Data Volume / Query Cost**: Pre-computing across ALL stores at BOD level will be expensive. The existing `ProvinceBenchmarkCalculator` already has an N-query optimization but it still iterates all provinces. For 100+ stores × 12 months, we MUST materialize snapshots, not compute on-demand.

2. **Offline Support**: The current `analytics_drift_loader.dart` only caches KPIs from local submissions. BOD-level data (province benchmarks, store rankings) cannot be computed offline from a single device's local data. The BOD page MUST clearly indicate it is online-only.

3. **Role Creep in PBAC**: The existing GEMINI.md gotcha "Hardcoded Role Filtering" warns against frontend role checks. The new BOD page must be access-gated exclusively via backend PBAC (the admin role check already in `GetAnalytics.cs`), not via `if (role == 'admin')` checks in Flutter. The `allowedActions` pattern must gate navigation to the BOD page.

</latent_space_scratchpad>

---

## 1. System Design Pattern

> **Pattern: Multi-Tenant Observability Ledger with Role-Projected Materialized Views**

```
[Role Context]
     │
     ▼
[Lens Selector]──────────────────────────────────────────────────────────┐
     │                                                                    │
     ▼                                                                    ▼
[Admin / BOD View]                                         [Store Manager / Area Manager View]
  Chain-wide KPIs                                            Store-scoped KPIs
  Province map                                               Province benchmark radar
  Store leaderboard                                          Category heatmap
  AP aging funnel                                            AP resolution timeline
  Auditor scatter                                            Auditor performance
  Program compliance                                         Program compliance
     │                                                                    │
     └──────────────────────────┬─────────────────────────────────────────┘
                                ▼
                    [Pre-Computed Snapshot Layer]
                    ┌──────────────────────────────────┐
                    │ StoreAnalyticsSnapshot (existing) │
                    │ ProvinceBenchmarkSnapshot (exist.) │
                    │ BodReportSnapshot (NEW)            │
                    └──────────────────────────────────┘
                                │
                                ▼
                    [Background Workers]
                    AreaBenchmarkWorker (existing)
                    BodReportWorker (NEW) — runs nightly
                                │
                                ▼
                    [PostgreSQL — AppDbContext]
```

---

## 2. Current Codebase Reality

<forensic_evidence>

### Commands Executed

- `list_dir c:\Users\HP\Documents\GitHub\Checkly\server\Features\Analytics` → 9 files confirmed
- `view_file server/Features/Analytics/GetAnalytics.cs` → 239 lines, role-tenanted, computes 5 KPIs + trend + section + insights + radar
- `view_file server/Features/Analytics/Dtos.cs` → 42 lines — existing contracts
- `view_file server/Features/Analytics/InsightGeneratorService.cs` → 5 rules, 3-insight cap
- `view_file server/Features/Analytics/GetTopFailures.cs` → template-scoped, 20 results max — **EXISTS but has no Flutter UI**
- `view_file server/Features/Analytics/GetMyStats.cs` → auditor personal stats — **EXISTS but surfaces only in dashboard, not analytics page**
- `view_file lib/features/analytics/manager/analytics_manager.dart` → 210 lines, API + Drift fallback
- `view_file lib/features/analytics/manager/analytics_data.dart` → 96 lines — AnalyticsData, RadarData, ActionableInsight
- `view_file lib/features/analytics/pages/analytics_body.dart` → 207 lines — KPI grid, TrendChart, CategoryHeatmap, InsightCards, RadarChart
- `view_file lib/features/analytics/widgets/analytics_kpi_card.dart` → 72 lines — simple icon+number card
- `view_file lib/features/analytics/widgets/trend_chart.dart` → 196 lines — fl_chart line chart
- `view_file lib/features/analytics/widgets/insights_radar_chart.dart` → 147 lines — fl_chart radar
- `view_file lib/features/analytics/widgets/category_heatmap.dart` → 138 lines — 2×2 color cells
- `view_file server/Features/Analytics/ProvinceBenchmarkCalculator.cs` → 138 lines — 3-query pattern, produces province-level benchmark snapshots

</forensic_evidence>

### What Already Exists

| Component | Location | Status |
|---|---|---|
| KPI Cards (5 metrics) | `analytics_kpi_card.dart` | ✅ Exists — needs delta % |
| Line Trend Chart (6-month) | `trend_chart.dart` | ✅ Exists — extend to dual-axis area |
| Category 2×2 Heatmap | `category_heatmap.dart` | ✅ Exists — replace with real heatmap bars |
| Insight Cards (3 max) | `insight_card.dart` | ✅ Exists — extend rules |
| Radar Chart (store vs region) | `insights_radar_chart.dart` | ✅ Exists — keep |
| Province benchmark calculator | `ProvinceBenchmarkCalculator.cs` | ✅ Exists — extend for BOD |
| Top failures endpoint | `GetTopFailures.cs` | ✅ Exists — **NO Flutter UI** |
| Auditor personal stats endpoint | `GetMyStats.cs` | ✅ Exists — **NOT on analytics page** |
| Filters (store/province/type/date) | `analytics_filter_chips.dart` | ✅ Exists |
| Offline fallback | `analytics_drift_loader.dart` | ✅ Exists |
| Store leaderboard | — | ❌ Missing |
| Geographic map | — | ❌ Missing |
| AP aging funnel | — | ❌ Missing |
| Auditor productivity scatter | — | ❌ Missing |
| Period-over-period delta | — | ❌ Missing |
| Score histogram | — | ❌ Missing |
| BOD summary view | — | ❌ Missing |
| Program compliance gauges | — | ❌ Missing |

---

## 3. E2E Workflow Map

```
[User opens Analytics Tab]
        │
        ▼
[Role Check (PBAC via JWT claims)]
        │
   ┌────┴─────────────────────┬────────────────────────┐
   │                          │                        │
   ▼                          ▼                        ▼
[admin]                [area_manager /         [auditor]
   │                   store_manager]               │
   ▼                          │                        ▼
[BodAnalyticsPage]     [AnalyticsPage]         [MyStatsPage]
   │                  (existing today)          (existing today)
   │                          │                only in dashboard
   ▼                          ▼
[GET /api/analytics/bod]  [GET /api/analytics]
   │                          │
   ▼                          ▼
[BodReportSnapshot]    [GetAnalytics.cs]
(pre-computed nightly) (existing, real-time)
   │
   ▼
[BOD Dashboard Sections]
   ├── [Chain KPI Summary Row — 6 metrics with delta vs prior period]
   ├── [Score Trend — Area Chart with audit count dual axis]
   ├── [Province Performance — Grouped Column Chart]
   ├── [Store Leaderboard — Ranked Horizontal Bar Chart]
   ├── [Category Weakness — Sorted Horizontal Bar with threshold line]
   ├── [Top Failures — Horizontal Bar Chart by fail rate %]
   ├── [AP Aging Funnel — Funnel Chart]
   ├── [Auditor Scatter — Volume vs Score quadrant]
   ├── [Program Compliance — Liquid/Progress gauges]
   └── [Insight Engine — AI-assisted recommendations (expandable rules)]
```

### State Machine for BOD Snapshot Worker

```
[Scheduler Trigger — nightly 02:00 UTC]
          │
          ▼
[BodReportWorker.ExecuteAsync()]
          │
          ├── Query 1: Chain-wide KPIs (total, avg, completion, APs) ─── current + prior period
          │
          ├── Query 2: Per-province avg score + audit count ─────────── last 30d + prior 30d
          │
          ├── Query 3: Store rankings (top 10 / bottom 10) ─────────── last 30d avgScore
          │
          ├── Query 4: Category weakness aggregation ──────────────── last 90d sectionScores
          │
          ├── Query 5: AP aging buckets (0-7d, 8-30d, 31-90d, 90d+) ─ open APs only
          │
          ├── Query 6: Auditor productivity (count vs avgScore) ─────── last 30d
          │
          └── UPSERT BodReportSnapshot (single row — chain-wide)
                        │
                        ▼
               [BodReportSnapshot saved to DB]
                        │
                        ▼
               [GET /api/analytics/bod returns snapshot JSON]
                        │
                        ▼
               [Flutter BodAnalyticsPage renders charts]
```

---

## 4. Comparative Decision Matrix

| Aspect | Option A: Extend Current Screen | Option B: Separate BOD Page + New Endpoints | Option C: External BI Tool |
|---|---|---|---|
| **Pattern** | Single screen overload | Hierarchical Ledger, role-projected | External system (Metabase/PowerBI) |
| **Effort** | Low (weeks) | Medium (2-3 sprints) | High (new infrastructure) |
| **BOD Presentation Quality** | Poor (scroll-heavy, cramped) | High (full-screen, tabbed, printable) | Very High (if configured) |
| **Offline Support** | Partial (Drift fallback) | Online-only for BOD snapshot | None |
| **Role Isolation** | Shared page, filter-gated | Hard page separation by role | N/A |
| **Maintenance Cost** | Low (one codebase) | Medium (two pages) | High (separate tool, license) |
| **Existing Code Reuse** | High | Medium (reuse widgets, new endpoints) | None |
| **GEMINI.md Compliance** | Risk (file > 400 lines) | Clean (new files per role) | N/A |
| **Verdict** | ❌ Reject — not BOD-worthy | ✅ **Recommended** | ❌ Reject — out of scope |

---

## 5. UI Component Routing Table

| Component | Overflow Limit | Drill-Down Target |
|---|---|---|
| Chain KPI Summary | 6 KPIs max | Tap → filter analytics page by KPI |
| Score Trend (Area Chart) | 12 months max | Tap month → activity list for that month |
| Province Columns | 20 provinces max (scroll) | Tap province → analytics filtered to province |
| Store Leaderboard | Top 10 + Bottom 10 | Tap store → analytics filtered to store |
| Category Weakness Bar | 15 categories max | Tap category → top failures for that category |
| Top Failures Bar | Top 10 by fail rate | Tap criterion → audit list with that failure |
| AP Aging Funnel | 4 fixed buckets | Tap bucket → action plans filtered by age |
| Auditor Scatter | 50 auditors max (label on hover) | Tap auditor → auditor's submission list |
| Program Compliance | Active programs only (max 5 shown) | Tap program → program detail page |
| Insights Panel | 5 max, expandable | Tap → deep link per insight type |

---

## 6. Phase-by-Phase Build Plan

### Phase 1: Server — BOD Snapshot Infrastructure (Track C — Full)

**Files to CREATE:**
- `server/Features/Analytics/BodReportSnapshot.cs` — Entity (AppDbContext migration required)
- `server/Features/Analytics/BodReportWorker.cs` — Hosted service, nightly schedule
- `server/Features/Analytics/BodReportCalculator.cs` — 6-query aggregation logic
- `server/Features/Analytics/GetBodReport.cs` — Admin-only endpoint projecting snapshot
- `server/Features/Analytics/BodReportDtos.cs` — Chain KPIs + Store Rankings + Category + AP Aging + Auditor Productivity

**Files to MODIFY:**
- `server/Program.cs` — Register BodReportWorker, map GET /api/analytics/bod
- `server/migrations/` — EF Core migration for BodReportSnapshot table
- `server/Features/Analytics/Dtos.cs` — Add `ChainKpis` record with delta fields

### Phase 2: Server — Extend Existing Endpoints

**Files to MODIFY:**
- `server/Features/Analytics/GetAnalytics.cs` — Add `periodDelta` fields to KPIs (current vs prior period)
- `server/Features/Analytics/InsightGeneratorService.cs` — Add 3 new rules: trend reversal, auditor outlier, program non-compliance
- `server/Features/Analytics/GetTopFailures.cs` — Remove templateId requirement for admin scope (allow chain-wide)

### Phase 3: Flutter — BOD Page

**Files to CREATE:**
- `lib/features/analytics/pages/bod_analytics_page.dart` — Admin-only tabbed page (Summary / Stores / Categories / People / Programs)
- `lib/features/analytics/manager/bod_analytics_manager.dart` — Calls /api/analytics/bod, no offline fallback
- `lib/features/analytics/manager/bod_analytics_data.dart` — Data classes for BOD snapshot
- `lib/features/analytics/services/bod_analytics_api_service.dart` — HTTP calls
- `lib/features/analytics/widgets/store_leaderboard_chart.dart` — Ranked horizontal bar chart
- `lib/features/analytics/widgets/ap_aging_funnel.dart` — Funnel chart (fl_chart BarChart stacked)
- `lib/features/analytics/widgets/auditor_scatter_chart.dart` — Scatter (fl_chart ScatterChart)
- `lib/features/analytics/widgets/score_histogram.dart` — Histogram (fl_chart BarChart grouped)
- `lib/features/analytics/widgets/program_compliance_gauge.dart` — Liquid/radial progress
- `lib/features/analytics/widgets/period_delta_kpi_card.dart` — KPI card with delta ▲▼ % indicator

**Files to MODIFY:**
- `lib/features/analytics/widgets/trend_chart.dart` — Extend to dual-axis area (score + audit count)
- `lib/features/analytics/widgets/category_heatmap.dart` — Replace 2×2 grid with sorted horizontal bars
- `lib/router/router.dart` — Add /analytics/bod route, guard with admin PBAC check
- `lib/features/analytics/pages/analytics_body.dart` — Add "top failures" section (consuming existing endpoint)
- `lib/_shared/navigation/` — Add BOD Analytics navigation entry for admin role

### Phase 4: Flutter — Enhanced Existing Analytics Page

**Files to MODIFY:**
- `lib/features/analytics/manager/analytics_data.dart` — Add `periodDelta` to KPI fields
- `lib/features/analytics/widgets/analytics_kpi_card.dart` — Add delta badge (▲3.2% / ▼1.5%)
- `lib/features/analytics/pages/analytics_body.dart` — Wire `GetTopFailures` UI for store manager view

---

## 7. New Server DTOs Required

```csharp
// BodReportDtos.cs

public sealed record ChainKpis(
    int TotalAudits,
    double AvgScore,
    double AvgScoreDelta,       // vs prior period
    int OpenAPs,
    int OverdueAPs,
    double CompletionRate,
    double CompletionRateDelta,
    int ActiveStores,
    int TotalAuditors);

public sealed record StoreRankEntry(
    string StoreName,
    string Province,
    double AvgScore,
    int AuditCount,
    int Rank);

public sealed record ApAgingBucket(
    string Label,               // "0-7 days", "8-30 days", etc.
    int Count);

public sealed record AuditorProductivity(
    string AuditorName,
    int AuditCount,
    double AvgScore);

public sealed record BodReportResponse(
    ChainKpis ChainKpis,
    List<TrendPoint> Trend,     // Reuse existing TrendPoint
    List<StoreRankEntry> TopStores,
    List<StoreRankEntry> BottomStores,
    List<SectionScore> CategoryBreakdown,
    List<ApAgingBucket> ApAging,
    List<AuditorProductivity> AuditorProductivity,
    DateTimeOffset SnapshotAt);
```

---

## 8. Blind Spots

1. **Query Cost at Scale**: The `BodReportCalculator` runs 6 GroupBy queries across all submissions. At 10,000+ submissions, Query 6 (auditor productivity) will hit a full table scan. **Mitigation**: Index `(AuditorId, Status, CreatedAt)` on the Submissions table, and enforce the 30-day window strictly.

2. **Offline Exclusion for BOD Page**: The BOD snapshot cannot be derived from a single device's local Drift cache. The new `BodAnalyticsManager` MUST explicitly NOT implement an offline fallback and must show a clear "Requires internet connection" state instead of silently returning zeros. Failure to do this violates the UX principle of honest empty states.

3. **Chart Library Constraints (fl_chart)**: `fl_chart` is excellent for line/bar/radar/scatter but has limited support for funnel charts and geographic maps. **Mitigation**: The AP Aging "funnel" will be implemented as a stacked horizontal bar chart with decreasing widths to simulate a funnel. Geographic visualization will use a static SVG province outline map with color overlays, not a full map library, to avoid a new package dependency.

---

## 9. Rules Conflicts

1. **GEMINI.md Gotcha — Hardcoded Role Filtering**: The BOD page must NOT be gated with `if (role == 'admin')` on the Flutter side. Navigation visibility to the BOD analytics route must come from the backend's `allowedActions` on the relevant DTO, following the HATEOAS pattern. Backend already forbids non-admin access to `GetBodReport.cs` via the role check — Flutter must respect `allowedActions: ["view_bod_analytics"]` from the user profile DTO.

2. **File Size Rule (400 lines max)**: `GetAnalytics.cs` is already at 239 lines with current features. Adding delta KPI logic will push it past 300 lines. Phase 2 modifications must extract delta computation into `KpiDeltaCalculator.cs` (static class, similar pattern to `InsightGeneratorService.cs`).

---

## Handoff Block

**Final Verdict**: ✅ VIABLE — Recommended as Option B (Separate BOD Page + New Endpoints).

**Persistent Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260524_135800_bod_analytics.md`

**Effort Sizing**: Track C (Full Enterprise Feature) — Estimated 3 sprints:
- Sprint 1: Server infrastructure (Phase 1 + Phase 2) — 5 backend files
- Sprint 2: Flutter BOD page + widgets (Phase 3) — 10 Flutter files
- Sprint 3: Existing page enhancements + integration testing (Phase 4) — 4 Flutter files

**Concurrency Strategy**: Server sprint can run in parallel with BOD widget prototyping. Wire up after endpoint is live.

**AI Agent Mission Brief**: Build a BOD-grade analytics system for Checkly by (1) adding a nightly `BodReportWorker` that pre-computes chain-wide snapshots (store rankings, AP aging, auditor productivity), (2) exposing a new admin-only `GET /api/analytics/bod` endpoint, and (3) creating a new `BodAnalyticsPage` in Flutter with 5 chart types (area trend, ranked bars, funnel, scatter, gauges) using the existing `fl_chart` dependency. Keep the existing `AnalyticsPage` for store managers — this is additive, not a replacement.

**Next Step**: Run the following workflow with this artifact as input:

```
/analyze-epic C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260524_135800_bod_analytics.md
```

This will slice the work into vertical, testable user stories before implementation begins.
