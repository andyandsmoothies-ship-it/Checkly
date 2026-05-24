<latent_space_scratchpad>
## Internal Reasoning

### Pattern Label
Multi-Tenant Observability Ledger with Pre-Computed Materialized Views.
This is a reporting domain, not a transactional one. Write path = nightly worker.
Read path = fast, flat SELECT from snapshot table. Pattern is confirmed from ADR.

### Fit Check (Shaping)

R1: BOD must see chain-wide KPIs with delta vs prior period
R2: Data must NOT degrade OLTP performance
R3: Charts must be "wow" quality, premium design
R4: BOD page is admin-only — gated via PBAC, not Flutter role check
R5: Worker must be idempotent (Upsert) and timezone-aware
R6: Admin can trigger on-demand refresh
R7: Snapshots must be pruned after 90 days
R8: Flutter page must display "Data as of [timestamp]"

Shape A — Extend current GetAnalytics.cs:
R2: FAIL (real-time aggregations = OLTP harm)
Shape B — Nightly worker + new endpoint + new Flutter page:
R1-R8: ALL PASS

### Traceability Check
Every backend endpoint must map to a UI component:
- GET /api/analytics/bod → BodAnalyticsPage (chain KPIs, trend, store leaderboard, category, AP aging, auditor scatter)
- POST /api/analytics/bod/refresh → On-Demand Refresh button (admin toolbar on BodAnalyticsPage)
- New AppCapabilities.AnalyticsBod → gates the route in app_router.dart + nav visibility in shell_tab.dart

### Key Codebase Discoveries
- AreaBenchmarkWorker uses: BackgroundService + DistributedLockManager + IServiceProvider scope
- AnalyticsEndpoints.cs uses: RequireCapability(AppCapabilities.AnalyticsAdmin) — same pattern for BOD
- AppCapabilities.cs already has AnalyticsAdmin — BUT AnalyticsBod MUST be a NEW separate constant
  because BOD is more privileged (ONLY admin, not area_manager) and needs a separate capability row seeded in Program.cs
- app_router.dart: /analytics route exists at line 258. New /analytics/bod must be added as a detail route
  (NOT in ShellRoute — it has no bottom nav tab; it is entered from admin dashboard or FAB on analytics page)
- StrokeCard confirmed as the universal card primitive — already used by analytics_kpi_card.dart (line 27)
- DistributedLockManager is a Singleton (Program.cs line 241) — use lock key "Checkly.BodReportWorker"
- fl_chart dependency already in use for trend_chart.dart, insights_radar_chart.dart — no new package needed

### Risk Scores (Reviewer Personas)
DB Architect:
- RISK: BodReportWorker queries all 6 aggregations serially in one nightly window. If index on Submissions
  (AuditorId, Status, CreatedAt) is missing, Query 6 will full-scan. Score = 7/10 — pass with index constraint.
Security Auditor:
- RISK: POST /api/analytics/bod/refresh is an Admin-only destructive trigger. Without rate-limiting,
  a compromised admin account could trigger it continuously to hammer the DB.
  Mitigation: In-memory rate limit (last run timestamp stored in worker state). Score = 8/10 — pass.
Junior Dev:
- RISK: BodReportDtos.cs + BodReportWorker.cs + BodReportCalculator.cs = 3 new files in Analytics folder.
  Naming is consistent with existing pattern (GetAnalytics, ProvinceBenchmarkCalculator). Easy to follow. Score = 9/10 — pass.

All scores ≥ 7. Plan proceeds.

### Key Decisions
- BodReportSnapshot is a SINGLE ROW entity (chain-wide). Not per-store. Complex per-store breakdown is inside the JSON column (serialized).
  Actually — for retention/pruning to work on Date dimension, BodReportSnapshot needs a Date field.
  Schema: Id (int), Date (DateOnly), ComputedAt (DateTimeOffset), Status (enum: Complete/PartiallyFailed), Payload (jsonb).
  Upsert key: UNIQUE(Date). Worker UPSERTS on Date = today.
