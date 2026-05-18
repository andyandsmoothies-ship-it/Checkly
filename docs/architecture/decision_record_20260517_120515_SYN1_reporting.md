# Architectural Decision Record: Analytics & Reporting Actionable Insights Upgrade

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260517_113808_RPT_reporting.md`
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260517_114319_RPT1_reporting_redesign.md`

## [ORIGIN_IDEA]
Transform static, descriptive reports (raw KPIs, simple line charts) into a narrative-driven, actionable insight engine that answers "So What?" for Store Managers and Area Managers — without over-engineering.

## <latent_space_scratchpad>
- Both research artifacts agree on the goal: make analytics actionable.
- RPT focuses heavily on chart diversity (scatter, boxplot) which threatens UI performance and adds external dependency risks.
- RPT1 focuses on natural language insight generation via backend rules.
- The Pugh Matrix heavily penalizes RPT for chart complexity and bloat risks. RPT1 wins mathematically but has serious backend performance (N+1) and clean architecture flaws that must be patched before handoff.
</latent_space_scratchpad>

## Summary of Options
- **Option 0: RPT (113808) [Baseline]**
  - **Hypothesis:** Replace data-dump UI with professional dashboard using Scatter, Boxplot, Radar, and Funnel charts.
  - **Architecture:** Hybrid. Basic KPIs in Drift, complex math in .NET backend.
- **Option 1: RPT1 (114319)**
  - **Hypothesis:** Backend computes `Insight` objects via a rule engine; Flutter renders natural-language insight cards + Radar/Line charts.
  - **Architecture:** Pure backend insight generation returning `AnalyticsResponse` + `List<ActionableInsight>`.

## Red Team Attack Vectors
- **RPT Baseline:** Scatter Plot Out of Memory crash (4,000+ points on low-end devices). Syncfusion library introduces bloat/licensing issues.
- **RPT1:** N+1 DDoS attack on Monday mornings due to regional benchmark queries per user. Statistically invalid alarms due to data sparsity (e.g., triggering a warning on a store with only 1 audit). Clean Architecture violation by injecting HTTP PBAC roles into the Domain layer `InsightGeneratorService`.

## Pugh Decision Matrix
*(Baseline: RPT 113808 = 0)*

| Non-Functional Requirement | Weight | Option 1: RPT1 (114319) |
|---|---|---|
| **[ORIGIN_IDEA] Alignment** | 3 | +1 (Explicit Insight object design) |
| **DB Load / N+1 Risk** | 2 | -1 (Regional benchmark queries cause N+1) |
| **Offline Capability** | 2 | 0 |
| **Package Bloat / Zero Bloat Rule** | 2 | 0 (Stays within `fl_chart`) |
| **Blast Radius** | 2 | 0 (Scoped to new service and DTO) |
| **Architectural Integrity** | 1 | -1 (Domain role coupling risk) |
| **Data Sparsity Handling** | 1 | -1 (No minimum audit count guard) |
| **Rendering Performance** | 1 | 0 (Radar + Line within perf limits) |

**Total Score: RPT1 (-2) vs RPT Baseline (-5).**

## Final Verdict
**RPT1 (114319) is the selected architecture.** The backend will be responsible for computing actionable insights (variances, benchmarks) and delivering them alongside standard aggregates. The frontend will render these as natural language cards and comparative Radar/Line charts using the existing `fl_chart` library.

## Executive Business Summary
Instead of just showing managers a screen full of numbers and leaving them to guess if they are doing a good job, the system will now explicitly tell them what needs attention. For example, instead of just displaying "Safety Score: 85%", it will highlight a card saying "⚠️ Safety scores dropped 12% this week compared to your region." This drastically reduces the time it takes for managers to figure out where to focus their operational efforts, directly tying analytics to action without requiring a human data analyst.

---

## Handoff Block

### Final Verdict
Option 1 (RPT1) is selected.

### Strict Constraints (MANDATORY for Implementation)
1. **Performance Patch (N+1 Mitigation / Materialized Views):** The backend MUST NOT query regional averages synchronously for every user. Regional benchmarks must be computed by a background worker (e.g., nightly cron or an event-driven `StoreAnalyticsUpdater`) and cached in a fast table or Redis. `GetAnalytics.cs` must only read from this pre-computed cache.
2. **Data Sparsity Guard:** Generating alarms on thin data causes alarm fatigue. The `InsightGeneratorService` MUST enforce a `MinimumAuditCount` (e.g., > 3) and `MinimumTimeWindow` inside the Domain layer before generating variance insights.
3. **Dumb UI = Fast UI:** The Flutter app should NOT know how insights are generated. The .NET Backend must return `ActionableInsight` objects containing pre-formatted natural language strings (e.g., "Food Safety improved by 12%"). This ensures excellent separation of concerns.
4. **Keep it Native (Zero Bloat):** Stick strictly to `fl_chart` in Flutter. Do NOT install massive JS visualization libraries like AntV or Syncfusion. A simple radar chart combined with text-based "Insight Cards" is significantly more actionable.
5. **Architecture Patch:** PBAC roles must NOT be passed into the Domain layer. The HTTP layer (Endpoint) resolves the user's role and passes simple boolean flags to the Application/Domain layer.

### Execution Slices
- **Slice 1:** Backend Service (`InsightGeneratorService`) and materialized cache for benchmarks.
- **Slice 2:** API DTO Updates (`AnalyticsResponse`, `ActionableInsight`).
- **Slice 3:** Flutter UI Refactor (Executive Summary Cards & Radar Chart integration).

### Requirements Alignment Check
**User flow alteration detected.** The addition of the "Executive Summary" insight cards fundamentally changes the Analytics dashboard layout. **The relevant `requirements.md` file MUST be updated before proceeding to slice implementation.**

### AI Agent Mission Brief
Update the Analytics system to be insight-driven by implementing a cached backend `InsightGeneratorService` (with N+1 and sparsity safeguards) and a Flutter UI that consumes `ActionableInsight` objects to display natural-language summary cards and basic `fl_chart` visual upgrades.

### Next Command
```bash
/analyze-epic file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/decision_record_20260517_120515_SYN1_reporting.md
```
