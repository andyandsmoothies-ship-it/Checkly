# System Architecture Research: Executive BOD Analytics System

[ORIGIN_IDEA]: "A comprehensive analytics feature... which can be shown on BOD meetings, not just simple cards as current. To support large chains, reporting for current roles should be more realistic, actionable... reference chart-visualization SKILL.md."

<latent_space_scratchpad>
**Debate & Tradeoffs:**
- Currently, `GetAnalytics.cs` loads KPIs, a simple 6-month trend, and section breakdown. It runs directly against the operational tables (`Submissions`, `ActionPlans`, `SubmissionSectionScores`).
- For a BOD-level dashboard, the visual requirements jump from "Cards" to complex comparative charts:
  - **Treemap** for compliance across regions and stores (Hierarchical).
  - **Boxplot** for score distributions across stores (identifying outliers vs median).
  - **Dual Axes Line Chart** showing Completion Rate vs Average Score over time.
  - **Radar/Spider Chart** for benchmarking (currently partially implemented via ProvinceBenchmarkCalculator, but needs expansion).
- *Performance Edge Case:* Running complex Boxplot math (quartiles) or massive group-bys across millions of submission records directly on the primary DB could cause severe performance degradation (OLTP interference).
- *Resolution:* We have two options:
  1. CQRS with a materialized view or read-replica (overkill for current scale).
  2. Aggregated Caching: Run a nightly background job (`IHostedService`) to aggregate these complex stats into an `AnalyticsSnapshots` table, and the BOD dashboard just queries the snapshots.
- *Visual Component (chart-visualization):* The Flutter frontend will need a robust charting library (e.g., `fl_chart` or `syncfusion_flutter_charts`) to render these complex visuals natively, or we embed web views running `antvis`/JS. Given Checkly is a Flutter app, we should map the backend endpoints to feed native Flutter charting widgets rather than web views for a premium feel, though we can use the exact visual patterns specified in `chart-visualization` SKILL.md.
</latent_space_scratchpad>

## E2E Workflow Map

```ascii
[BOD Member / Exec] 
       |
    (Taps "Executive Dashboard")
       v
[Flutter Client: ExecutiveDashboardView]
       |
       +--> [GET /api/analytics/executive]
       |         |
       |         +--> [Auth Guard: Check Role == "admin" || "area_manager"]
       |         |
       |         +--> [EF Core: Query AnalyticsSnapshots & Submissions]
       |         |
       |         +--> [Calculation Engine: Compute Quartiles, Rolling Averages]
       |         |
       |         +--> Return JSON (TreemapData, BoxplotData, TrendData)
       v
[Flutter Chart Components]
  |- Treemap Chart (Region -> Store Compliance)
  |- Dual Axes Chart (Trend vs Completion)
  |- Boxplot Chart (Score Distributions)
  |- Radar Chart (Category Benchmark)
```

## Impact Spectrum

| Option | Approach | Pros | Cons | Verdict |
|---|---|---|---|---|
| **Option A (Strict Native Fit)** | Real-time EF Core queries for all charts. | No new infrastructure or background jobs needed. | High DB load. Calculating quartiles in raw SQL/EF is notoriously slow. | **Rejected** for full implementation, but acceptable for MVP. |
| **Option B (Pragmatic Balance)** | Daily Background Worker (`IHostedService`) computing complex aggregations into an `ExecutiveSnapshots` table. | Fast reads. Protects OLTP DB. Easy to query complex chart shapes. | Data is up to 24 hours stale (acceptable for BOD meetings). | **Approved**. |
| **Option C (Enterprise Textbook Overhaul)** | Export data to a dedicated OLAP Data Warehouse (Snowflake/BigQuery). | Infinite scale, complex BI tooling. | Massive overkill, high cost, breaks current monolithic simplicity. | **Rejected**. |

## Blind Spots
1. **Payload Size for Treemaps:** Treemaps across a national chain might return thousands of nodes in a single JSON payload. The flutter rendering engine might struggle.
2. **Timezone Shifts:** Background aggregation at "midnight" is tricky if stores span multiple timezones. Snapshots might misalign with local store realities.
3. **Historical Data Mutation:** If a manager voids an old audit, the historical snapshot needs to be invalidated and re-calculated.

## Conflicts With Rules
1. **Rule Conflict (Gotcha: Strict 1-to-M Store Assignment Unique Constraint):** Analytics logic for AMs requires querying via `ProfileStoreAssignment`. If an AM changes territory, their historical snapshot analytics might misalign with the current live territory map, requiring a point-in-time vs current-time authorization decision.

## UI Component Routing Table

| Chart Component | Chart Type (Skill Ref) | Data Source Endpoint | Overflow Limit | Downstream Route |
|---|---|---|---|---|
| Regional Compliance Map | `generate_treemap_chart` | `/api/analytics/executive/regions` | Top 5 Regions | Tap -> Region Drilldown |
| Score Distribution | `generate_boxplot_chart` | `/api/analytics/executive/distributions` | Top 10 Stores | Tap -> Store History |
| Performance vs Time | `generate_dual_axes_chart`| `/api/analytics/executive/trends` | 12 Months | N/A |
| Category Benchmark | `generate_radar_chart` | `/api/analytics/executive/benchmarks`| 8 Categories max | Tap -> Category Detail |

## Forensic Evidence
<forensic_evidence>
- `grep_search` executed for `report`, `analytic`, `dashboard` in `server/`.
- Found `GetAnalytics.cs` and `Dtos.cs`.
- Identified current limitations: Only simple `TrendPoint` and `SectionScore` returned. No complex charting logic exists natively.
</forensic_evidence>

---

## Handoff Block

**Final Verdict:** Viable. Proceed with **Option B (Pragmatic Balance)**.
**Effort Sizing:** Track C (Large Feature). Requires DB Schema updates (Snapshots table), Background Worker, new Endpoints, and 4 new complex Flutter Chart components. Concurrency: Backend API and Frontend Charts can be developed in parallel using mocked JSON contracts.

**AI Agent Mission Brief:** 
Implement the "Executive BOD Analytics" feature. Start by creating the backend endpoint `/api/analytics/executive` that provides mock data shaped for Treemaps, Boxplots, and Dual-Axes charts, then implement the Flutter UI using native charting libraries matching the `chart-visualization` specifications.

**Next Command:**
```bash
/analyze-epic {file:///c:/Users/HP/Documents/GitHub/Checkly/docs/product/research_20260524_135800_bod_analytics.md}
```
