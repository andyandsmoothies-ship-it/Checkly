<latent_space_scratchpad>
Key discovery from code reading:
1. Template.cs has a `Type` field (string, values: 'QC', 'Training', 'General') — this already partially serves as an archetype marker!
2. Submission already has `ScoringMode` which the BOD calculator already uses to filter out surveys.
3. BodChainKpis DTO already has CompletionRate AND AvgTtrDays — these fields are ALREADY computed and returned from the API.
4. Flutter BodChainKpis already parses completionRate and avgTtrDays from JSON.
5. The BOD dashboard may just not be displaying these two KPIs prominently enough.

So the situation is much simpler than expected:
- We do NOT need a net-new database table for archetypes. The existing Template.Type field can be extended.
- The backend already calculates CompletionRate and AvgTtrDays in BodChainKpis.
- The Flutter model already has these fields parsed.
- The MAIN work is: 
  (a) Define the 3 Archetypes formally and map them to existing Template.Type values.
  (b) Add an Archetype-aware filter to BodReportCalculator so leaderboards only compare same-archetype submissions.
  (c) Update the Flutter BOD dashboard KPI card to prominently surface CompletionRate and AvgTtrDays.
  (d) Formally close the 2 pending complex filter tasks.

Shapes:
- Shape A: Extend existing Template.Type to serve as the Archetype (rename/expand, no new column).
- Shape B: Add a new separate TemplateArchetype column to Template entity alongside the existing Type.

Shape A is better — it avoids a new migration, reuses an existing discriminator, and requires less code change.

The main risk: if ScoringMode on submissions is set correctly at creation time (already the case in the codebase), we can use that as a filter gate even without touching Template.Type at all.

Pattern: This is a Data Pipeline Enrichment + Filter Gate pattern. We enrich the nightly pipeline with archetype-aware filtering and surface existing calculated metrics more prominently on the frontend.
</latent_space_scratchpad>

# Epic Analysis: Golden Output Metrics MVP (Option 2)

**Date**: 2026-05-28 | **ShortID**: c3563378 | **ConvID**: c3563378-9cd7-4609-ae6d-2aba9f71c9ff
**Pattern**: Data Pipeline Filter Gate + Frontend KPI Promotion

---

## Input Lineage

- **Primary Source**: `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260528_135200_c3563378_pm_options_impact.md`
- **Strategy Source**: `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260528_115200_c3563378_pm_3_ideas_comparison.md`
- **BOD Requirements v4**: `c:\Users\HP\Documents\GitHub\Checkly\docs\project\requirements_20260527_171654_c3563378_bod_analytics_full_scope_v4.md`

---

## Executive Summary

Option 2 ("Golden Output Metrics") solves the multi-template analytics conflict by standardizing on **3 universal business metrics** (Completion Rate, TTR, Compliance Status counts) and preventing mathematically invalid cross-template mixing via **Archetype segregation**.

```
[Dynamic Templates] ──► [Archetype Gate] ──► [Golden Metrics Dashboard]
  - Scored Audits       - ScoredAudit          - Completion Rate %
  - Task Campaigns      - TaskCampaign          - Avg TTR Days
  - Fault Logs          - FaultLog              - Open/Overdue AP Counts
```

**Key Discovery**: The backend ALREADY calculates `CompletionRate` and `AvgTtrDays` inside `BodChainKpis`. The Flutter `BodChainKpis.fromJson` ALREADY parses both fields. The main work is:
1. Formalizing the 3 Archetypes (extend `Template.Type`).
2. Adding an Archetype filter gate to leaderboard queries in `BodReportCalculator.cs`.
3. Promoting CompletionRate and AvgTtrDays to be **first-class visible KPI tiles** in the Flutter dashboard.
4. Officially closing the 2 pending complex filter tasks.

---

## Decision Matrix

### Requirements

| ID | Requirement |
| :--- | :--- |
| R1 | Prevent mathematically invalid average score mixing across different template types. |
| R2 | Surface Completion Rate and TTR as primary KPIs on the BOD dashboard. |
| R3 | Allow store leaderboard comparisons only within the same archetype. |
| R4 | Keep BOD dashboard loading in <50ms (nightly snapshot). |
| R5 | The solution must work offline-first on the Flutter client. |

### Shapes

**Shape A (Recommended): Extend `Template.Type` to serve as the Archetype field.**
- The `Template` entity already has a `string Type` field with values `QC`, `Training`, `General`.
- We define a formal enum-equivalent mapping:
  - `QC` → `ScoredAudit` (generates 0-100 score).
  - `General` → `TaskCampaign` (generates completion %).
  - `Training` → remains `Training` (already filtered out by `ScoringMode != "survey"`).
- No new migration column needed. Filter logic added to `BodReportCalculator.cs` queries.