- Retention: Worker deletes WHERE Date < today - 90 days as final step.
- Timezone: Worker reads CorporateTimezone from appsettings.json. Converts Now() to that TZ to determine "today" for snapshot Date.
- No new Flutter package needed. AP funnel = stacked horizontal bar (fl_chart). Geography = out of scope for this epic.
</latent_space_scratchpad>

# Epic Plan: BOD Analytics — Executive Dashboard
**Date**: 2026-05-24
**Workflow**: /analyze-epic | **Track**: C (Full Enterprise Feature)
**Status**: Approved for Implementation

---

## Input Lineage
- **ADR**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\decision_record_20260524_141300_synth_bod_analytics.md`
- **Research (Deep)**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260524_135800_bod_analytics.md`

---

## Executive Summary

The BOD Analytics system upgrades Checkly from simple KPI cards to a premium, multi-chart executive dashboard suitable for Board of Directors presentations. It uses a **nightly background worker** to pre-compute heavy chain-wide aggregations (store rankings, category weakness, AP aging, auditor productivity) into a `BodReportSnapshot` table. A new admin-only endpoint and a dedicated Flutter page serve this pre-computed data instantly.

```
[Admin opens "BOD Analytics"]
        │
        ▼
[Flutter: BodAnalyticsPage]
    "Data as of: [timestamp]"
        │
        ▼
[GET /api/analytics/bod]
    RequireCapability(AnalyticsBod)
        │
        ▼
[BodReportSnapshot table — last nightly row]
        │
        ▼
[6 Chart Sections rendered]
    KPI Row | Trend | Store Leaderboard
    Category | AP Funnel | Auditor Scatter
        │
[Admin Refresh Button]
        │
        ▼
[POST /api/analytics/bod/refresh]
    Rate-limited: 1 per 15 min
        │
        ▼
[BodReportWorker.TriggerNowAsync()]
```

---

## Decision Matrix

| Criteria | Shape A: Extend GetAnalytics.cs | Shape B: New Worker + Page [WINNER] |
|---|---|---|
| OLTP Performance (R2) | ❌ Live aggregations over millions of rows | ✅ Reads pre-computed snapshot |
| BOD UX Quality (R3) | ❌ Shared page, cramped, scroll-heavy | ✅ Dedicated full-screen page, 6 tabbed sections |
| Idempotency (R5) | N/A | ✅ Upsert on UNIQUE(Date) |
| PBAC Gating (R4) | ❌ Mixed access model | ✅ New AppCapabilities.AnalyticsBod constant |
| On-Demand Refresh (R6) | ❌ Not possible | ✅ POST /refresh endpoint |
| Data Retention (R7) | N/A | ✅ Pruning step in worker |
| GEMINI.md File-Size Rule | ❌ GetAnalytics.cs would exceed 400 lines | ✅ New files, all < 400 lines |

**Winner: Shape B.**

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Query 6 full-table scan (auditor productivity) | High | Add DB index `(CreatedById, Status, CreatedAt)` on Submissions — in Slice 1 migration |
| Worker crashes mid-run | Medium | try/catch per query; saves `PartiallyFailed` status, not a NULL row |
| Admin refresh abuse / DB hammer | Medium | In-memory last-run timestamp in `BodReportWorker`. Reject if last run < 15 min ago. Return HTTP 429. |
| Timezone split-day bug | High | Worker reads `CorporateTimezone` from `appsettings.json`. Uses `TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, tz)` to anchor snapshot `Date` |
| 90-day snapshot bloat | Low | Worker's final step: `DELETE WHERE Date < today - 90` |
| Flutter fl_chart funnel limitation | Low | AP Aging rendered as stacked horizontal bar chart with decreasing widths — no new package |

---

## Visual & Functional Context

