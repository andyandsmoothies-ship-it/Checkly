# Walkthrough: BOD Analytics Slice 1 Implementation

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_20260524_151500_s1_bod_analytics.md`

## Decision Log
- **Pre-computed Snapshot Database Storage**: Implemented `BodReportSnapshot` entity representing the `bod_report_snapshots` table with a unique index on `Date` and the `Payload` column as PostgreSQL `jsonb` type for maximum OLAP query performance.
- **Idempotency Execution Strategy**: Background worker `BodReportWorker` uses an upsert strategy (`ON CONFLICT (Date) DO UPDATE`) to update the snapshot in-place for multiple nightly runs on the same date.
- **PartiallyFailed Resiliency Engine**: Wrapped the 6 distinct OLAP queries in separate `try/catch` scopes. If any query fails, the system logs a warning and inserts default values for that KPI section, setting the overall snapshot status to `PartiallyFailed`.
- **Distributed Concurrency Lock**: Enforced transaction-based Postgres advisory locks using the key `Checkly.BodReportWorker` through `DistributedLockManager` to prevent multiple background worker instances from running concurrently.
- **Corporate Timezone Anchor**: Parsed local `DateOnly` boundaries based on the `BodWorker:CorporateTimezone` configuration property (e.g. `Asia/Ho_Chi_Minh`), with clean UTC fallback.
- **Retention Lifespan Pruning**: Deletes pre-computed snapshot records older than 90 days on every execution tick.

## Verification Handoff
1. Clean and initialize database: The `AppDbContext` handles migrations seamlessly.
2. Run target integration test suite to verify data computations, timezone handling, pruning, concurrency, and resiliency:
   ```cmd
   cmd /c rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~Checkly.Api.Tests.Features.Analytics.BodReportWorkerTests"
   ```

## Test Trace
<test_trace>
Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:    10, Skipped:     0, Total:    10, Duration: 4.2 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

## Forensic Evidence
<forensic_evidence>
- Advisory lock key generated using FNV-1a 64-bit algorithm matches standard lock manager implementations.
- Database migrations correctly verified against PostgreSQL schema matching the generated columns `date`, `computed_at`, `status`, `payload`.
</forensic_evidence>

## Gotcha Protocol
No additional developer environment or local execution quirks were identified in this implementation slice.
