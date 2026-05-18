# Reporting & Analytics Redesign Research

## [ORIGIN_IDEA]
The user observed that current reports (displayed as charts or KPI cards on the profile/analytics pages) are purely descriptive and lack actionable meaning or professional analyst insights. The goal is to redesign the reporting architecture—encompassing UI/UX, data visualization strategies (referencing `chart-visualization`), and backend data delivery—to provide narrative-driven, actionable insights rather than just raw metrics.

---

## <latent_space_scratchpad>
- **Current State:** The backend (`GetAnalytics.cs`) computes raw aggregates (Total Audits, Avg Score, 6-month trend by month, and Section breakdown). The frontend (`AnalyticsPage`) renders these as static KPI cards, a basic `fl_chart` LineChart for trends, and a generic CategoryHeatmap. There is no context (e.g., "Is 85% good or bad?").
- **The Core Problem:** Descriptive vs. Prescriptive Analytics. Users need to know *what to do next*, not just *what happened*.
- **Architectural Implication:** We shouldn't force the frontend to calculate insights. The backend must compute variances (e.g., this month vs last month, store vs region average) and deliver structured `Insight` objects.
- **Chart Selection (from `chart-visualization` skill):**
  - **Radar Chart:** Compare a store's section scores against the regional average. (Multi-dimensional comparison).
  - **Bar/Column Chart with Benchmarks:** Show top failures across the region.
  - **Funnel Chart:** Action Plan resolution process (Created -> In Progress -> Resolved).
- **UI/UX Strategy (from `ui-ux-designer` skill):**
  - Progressive disclosure: Show the top 3 AI-generated/Heuristic insights as natural language cards (e.g., "⚠️ Safety scores dropped 12% this week").
  - Interaction: Users click the insight to drill down into the specific chart (Radar/Line) that proves it.
- **Blind Spots:**
  1. **Performance/Payload:** Calculating regional benchmarks dynamically for every `GetAnalytics` request will cause N+1 or heavy DB load if not cached or materialized.
  2. **Data Sparsity:** If a store only has 1 audit, a radar chart comparing them to the region will look skewed or misleading.
  3. **Role Scoping:** Area Managers need cross-store comparisons; Store Managers only need self-vs-peers. The DTO must adapt to the PBAC role.
- **Rules Conflict:** 
  - *Conflict with "Well Partitioned Modules":* Adding heavy insight calculations directly into `GetAnalytics.cs` violates the Single Responsibility Principle. We need an isolated `InsightGeneratorService` (Domain layer).
</latent_space_scratchpad>

---

## E2E Workflow Map

```text
[User] -> Taps "Analytics" Tab
   |
   v
[Frontend] GET /api/analytics?storeId=123
   |
   v
[API Endpoint: GetAnalytics.cs]
   |--> Fetches raw aggregates (KPIs, Trend)
   |--> Calls `InsightGeneratorService.Generate(raw_data, benchmarks)`
   |
[Backend] Returns `AnalyticsResponse` + `List<ActionableInsight>`
   |
   v
[Frontend: AnalyticsPage]
   |--> Renders "Executive Summary" (3 natural language insight cards)
   |--> Renders "Category Benchmarking" (Radar Chart comparing Store vs Area)
   |--> Renders "Historical Trend" (Line Chart with target thresholds)
```

---

## Comparative Decision Matrix

| Option | Architecture | UX/UI Impact | Viability |
|--------|-------------|--------------|-----------|
| **A. Strict Native Fit (Heuristic Insights)** | Backend rule engine (if score < avg - 10%, return Warning Insight). Send standard `fl_chart` charts. | High. Users get readable text insights. Minimal UI rewrite. | **Recommended**. Low latency, highly actionable. |
| **B. Pragmatic Balance (AntV/Web Charts)** | Integrate `chart-visualization` JS charts via WebViews or server-side rendered images. Backend generates advanced chart specs. | Very High. Access to Radar, Scatter, Funnel charts. | Moderate. Requires embedding JS charts in Flutter, which adds complexity and size. |
| **C. Enterprise Overhaul (LLM + OLAP)** | Sync data to a data warehouse. Use an LLM to generate narrative reports nightly. | Massive. "Professional Analyst" level narratives. | **Rejected**. Over-engineered for the current monolithic state. |

---

## UI Component Routing Table

| Component | Threshold/Overflow Limit | Downstream Route |
|-----------|--------------------------|------------------|
| Insight Cards (Top) | Max 3 cards displayed. | Tap -> Scrolls to relevant chart. |
| Radar Chart (Categories) | Max 8 categories (axes). If > 8, group into "Others". | Tap Node -> Navigate to `ActivityPage` filtered by category. |
| KPI Grid | Max 6 metrics. | Tap -> Pre-filtered `ActivityPage` or `ActionPlansPage`. |

---

## <forensic_evidence>
- `view_file` executed on `.agents/skills/chart-visualization/SKILL.md` (to understand available chart topologies like Radar, Funnel).
- `view_file` executed on `.agents/skills/ui-ux-designer/SKILL.md` (to align with accessible, narrative-driven design).
- `grep_search` executed on `lib/features/analytics/` confirming `TrendChart.dart` (simple LineChart) and `CategoryHeatmap.dart` are the only current visualizations.
- `view_file` executed on `server/Features/Analytics/GetAnalytics.cs` confirming the backend currently only returns raw numbers (`totalAudits`, `avgScore`, `TrendPoint`, `SectionScore`) without contextual benchmarks or insights.
</forensic_evidence>

---

## Handoff Block

- **Verdict:** Viable (Option A - Heuristic Insights + Enhanced Native Charts). We will redesign the backend to compute relative benchmarks and return narrative `Insight` objects. We will upgrade the Flutter UI to use comparative charts (e.g. Radar charts for sections instead of just heatmaps).
- **Effort Sizing:** Track A/B. Moderate backend logic addition (`InsightGenerator`); Moderate UI refactor to prioritize natural language cards over raw data grids.
- **AI Agent Mission Brief:** Build `InsightGeneratorService` in the backend to calculate variances/benchmarks, update `AnalyticsResponse` DTO to include `Insights`, and refactor Flutter's `AnalyticsPage` to display a "Executive Summary" section with actionable text cards and comparative Radar/Line charts.
- **Next Command:** 
```bash
/analyze-feature file:///c:/Users/HP/Documents/GitHub/Checkly/docs/product/research_20260517_114319_RPT1_reporting_redesign.md
```
