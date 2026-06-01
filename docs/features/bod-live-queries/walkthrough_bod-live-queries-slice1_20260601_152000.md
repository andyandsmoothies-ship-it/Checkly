---
ConversationID: 326acb94-76b9-487a-9906-54fa1bd07b9b
---

# Walkthrough: BOD Live Queries Slice 1

This walkthrough details the complete implementation of **BOD Live Queries Slice 1**, removing the obsolete nightly snapshot infrastructure and manual refresh endpoint, and transitioning the global analytics endpoint to dynamic database-driven live calculations.

## Architectural Changes

Before these changes, the system used a background worker to run nightly queries, save static JSON results in a snapshot table, and serve them:

```
[Client App] ──(GET)──> [/api/analytics/bod] ──> [BOD Snapshot Table] <──(Nightly Worker)── [Database Entities]
```

After Slice 1, the snapshot table and worker are removed entirely, and the dashboard query is computed live from the main database:

```
[Client App] ──(GET)──> [/api/analytics/bod] ──(Dynamic Query)──> [Submissions/Stores/APs] ──> [Live Computed KPIs]
```

## Files Deleted

- `server/Features/Analytics/BodReportWorker.cs` (Obsolete nightly worker & seeder helper)
- `server/Features/Analytics/RefreshBodReport.cs` (Obsolete manual refresh endpoint)
- `server/Common/Persistence/Entities/BodReportSnapshot.cs` (Obsolete database snapshot entity)
- `server/Common/Persistence/Configurations/BodReportSnapshotConfiguration.cs` (Obsolete EF Core database config)
- `server/tests/Checkly.Api.Tests/Features/Analytics/BodReportWorkerTests.cs` (Obsolete background job tests)

## Files Modified

### 1. `server/Common/Persistence/AppDbContext.cs`
- Removed the declaration of `DbSet<BodReportSnapshot> BodReportSnapshots`.

### 2. `server/Program.cs`
- Removed dependency injection registrations for `BodReportWorker` background service.
- Retained the `BodReportCalculator` registration for unit tests.

### 3. `server/Features/Analytics/AnalyticsEndpoints.cs`
- Removed the endpoint mapping for `/api/analytics/bod/refresh` (`RefreshBodReport`).

### 4. `server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsEndpointTests.cs`
- Fully refactored `GetBodReport_AsAdmin_ReturnsSuccessAndPayload` to seed dynamic entities (Store, Submission, ActionPlan) and query them live, verifying the dynamic JSON response structure.
- Refactored `GetBodReport_EmptyDatabase_ReturnsZeroedKpisAndIsLiveTrue` to assert `200 OK` with zeroed KPIs instead of `404 Not Found`.
- Deleted all obsolete refresh rate-limiting and concurrent lock tests.

### 5. `server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsFilteredEndpointTests.cs`
- Removed the obsolete test `GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot` which referenced `BodReportWorker`.

## Database Migrations

Created and verified a new EF Core migration:
- **Migration Name**: `DropBodReportSnapshotTable`
- **File**: `server/Common/Persistence/Migrations/20260601081459_DropBodReportSnapshotTable.cs`
- **Action**: Drops the `bod_report_snapshots` table from the Postgres database.
