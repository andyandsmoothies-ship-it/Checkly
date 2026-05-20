# Test Execution Log: SL-2 Phase B2 (Server API Layer)

## Test Environment
- **Target**: `checkly_test` Database
- **Framework**: xUnit v3 / .NET 10
- **Timestamp**: 2026-05-20T06:27:55+07:00

## Test Results

All 537 tests passed.

```text
Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:   537, Skipped:     7, Total:   544, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
```

## Specific Coverage Verified
- **AnalyticsTests.AM_Can_Access_Area_Leaderboard**: Passed (verifies PBAC analytics:area).
- **ProvinceLeaderboardEndpointTests**: All 3 scenarios passed (isolated database generation with Guid naming).
- **ProvinceBenchmarkCalculatorTests**: Calculator bounds and thresholds passed.
