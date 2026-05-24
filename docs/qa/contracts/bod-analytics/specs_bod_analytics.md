# Handoff Specifications: BOD Analytics Slice 1 (Data Engine)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_20260524_151500_s1_bod_analytics.md`

---

## 🛠️ Test Infrastructure Map

The following map defines exactly how each of the 8 acceptance criteria is physically mapped to our integration test suite inside `BodReportWorkerTests.cs` and `BodReportWorkerStubs.cs`:

| Scenario ID | Scenario Name | Test Method / Execution Logic | Target Verification |
|---|---|---|---|
| **TC-SL1-01** | Idempotent Snapshot Upsert | `RunNightlyJobAsync_TwiceOnSameDate_IsIdempotent()` | Verifies that executing the background task twice on the same DateOnly does not create duplicate entries in the database, updating the single row dynamically. |
| **TC-SL1-02** | Query Resiliency with PartiallyFailed Status | `RunNightlyJobAsync_OneQueryFails_SavesWithPartiallyFailedStatus()` | Feeds a custom `FakeFailingBodReportCalculator` to verify that when individual query blocks fail, the worker writes the snapshot with `Status = "PartiallyFailed"` and preserves partial JSON content instead of crashing or throwing exceptions. |
| **TC-SL1-03** | Retention Pruning | `PruneOldSnapshotsAsync_PrunesSnapshotsOlderThan90Days()` | Seeds database rows with DateOnly parameters at `AddDays(-91)` and `AddDays(-89)` to confirm that only rows older than 90 days are deleted during the cleanup tick. |
| **TC-SL1-04** | Distributed Locking | `BodReportWorker_AcquiresDistributedLock_AndPreventsParallelRuns()` | Pre-acquires a transaction-scoped advisory lock on connection 1 and triggers the worker on connection 2, asserting that it gracefully skips execution. |
| **TC-SL1-05** | Timezone-Aware Date | `DerivesDateOnly_UsingConfiguredCorporateTimezone()` | Asserts timezone-conversion behavior for Vietnam (UTC+7) and Eastern US (UTC-4) at specific boundaries. |
| **TC-SL1-06** | Static Capabilities | `AppCapabilities_Has_AnalyticsBod_Constant_Reflected()` <br> `Capability_AnalyticsBod_IsSeededForAdmin()` | Uses reflection to assert that `AppCapabilities.AnalyticsBod` exists and is seeded in the PostgreSQL `role_capabilities` table for the "admin" role. |
| **TC-SL1-07** | Timezone Fallback | `ResolveTimeZone_InvalidTimeZoneName_FallsBackGracefully()` | Verifies that an invalid timezone name yields UTC gracefully rather than raising unhandled OS-level exceptions. |
| **TC-SL1-08** | Zero Submissions | `RunNightlyJobAsync_EmptyDatabase_ExecutesWithoutCrashing()` | Verifies that runs against an empty database populate default aggregates like `TotalAudits = 0` safely. |

---

## 🚦 Instructions for Builder Handoff

1. **Test Environment**:
   - Tests run against the logical `checkly_test` database (Logical Database Separation is handled automatically by `TestWebApplicationFactory`).
   
2. **Implementation Sequence**:
   - The Builder must define the static action capability `"analytics:bod"` in `server/Common/Auth/AppCapabilities.cs` and map it to `admin` in db seeding (`Program.cs` / `TestWebApplicationFactory.cs`).
   - The Builder must register the `BodReportSnapshot` entity in `AppDbContext.cs`.
   - The Builder must implement `BodReportCalculator` and `BodReportWorker` background worker to compute and prune analytics snapshots nightly.
   - Delete the temporary test stub `BodReportWorkerStubs.cs` once the production structures are fully coded and compiled in their proper assemblies!
