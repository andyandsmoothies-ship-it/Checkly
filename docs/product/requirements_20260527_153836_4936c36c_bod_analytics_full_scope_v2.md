# Boardroom (BOD) Analytics — Complete Feature Scope & Architecture (V2)

**Date**: 2026-05-27 | **ShortID**: 4936c36c
**Status**: Approved & Reference Design (Updated with Gap Sweep)

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
    - Serves baseline KPIs                                 - Shows latest today's data
```

---

## 2. System Architecture & Data Flow

### Pipeline A: The Nightly Snapshot Generator
Every night at 2:00 AM (in the corporate timezone, e.g., `Asia/Ho_Chi_Minh`), a background worker aggregates all compliance data and caches it as a single JSON payload.

```
 [Db Background Job] ──► [Distributed Lock] ──► [BodReportCalculator] ──► [Save to PostgreSQL]
 (BodReportWorker)       (Prevents multiple     (Runs 6 DB queries to   (Stores as JSONB in
  runs at 2:00 AM         workers running)       generate snapshot)      BodReportSnapshots)
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

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            BOD Analytics Screen                             │
├──────────────────────────────────────┬──────────────────────────────────────┤
│ 1. KPI Grid (Total Audits, Avg Score,│ 2. MoM Compliance Trend (12-Month)   │
│    Completion Rate, Action Plans)    │    - Tapping shows monthly details    │
│    - Drill-down: AP Funnel Sheet     │                                      │
├──────────────────────────────────────┼──────────────────────────────────────┤
│ 3. Store Leaderboard (Top/Bottom)    │ 4. Category Weaknesses (Failing Bars)│
│    - Drill-down: Store Summary Sheet │    - Drill-down: Store Failures Sheet│
├──────────────────────────────────────┼──────────────────────────────────────┤
│ 5. Action Plan Aging Funnel (Buckets)│ 6. Auditor Productivity Scatter      │
│    - Drill-down: Open APs Sheet      │    - Drill-down: Auditor Detail Sheet│
└──────────────────────────────────────┴──────────────────────────────────────┘
```

### Card 1: Executive KPI Grid
* **What it displays**:
  * **Total Audits Completed**: Count of all non-rejected completed submissions.
  * **Average Compliance Score**: Rounded mean score of scored templates.
  * **Flagship Benchmark Subtitle**: Under the Average Compliance Score, the UI displays a benchmark label comparing the organization to the top store: `"X% of flagship (Store Name Y%)"`. The top store is the store with the highest average score and at least one completed audit in the last 30 days. Note: This benchmark footer is populated dynamically when filters are active (live query mode); in the baseline nightly snapshot response, `goldenStore` is `null` and the benchmark subtitle is hidden in the UI by default.
  * **Audit Completion Rate**: Percentage of completed scheduled audits.
  * **Open & Overdue Action Plans**: Outstanding corrective action plans.
  * **Average Time-to-Resolve (TTR)**: Average days taken to close resolved action plans (`avgTtrDays`). Note: In the pre-computed nightly snapshot payload, `avgTtrDays` defaults to `0.0` (not pre-calculated by the background job), but it is fully computed dynamically when queries shift to the live filtered path.
* **Drill-down behavior**:
  * Tapping the **Open/Overdue Action Plans** tile opens the **Action Plan Aging Bottom Sheet**, displaying all pending corrective plans across the organization.
  * Displays a Month-over-Month (MoM) variance indicator (e.g. `+2.4% ↑` or `-1.1% ↓`) computed client-side.

### Card 2: 12-Month Score Trend
* **What it displays**: A line chart showing the monthly average score trend over the last 12 months, with a Simple Moving Average (SMA) line overlay to highlight long-term directions.
* **Drill-down behavior**: Tapping a monthly data point highlights the variance compared to the previous month and shows the audit count for that specific period.

### Card 3: Store Leaderboard (Top & Bottom Stores)
* **What it displays**: Two side-by-side lists showing the top 5 performing stores and the bottom 5 performing stores based on their average score in the last 30 days.
* **Drill-down behavior**:
  * Tapping a store name opens the **Store Executive Summary Sheet**, displaying the store's last 5 audits, average scores, and its top 3 failing compliance categories.
  * Tapping the sync status indicator dot (Green = Sync Healthy, Red = Out of Sync) opens the **Store Synchronization Modal** (`BodStoreSyncModal` bottom sheet). This modal displays the database sync age (e.g. "Synced just now" or "Synced 2h ago") and features a `"Perform Live Sync"` button that simulates database synchronization.

### Card 4: Category Compliance Weaknesses
* **What it displays**: A bar chart displaying the 5 compliance categories (e.g. "Food Safety", "Fire Prevention") with the lowest average scores over the last 90 days.
* **Drill-down behavior**:
  * Tapping a failing category bar opens the **Category Failure Bottom Sheet**.
  * Displays a list of all stores, ordered worst-first, showing their individual compliant scores and audit counts for that category.

### Card 5: Action Plan Aging Funnel
* **What it displays**: A horizontal funnel dividing open action plans into four aging buckets:
  * `0-7 days`
  * `8-30 days`
  * `31-90 days`
  * `90+ days`
* **Drill-down behavior**:
  * Tapping an aging bucket opens the **Action Plan Bucket Details Sheet**.
  * Queries real database action plans where age falls into the selected duration.
  * Returns a list containing: `{ CriteriaLabel, StoreName, ManagerName, AgeInDays }`. Note: The `Deadline` column is not mapped or returned in the `ApDetailEntry` DTO by the live database endpoint.

### Card 6: Auditor Productivity & Bias Scatter
* **What it displays**: A scatter plot mapping auditors by the number of completed audits (X-axis) and their average audit score (Y-axis). Helps executives spot strict or generous grading behaviors.
* **Data Retrieval**: This card queries data from a dedicated server API endpoint `GET /api/analytics/auditors/productivity`.
* **Drill-down behavior**:
  * Tapping an auditor's point opens the **Auditor Detail Bottom Sheet**.
  * Displays the auditor's dynamic **Bias Rating**:
    * **Strict**: Average score is 5.0+ points below the national average.
    * **Generous**: Average score is 5.0+ points above the national average.
    * **Balanced**: Average score falls within 5.0 points of the national average.
  * Displays total completed audits and a list of stores audited in the selected time range.

---

## 4. Database Integration & O(1) Telemetry

To support real-time interaction without degrading server performance under heavy boardroom query loads, the database schema integrates two vital optimizations:

### 1. O(1) Store Synchronization Telemetry
Instead of querying millions of audit transaction rows to calculate when a store last synchronized its offline device, we store an in-place column directly on the `Stores` table:

```
┌───────────────────────────────────────┐
│                 Store                 │
├───────────────────────────────────────┤
│ Id (PK)                               │
│ Name                                  │
│ Address2 (Province, District)         │
│ LastSyncedAt (DateTime?, Nullable)    │  ◄── O(1) In-place timestamp
└───────────────────────────────────────┘
```
* Every time a device syncs, the server executes a quick, direct `UPDATE Stores SET LastSyncedAt = NOW() WHERE Id = @StoreId`.
* Reading the sync status on the leaderboard is a simple, zero-join project query.

### 2. Standard Owned Address Geography for Fast Filtering
The owned `StoreAddress` configuration maps geographic boundaries natively:
* `Store.Address2.Province`
* `Store.Address2.District`
Database queries utilize owned properties on these columns. Note: While designed for speed, composite database indexes are not registered in the EF Core configuration (`StoreConfiguration.cs`) for `address_province` and `address_district` in the current version. Live queries run performant single-table filtering.

---

## 5. Technical API & DTO Specifications

### 1. Main Dashboard Report Endpoint
* **Route**: `GET /api/analytics/bod`
* **Query Parameters**:
  * `province` (string, optional) — Filter by province.
  * `district` (string, optional) — Cascading filter by district.
* **Response Model Schema**:
  The response structure varies slightly depending on whether the baseline nightly snapshot is served or a live dynamic regional query is active.

#### Structure A: Dynamic Live Query (Province/District Filters Active)
```json
{
  "isLiveData": true,
  "kpis": {
    "totalAudits": 482,
    "avgScore": 82.4,
    "completionRate": 94.2,
    "openActionPlans": 12,
    "overdueActionPlans": 3,
    "activeStores": 45,
    "totalAuditors": 8,
    "avgTtrDays": 4.5
  },
  "goldenStore": {
    "storeName": "Hanoi Central Store",
    "avgScore": 95.0,
    "province": "Hanoi"
  },
  "trend": [
    { "month": "2025-06", "avgScore": 81.2, "auditCount": 40 },
    { "month": "2025-07", "avgScore": 83.5, "auditCount": 42 }
  ],
  "topStores": [
    { "storeId": "guid", "storeName": "Store A", "avgScore": 95.5, "auditCount": 5, "lastSyncedAt": "2026-05-26T02:00:00Z" }
  ],
  "bottomStores": [
    { "storeId": "guid", "storeName": "Store Z", "avgScore": 62.1, "auditCount": 4, "lastSyncedAt": "2026-05-25T18:30:00Z" }
  ],
  "weaknesses": [
    { "categoryName": "Food Safety", "templateTitle": "Food Safety Check", "avgScore": 72.1, "auditCount": 24 }
  ],
  "actionPlanAging": [
    { "bucket": "0-7d", "count": 5 },
    { "bucket": "8-30d", "count": 4 },
    { "bucket": "31-90d", "count": 2 },
    { "bucket": "90d+", "count": 1 }
  ],
  "auditorProductivity": [
    { "auditorId": "guid", "auditorName": "John Doe", "completedAudits": 15, "avgScore": 84.2 }
  ],
  "allowedActions": ["refresh"]
}
```

#### Structure B: Nightly Cached Snapshot (No Filter Active)
```json
{
  "kpis": {
    "totalAudits": 482,
    "avgScore": 82.4,
    "completionRate": 94.2,
    "openActionPlans": 12,
    "overdueActionPlans": 3,
    "activeStores": 45,
    "totalAuditors": 8,
    "avgTtrDays": 0.0
  },
  "goldenStore": null,
  "trend": [
    { "month": "2025-06", "avgScore": 81.2, "auditCount": 40 }
  ],
  "topStores": [
    { "storeId": "guid", "storeName": "Store A", "avgScore": 95.5, "auditCount": 5, "lastSyncedAt": null }
  ],
  "bottomStores": [
    { "storeId": "guid", "storeName": "Store Z", "avgScore": 62.1, "auditCount": 4, "lastSyncedAt": null }
  ],
  "weaknesses": [
    { "categoryName": "Food Safety", "templateTitle": "Food Safety Check", "avgScore": 72.1, "auditCount": 24 }
  ],
  "actionPlanAging": [
    { "bucket": "0-7d", "count": 5 }
  ],
  "auditorProductivity": [
    { "auditorId": "guid", "auditorName": "John Doe", "completedAudits": 15, "avgScore": 84.2 }
  ],
  "status": "completed",
  "date": "2026-05-26",
  "computedAt": "2026-05-26T02:00:00Z",
  "allowedActions": ["refresh"]
}
```

### 2. Store Executive Summary Endpoint
* **Route**: `GET /api/analytics/stores/{storeId}/bod-summary`
* **Response Model (`StoreBodSummary`)**:
  ```json
  {
    "storeName": "Hanoi Central Store",
    "recentAudits": [
      { "date": "2026-05-20T10:00:00Z", "score": 85.0, "auditorName": "John Doe" }
    ],
    "categoryBreakdown": [
      { "categoryName": "Food Safety", "score": 70.2 },
      { "categoryName": "Customer Experience", "score": 92.5 }
    ]
  }
  ```

### 3. Category Compliance Details Endpoint
* **Route**: `GET /api/analytics/bod/category/{name}`
* **Response Model (`List<CategoryStoreEntry>`)**:
  ```json
  [
    { "storeName": "Store Z", "avgScore": 55.4, "auditCount": 6, "failureCount": 3 },
    { "storeName": "Store Y", "avgScore": 72.0, "auditCount": 5, "failureCount": 1 }
  ]
  ```

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

### 5. Auditor Productivity Endpoint
* **Route**: `GET /api/analytics/auditors/productivity`
* **Response Model (`List<AuditorProductivityEntry>`)**:
  ```json
  [
    {
      "auditorId": "guid",
      "auditorName": "John Doe",
      "completedAudits": 15,
      "avgScore": 84.2,
      "biasRating": "Generous"
    }
  ]
  ```

### 6. On-Demand Report Refresh Endpoint
* **Route**: `POST /api/analytics/bod/refresh`
* **Behavior**: Triggers a background recalculation of the BOD snapshot. Protected by an advisory lock to prevent multiple concurrent calculations.
* **Response Model**:
  ```json
  {
    "status": "triggered",
    "computedAt": "2026-05-26T08:00:00Z"
  }
  ```
  *(Returns `429 Too Many Requests` with a `retryAfter` message if rate-limited, or `409 Conflict` if locked).*

---

## 6. Developer Gotchas & Safeguards

To maintain Checkly's premium feel and technical reliability, developers must adhere to these strict execution rules:

### Gotcha 1: PostgreSQL Null Inequality Comparison
In EF Core queries targeting PostgreSQL, any inequality comparison like:
```csharp
s.ReviewStatus != "rejected"
```
will silently exclude all records where `ReviewStatus` is `NULL`. This occurs because PostgreSQL evaluates `NULL != 'rejected'` as falsy.
* **The Safeguard**: Always structure inequality checks to explicitly allow null values:
  ```csharp
  (s.ReviewStatus == null || s.ReviewStatus != "rejected")
  ```

### Gotcha 2: UI Responsive Layout & Card Overflows
On narrow mobile screens or headless integration test environments, horizontal components inside the KPI cards can easily overflow.
* **The Safeguard**: Always wrap title text and numerical labels in `Expanded` or `Flexible` widgets, and use descriptive icons instead of verbose text strings.

### Gotcha 3: Staggered Entrance Animations Memory Leak
Highly active animations (e.g. bouncy buttons, staggered list wraps) instantiate internal timers. If the timer reference is not disposed, tests will fail with a `"A Timer is still pending even after the widget tree was disposed"` exception.
* **The Safeguard**: Always cancel and clean up animations, tick controllers, and delayed timers inside the stateful widget's `dispose()` method.

### Gotcha 4: No Database Drops in Production
* **The Safeguard**: Never write test setup or teardown logic (such as `EnsureDeleted()`) without hardcoded safeguards that explicitly verify the database name ends in `_test`.

### Gotcha 5: Pre-computed Snapshot Polling
When triggering on-demand calculations (e.g. via `POST /api/analytics/bod/refresh`), the API returns immediately while calculations complete in the background.
* **The Safeguard**: The Flutter frontend must poll the GET endpoint every 5 seconds (with a 60s timeout fallback) until the retrieved `computedAt` timestamp increases, showing a loading shimmer in the meantime to ensure real-time visual accuracy without instant page snaps.

### Gotcha 6: OLAP Background Aggregations (Advisory Locking)
To prevent database performance degradation under heavy aggregate queries, boardroom analytics are calculated in a nightly background job and cached as `jsonb` documents in a snapshot table.
* **The Safeguard**: Protect worker concurrency using PostgreSQL-native transaction-level advisory locks to eliminate race conditions and thundering herds.

### Gotcha 7: BOD Section Scores Key Mismatch
Do not assume `SubmissionSectionScores` JSON uses raw names or simple keys. The Flutter frontend `_buildSectionScoresJson()` serializes group details under distinct keys (the group UUIDs) with nested `title`, `score`, and `maxScore`/`maxPoints` properties.
* **The Safeguard**: The backend `SectionScoreExploder.cs` extracts the human-readable section title from this nested `"title"` property to match UI category queries, falling back to the property name key for older or simpler payloads.

---

## 7. Developer Guide: How to Add New Drill-Downs

When extending the boardroom dashboard with a new analytical card:
1. **Model First**: Design the C# record DTO in `BodReportDtos.cs` and the corresponding Dart model class in `bod_analytics_data.dart`.
2. **Endpoint Separation**: Create a separate endpoint handler class instead of modifying `BodReportCalculator.cs`. Keep the calculator small and maintainable.
3. **No Page Navigations**: Always present detailed views inside an overlay modal sheet (`showModalBottomSheet`) to preserve the executive's filtered filter state.
4. **Integration Testing**: Always write a contract integration test. Assert response contents and print out response bodies on failures to make errors clear.
