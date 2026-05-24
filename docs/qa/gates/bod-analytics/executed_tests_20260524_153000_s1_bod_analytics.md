# Executed Tests: BOD Analytics Slice 1

Date: 2026-05-24
Test Suite: `Checkly.Api.Tests.Features.Analytics.BodReportWorkerTests`

## Execution Command
```cmd
rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~Checkly.Api.Tests.Features.Analytics.BodReportWorkerTests"
```

## Raw Output Log
<test_trace>
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:    10, Skipped:     0, Total:    10, Duration: 4.2 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

## Forensic Evidence
<forensic_evidence>
Executed target integration tests via dotnet test runner with rtk wrapper.
All 10 integration test cases passed cleanly, verifying the data pre-computation worker, lock, timezone resolution, idempotency updates, resilient calculators, and retention pruning policies.
</forensic_evidence>

## Details of Executed Scenarios
1. **`AppCapabilities_Has_AnalyticsBod_Constant_Reflected`**: Verifies static capability definition matches specification.
2. **`Capability_AnalyticsBod_IsSeededForAdmin`**: Asserts role-capability mapping exists for 'admin' role in database.
3. **`AppDbContext_Has_BodReportSnapshots_Property_Configured`**: Verifies the DB schema property is mapped to the table properly.
4. **`RunNightlyJobAsync_TwiceOnSameDate_IsIdempotent`**: Verifies that duplicate calculations on the same day update snapshots in place.
5. **`RunNightlyJobAsync_OneQueryFails_SavesWithPartiallyFailedStatus`**: Tests resiliency fallback logic: if one OLAP query fails, other values are saved and status is marked `PartiallyFailed`.
6. **`PruneOldSnapshotsAsync_PrunesSnapshotsOlderThan90Days`**: Checks snapshot lifetime management and older snapshot clean-up.
7. **`BodReportWorker_AcquiresDistributedLock_AndPreventsParallelRuns`**: Verifies that parallel execution ticks are protected via pg advisory lock concurrency guards.
8. **`DerivesDateOnly_UsingConfiguredCorporateTimezone`**: Tests DateOnly mapping based on corporate timezone offset config.
9. **`ResolveTimeZone_InvalidTimeZoneName_FallsBackGracefully`**: Verifies UTC fallback handling for invalid timezone identifiers.
10. **`RunNightlyJobAsync_EmptyDatabase_ExecutesWithoutCrashing`**: Asserts fallback KPIs on an empty database (zero matching records) returns safe defaults.
