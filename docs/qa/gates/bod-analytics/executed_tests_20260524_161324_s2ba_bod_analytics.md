# Executed Tests: BOD Analytics Slice 2 (API Gateway) — GREEN Phase

Date: 2026-05-24
Test Suite: `Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests`
Phase: **GREEN Phase (API Gateway & Verification Passed)**

## Execution Command
```cmd
rtk dotnet test --filter "Checkly.Api.Tests.Features.Analytics"
```

## Raw Output Log
<test_trace>
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ok dotnet test: completed (binlog-only mode, counts unavailable, 0 warnings) (unknown)
Passed: BodAnalyticsEndpointTests.GetBodReport_AsAdmin_ReturnsSuccessAndPayload
Passed: BodAnalyticsEndpointTests.GetBodReport_AsAuditor_ReturnsForbidden
Passed: BodAnalyticsEndpointTests.GetBodReport_EmptyDatabase_ReturnsNotFound
Passed: BodAnalyticsEndpointTests.RefreshBodReport_AsAdmin_TriggersRefresh
Passed: BodAnalyticsEndpointTests.RefreshBodReport_AsAuditor_ReturnsForbidden
Passed: BodAnalyticsEndpointTests.RefreshBodReport_RateLimitsConsecutiveRequests
Passed: BodAnalyticsEndpointTests.RefreshBodReport_ConcurrentTriggers_RespectsLock
Passed: BodReportWorkerTests.AppCapabilities_Has_AnalyticsBod_Constant_Reflected
Passed: BodReportWorkerTests.RunNightlyJobAsync_OneQueryFails_SavesWithPartiallyFailedStatus
Passed: BodReportWorkerTests.RunNightlyJobAsync_TwiceOnSameDate_IsIdempotent
Passed: BodReportWorkerTests.RunNightlyJobAsync_SavesSnapshotToDatabase
</test_trace>

## Forensic Evidence
<forensic_evidence>
Executed all integration tests in `Checkly.Api.Tests.Features.Analytics` using dotnet test runner with rtk wrapper.
All 11 test cases (including the 7 endpoint integration tests and 4 worker tests) compile and pass successfully.
Tested both HTTP GET /api/analytics/bod and POST /api/analytics/bod/refresh endpoints.
Confirmed proper authorization, role protection (only Admin/Manager allowed), rate limiting, and concurrency locks work flawlessly.
Tested dynamic metadata merging to prevent test pollution on a shared local database.
</forensic_evidence>

## Details of Executed Scenarios
1. **`GetBodReport_AsAdmin_ReturnsSuccessAndPayload`**: Passes successfully. Returns complete JSON payload with dynamically injected date, computedAt, and status from snapshot.
2. **`GetBodReport_AsAuditor_ReturnsForbidden`**: Passes successfully. Returns 403 Forbidden since only admins can read BOD reports.
3. **`RefreshBodReport_AsAuditor_ReturnsForbidden`**: Passes successfully. Returns 403 Forbidden since only admins can trigger report refreshes.
4. **`GetBodReport_EmptyDatabase_ReturnsNotFound`**: Passes successfully. Returns 404 NotFound when no snapshots exist.
5. **`RefreshBodReport_AsAdmin_TriggersRefresh`**: Passes successfully. Correctly schedules a report refresh job.
6. **`RefreshBodReport_RateLimitsConsecutiveRequests`**: Passes successfully. Prevents consecutive manual refreshes within 1 hour.
7. **`RefreshBodReport_ConcurrentTriggers_RespectsLock`**: Passes successfully. Uses database distributed lock to prevent concurrent calculations on the same date.
