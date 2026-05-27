# Boardroom (BOD) Analytics — Complete Feature Scope & Architecture (V4)

**Date**: 2026-05-27 | **ShortID**: c3563378
**Status**: Approved & Reference Design (Resolves code drifts: aligned Action Plan Aging Funnel to server schema, mapped activeStores/totalAuditors KPIs, corrected BodGoldenStore mapping)

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

```
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

```
 [Db Background Job] ──► [Distributed Lock] ──► [BodReportCalculator] ──► [Save to PostgreSQL]
```

### Pipeline B: The Dynamic Live Filter & Drill-down
When an executive applies a regional filter (e.g., filtering by a specific Province or District), or taps a card to drill down into details, the system shifts into **Live Query Mode**.

```
 [Flutter UI Page] ──► [Selects Province] ──► [GET /api/analytics/bod?province=Hanoi]
         │                                                      │
         ▼                                                      ▼
 [Shows Dynamic Badge] ◄── [Returns Live Response] ◄── [Dynamic SQL Query on DB]
```

---

## 3. The 6 Boardroom Cards & Interactive Drill-Downs

The dashboard contains 6 distinct analytical widgets. Each card has a specific purpose and an interactive drill-down path to reveal detailed data.

### Card 1: Executive KPI Grid
* **What it displays**: Total Audits, Average Compliance Score (with Flagship Benchmark subtitle when live-querying), Audit Completion Rate, Open & Overdue Action Plans, and Average Time-to-Resolve (TTR).
* **State Alignment**: Fully aligned. The Flutter model correctly parses and displays `activeStores` and `totalAuditors` KPIs, and maps the `BodGoldenStore` DTO including its `province` field.
* **Drill-down behavior**: Tapping the Open/Overdue Action Plans tile opens the Action Plan Aging Bottom Sheet.

### Card 2: 12-Month Score Trend
* **What it displays**: A line chart showing the monthly average score trend over the last 12 months, with a Simple Moving Average (SMA) line overlay.
* **Drill-down behavior**: Tapping a monthly data point highlights the variance compared to the previous month and shows the audit count.

### Card 3: Store Leaderboard (Top & Bottom Stores)
* **What it displays**: Top 5 and bottom 5 performing stores based on average scores.
* **Drill-down behavior**:
  * Tapping a store name opens the **Store Executive Summary Sheet**.
  * Tapping the sync status indicator dot opens the **Store Synchronization Modal**. This modal displays the database sync age (e.g. "Synced just now") and features a `"Perform Live Sync"` button that simulates database synchronization (Note: Live sync is simulated on the frontend, there is no dedicated `/sync` API).

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

## 4. Database Integration & O(1) Telemetry

### 1. O(1) Store Synchronization Telemetry
We store an in-place column directly on the `Stores` table (`LastSyncedAt`). Every time a device syncs, the server executes a quick, direct `UPDATE`.

### 2. Standard Owned Address Geography for Fast Filtering
The owned `StoreAddress` configuration maps geographic boundaries natively (`Store.Address2.Province`, `Store.Address2.District`), allowing performant single-table filtering.

---

## 5. Technical API & DTO Specifications

### 1. Main Dashboard Report Endpoint
* **Route**: `GET /api/analytics/bod`
* **Query Parameters**:
  * `province` (string, optional)
  * `district` (string, optional)
* **Response Model Schema**: Varies slightly depending on whether the baseline nightly snapshot is served or a live dynamic regional/date query is active. *(See V2 document for full schema example).*

### 2. Store Executive Summary Endpoint
* **Route**: `GET /api/analytics/stores/{storeId:guid}/bod-summary`
* **Purpose**: Retrieves the store's last 5 audits, average scores, and top 3 failing compliance categories.

### 3. Category Compliance Details Endpoint
* **Route**: `GET /api/analytics/bod/category/{name}`
* **Purpose**: Retrieves a list of stores that are failing the most in a specific category.

### 4. Action Plan Aging Detail Endpoint
* **Route**: `GET /api/analytics/bod/ap/{bucket}`
* **Response Model (`List<ApDetailEntry>`)**:
  ```json
  [
    {
      "id": "guid",
      "criteriaLabel": "Check temperature log missing entries",
      "storeName": "Store Z",
      "managerName": "Michael Scott",
      "ageInDays": 94
    }
  ]
  ```

### 5. Auditor Productivity Aggregate Endpoint
* **Route**: `GET /api/analytics/auditors/productivity`
* **Purpose**: Retrieves the top-level scatter plot data (Auditor ID, name, completed audits, average score, and dynamic Bias Rating).

### 6. On-Demand Report Refresh Endpoint
* **Route**: `POST /api/analytics/bod/refresh`
* **Purpose**: Triggers a background recalculation of the BOD snapshot using an advisory lock.

---

## 6. Developer Gotchas & Safeguards

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

---

## 7. Developer Guide: How to Add New Drill-Downs

When extending the boardroom dashboard with a new analytical card:
1. **Model First**: Design the C# record DTO in `BodReportDtos.cs` and the corresponding Dart model class in `bod_analytics_data.dart`.
2. **Endpoint Separation**: Create a separate endpoint handler class instead of modifying `BodReportCalculator.cs`.
3. **No Page Navigations**: Always present detailed views inside an overlay modal sheet (`showModalBottomSheet`).
4. **Integration Testing**: Always write a contract integration test. Assert response contents and print out response bodies on failures.
