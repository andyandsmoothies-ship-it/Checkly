---
ConversationID: aa0d4917-b447-4894-b6c8-3c45d26b9ecd
---

# Slice 1 Task: Live BOD Report Fallback & Endpoint Cleanup

```
 [Client API Call] ---> [GET /api/analytics/bod]
                             |
                             +---> If Completed Snapshot exists -> Return Snapshot (isLive: false)
                             |
                             +---> Else -> Execute Live Calculation -> Return Live DTO (isLive: true)
                                         |
                                         +---> Empty DB: Return Zeroed KPIs
                                         +---> Seeded DB: Perform memory/SQL aggregation

 [GET /api/analytics/bod/refresh] ---> DELETED (Returns 404 Not Found)
```

## 1. Executive Summary
The acceptance tests for **BOD Live Queries - Slice 1** have been authored and verified. They are fully compiling and failing for the correct business logic reasons (RED). This task handoff provides the exact steps for the Builder to implement the production changes to satisfy the acceptance criteria.

## 2. Verified Test Failures (RED for the Right Reason)

All three acceptance tests in [BodLiveQueries_Slice1_Tests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/BodLiveQueries_Slice1_Tests.cs) fail with exact business mismatches:

### A. Fallback on Empty Database
* **Test**: `GetGlobalReport_EmptyDatabase_ReturnsZeroedKpisAndIsLiveTrue`
* **Current Error**: 
  ```
  Expected HTTP 200 OK for live query fallback on empty DB, but got NotFound. 
  Body: {"error":"No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM."}
  ```
* **Why**: The endpoint currently hard-fails with `404` when no completed snapshot is found in the database.

### B. Live Aggregation on Seeded Submissions
* **Test**: `GetGlobalReport_SeededSubmissions_ReturnsLiveComputedValues`
* **Current Error**:
  ```
  Expected HTTP 200 OK for live query calculation, but got NotFound. 
  Body: {"error":"No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM."}
  ```
* **Why**: The endpoint does not perform live SQL/in-memory calculations to aggregate submission metrics when snapshots are absent.

### C. Deprecated Refresh Endpoint Cleanup
* **Test**: `PostRefreshReport_ReturnsNotFound`
* **Current Error**:
  ```
  Expected HTTP 404 Not Found for deleted refresh endpoint, but got OK. 
  Body: {"status":"triggered","computedAt":"2026-06-01T08:06:51.81051+00:00"}
  ```
* **Why**: The `POST /api/analytics/bod/refresh` route remains fully active in the route configuration.

---

## 3. Builder Implementation Checklist

### Core Endpoint Cleanup
- [ ] **Delete Endpoint**: Remove `POST /api/analytics/bod/refresh` from the route mappings in `server/src/Checkly.Api/Features/Analytics/BodAnalyticsEndpoint.cs` (or equivalent feature routing registry).
- [ ] **Prune Dependencies**: Delete any background job triggers or command handlers specific only to the synchronous manual refresh, if they are no longer referenced.

### Live Fallback & Calculation Engine
- [ ] **Modify Route**: Update `GET /api/analytics/bod` inside `BodAnalyticsEndpoint.cs` to check for a completed snapshot:
  - If a snapshot exists, return it with `isLive: false` (existing behavior).
  - If **no** snapshot exists, execute a dynamic live calculation of all non-rejected submissions (`ReviewStatus != "rejected"` or `ReviewStatus == null`) across all stores.
- [ ] **Live Calculator Logic**:
  - Filter submissions to those matching `ReviewStatus != "rejected"` or `ReviewStatus == null` (see PostgreSQL Null inequality gotcha).
  - Calculate KPIs:
    - **`totalAuditors`**: Count of distinct `ProfileId` (auditors) who submitted at least one qualifying audit.
    - **`totalAudits`**: Total count of qualifying submissions.
    - **`completedPrograms`**: Number of distinct `ProgramId` represented in the qualifying submissions.
    - **`averageAuditScore`**: Simple average of all qualifying submissions' `Score` field. If there are no audits, average score is `0.00`.
    - **`geofenceBypassCount`**: Total count of submissions where `GeofenceBypassCount > 0` (as defined in `BodKpiGrid` gotcha).
  - Wrap these live metrics inside the target DTO, mapping the `isLive` boolean flag to `true`.
- [ ] **C# Gotchas to Watch**:
  - **Null Inequality translation bug**: Ensure comparisons like `ReviewStatus != "rejected"` are written as `(s.ReviewStatus == null || s.ReviewStatus != "rejected")` in EF Core queries.
  - **No Division-by-Zero**: Ensure the average score does not fail when `totalAudits == 0`.

---

## 4. Key Files to Refer and Edit

### Related Test File (Read/Run Only)
* [BodLiveQueries_Slice1_Tests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/BodLiveQueries_Slice1_Tests.cs) (Verify code passes after coding)

### Target Production Files to Modify
* [BodAnalyticsEndpoint.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/src/Checkly.Api/Features/Analytics/BodAnalyticsEndpoint.cs) (Contains route mapping and GET/POST handlers)

### Reference Domain Entities
* [Submission.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/src/Checkly.Api/Common/Persistence/Entities/Submission.cs)
* [BodReportSnapshot.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/src/Checkly.Api/Common/Persistence/Entities/BodReportSnapshot.cs)

---

## 5. Verification Commands

Run the targeted acceptance tests to verify implementation correctness:
```powershell
rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter BodLiveQueries_Slice1_Tests
```
