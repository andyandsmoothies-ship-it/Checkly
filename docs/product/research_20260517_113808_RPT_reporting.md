# Analytics & Reporting: Actionable Insights Upgrade (Research)

## [ORIGIN_IDEA]
Transform the static, data-dump reporting (KPIs, simple trend line) into a professional, analyst-driven insight engine. Stop showing raw numbers and start answering the "So What?" question for Store Managers and Area Managers.

## E2E Workflow Map (Current vs Proposed)

**Current Flow (Data Driven):**
```text
[User Opens Profile] --> [Sees "Score: 85%"] --> [Sees 6-Month Line Chart] --> [User has to guess if 85% is good/bad] --> [User leaves]
```

**Proposed Flow (Insight Driven):**
```text
[User Opens Analytics] --> [Sees "Score is 85% (⬆️ 5% vs last month)"] 
                           |--> [Read AI/Stat-driven summary: "Food Safety improved by 12%"]
                           |--> [View advanced correlation: "Score vs. Overdue Action Plans"]
                           |--> [Identify Outliers: "Store X needs attention"]
```

## Comparative Decision Matrix (Chart Types & Insights)

To build a professional analyst-grade dashboard, we need to upgrade the visuals using the `chart-visualization` skill guidelines and `fl_chart`/custom drawing. Here are the core upgrades proposed:

| Objective | Current Approach | Proposed Approach (Analyst Grade) | Recommended Chart Type |
| :--- | :--- | :--- | :--- |
| **KPIs** | Plain Numbers | **Delta & Context**: Show numbers vs previous period (WoW, MoM) with color-coded arrows. | `Stat Cards with Sparklines` |
| **Trend** | Simple Line Chart | **Trend with Benchmarks**: Show the trend line overlaid against a target/benchmark area (e.g., 80% passing line). | `generate_line_chart` (Dual Axes) |
| **Performance Spread** | None | **Outlier Detection**: Show the distribution of scores across all stores/audits to spot anomalies. | `generate_boxplot_chart` or `generate_histogram_chart` |
| **Correlation** | None | **Cause & Effect**: Map Audit Scores against Overdue Action Plans to prove that neglecting action plans lowers scores. | `generate_scatter_chart` (Correlation) |
| **Process Flow** | None | **Compliance Funnel**: Show how many failed items turn into action plans, and how many are resolved. | `generate_funnel_chart` |
| **Categories** | Basic Heatmap | **Radar / Spider**: Compare a specific store's category performance against the regional average. | `generate_radar_chart` |

## UI Component Routing Table & Layout

Instead of stuffing everything into the Profile page, we should elevate Analytics to a dedicated, full-screen dashboard experience.

**Dashboard Structure:**
1. **The Executive Summary (Top)**: "Your region is performing well, but **Safety Compliance** has dropped. **3 stores** require immediate action." (Auto-generated insight sentence based on rules).
2. **The Metric Ribbon**: 4 KPI cards with Sparklines (mini-charts) and % Deltas.
3. **The Correlation Matrix (Middle)**: Scatter Plot (Scores vs. Overdue Actions).
4. **The Deep Dive (Bottom)**: Tabs for `Trends`, `Categories (Radar)`, and `Outliers (Boxplot)`.

<latent_space_scratchpad>
*   **Tradeoff 1: Offline Processing vs Backend Processing.**
    *   Currently, `AnalyticsManager.dart` computes everything locally using Drift. This is great for offline, but bad for complex math (Standard Deviations for Boxplots, Linear Regression for Scatter Plots).
    *   **Recommendation**: Keep basic KPIs and local Trends in Drift. Move advanced correlations and outlier detection to the `.NET Backend` (`GetAnalytics.cs`) and fetch them when online, caching the JSON result.
*   **Tradeoff 2: Charting Library.**
    *   We currently use `fl_chart`. It is good for Line/Bar/Scatter/Radar charts.
    *   For Sankey/Funnel/Boxplot, `fl_chart` lacks native support. We either draw them with custom `CustomPainter`, use a different package (like `syncfusion_flutter_charts`), or simplify the requirement.
    *   **Recommendation**: Stick to `fl_chart` for Radar, Scatter, and Dual-Axis Line. Use Custom Painters for the Funnel and Sparklines to avoid adding heavy 3rd-party dependencies.
</latent_space_scratchpad>

## Impact Spectrum
*   **Option A (Strict native fit):** Visual upgrade only. Add sparklines and basic deltas directly to `AnalyticsManager.dart` using existing offline logic.
*   **Option B (Pragmatic balance):** Hybrid approach. Basic KPIs offline, complex math (correlation, outlier detection) queried from the backend when online.
*   **Option C (Enterprise textbook overhaul):** Completely rewrite the Analytics pipeline using an external OLAP tool or dedicated Analytics service, removing local drift processing.

## Blind Spots
1.  **Memory/Payload Size:** Syncing thousands of submissions locally in `AnalyticsManager` will hit memory limits on low-end devices. Boxplots require all individual data points.
2.  **Chart Rendering Cost:** Rendering hundreds of scatter plot dots with `fl_chart` may drop frames during scrolling.
3.  **Offline Expectations:** If we move insight generation to the backend, users may be confused when insights vanish while in airplane mode.

## Conflicts With Rules
1.  **Conflict with "Zero Bloat":** We might need a new library if `fl_chart` cannot handle Sankey diagrams efficiently, conflicting with the restriction against unauthorized packages.
2.  **Conflict with "Massively Overloaded Tests":** Creating complex math on the frontend will require heavy unit tests to prove correctness, which might drift from backend definitions.

<forensic_evidence>
- Used `view_file` to inspect `lib/features/analytics/manager/analytics_manager.dart` (Flutter) which showed local KPIs via Drift.
- Used `grep_search` in the `server` directory and `view_file` on `server/Features/Analytics/GetAnalytics.cs` (.NET Backend) to inspect the remote KPIs API.
</forensic_evidence>

## Handoff Block

> [!IMPORTANT]
> **User Review Required**
> Please review the proposed Analytics upgrades. Which direction should we prioritize for the next phase?

**Final Verdict**: Viable. The analytics logic already exists, we just need to enhance the UI and optionally the backend math to provide real insights.

**Effort Sizing**: Option A (Track C - UI Only), Option B (Track A/B - Full Stack).

**AI Agent Mission Brief**: The user wants to replace static data reports with actionable insights. Review the chosen option (A or B) and implement the new reporting dashboard components and data pipelines.

**Next Step**:
Please reply with Option A or Option B.
Once decided, run the implementation workflow:
`@[/analyze-feature] docs/product/research_20260517_113808_RPT_reporting.md`
