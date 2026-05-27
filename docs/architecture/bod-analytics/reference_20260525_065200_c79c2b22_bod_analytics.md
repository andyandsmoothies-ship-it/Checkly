# Boardroom (BOD) Analytics Technical Reference

This document serves as the absolute system architecture, database design, and frontend/backend reference for the Boardroom (BOD) Executive Analytics features.

## 1. System Topology & Flow

Here is a simplified text topology showing how the different components of the BOD Analytics system interact across offline/online layers:

```
[Flutter UI: BodAnalyticsPage]
       │ (State Management)
       ▼
[BodAnalyticsManager]
       │
       ├─► [Live Mode Filtered API] ──► GET /analytics/bod?province=Hanoi&district=...
       │                                     │ (On-the-fly execution)
       │                                     ▼
       │                               [BodReportCalculator]
       │                                     │
       │                                     ▼
       │                               [PostgreSQL DB] (Reads active records)
       │
       └─► [Standard Recalculation Flow]
               │ (1. POST /analytics/bod/refresh)
               ▼
         [RefreshBodReport Endpoint] ──► [PostgreSQL Advisory Lock] (Job concurrency)
               │ (2. Enqueues computation)
               ▼
         [BodReportWorker] ────────────► [BodReportCalculator]
               │                               │
               │ (3. Generates Snapshot JSONB) ┼──► [PostgreSQL DB]
               ▼                               │
         [BodSnapshots Table] ◄────────────────┘
               ▲
               │ (4. Polled every 5s by BodAnalyticsManager)
               └─► GET /analytics/bod ──► [GetBodReport Endpoint]
```

---

## 2. Code Directory Map

### Backend (ASP.NET Core .NET 10)
All files reside in the backend under `server/Features/Analytics/`:
* **[AnalyticsEndpoints.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/AnalyticsEndpoints.cs)**: Exposes API routes (`GET /analytics/bod`, `POST /analytics/bod/refresh`, and `/analytics/ap-bucket-detail`).
* **[BodReportDtos.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/BodReportDtos.cs)**: Declares strongly typed records representing the boardroom report structures (`BodChainKpis`, `BodCategoryWeakness`, `BodStoreRankEntry`, etc.).
* **[BodReportCalculator.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/BodReportCalculator.cs)**: The core mathematical engine containing highly optimized PostgreSQL database queries for average scores, action plan buckets, auditor productivity, and category compliance.
* **[BodReportWorker.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/BodReportWorker.cs)**: An asynchronous background worker that calculates snapshots and writes the resulting JSONB payloads to the `BodSnapshots` database table.
* **[GetBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/GetBodReport.cs)**: Resolves retrieval of either the latest pre-computed global snapshot or on-the-fly regional query projections.
* **[RefreshBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/RefreshBodReport.cs)**: Accepts manual background recalculation requests, using PostgreSQL transaction advisory locks to guarantee single worker execution.

### Frontend (Flutter/Dart Offline-First)
All files reside in the frontend under `lib/features/analytics/`:
* **[bod_analytics_page.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/pages/bod_analytics_page.dart)**: The main page widget that binds to the state manager and renders appropriate states (Loading, Offline, Empty, Success).
* **[bod_analytics_manager.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/manager/bod_analytics_manager.dart)**: Manages state, implements rate-limit exception handlers, executes asynchronous polling, and maintains filtering states.
* **[bod_analytics_data.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/manager/bod_analytics_data.dart)**: Houses Dart-native DTO models and deserializers (`fromJson` mappings) that gracefully parse both list and map representations of the AP Aging Buckets.
* **[bod_analytics_api_service.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/services/bod_analytics_api_service.dart)**: Standard API service connecting to backend HTTP endpoints using the preconfigured Dio client.
* **[widgets/](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/widgets/)**: Custom UI elements containing the regional filters and 6 executive cards:
  * `BodKpiGrid`: Total audits, average score, completion rate, open and overdue action plans.
  * `BodScoreTrend`: Line chart showing audit scores trends over time.
  * `BodStoreLeaderboard`: Bottom and top stores with performance metrics.
  * `BodCategoryWeakness`: Highlighting compliance failure spots.
  * `BodApAgingFunnel`: Funnel visual for action plans age distribution.
  * `BodAuditorScatter`: Audit volumes and scores completed per auditor.
  * `BodRegionFilterBar`: Interactive dropdowns to filter by Province and District.