**Shape B: Add a new `TemplateArchetype` column to the `Template` entity.**
- Requires an EF Core migration and a new column on `public.templates`.
- More explicit but adds schema complexity for a result achievable via Shape A.

### Fit Check

| Requirement | Shape A (Extend Type) | Shape B (New Column) |
| :--- | :---: | :---: |
| R1 — Prevent mixing | ✅ Filter by existing Type field | ✅ Filter by new Archetype column |
| R2 — Surface KPIs | ✅ Frontend-only change | ✅ Frontend-only change |
| R3 — Leaderboard isolation | ✅ Add WHERE clause in leaderboard query | ✅ Same |
| R4 — <50ms load | ✅ No change to snapshot path | ✅ No change to snapshot path |
| R5 — Offline-first | ✅ No sync layer changes needed | ⚠️ Needs sync update for new column |

**Winner: Shape A** — Reuses an existing field. No new migration. No sync engine change. Less risk.

---

## Risk Assessment

| Risk | Severity | Mitigation |
| :--- | :--- | :--- |
| `Template.Type` values are inconsistently populated in the DB | 🟡 Medium | Add a defensive fallback: if `Type` is null or unknown, treat as `ScoredAudit` (the majority case). |
| Leaderboard query performance after adding WHERE TYPE clause | 🟢 Low | `templates.type` is a varchar column — adding an index is trivial if needed. |
| Breaking existing tests that assert specific BodChainKpis values | 🟡 Medium | Run `dotnet test` after each archetype filter change. Tests in `BodAnalyticsFilteredEndpointTests.cs` verify KPI values. |
| Existing Flutter tests for the dashboard KPI card layout | 🟡 Medium | Adding new KPI tiles can break golden tests. Run `flutter test --update-goldens` after UI change. |

---

## Visual & Functional Context

### BOD Dashboard KPI Card (Existing vs. Target)

```
[EXISTING]                              [TARGET]
┌────────────────────────────────┐      ┌────────────────────────────────────┐
│  Total Audits   Avg Score      │      │  Total Audits   Completion Rate ★  │
│  125            87.5%          │      │  125            92.3%              │
│  Completion %   Open APs       │      │  Avg TTR Days ★  Open APs         │
│  (hidden)       14             │      │  4.2 days        14               │
└────────────────────────────────┘      └────────────────────────────────────┘
★ = Now prominently visible as a first-class KPI tile
```

### Affected Screens

| Screen | Change |
| :--- | :--- |
| BOD Dashboard (KPI Grid Card) | Make `CompletionRate` and `AvgTtrDays` visible tiles |
| BOD Store Leaderboard Card | Add Archetype label badge on each store entry |
| Template Admin Screen (if exists) | No change needed — `Type` field already editable |

---

## System Context

- **Offline/Online**: The snapshot payload contains `completionRate` and `avgTtrDays` already. No network change needed.
- **RBAC**: BOD is admin-only. No RBAC change required.
- **API Contract**: `BodChainKpis` DTO already returns `CompletionRate` and `AvgTtrDays`. Contract is stable.
- **Sync**: No Flutter SQLite sync change needed (Shape A uses existing Template.Type, no new column).

---

## Lifecycle Context

| State | Behavior |
| :--- | :--- |
| **Empty State** | If a store has no `ScoredAudit` type submissions, the leaderboard card shows "No scored audits in this period" instead of a 0% score. |
| **Error State** | If `BodReportCalculator` fails on the archetype-filtered leaderboard query, it falls through to `PartiallyFailed` status (existing pattern). |
| **Rollback** | Shape A is additive — a WHERE clause in the leaderboard query is the only code change on the backend. Reverting is a 1-line SQL guard removal. |

---

## Data Context

### No New Migration Required (Shape A)

The existing `Template.Type` column (`varchar`) already maps to our 3 archetypes:

```
Template.Type = 'QC'       ──► Archetype: ScoredAudit   (compare by score)
Template.Type = 'General'  ──► Archetype: TaskCampaign   (compare by completion %)
Template.Type = 'Training' ──► Archetype: FaultLog/Survey (no leaderboard comparison)
```

The only data change: Add a WHERE guard in the `BodReportCalculator.cs` store leaderboard query (Query 3) to only select submissions linked to `ScoredAudit` templates.

---

## Architecture Flow

```
[NIGHTLY JOB — 2:00 AM]
  BodReportCalculator.ComputeDailyReportWithTimezoneAsync()
        │
        ├──► Query 1: KPIs (CompletionRate already calculated — NO CHANGE)
        │
        ├──► Query 2: 12-Month Trend (already filters ScoringMode != survey — NO CHANGE)
        │
        ├──► Query 3: Store Leaderboard ◄── ADD: WHERE t.Type = 'QC' filter
        │             (join Template via TemplateId on Submission)
        │
        ├──► Query 4: Category Weaknesses (section scores, already has MaxScore > 0 guard — NO CHANGE)
        │
        ├──► Query 5: Action Plan Aging (NO CHANGE)
        │
        └──► Query 6: Auditor Productivity (NO CHANGE)

[FLUTTER DASHBOARD]
  BodDashboardBody
        │
        └──► KPI Grid Card ◄── UPDATE: Promote CompletionRate + AvgTtrDays to visible tiles
```

