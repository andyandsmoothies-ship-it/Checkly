<latent_space_scratchpad>
This slice focuses strictly on the deletion of the nightly snapshot infrastructure (worker, snapshot entity, snapshot DB configuration, refresh endpoint, and associated DI registrations) while modifying the main GET /api/analytics/bod endpoint to elegantly fall back to the live query path when the province filter is null.

Edge cases considered:
1. What if there are zero stores in the database? The live query path handles empty collections gracefully, returning zeroed KPI fields with a 200 OK.
2. What if a user with low capability calls the GET endpoint? It must still return a 403 Forbidden via the API's standard policy validation.
3. allowedActions: The frontend uses the presence of the "refresh" action in the `allowedActions` array to display the refresh button. Since we are removing the refresh capability, `allowedActions` returned in the dynamic live query path must omit "refresh" so the frontend automatically hides the button.
4. Database migrations: We will add an EF Core migration `DropBodReportSnapshotTable` that safely drops the table `bod_report_snapshots` and its index `IX_bod_report_snapshots_date`.

Testing:
- We will remove the obsolete `BodReportWorkerTests.cs` entirely.
- We will modify `BodAnalyticsEndpointTests.cs` to test the new live global endpoint behavior (asserting 200 OK, dynamic calculations on seeded submissions/action plans, and the presence of `isLiveData: true` in the response) instead of checking static snapshot data.
- We will delete the manual refresh rate-limiting and locking tests in `BodAnalyticsEndpointTests.cs` since that endpoint and the worker no longer exist.
- We will remove `GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot` from `BodAnalyticsFilteredEndpointTests.cs` as it specifically relies on the nightly worker.
</latent_space_scratchpad>

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\analysis_epic_20260601_140600.md`

## Executive Summary & Out of Scope
The goal of Slice 1 is to remove the nightly report snapshot caching layers and background processing worker entirely. This includes removing the `BodReportSnapshot` database table, the `BodReportWorker` background hosted service, and the manual `POST /api/analytics/bod/refresh` trigger endpoint. The main GET endpoint `/api/analytics/bod` will be modified to run the dynamic live query engine globally when no filters are provided, rather than serving a stale static snapshot.

**Out of Scope for Slice 1:**
- Creating optimized composite database indexes (Slice 2).
- Optimizing global live query execution plans and removing redundant filters (Slice 3).
- Adding complex integration tests for high-volume database scenarios (Slice 4).

## System Context
- **APIs**:
  - `GET /api/analytics/bod` (Global live analytics)
  - Deleted: `POST /api/analytics/bod/refresh`
- **Capabilities**:
  - Requires `AppCapabilities.AnalyticsBod` via the standard PBAC pipeline.
- **Allowed Actions**:
  - Omit `"refresh"` from the `allowedActions` response list since manual trigger is removed.
- **Telemetry**:
  - Standard minimal API structured logging remains active on the live query path.

## Lifecycle Context
### 4-State Matrix (GET /api/analytics/bod)
1. **Success State**: Returns HTTP 200 OK with the full live-calculated JSON KPI payload, trend array, leaderboards, and category weaknesses. `isLiveData` is set to `true`.
2. **Loading State**: Handled natively by the client client-side shimmer widgets while the REST call is outstanding.
3. **Empty State**: Returns HTTP 200 OK with zeroed KPIs and empty arrays when no stores or active submissions exist in the selected scope.
4. **Error State**: Returns HTTP 403 Forbidden for unauthorized roles, or HTTP 500 Internal Server Error if database queries fail.

## Constraint Traceability
| Input Requirement | Description | Test Contract ID |
| :--- | :--- | :--- |
| **REQ-01** | Delete snapshot database entity and table | TC-SL1-01 |
| **REQ-02** | Remove background worker hosted service and registration | TC-SL1-02 |
| **REQ-03** | Delete refresh on-demand endpoint | TC-SL1-03 |
| **REQ-04** | Fallback global GET route to dynamic live queries | TC-SL1-04 |

## Test Contracts
### TC-SL1-01: Table Drop Verification
- **Description**: Verify database schema compiles and updates correctly without `BodReportSnapshot` entity or configuration.
- **Fail-First Explanation**: Running migrations validation fails when database still attempts to reference `BodReportSnapshot` mapping.

### TC-SL1-02: Worker Removal Verification
- **Description**: Confirm background worker service `BodReportWorker` is removed from `Program.cs` and doesn't load.
- **Fail-First Explanation**: Program.cs fails to compile if `BodReportWorker` is still referenced in registrations.

### TC-SL1-03: Deletion of Refresh API
- **Description**: Verifies `POST /api/analytics/bod/refresh` returns 404 Not Found.
- **Fail-First Explanation**: Calling the refresh endpoint returns 404 instead of rate-limited response or 200 OK.

### TC-SL1-04: Global Live Fallback
- **Description**: Verifies `GET /api/analytics/bod` (with no province filter) returns HTTP 200 OK with `isLiveData: true` and dynamically calculated values.
- **Fail-First Explanation**: Calling the endpoint returns 404 or falls back to snapshot database check, resulting in a database exception or "not found" error.

## Test Fixture & Payloads
### Setup Requirements
- Seeding 1 Active Store, 1 Completed Submission (score = 90.0), and 1 Open Action Plan in the database prior to calling GET `/api/analytics/bod`.

### Payloads: GET /api/analytics/bod (Global)
**Response Payload (200 OK):**
```json
{
  "isLiveData": true,
  "kpis": {
    "totalAudits": 1,
    "avgScore": 90.0,
    "completionRate": 100.0,
    "openActionPlans": 1,
    "overdueActionPlans": 0,
    "activeStores": 1,
    "totalAuditors": 1,
    "avgTtrDays": 0.0,
    "geofenceBypassCount": 0
  },
  "goldenStore": {
    "storeName": "Hanoi Express Store",
    "avgScore": 90.0,
    "province": "Hanoi"
  },
  "trend": [
    {
      "month": "2026-06",
      "avgScore": 90.0,
      "auditCount": 1
    }
  ],
  "topStores": [
    {
      "storeId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "storeName": "Hanoi Express Store",
      "avgScore": 90.0,
      "auditCount": 1,
      "lastSyncedAt": null
    }
  ],
  "bottomStores": [
    {
      "storeId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "storeName": "Hanoi Express Store",
      "avgScore": 90.0,
      "auditCount": 1,
      "lastSyncedAt": null
    }
  ],
  "weaknesses": [],
  "actionPlanAging": [
    {"bucket": "0-7d", "count": 1},
    {"bucket": "8-30d", "count": 0},
    {"bucket": "31-90d", "count": 0},
    {"bucket": "90d+", "count": 0}
  ],
  "auditorProductivity": [
    {
      "auditorId": "d3b07384-d113-49c6-80cd-33fe9266a2a6",
      "auditorName": "John Doe",
      "completedAudits": 1,
      "avgScore": 90.0
    }
  ],
  "allowedActions": []
}
```

## Tools & Commands
- **Required Skills**: `ef-core`, `testing-strategy`
- **Execution Command**: `rtk dotnet build`
- **Testing Command**: `rtk dotnet test`

## Proposed Changes
### [DEL] server/Features/Analytics/BodReportWorker.cs
- Remove the nightly background worker service class.

### [DEL] server/Features/Analytics/RefreshBodReport.cs
- Remove the manual on-demand trigger handler endpoint.

### [DEL] server/Common/Persistence/Entities/BodReportSnapshot.cs
- Delete the snapshot entity.

### [DEL] server/Common/Persistence/Configurations/BodReportSnapshotConfiguration.cs
- Delete the EF Core mapping configuration for snapshot table.

### [DEL] server/tests/Checkly.Api.Tests/Features/Analytics/BodReportWorkerTests.cs
- Obsolete test class for nightly worker.

### [MOD] server/Common/Persistence/AppDbContext.cs
- Remove `DbSet<BodReportSnapshot> BodReportSnapshots` property mapping.

### [MOD] server/Program.cs
- Remove registration of `BodReportWorker` background service:
  ```csharp
  // Delete lines:
  builder.Services.AddSingleton<BodReportWorker>();
  builder.Services.AddHostedService(sp => sp.GetRequiredService<BodReportWorker>());
  ```

### [MOD] server/Features/Analytics/AnalyticsEndpoints.cs
- Remove `POST /bod/refresh` map registration:
  ```csharp
  // Delete line:
  group.MapPost("/bod/refresh", RefreshBodReport.HandleAsync).RequireCapability(AppCapabilities.AnalyticsBod);
  ```

### [MOD] server/Features/Analytics/GetBodReport.cs
- Modify the filter checks. Make the `province` check optional inside the dynamic live path, running calculations globally when it is null.
- Remove lines 409-449 which query `AppDbContext.BodReportSnapshots`.

### [MOD] server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsEndpointTests.cs
- Clean up obsolete `DELETE FROM bod_report_snapshots` calls.
- Delete refresh endpoints tests: `RefreshBodReport_AsAuditor_ReturnsForbidden`, `RefreshBodReport_AsAdmin_TriggersRefresh`, `RefreshBodReport_RateLimitsConsecutiveRequests`, `RefreshBodReport_ConcurrentTriggers_RespectsLock`.
- Update `GetBodReport_AsAdmin_ReturnsSuccessAndPayload` to seed stores, submissions, and action plans and assert live-computed responses instead of reading from seeded snapshot payload.
- Update `GetBodReport_EmptyDatabase_ReturnsNotFound` to assert that an empty database returns a 200 OK with zeroed KPIs instead of 404 (since live calculations are gracefully zero-fallback).

### [MOD] server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsFilteredEndpointTests.cs
- Remove obsolete test `GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot` which relies on nightly worker class.

### [NEW] Database Migration
- Add `DropBodReportSnapshotTable` EF core migration to drop table `bod_report_snapshots`.

## Concept Diagram
```
Before:
[Client] --> GET /bod ---------> [AppDbContext (Snapshots Table)]
[Client] --> POST /bod/refresh -> [BodReportWorker] -> [Compute & Write Snapshot]