---

## 3. Key Architectural Patterns & Logic Flows

### A. Strict Separation of Live vs. Cached Modes
To protect database performance from heavy analytical queries under high concurrency, the system applies a strict separation:

1. **Global/Live Mode (Cached by Default)**:
   - When the user views the entire chain, they are served a pre-computed boardroom report snapshot.
   - Recalculating this snapshot is resource-heavy, so it is processed asynchronously via `POST /analytics/bod/refresh` and cached in the `BodSnapshots` snapshot table as a `jsonb` column.
2. **Filtered/Interactive Mode (On-the-Fly)**:
   - When a user filters by Province or District (e.g. "Hanoi"), the query acts on a narrower database scope.
   - The API bypasses the snapshot table and queries active database records directly using highly optimized database indexes.
   - The frontend immediately sets `isLoading = false` without triggering server background workers or starting any async polling loop, keeping the UI fast and snappy.

### B. Rate-Limiting Protection (429) & Background Recalculation Polling
Because generating global snapshots is a heavy task, the server limits the frequency of recalculation requests. The interaction workflow is robust:

```
[Refresh Triggered]
       │
       ▼
   [POST /refresh]
       │
       ├─► HTTP 429: Rate Limit Exceeded
       │       │
       │       ▼
       │   [Manager Catch Block]
       │   - Stop loading indicator
       │   - Invoke InteractionManager.showWarningToast()
       │   - Prevent any polling loops from starting
       │
       └─► HTTP 200: Recalculation Enqueued
               │
               ▼
           [Start Polling Loop]
           - Capture current computedAt timestamp
           - Poll GET /analytics/bod every 5s
           - Max 12 attempts (60 seconds)
           - If new computedAt is detected: Update UI & Stop
           - If 60s timeout hits: Show warning toast & Stop
```

---

## 4. DB Snapshots & Advisory Locks
The background worker employs an **Advisory Lock** schema in PostgreSQL. Before starting a calculation job, the worker attempts to acquire an advisory lock:

```sql
SELECT pg_try_advisory_xact_lock(100201);
```

* **Purpose**: This ensures that even if multiple administrators trigger recalculations simultaneously, only a single computation job executes at any given moment. All subsequent requests are rejected or bypass execution, completely eliminating race conditions and thundering herds.
* **Storage**: The calculated snapshot is serialized to JSON and stored in a table structured as:
```sql
CREATE TABLE "BodSnapshots" (
    "Id" UUID PRIMARY KEY,
    "ComputedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "Status" VARCHAR(50) NOT NULL, -- e.g., 'Complete', 'PartiallyFailed'
    "Data" JSONB NOT NULL
);
```

---

## 5. QA Testing Strategy (ATDD & Unit Contracts)

### Flutter State Manager Unit Assertions
We maintain strict Detroit-style unit tests verifying that state changes match the contract. These are enforced in [bod_analytics_manager_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/manager/bod_analytics_manager_test.dart):
* **TC-BOD-INIT-01**: Verifies correct default initial state values.
* **TC-BOD-LOAD-01**: Verifies state transitions (Loading ➡️ Success) during successful data fetches.
* **TC-BOD-LOAD-02**: Verifies HTTP 404 responses are mapped to the empty dashboard state.
* **TC-BOD-LOAD-03**: Verifies Dio network failures trigger the offline connection UI.
* **TC-BOD-LOAD-04**: Verifies generic errors yield user-friendly error messages.
* **TC-BOD-REFRESH-01**: Confirms polling enqueues checks every 5 seconds and successfully completes when the `computedAt` timestamp changes.
* **TC-BOD-REFRESH-02**: Asserts that polling times out gracefully after 12 checks (60 seconds) and shows a warning toast.
* **TC-BOD-REFRESH-03**: Confirms that a `429 Rate Limit` failure triggers an immediate warning toast and skips polling completely.
* **TC-BOD-REFRESH-04**: Verifies that filtering immediately completes without initiating server recalculations.
