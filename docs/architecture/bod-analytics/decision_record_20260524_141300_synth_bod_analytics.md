# Architectural Decision Record: BOD Analytics System

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260524_135800_bod_analytics_original.md`
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260524_135800_bod_analytics.md`

## [ORIGIN_IDEA]
"A comprehensive analytics feature... which can be shown on BOD meetings, not just simple cards as current. To support large chains, reporting for current roles should be more realistic, actionable... reference chart-visualization SKILL.md."

<latent_space_scratchpad>
Debate & Tradeoffs:
Option A (Real-time) is simple but will crash the DB at scale due to complex quartiles and aggregations over millions of rows.
Option B (Materialized View / Snapshots) protects the DB but introduces temporal staleness (up to 24 hours) and background job complexity.
Option C (Data Warehouse) solves scale but is massive overkill, expensive, and breaks the monolith.
</latent_space_scratchpad>

## Normalized Summary of Options
1. **Option A (Real-time Queries):** Extend existing `GetAnalytics.cs` to calculate complex charts (boxplots, treemaps) on the fly via EF Core.
2. **Option B (Materialized Snapshots):** Implement a nightly `BodReportWorker` to pre-calculate heavy aggregations into a `BodReportSnapshot` table. Serve via a new `GetBodReport` endpoint to a dedicated Flutter page.
3. **Option C (External DW):** Export data to Snowflake/BigQuery and use an external BI tool or embedded WebViews for charts.

## Red Team Attack Vectors (Hostile Interrogation)
- **Option A (Real-time):** **CATASTROPHIC FAILURE.** Calculating store-by-store quartiles, histograms, and YoY trends over 5 million `Submission` rows in real-time will cause Postgres CPU spikes. When 10 Area Managers load the app at 9:00 AM, the OLTP database locks up, halting live store audits. App goes down.
- **Option B (Materialized Snapshots):** **CATASTROPHIC FAILURE.** The `BodReportWorker` runs nightly. If it throws an unhandled exception on a malformed audit from a single store, the entire nightly job crashes. The BOD wakes up to 48-hour stale data or empty dashboards. Also, timezone mismatch: if "nightly" is UTC, stores in Asia are mid-day.
- **Option C (External DW):** **CATASTROPHIC FAILURE.** Sync pipeline breaks. External BI webview requires a separate authentication cookie. Area managers on iPads in deep freezers (offline) get a blank white screen instead of cached data.

## Pugh Decision Matrix
| Criteria | Option A (Baseline) | Option B (Snapshots) | Option C (External DW) |
|---|---|---|---|
| **Origin Idea Alignment** (Weight x2) | 0 | +2 | -2 (Loss of native app feel) |
| **Main Thread / DB Performance** | 0 | +1 | +1 |
| **Offline Sync Capability** | 0 | 0 (BOD is online-only) | -1 |
| **Blast Radius (Risk to Core App)** | 0 | -1 | 0 |
| **UX & Native Feel** | 0 | +1 | -1 |
| **TOTAL SCORE** | **0** | **+3** | **-3** |

## Final Verdict
**Option B (Materialized Snapshots)** is the mathematical winner. We will implement a nightly background worker and a separate set of endpoints/UI to protect the core OLTP database while delivering a native, premium experience. Option A is suicidal for performance, and Option C is an over-engineered distraction.

## Executive Business Summary
To give the Board of Directors fast, beautiful charts without crashing the live store-audit system, we will build a "nightly snapshot" system. Every night, the server will crunch the massive amounts of data and save the answers. When the BOD opens the app, it instantly loads the pre-computed answers. The tradeoff is that the BOD dashboard will be up to 24 hours behind live data, which is standard for executive reporting.

## Handoff Block
### 1. Final Verdict
Option B (Materialized Snapshots) with a dedicated BOD Analytics Flutter page.

### 2. Strict Constraints

