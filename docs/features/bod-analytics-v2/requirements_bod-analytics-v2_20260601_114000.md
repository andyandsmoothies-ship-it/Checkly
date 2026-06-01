---
conversation_id: "7e84733f-638e-4569-87dd-9901b796b109"
created_at: "2026-06-01T11:40:00+07:00"
topic: "bod-analytics-v2"
type: "other"
status: "COMPLETED"
---

# Boardroom (BOD) Analytics — Complete Feature Scope & Architecture (V5)

**Date**: 2026-06-01 | **ShortID**: c3563378
**Status**: Approved & Reference Design (Updated to include Store Manager tenancy bounds, Province Peer Quartile Rankings, SLA Overdue Action Plan aging buckets, and Admin Geofence Telemetry KPI)

---

## 1. Overview & Business Goal

The Boardroom (BOD) Analytics dashboard is a premium executive reporting screen designed for Checkly administrators and members of the Board of Directors. It provides a birds-eye view of corporate compliance, auditor productivity, store performance, and operational bottlenecks.

### The Business Terminology Map
To prevent confusion between business language and technical database language, we use this direct mapping:
* **UI/Business Language**: Users see and talk about **Audits** (e.g., "Total Audits", "Average Audit Score", "Audit Templates").
* **DB/Technical Code**: The database and API endpoints use the entity name **Submission** (e.g., `Submissions` table, `SubmissionSectionScores`, `GetBodReport`).
* **Rule**: We never rename database tables or C# classes to match the business language. We map them cleanly at the presentation layer.

### The Core Hybrid Design Pattern
Executive dashboards must load instantly but also support live, interactive exploration. We solve this using a **Hybrid OLAP (Online Analytical Processing) and OLTP (Online Transaction Processing) Architecture**:

```text
                  ┌──────────────────────────────────────────────┐
                  │                 Flutter UI                   │
                  └──────────────────────┬───────────────────────┘
                                         │
                    No Filter Active     │     Filters Applied
              ┌──────────────────────────┴──────────────────────────┐
              ▼                                                     ▼
    [ Nightly Cached Snapshot ]                            [ Live Dynamic Query ]
    - Calculated at 2:00 AM daily                          - Fetched live from DB
    - Loads in <50ms                                       - Computes filtered subset
    - Shows latest today's data                            - Shows latest today's data
```

---

## 2. System Architecture & Data Flow

### Pipeline A: The Nightly Snapshot Generator
Every night at 2:00 AM (in the corporate timezone), a background worker aggregates all compliance data and caches it as a single JSON payload.

```text
 [Db Background Job] ──► [Distributed Lock] ──► [BodReportCalculator] ──► [Save to PostgreSQL]
```

### Pipeline B: The Dynamic Live Filter & Drill-down
When an executive applies a regional filter (e.g., filtering by a specific Province or District), or taps a card to drill down into details, the system shifts into **Live Query Mode**.

```text
 [Flutter UI Page] ──► [Selects Province] ──► [GET /api/analytics/bod?province=Hanoi]
         │                                                      │
         ▼                                                      ▼
 [Shows Dynamic Badge] ◄── [Returns Live Response] ◄── [Dynamic SQL Query on DB]
```

---

## 3. The 6 Boardroom Cards & Interactive Drill-Downs

The dashboard contains 6 distinct analytical widgets. Each card has a specific purpose and an interactive drill-down path to reveal detailed data.

### Card 1: Executive KPI Grid
* **What it displays**: Total Audits, Average Compliance Score (with Flagship Benchmark subtitle when live-querying), Audit Completion Rate, Open & Overdue Action Plans, Average Time-to-Resolve (TTR), and **Geofence Bypasses count**.
* **State Alignment**: Fully aligned. The Flutter model correctly parses and displays `activeStores`, `totalAuditors`, and `geofenceBypassCount` KPIs.
* **Geofence Telemetry KPI**:
    * Mapped directly from backend `GeofenceBypassCount` (absolute count of completed, non-rejected audits submitted where `IsGeofenceBypassed = true`).
    * Displays inside Row 4 of the `BodKpiGrid` on the frontend, next to the Total Auditors card.