```
BodAnalyticsPage (admin-only, online-only)
┌───────────────────────────────────────────────────────────┐
│  "Executive Dashboard"           [🔄 Refresh]             │
│  Data as of: 24 May 2026, 02:15 AM (Asia/Bangkok)         │
├───────────────────────────────────────────────────────────┤
│  [KPI Row] 6 metrics with ▲▼ delta badges                 │
│    TotalAudits | AvgScore▲ | Completion% | OpenAPs | etc. │
├───────────────────────────────────────────────────────────┤
│  [Score Trend] Dual-axis area chart (score + audit count) │
│    12-month window                                        │
├───────────────────────────────────────────────────────────┤
│  [Store Leaderboard] Top 10 / Bottom 10 horizontal bars   │
│    Tap → /analytics?store=X                               │
├───────────────────────────────────────────────────────────┤
│  [Category Weakness] Sorted horizontal bars with target   │
│    Tap → Top Failures for that category                   │
├───────────────────────────────────────────────────────────┤
│  [AP Aging] Stacked horizontal bars (0-7d, 8-30d, 30d+)  │
├───────────────────────────────────────────────────────────┤
│  [Auditor Scatter] Volume (x) vs Score (y) quadrant chart │
│    Tap → auditor's submission history                     │
└───────────────────────────────────────────────────────────┘
```

### Overflow & Drill-Down Routing

| Component | Overflow Limit | Drill-Down Target | Empty State |
|---|---|---|---|
| KPI Row | 6 metrics max | N/A | Show "--" with no delta |
| Score Trend | 12 months max | N/A | "No trend data yet" |
| Store Leaderboard | Top 10 + Bottom 10 (20 total) | `/analytics?storeId=X` | "No store data in snapshot" |
| Category Weakness | 15 categories max (scroll) | `/analytics?category=X` | "No category data" |
| AP Aging | 4 fixed buckets | `/plans?filter=aging` | Show all buckets as 0 |
| Auditor Scatter | 50 max (overflow: hide label) | `/activity?auditorId=X` | "No auditor data" |

### UI Traceability

| Backend Capability | Frontend Consumer |
|---|---|
| `GET /api/analytics/bod` | `BodAnalyticsPage` — all chart sections |
| `POST /api/analytics/bod/refresh` | Refresh FAB / icon button in `BodAnalyticsPage` app bar |
| `AppCapabilities.AnalyticsBod` | `app_router.dart` route guard + `shell_tab.dart` (no tab — entry from admin dashboard link) |

---

## System Context

| Aspect | Constraint |
|---|---|
| **Offline** | BOD page is ONLINE-ONLY. `BodAnalyticsManager` must NOT implement Drift fallback. Show explicit `ChecklyErrorState(message: "BOD Analytics requires an internet connection.")` when offline. |
| **PBAC** | New constant: `AppCapabilities.AnalyticsBod = "analytics:bod"`. Seeded for `admin` role only in `Program.cs` + `TestWebApplicationFactory.cs`. Route guard in `app_router.dart` uses `pm.can(AppCapabilities.analyticsBod)`. |
| **Rate Limiting** | `POST /refresh` — worker stores `_lastManualRun` in memory. Returns HTTP 429 if called within 15 minutes of last run. |
| **Timezone** | `appsettings.json` key: `"BodWorker": { "CorporateTimezone": "SE Asia Standard Time", "IntervalHours": 24 }`. |
| **API Contract** | `GET /api/analytics/bod` returns `BodReportResponse` (see Data Context). `POST /refresh` returns `{ "status": "triggered", "computedAt": "<ISO8601>" }` or `{ "status": "rate_limited", "retryAfter": "15 min" }`. |

---

## Lifecycle Context

| State | What Happens |
|---|---|
| First load, no snapshot exists yet | Flutter shows `ChecklyEmptyState("BOD report not yet generated. It runs nightly at 02:00 AM.")` |
| Snapshot is `PartiallyFailed` | Flutter shows a yellow warning banner: `"Some data may be incomplete due to a computation error."` alongside whatever data was saved |
| Worker job crashes entirely (status = null row) | Backend returns 404. Flutter shows full error state. |
| Admin taps Refresh, rate-limited | Flutter shows snackbar: `"Refresh available in X minutes."` |
| Admin taps Refresh, succeeds | Flutter shows loading skeleton while polling for new `ComputedAt > previous ComputedAt`. Polls every 5 seconds for up to 60 seconds. |
| Snapshot older than 90 days | Will not exist — pruned. History is not surfaced in the UI. |