---

## Risk Review & Security

**DB Architect (8/10)**: Shape A avoids schema bloat. The WHERE clause in Query 3 is simple. Risk: `TemplateId` must be joined from `Submission`. Check that `Submission.TemplateId` is indexed.

**Security Auditor (9/10)**: No new endpoints. No new auth surfaces. The archetype filter is server-side only.

**Junior Dev (8/10)**: The scope is small. The Flutter change (promoting 2 KPI tiles) is isolated to `bod_dashboard_body.dart`. No routing changes. Risk: Golden test screenshots will need updating.

All scores ≥ 7. Plan passes.

---

## Logs & Audits

- The existing `PartiallyFailed` status on `BodReportSnapshot` handles all archetype query failures automatically.
- No new structured log events needed.
- The existing `_logger.LogWarning(ex, "Query 3 (Top/Bottom Stores) failed...")` covers the archetype filter path.

---

## Testing Expectations

| Test Type | What to Test |
| :--- | :--- |
| **Integration (C#)** | `BodAnalyticsFilteredEndpointTests` — assert that the leaderboard only contains stores with `QC` template submissions when the archetype guard is active. |
| **Unit (C#)** | `BodReportWorkerTests` — verify that a store using a `General` template does not appear in the top/bottom leaderboard. |
| **Widget (Flutter)** | `bod_dashboard_body` golden test — assert that `CompletionRate` and `AvgTtrDays` tiles are visible in the KPI grid. |

<command_logs>
- grep_search: BodReport in server/*.cs → Found BodReportCalculator.cs, BodReportWorker.cs, tests
- grep_search: TemplateArchetype → Not found (field does not exist yet)
- view_file: Template.cs → Confirmed Type field ('QC', 'Training', 'General')
- view_file: BodReportCalculator.cs → Confirmed CompletionRate already calculated
- view_file: BodReportDtos.cs → Confirmed BodChainKpis already has AvgTtrDays
- view_file: bod_analytics_data.dart → Confirmed Flutter already parses completionRate, avgTtrDays
- list_dir: server/Features/Analytics → Identified 18 files, no Archetype handler
- list_dir: lib/features/analytics → Confirmed manager/bod_analytics_data.dart exists
</command_logs>

---

## Handoff Block

**Decision**: Shape A — Extend existing `Template.Type` as the Archetype gate. No new database table. No new migration. No sync engine change.

**Epic Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\analysis_epic_20260528_162900_c3563378_golden-metrics-mvp_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

---

### Work Slices

**Slice 1 — Backend Archetype Filter Gate** `[BLOCKING]`
- Add a JOIN to `Templates` table in Query 3 (Store Leaderboard) inside `BodReportCalculator.cs`.
- Add WHERE guard: `t.Type == "QC"` to restrict leaderboard to Scored Audits only.
- **Risk: Network/Database** → Plan → Write Acceptance Tests → Build

**Slice 2 — Flutter KPI Card Promotion** `[SEQUENTIAL after Slice 1]`
- Update `bod_dashboard_body.dart` KPI Grid card to display `CompletionRate` and `AvgTtrDays` as primary visible tiles (both fields already parsed, just hidden/not rendered).
- **Risk: Visuals** → Plan → Build (then run flutter test --update-goldens)

**Slice 3 — Close Pending Tasks** `[PARALLEL with Slice 2]`
- Formally mark the 2 pending complex filter tasks as "Out of Scope for MVP":
  - Date-range filter API on `GET /api/analytics/bod`
  - Tap-to-Filter on Charts gesture
- Update their task files with `[CANCELLED — Out of Scope MVP]` status.
- **Risk: Visuals** → Plan → Build

---

### Handoff Roadmap

Execute slices ONE AT A TIME in this order:

- **Slice 1**: [Risk: Network/Database] Plan → Write Acceptance Tests → Build
  - Target file: `server/Features/Analytics/BodReportCalculator.cs` (Query 3 — Store Leaderboard).
  - Test file: `server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsFilteredEndpointTests.cs`.
- **Slice 2**: [Risk: Visuals] Plan → Build → Run `flutter test --update-goldens`
  - Target file: `lib/features/analytics/widgets/bod_dashboard_body.dart`.
- **Slice 3**: [Risk: Visuals] Plan → Build
  - Update the 2 pending task markdown files to mark them cancelled.

Epic Plan: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\analysis_epic_20260528_162900_c3563378_golden-metrics-mvp_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`