* **Drill-down behavior**: Tapping the Open/Overdue Action Plans tile opens the Action Plan Aging Bottom Sheet.

### Card 2: 12-Month Score Trend
* **What it displays**: A line chart showing the monthly average score trend over the last 12 months, with a Simple Moving Average (SMA) line overlay.
* **Drill-down behavior**: Tapping a monthly data point highlights the variance compared to the previous month and shows the audit count.

### Card 3: Store Leaderboard (Top & Bottom Stores)
* **What it displays**: Top 5 and bottom 5 performing stores based on average scores.
* **Dashboard Sorting & State Preservation**:
    * Stores leaderboard automatically supports worst-performing stores first sorting.
    * State preservation filters are fully retained during page operations.
* **Drill-down behavior**:
    * Tapping a store name opens the **Store Executive Summary Sheet** (also accessed as the **Store BOD Summary Sheet**).
    * Tapping the sync status indicator dot opens the **Store Synchronization Modal**. This modal displays the database sync age (e.g. "Synced just now") and features a `"Perform Live Sync"` button that simulates database synchronization.

### Card 4: Category Compliance Weaknesses
* **What it displays**: A bar chart displaying the 5 compliance categories with the lowest average scores.
* **Drill-down behavior**: Tapping a failing category bar opens the **Category Failure Bottom Sheet**, listing stores ordered worst-first for that category.

### Card 5: Action Plan Aging Funnel
* **What it displays**: A horizontal funnel dividing open action plans into four aging buckets: `0-7 days`, `8-30 days`, `31-90 days`, and `90+ days`.
* **State Alignment**: Fully aligned. The Flutter frontend maps and aggregates buckets matching the server schema (`0-7d`, `8-30d`, `31-90d`, `90d+`) to ensure perfect data binning.
* **Drill-down behavior**: Tapping an aging bucket opens the **Action Plan Bucket Details Sheet**. Returns a list containing `{ CriteriaLabel, StoreName, ManagerName, AgeInDays }`.

### Card 6: Auditor Productivity & Bias Scatter
* **What it displays**: A scatter plot mapping auditors by the number of completed audits and their average audit score.
* **Drill-down behavior**: Tapping an auditor's point opens the **Auditor Detail Bottom Sheet**. Displays the auditor's dynamic **Bias Rating** (Strict, Generous, Balanced), and total completed audits.

---

## 4. Fine-Grained Tenancy & Access Controls

To protect administrative dashboard data, both the backend APIs and frontend UI components strictly enforce a Role-Based and Policy-Based Access Control (RBAC/PBAC) framework.

### The Access Boundary Matrix

```text
[Auditor Login] ───> Attempt Endpoint/UI ───> returns 403 Forbidden (Strict Block)

[Store Manager] ───> Can view ONLY their own StoreId ───> otherwise 403 Forbidden

[Area Manager]  ───> Can view ONLY stores assigned via ProfileStoreAssignments ───> otherwise 403

[Admin / BOD]   ───> Unrestricted access (can view all stores and global statistics)
```

* **Auditors**: Strictly forbidden from accessing any BOD summary endpoints or views.
* **Store Managers**: Access is restricted strictly to their assigned `StoreId` stored on their `Profile` record. Attempting to view any other store results in a `403 Forbidden` rejection.
* **Area Managers**: Access is restricted strictly to the subset of stores assigned to them via the `ProfileStoreAssignments` table.
* **Admins & BOD Members**: Have unrestricted, full-scope access.

---

## 5. Peer Provincial Quartiles & Action Plan Aging for Stores

When a manager drills down into a specific store, they receive a customized executive report that contains localized peer benchmarking and remediation buckets:

### 1. Peer Provincial Quartiles
* **Rule**: The store is ranked against all active peer stores located in the same **Province**.
* **Statistical Constraint**: Ranking is only computed if there are **at least 4 active peer stores** in the same province. If this count is not met, the quartile rank label is set to `null` to avoid misleading data representation.
* **Quartile Classification Math**:
    * Compute store percentile ranking:
      $$\text{Percentile} = \frac{\text{Total Stores} - \text{Store Rank}}{\text{Total Stores}}$$
    * Map percentile value to a high-contrast regional quartile label:
        * `percentile >= 0.75` → `"Top 25% in Region"` (Success Green)
        * `percentile >= 0.50` → `"Top 50% in Region"` (Warning Yellow)
        * `percentile >= 0.25` → `"Top 75% in Region"` (Warning Yellow)
        * Otherwise → `"Bottom 25% in Region"` (Alert Red)

### 2. SLA Overdue Action Plans
* Expired open action plans are counted in UTC and binned into three visual compact status buckets:
    * **0–7 Days** (Green badge)
    * **8–30 Days** (Orange badge)
    * **31+ Days** (Red badge)

---

## 6. Technical API & DTO Specifications

### 1. Main Dashboard Report Endpoint
* **Route**: `GET /api/analytics/bod`
* **Query Parameters**:
  * `province` (string, optional)
  * `district` (string, optional)
* **Response Model DTO (`BodReportResponse`)**:
  ```json
  {
    "kpis": {
      "totalAudits": 42,
      "avgScore": 88.5,
      "completionRate": 92.4,
      "openActionPlans": 12,
      "overdueActionPlans": 4,
      "activeStores": 18,
      "totalAuditors": 6,
      "avgTtrDays": 3.2,
      "geofenceBypassCount": 2
    },
    "trend": [],
    "topStores": [],
    "bottomStores": [],
    "weaknesses": [],
    "actionPlanAging": [],
    "auditorProductivity": []
  }
  ```

### 2. Store Executive Summary Endpoint
* **Route**: `GET /api/analytics/stores/{storeId:guid}/bod-summary`
* **Response Model DTO (`StoreBodSummary`)**:
  ```json
  {
    "storeName": "Maycha Hanoi",
    "recentAudits": [
      {
        "date": "2026-06-01T10:00:00Z",
        "score": 90.0,
        "auditorName": "John Doe"
      }
    ],
    "categoryBreakdown": [
      {
        "categoryName": "Food Safety",
        "avgScore": 85.0
      }
    ],
    "quartileLabel": "Top 25% in Region",
    "regionalAvgScore": 82.5,
    "slaOverdueBuckets": [
      {
        "bucket": "0-7d",
        "count": 2
      },
      {
        "bucket": "8-30d",
        "count": 1
      },
      {
        "bucket": "31+d",
        "count": 0
      }
    ]
  }
  ```

---

## 7. Developer Gotchas & Safeguards

### Gotcha 1: PostgreSQL Null Inequality Comparison
Always structure inequality checks to explicitly allow null values: `(s.ReviewStatus == null || s.ReviewStatus != "rejected")`.

### Gotcha 2: UI Responsive Layout & Card Overflows
Always wrap title text and numerical labels in `Expanded` or `Flexible` widgets in Flutter to prevent horizontal layout overflows on small screens.

### Gotcha 3: Staggered Entrance Animations Memory Leak
Always cancel and clean up animations, tick controllers, and delayed timers inside the stateful widget's `dispose()` method to prevent test failures.

### Gotcha 4: No Database Drops in Production
Never use `EnsureDeleted()` in test setup without a hardcoded safeguard checking if the database connection string contains `_test`.

### Gotcha 5: Pre-computed Snapshot Polling
The Flutter frontend must poll the `GET /api/analytics/bod` result every 5 seconds until `computedAt` increases.

### Gotcha 6: OLAP Background Aggregations (Advisory Locking)
Protect background worker concurrency using PostgreSQL-native transaction-level advisory locks to eliminate race conditions.

### Gotcha 7: BOD Section Scores Key Mismatch
The backend `SectionScoreExploder.cs` extracts the human-readable section title from the nested `"title"` property inside `SubmissionSectionScores` JSON.

### Gotcha 8: Purged Singular Category Tag
Never re-introduce a singular `category_tag` column or property to `Template` or `Submission` models. All group-level or criterion-level tags must use the plural `CategoryTags` (string arrays).