After (Slice 1):
[Client] --> GET /bod ---------> [AppDbContext (Live Stores & Submissions)]
```

## Execution Slices

### Slice 1: Delete Background Worker, Snapshots Infrastructure, and Setup Live Fallback
- **Summary**: Deletes `BodReportWorker`, `RefreshBodReport`, `BodReportSnapshot` database entities, updates DI registration in `Program.cs`, endpoint registry in `AnalyticsEndpoints.cs`, and refactors `GetBodReport.cs` to execute dynamic queries globally when `province` is null.
- **Value**: Establishes a completely clean compiler build, removes fragile caching layers, and redirects the global analytics dashboard to run live calculations.
- **Entry State**: Snapshot system, worker, and refresh endpoints are active.
- **Exit State**: Background worker, snapshot table, and refresh endpoint are deleted. Global `/api/analytics/bod` GET route correctly serves live queries with `isLiveData: true`. Codebase compiles with 0 warnings.
- **Complexity Rating**: Medium (requires careful modification of integration tests to assert live queries instead of snapshot seeding).
- **Acceptance Criteria**:
  1. `BodReportWorker.cs`, `RefreshBodReport.cs`, `BodReportSnapshot.cs`, `BodReportSnapshotConfiguration.cs`, and `BodReportWorkerTests.cs` are completely deleted from disk.
  2. `AppDbContext.cs` lacks `BodReportSnapshots` property and compiling runs with zero database references.
  3. `Program.cs` and `AnalyticsEndpoints.cs` compile cleanly without registrations for the deleted classes/routes.
  4. Integration tests in `BodAnalyticsEndpointTests.cs` and `BodAnalyticsFilteredEndpointTests.cs` compile cleanly and pass with `rtk dotnet test`.

<command_logs>
- `rtk dotnet build`
</command_logs>

## Handoff Block
Absolute plan path: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice1_20260601_145500.md`

Please proceed sequentially with:
- **Slice 1**: Plan -> Write Acceptance & Unit Tests -> Build
- **Handoff Target**: Execute Step 5: Route Selection. We recommend **Route 3 (Acceptance Tests First)** since this slice involves database modifications, API deletion, and backend integration test refactoring.