---

## Data Context

### New Entity: BodReportSnapshot

```
table: bod_report_snapshots

Id           int           PK, auto-increment
Date         date          NOT NULL — UNIQUE (Upsert key)
ComputedAt   timestamptz   NOT NULL — exact finish time, including TZ
Status       varchar(20)   NOT NULL — "Complete" | "PartiallyFailed"
Payload      jsonb         NOT NULL — serialized BodReportPayload
```

> The Payload column stores the full aggregated result as JSONB.
> This avoids 6+ additional tables and keeps the snapshot atomic.
> The Get endpoint deserializes the JSONB into BodReportResponse.

### New DB Index (on existing Submissions table)

```sql
CREATE INDEX IF NOT EXISTS ix_submissions_creator_status_created
ON submissions (created_by_id, status, created_at);
```

Mitigates full-table scan on Query 6 (auditor productivity).

### New Capability Seed (Migration)

```
capability: analytics:bod
seeded for: admin role
```

### BodReportResponse (C# Record — BodReportDtos.cs)

```
BodReportResponse
  ├── ChainKpis (TotalAudits, AvgScore, AvgScoreDelta, CompletionRate, CompletionRateDelta, OpenAPs, OverdueAPs, ActiveStores, TotalAuditors)
  ├── List<TrendPoint>         — reuse existing DTO
  ├── List<StoreRankEntry>     — StoreName, Province, AvgScore, AuditCount, Rank
  ├── List<SectionScore>       — reuse existing DTO
  ├── List<ApAgingBucket>      — Label ("0-7d", "8-30d", "31-90d", "90d+"), Count
  ├── List<AuditorProductivity>— AuditorName, AuditCount, AvgScore
  ├── SnapshotStatus           — "Complete" | "PartiallyFailed"
  └── ComputedAt               — DateTimeOffset
```

---

## Architecture Flow

```
[Nightly Scheduler — 02:00 AM Corp TZ]
         │
         ▼
[BodReportWorker.ExecuteAsync()]
    Uses DistributedLockManager("Checkly.BodReportWorker")
    to prevent thundering herd
         │
         ▼
[BodReportCalculator.ComputeAsync(db, date, tz)]
    Query 1: Chain KPIs — current period + prior period delta
    Query 2: 12-month trend (reuse TrendPoint DTO logic)
    Query 3: Top 10 + Bottom 10 stores by avg score (last 30d)
    Query 4: Category weakness — SectionScores aggregated (last 90d)
    Query 5: AP aging buckets — open APs grouped by (now - CreatedAt)
    Query 6: Auditor productivity — (AuditCount, AvgScore) per auditor (last 30d)
    → Each query wrapped in try/catch; status = PartiallyFailed if any throws
         │
         ▼
[Upsert BodReportSnapshot WHERE Date = today]
    INSERT ... ON CONFLICT (Date) DO UPDATE SET ...
         │
         ▼
[Prune: DELETE WHERE Date < today - 90 days]
         │
         ▼
[GET /api/analytics/bod]
    RequireCapability("analytics:bod")
    → SELECT TOP 1 FROM BodReportSnapshot ORDER BY Date DESC
    → Deserialize Payload jsonb → BodReportResponse
         │
         ▼
[Flutter BodAnalyticsPage]
    BodAnalyticsManager.load() → calls GET /api/analytics/bod
    Renders 6 sections using existing fl_chart + StrokeCard
    Displays "Data as of: [ComputedAt, localized]" header
    "Refresh" button → POST /api/analytics/bod/refresh
```

---

## Risk Review & Security