**Backend — Worker & Data**
- **PBAC Gating:** The BOD page MUST be gated using `allowedActions` from the backend profile DTO, NOT hardcoded Flutter role checks.
- **Idempotent Worker (Upsert):** The `BodReportWorker` MUST use an Upsert (`INSERT ... ON CONFLICT DO UPDATE`) keyed on `[Date, SnapshotType]`. A blind `INSERT` is FORBIDDEN. If the worker restarts or runs twice, it must overwrite the existing snapshot — never throw a duplicate key exception or double-count data.
- **Worker Resilience:** The `BodReportWorker` MUST wrap each of its 6 queries in try/catch to prevent a single malformed record from aborting the entire nightly job. Failed queries must be logged with a structured error, and the snapshot must be saved in a `PartiallyFailed` state rather than discarded.
- **Timezone Anchor:** The worker MUST anchor all aggregation windows to a single agreed-upon corporate timezone (e.g., `Asia/Bangkok` or whichever is in `appsettings.json`). A snapshot taken at midnight UTC will split the business day for stores in Asia, producing charts that are wrong by half a day. This MUST be configurable, not hardcoded.
- **ComputedAt Timestamp:** The `BodReportSnapshot` entity MUST store a `ComputedAt DateTimeOffset` field. This value must be included in the `BodReportResponse` DTO so the Flutter UI can surface it.
- **On-Demand Refresh Endpoint:** An Admin-only `POST /api/analytics/bod/refresh` endpoint MUST exist to manually trigger the worker computation. This is the escape hatch for when the nightly job fails before a critical BOD meeting. The endpoint must be rate-limited (max 1 execution per 15 minutes) to prevent abuse.
- **Data Retention Policy:** The `BodReportWorker` MUST include a pruning step as its final action each night: keep daily snapshots for 90 days, then delete daily records older than 90 days. Monthly rollup snapshots are a future concern — for now, prune-and-drop is acceptable.

**Flutter UI**
- **Offline States:** The BOD page MUST explicitly block offline access with a clear error state. Do not attempt to synthesize BOD data from the local Drift cache.
- **"Data as of" Indicator:** The Flutter `BodAnalyticsPage` MUST display a visible `"Data as of: [ComputedAt timestamp, localized]"` indicator at the top of the page. This is non-negotiable for executive trust. Executives must never confuse 24-hour stale data with real-time data.
- **Premium Design Mandate:** The BOD analytics UI MUST use the project's premium design system (`StrokeCard`, `PillChip`, custom typography). Raw Material colors, default card widgets, and unstyled containers are FORBIDDEN. All chart animations must use smooth easing curves and respect `MediaQuery.disableAnimationsOf(context)` for accessibility. The UI must feel indistinguishable from a high-end BI tool.

### 3. Execution Slices
- **Slice 1:** Backend infrastructure (`BodReportSnapshot` entity with `ComputedAt` + unique index, Idempotent `BodReportWorker` with retention pruning, EF Core Migrations).
- **Slice 2:** Backend API (`GetBodReport` endpoint + `POST /bod/refresh` on-demand endpoint, PBAC mapping, timezone config).
- **Slice 3:** Flutter UI (`BodAnalyticsPage` with "Data as of" header, `BodAnalyticsManager`, premium-styled native `fl_chart` widgets).

### 4. Requirements Alignment Check
WARNING: The user flow has changed. Requirements must be updated to reflect:
1. BOD Analytics is a separate, admin-only page — not an extension of the existing `AnalyticsPage`.
2. Data is NOT real-time (up to 24h stale). This must be communicated in the UI.
3. An on-demand refresh mechanism exists for critical sessions.
4. The BOD page is strictly online-only.

### 5. AI Agent Mission Brief
Implement an idempotent, timezone-aware `BodReportWorker` with a built-in data retention pruning step to aggregate nightly stats into a `BodReportSnapshot` table. Expose the data via a PBAC-gated `GET /api/analytics/bod` and an admin-only `POST /api/analytics/bod/refresh` endpoint. Build a premium Flutter `BodAnalyticsPage` displaying a "Data as of" timestamp header and native `fl_chart` widgets styled to the project's design system.

### 6. Next Command
```bash
/analyze-epic {file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/bod-analytics/decision_record_20260524_141300_synth_bod_analytics.md}
```
