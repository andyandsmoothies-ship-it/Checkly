# Checkly Boardroom Analytics & Multi-Field Architectural Report

```text
[Submission Type: QC, General, Training]
                   │
                   ├─► [Filter Gate: Type == "QC"] ─────────► [Store Leaderboard & Weaknesses]
                   ├─► [Filter Gate: Type == "General"] ────► [Completion & TTR Analytics]
                   └─► [Filter Gate: Type == "Training"] ───► [HR Course Metrics & Compliance]
```

This report analyzes the expansion of the Boardroom (BOD) Dashboard to cover new business fields (Facility Maintenance, HR Training, and Customer Experience) and documents three critical architectural blind spots identified during implementation.

---

## 1. Boardroom Analytics Multi-Field Vision

To support enterprise clients with multi-departmental operations, the BOD dashboard must segment metrics across the three core template archetypes:

### Metric Allocation Map
| Business Field | Underlying Archetype | Key Boardroom Metric | Goal / Target |
| :--- | :--- | :--- | :--- |
| **Quality Control (QC)** | `'QC'` | Brand Standard Compliance % | > 90.0% compliance |
| **Operations & Checklists** | `'General'` | Completion Rate & Avg TTR | > 95.0% completion, < 2.0 days TTR |
| **HR & Safety Training** | `'Training'` | Staff Course Completion % | 100.0% completion rate |

### Core Expansion Features
1. **Departmental Breakdown Card**: Displays separate mini-tiles for each archetype so executives can see which department is lagging behind.
2. **Dynamic Leaderboard Toggles**: Allows the leaderboard to rank stores by *Quality score*, *Checklist completion speed*, or *Training compliance*.
3. **Cross-Field Correlation Engine**: Plots Store Training Completion against Store QC score to statistically prove the return on investment (ROI) of training programs.

---

## 2. Technical Audit of Newly Identified Blind Spots

During the architectural audit of `BodReportCalculator.cs`, three potential failures were discovered:

### Blind Spot 1: "Category Weakness" Data Pollution (Severity: CRITICAL)
* **Status**: Query 4 (`Category Weaknesses`) pulls data from `SubmissionSectionScores` where `MaxScore > 0`.
* **The Failure**: If an employee fails a **Training Quiz** (e.g. "Module 1 Safety Quiz"), that quiz section has points (`MaxScore > 0`). As a result, training failures will be pulled into the Boardroom Operational Weaknesses, diluting and polluting actual store compliance metrics (e.g., food safety issues).
* **The Code-Level Gap**:
  ```csharp
  // CURRENT CODE (Lacks archetype filter)
  var sectionStats = await db.SubmissionSectionScores.AsNoTracking()
      .Where(ss => ss.CreatedAt >= start90DaysAgo && ss.CreatedAt <= targetDateTime && ss.MaxScore > 0)
  ```
* **The Solution**: Apply a `.Where(ss => ss.Submission.Template.Type == "QC")` filter to isolate operational category weaknesses.

---

### Blind Spot 2: Action Plan Generation on Unscored Checklists (Severity: MEDIUM)
* **Status**: Scored audits ('QC') generate Action Plans based on point deductions.
* **The Failure**: For `'General'` operational checklists (Task Campaigns), there are no points—tasks are marked as simple checkmarks (Pass/Fail). If the backend action plan generator expects point reductions or score calculations, it will trigger null-pointer exceptions or compute incorrect statistics.
* **The Solution**: Ensure the Action Plan engine bypasses all mathematical score evaluations for non-QC submissions and maps failed checklist rows directly to task tickets.

---

### Blind Spot 3: "Cold-Start" Empty Store Display (Severity: LOW)
* **Status**: The store leaderboard calculates rankings using `Average(s.TotalScore)`.
* **The Failure**: Newly opened stores have **0 completed submissions**. These stores will be excluded from the database queries. When the Flutter frontend opens a newly opened store's dashboard page, the lack of data could cause a layout crash or present a confusing `0%` score (which falsely implies a total quality failure).
* **The Solution**: Ensure the Flutter widgets use clean conditional rendering (`if (score == null) ShowEmptyPlaceholder()`) to welcome new stores without error flags.

---

### Blind Spot 4: Chain-Level Average Score & Trend Inflation (Severity: CRITICAL)
* **Status**: Query 1 (Chain KPIs) and Query 2 (12-Month Trend) in `BodReportCalculator.cs` and `GetBodReport.cs` calculate averages using only `s.ScoringMode != "survey" && s.TotalScore.HasValue`.
* **The Failure**: When HR Training quizzes (`'Training'`) are introduced, they are scored exams (not surveys) and have total scores. The system will mix employee training scores into the store operational compliance scores.
* **The Solution**: Inject the archetype filter gate `(s.TemplateId == null || s.Template!.Type == "QC")` into both nightly and live average calculations.

---

### Blind Spot 5: "Global Golden Store" Course Contamination (Severity: HIGH)
* **Status**: `GetBodReport.cs` (line 132) queries the highest average score globally to crown the "Global Golden Store" on the dashboard benchmark footer.
* **The Failure**: Because there is no archetype check, a store completing simple training courses with 100% scores will contaminate the query and steal the benchmark title from a genuine top-performing compliance store.
* **The Solution**: Apply the `s.Template.Type == "QC"` gate to the benchmark query.

---

### Blind Spot 6: Departmental Completion Rate Skew (Severity: MEDIUM)
* **Status**: The completion rate is calculated chain-wide as `totalAudits / totalScheduled`.
* **The Failure**: Checking a daily checklist (`General`) is frequent, whereas a regulatory quality audit (`QC`) is weekly. Merging these targets means a checklist delay will mathematically hide severe lags in critical safety inspections.
* **The Solution**: Isolate completion rates on the dashboard by template archetype rather than presenting a single global metric.

---

## 3. Recommended Implementation Sequence

To resolve these gaps and secure Checkly for multi-field scaling, implement the following steps:

```text
[Step 1: Fix Queries 1, 2, 4 & Benchmark] ──► [Step 2: Add AP Guards] ──► [Step 3: Flutter UI empty states]
```

1. **Secure Core Analytics**: Inject the `Template.Type == "QC"` gate into Query 1, Query 2, Query 4, and the Golden Store query in both `BodReportCalculator.cs` and `GetBodReport.cs`.
2. **Insulate Action Plans**: Verify and add guards to the Action Plan service to prevent mathematical errors on unscored checklists.
3. **Graceful UI Layout**: Update the Flutter `bod_dashboard_body.dart` and `bod_kpi_grid.dart` to cleanly handle null/empty store states.