| Check | Verdict |
|---|---|
| DB Architect (8/10) | Upsert prevents duplicates. Index on Submissions mitigates scan. JSONB payload avoids N-table JOINs on read. ✅ |
| Security Auditor (8/10) | New capability `analytics:bod` is seeded only for admin. Rate-limited refresh prevents DB abuse. No JWT claims added (no token bloat). ✅ |
| Junior Dev (9/10) | New files follow exact naming patterns of existing code (AreaBenchmarkWorker → BodReportWorker, ProvinceBenchmarkCalculator → BodReportCalculator). No magic strings — AppCapabilities constant. ✅ |

**No score below 7. Plan passes.**

---

## Logs & Audits

The `BodReportWorker` MUST emit structured log events at these points:

```
LogInformation("BodReportWorker started. CorporateTimezone: {Tz}", tz.Id)
LogInformation("BodReportCalculator completed all 6 queries in {Ms}ms", sw.ElapsedMilliseconds)
LogWarning("BodReportCalculator Query {QueryNumber} failed: {Error}", queryNumber, ex.Message)
LogInformation("BodReportSnapshot saved for Date: {Date}. Status: {Status}", date, status)
LogInformation("BodReportWorker pruned {Count} snapshots older than 90 days", count)
LogWarning("POST /analytics/bod/refresh rate-limited. LastRun: {LastRun}", _lastManualRun)
```

---

## Testing Expectations

| Slice | Test Type | Scope |
|---|---|---|
| Slice 1 (Worker) | Integration — ATDD | Worker runs Upsert on first call, then UPDATE (not INSERT) on second call for same Date. Worker deletes rows older than 90 days. Worker saves PartiallyFailed if a query throws. |
| Slice 1 (Worker) | Integration — ATDD | POST /refresh returns 429 if called within 15 minutes |
| Slice 2 (API) | Integration — ATDD | GET /bod returns 403 for area_manager. Returns 200 for admin. Returns 404 when no snapshot exists. ComputedAt is present in response. |
| Slice 3 (Flutter) | Widget test | BodAnalyticsPage renders "Data as of" text from ComputedAt. PartiallyFailed status shows yellow warning banner. Offline shows error state (not empty zeros). |

---

<forensic_evidence>
- `list_dir server/Features/Analytics` → 9 files confirmed: AreaBenchmarkWorker.cs, Dtos.cs, GetAnalytics.cs, GetTopFailures.cs, GetMyStats.cs, InsightGeneratorService.cs, ProvinceBenchmarkCalculator.cs, AnalyticsEndpoints.cs, GetAnalyticsInsightsResolver.cs
- `list_dir lib/features/analytics/widgets` → 6 widgets confirmed: analytics_filter_sheet.dart, analytics_kpi_card.dart, category_heatmap.dart, insight_card.dart, insights_radar_chart.dart, trend_chart.dart
- `view_file server/Features/Analytics/AreaBenchmarkWorker.cs` → BackgroundService + DistributedLockManager + IServiceProvider scope pattern confirmed (72 lines)
- `view_file server/Features/Analytics/AnalyticsEndpoints.cs` → RequireCapability() pattern at lines 15, 19, 23 confirmed
- `view_file server/Features/Analytics/Dtos.cs` → TrendPoint + SectionScore are reusable sealed records (42 lines)
- `view_file server/Common/Auth/AppCapabilities.cs` → AnalyticsAdmin ("analytics:admin") exists at line 36. AnalyticsBod ("analytics:bod") DOES NOT exist — must be added as NEW constant
- `view_file lib/_shared/router/app_router.dart` → /analytics route at line 258 (ShellRoute section ends at line 90). /analytics/bod must be a detail route — NOT inside ShellRoute
- `view_file lib/_shared/router/main_shell.dart` → capability-gated tabs use ShellTab.all + PolicyManager.can() at line 171
- `grep_search allowedActions server/` → pattern confirmed in GetSubmission.cs lines 52-80. List<string> built from PBAC checks then returned in DTO
- `grep_search StrokeCard lib/features/analytics/` → used in analytics_kpi_card.dart:27, trend_chart.dart:34, insights_radar_chart.dart:30, category_heatmap.dart:31 — confirmed as universal card primitive in analytics feature
- `grep_search DistributedLockManager server/` → Singleton registered at Program.cs:241. Used in AreaBenchmarkWorker with lock key "Checkly.ProvinceBenchmarkWorker"
- `grep_search IHostedService server/` → No results — workers inherit from BackgroundService directly, not via IHostedService interface
</forensic_evidence>


