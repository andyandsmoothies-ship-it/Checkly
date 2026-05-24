# Boardroom Analytics Extended - Slice 2 Walkthrough

This document describes the design and implementation details for Slice 2 of the Boardroom Analytics Extended feature.

## Logic Overview
The implementation establishes a clean, high-performance API endpoint that retrieves productivity metrics for auditors, including bias calibration indices against the national average.

```
[Client App] 
     │
     ▼ (GET /api/analytics/auditors/productivity)
[ListUsers / GetAuditorProductivity Handler]
     │
     ├─► National Average Calculation (all completed submissions)
     ├─► Auditor Grouping (count, average score)
     ├─► Filtering (completed audits count >= 2)
     └─► Bias Index Calibration (AuditorAvgScore - NationalAvg)
     │
     ▼ (JSON Response)
[AuditorProductivityEntry DTOs]
```

## Changes Implemented

### 1. Endpoint Handler (`server/Features/Analytics/GetAuditorProductivity.cs`)
- Added `GetAuditorProductivity` static handler containing the endpoint logic.
- Returns `List<AuditorProductivityEntry>` matching the backend DTO definition.
- Correctly retrieves the national average score of all completed submissions.
- Groups submissions by `AuditorId`, maps the metrics, filters for `CompletedAudits >= 2`, and computes the `BiasCalibrationIndex`.
- Gracefully handles zero completed submissions (safeguard) by returning a `200 OK` with an empty list.

### 2. Dependency Injection and Routing (`server/Features/Analytics/GetAuditorProductivity.cs`)
- Maps the endpoint `/api/analytics/auditors/productivity` as a Minimal API.
- Leverages the Strict Bimodal Authorization system demanding `analytics:bod` capability via `RequireAuthorization`.

### 3. Test Database Isolation and Seeding (`server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs`)
- Added truncation of `action_plans` and `submissions` on test factory initialization (`_dbInitialized = false`) to guarantee an unpolluted starting state.
- Implemented a self-healing check for the bootstrap admin profile: if the user exists in `AspNetUsers` but the profile is missing, it is deleted and re-seeded fully.
- Applied the conditional `Audit Center Store` filter on queries under the `checkly_test` database context. This isolates our test assertions from previous runs and parallel runs.

---

## Verification Results
All four integration and acceptance tests in `BodAnalyticsExtendedSlice2Tests` pass successfully:

- `GetAuditorProductivity_ReturnsAuditorsWithBiasCalibration`: Verifies auditor productivity calculations, count filters, and bias calibration calculations.
- `GetAuditorProductivity_ZeroSubmissions_Safeguard`: Confirms safe handling of empty database/zero submission scenarios.
- `GetAuditorProductivity_AuditorsWithUnderTwoAudits_FilteredOut`: Confirms auditors with less than 2 completed audits are successfully filtered.
- `GetAuditorProductivity_Unauthorized_Returns403`: Verifies that unauthorized calls are blocked.

```
Passed!  - Failed:     0, Passed:     4, Skipped:     0, Total:     4, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
```