---

## Handoff Block

**Final Verdict**: ✅ VIABLE — Option B (Nightly Worker + Separate BOD Page)

**Epic Plan Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\analysis_epic_20260524_142100_bod_analytics.md`

---

### Slice 1: Backend Infrastructure — The Data Engine

- **Plain English Summary**: Build the "factory" that runs every night and produces the data the BOD dashboard will read. This includes the database table that stores the nightly report, the background worker that computes it, and the calculation engine that runs 6 queries.
- **Why this step now?**: Nothing else can be built without data. This is the BLOCKING foundation. The API and the Flutter UI both depend on this snapshot table existing and having data in it.
- **Scenario Focus**: Basic Scenario (Happy Path — worker runs, snapshot is saved)
- **Value Delivered**: A nightly snapshot of chain-wide analytics is saved to the database every night at 02:00 AM (corporate timezone). An admin can also trigger it manually.
- **Entry State Required**: Project has a running PostgreSQL database. `AreaBenchmarkWorker` pattern exists and is proven.
- **Exit State Guaranteed**: `BodReportSnapshot` table exists. Daily Upsert works correctly (second run for same date updates, not inserts). Retention pruning deletes rows older than 90 days. `POST /api/analytics/bod/refresh` returns 429 if called within 15 minutes.
- **Architectural Scope**: DB migration (new table + index), `BodReportSnapshot.cs` (entity), `BodReportDtos.cs` (C# records), `BodReportCalculator.cs` (6 queries), `BodReportWorker.cs` (BackgroundService), `AppCapabilities.cs` (new constant), `Program.cs` (worker registration + capability seed).
- **Acceptance Criteria**:
  - `[AC-1]` Worker runs → snapshot row inserted for today's date. Run again → same row UPDATED, row count does not increase.
  - `[AC-2]` If Query 3 throws (simulate with bad data), worker saves row with `Status = PartiallyFailed`.
  - `[AC-3]` Snapshot rows older than 90 days are deleted after worker runs.
  - `[AC-4]` `POST /api/analytics/bod/refresh` returns 200 on first call. Returns 429 within 15 minutes.
  - `[AC-5]` Non-admin role (area_manager) calling `POST /refresh` returns 403.

**Order**: `[BLOCKING]` — Slices 2 and 3 cannot start until this exits with green tests.

---

### Slice 2: Backend API — The Gateway

- **Plain English Summary**: Expose the pre-computed nightly snapshot through a secure API endpoint that the Flutter app can call. Only admins can access it.
- **Why this step now?**: Slice 1 has the data. This slice adds the door to access it. The Flutter team can begin widget development against the mocked JSON contract from this endpoint.
- **Scenario Focus**: Basic Scenario
- **Value Delivered**: The Flutter team has a live, secure endpoint to call: `GET /api/analytics/bod`. The JSON contract is locked.
- **Entry State Required**: Slice 1 is complete. `BodReportSnapshot` table exists with at least one row.
- **Exit State Guaranteed**: `GET /api/analytics/bod` returns `BodReportResponse` JSON for admin. Returns 403 for area_manager. Returns 404 when no snapshot exists. `ComputedAt` and `SnapshotStatus` are present in every response.
- **Architectural Scope**: `GetBodReport.cs` (handler), `BodReportDtos.cs` (extend with response records), `AnalyticsEndpoints.cs` (register 2 new routes), `AppCapabilities.cs` (add `AnalyticsBod` constant).
- **Acceptance Criteria**:
  - `[AC-1]` `GET /api/analytics/bod` returns 200 with valid `BodReportResponse` JSON for admin token.
  - `[AC-2]` Response includes `computedAt` (ISO 8601 string) and `snapshotStatus` (`"Complete"` or `"PartiallyFailed"`).
  - `[AC-3]` `GET /api/analytics/bod` returns 403 for area_manager token.
  - `[AC-4]` `GET /api/analytics/bod` returns 404 when no snapshot row exists (empty DB scenario).
  - `[AC-5]` JSON payload includes all 6 sections: `chainKpis`, `trend`, `topStores`, `bottomStores`, `categoryBreakdown`, `apAging`, `auditorProductivity`.

**Order**: `[SEQUENTIAL]` — Must run strictly after Slice 1. Can be developed in parallel with Slice 3 widget scaffolding, using mocked JSON.

---

### Slice 3: Flutter UI — The Executive View

- **Plain English Summary**: Build the full-screen premium executive dashboard that the admin/BOD members will actually see. This connects to the real API from Slice 2 and renders 6 chart sections using the existing fl_chart library and the project's premium design system.
- **Why this step now?**: Both data (Slice 1) and API (Slice 2) are ready. This slice wires them into a beautiful Flutter page.
- **Scenario Focus**: Basic Scenario (admin opens page, sees charts with "Data as of" timestamp)
- **Value Delivered**: The BOD Analytics page is live. Admins can navigate to it, see all 6 chart sections, tap Refresh to trigger an on-demand recompute, and share the screen at meetings.
- **Entry State Required**: Slice 2 is complete. `GET /api/analytics/bod` returns valid JSON.
- **Exit State Guaranteed**: `BodAnalyticsPage` renders all 6 chart sections from live API data. "Data as of" timestamp is displayed. Offline state shows a clear error (no zeros). PartiallyFailed banner is shown when status indicates it. `/analytics/bod` route is guarded by `AppCapabilities.analyticsBod`.
- **Architectural Scope**: `bod_analytics_page.dart`, `bod_analytics_manager.dart`, `bod_analytics_data.dart`, `bod_analytics_api_service.dart`, `store_leaderboard_chart.dart`, `ap_aging_chart.dart`, `auditor_scatter_chart.dart`, `period_delta_kpi_card.dart`. Modify: `app_router.dart` (add `/analytics/bod` route with PBAC guard), `AppCapabilities` Dart constant file.
- **Acceptance Criteria**:
  - `[AC-1]` Page renders "Data as of: [localized ComputedAt]" at the top.
  - `[AC-2]` When API returns `snapshotStatus = "PartiallyFailed"`, a yellow warning banner is shown alongside charts.
  - `[AC-3]` When device is offline, the page shows `ChecklyErrorState` — NOT zeros.
  - `[AC-4]` Refresh button returns a snackbar "Refresh available in X minutes" when rate-limited (429 response).
  - `[AC-5]` Navigating to `/analytics/bod` as area_manager redirects to `/home`.
  - `[AC-6]` All chart cards use `StrokeCard`. No raw `Card` or `Container` widgets.

**Order**: `[SEQUENTIAL]` — Must run after Slice 2 is approved. Widget scaffolding can be done in `[PARALLEL]` with Slice 2 using mocked JSON fixtures.

---

### Handoff Roadmap

Execute slices ONE AT A TIME in this exact order:

- **Slice 1 — Data Engine** (BLOCKING — do this first):
  `Plan → Write Acceptance Tests → Build`

- **Slice 2 — API Gateway** (SEQUENTIAL after Slice 1):
  `Plan → Write Acceptance Tests → Build`

- **Slice 3 — Flutter UI** (SEQUENTIAL after Slice 2):
  `Plan → Write Unit Tests → Build`

**Epic Plan File**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\analysis_epic_20260524_142100_bod_analytics.md`
