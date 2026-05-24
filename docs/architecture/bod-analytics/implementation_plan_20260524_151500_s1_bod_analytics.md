<latent_space_scratchpad>
Target: Implement the nightly pre-computed BOD analytics engine.
Key constraints:
1. Idempotency: Daily Upsert (date is unique index). Runs again on same date -> updates existing row, doesn't insert new.
2. PartiallyFailed status: If any query in the calculator fails (e.g. Query 3 throws because of bad store data), catch it, mark the snapshot status as PartiallyFailed, but save the other completed query payloads.
3. Retention pruning: Delete snapshots older than 90 days.
4. AppCapabilities seeding: Seed AppCapabilities.AnalyticsBod ("analytics:bod") in BOTH Program.cs and TestWebApplicationFactory.cs.
5. Distributed lock: Worker must run inside TryExecuteInLockAsync using "Checkly.BodReportWorker" as the lock key.
6. Timezone anchor: Worker must read corporate timezone from configuration "BodWorker:CorporateTimezone" (defaults to "Asia/Ho_Chi_Minh" or "SE Asia Standard Time" depending on OS) and use it to determine the local Date for aggregation.
7. Technical vs Business naming: Technical model is BodReportSnapshot, payload is jsonb.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\analysis_epic_20260524_142100_bod_analytics.md`

## Executive Summary & Out of Scope
Slice 1 builds the high-performance Data Engine for Board of Directors (BOD) Analytics. It establishes the database persistence layer, a background worker execution system, an idempotent aggregate calculator that runs 6 distinct OLAP-style queries, and automatic data lifecycle management.

### Out of Scope
- HTTP Endpoints (`GET /api/analytics/bod`, `POST /api/analytics/bod/refresh`) - covered in Slice 2.
- UI views, Flutter managers, and widget layouts - covered in Slice 3.
- Rate-limiting rules (429 handling) on API routes - covered in Slice 2.

## System Context
- **Data Lifecycle Model**: Nightly Aggregation (materialized view in a Postgres JSONB column).
- **Worker Execution Frequency**: Runs nightly at 02:00 AM (Corporate Timezone).
- **Concurrency Protection**: Coordinated distributed lock via `DistributedLockManager`.
- **Security & PBAC**: Capability `analytics:bod` is defined as a granular static string in `AppCapabilities.cs` and seeded.

## Lifecycle Context
The Data Engine worker computes snapshots which can have the following lifecycle statuses:
- **`Complete`**: All 6 queries succeeded, full JSON payload is stored.
- **`PartiallyFailed`**: At least one query failed/threw. The successful queries' payloads are saved; failed sections contain fallback empty states.
- **`Pruned`**: Snapshots older than 90 days are deleted.

## Constraint Traceability

| Constraint ID | Description | Test Contract ID |
|---|---|---|
| C-SL1-01 | Idempotency: Upsert updates the row on repeat runs for the same date. | TC-SL1-01 |
| C-SL1-02 | PartiallyFailed status when a query throws, preserving other query data. | TC-SL1-02 |
| C-SL1-03 | Retention policy: Prune rows older than 90 days. | TC-SL1-03 |
| C-SL1-04 | Distributed locking protects execution against parallel worker instances. | TC-SL1-04 |
| C-SL1-05 | Corporate Timezone is configurable and parsed safely. | TC-SL1-05 |
| C-SL1-06 | Capability `analytics:bod` is seeded on app startup and in test factory. | TC-SL1-06 |

## Test Contracts

| Test ID | Description | State Matrix | Why it fails first |
|---|---|---|---|
| **TC-SL1-01** | Running calculator twice on same date updates the single row (Count = 1). | Single date, multiple runs. | EF Core would try to INSERT and throw duplicate key / unique index violation, or insert 2 rows. |
| **TC-SL1-02** | Query 3 throws exception -> snapshot saved with `Status = "PartiallyFailed"`. | Submissions seeded, Query 3 mocked failure. | Calculator would crash the whole worker without saving anything, or throw unhandled. |
| **TC-SL1-03** | Snapshot with date 91 days ago is deleted when worker runs. | 1 row 91 days old, 1 row today. | The old row is left in the DB, count remains 2. |
| **TC-SL1-04** | Running worker in parallel only executes calculation once. | Lock active. | Both workers run the calculation, creating a race condition. |
| **TC-SL1-05** | Derives local Date using the configured timezone instead of UtcNow.Date. | Configured timezone. | Mismatch between corporate date boundaries and UTC. |
| **TC-SL1-06** | Capability `analytics:bod` is assigned to Admin role and available in tests. | Admin registration, PBAC cache. | Role lacks capability, returning 403. |

## Test Fixture & Payloads
Acceptance tests will run in `Checkly.Api.Tests` using a dedicated Postgres integration database.
### Required Test Fixtures
- Seeded stores (at least 3 active stores).
- Seeded submissions (at least 5 completed audits across the stores over the past 30 days).
- Seeded action plans (some open, some overdue).
- Seeded auditor profile (active auditor user).

## Tools & Commands
- **Required Skills**: `dotnet-rbac-authorization`, `ef-core`
- **Execution Command**: `rtk dotnet test --filter "FullyQualifiedName~Checkly.Api.Tests.Features.Analytics"`

## Proposed Changes

### `[MOD]` `server/Common/Auth/AppCapabilities.cs`
- Add `public const string AnalyticsBod = "analytics:bod";` constant.

### `[NEW]` `server/Common/Persistence/Entities/BodReportSnapshot.cs`
- Entity class with `Id`, `Date` (DateOnly), `ComputedAt` (DateTimeOffset), `Status` (string), `Payload` (string).

### `[NEW]` `server/Common/Persistence/Configurations/BodReportSnapshotConfiguration.cs`
- EF Core table mapping configuration:
  - Table name: `bod_report_snapshots`
  - Unique index on `Date`
  - Column types: `Payload` as `jsonb`, `Status` as `character varying(20)`

### `[MOD]` `server/Common/Persistence/AppDbContext.cs`
- Add `public DbSet<BodReportSnapshot> BodReportSnapshots => Set<BodReportSnapshot>();`

### `[NEW]` `server/Features/Analytics/BodReportDtos.cs`
- DTO records for `BodReportResponse`, `BodChainKpis`, `BodStoreRankEntry`, `BodApAgingBucket`, `BodAuditorProductivity`.

### `[NEW]` `server/Features/Analytics/BodReportCalculator.cs`
- Aggregate calculator. Executes 6 queries:
  1. **Chain KPIs**: Current period vs prior period deltas (Total audits, Avg score, Completion rate, Open/Overdue APs, Active stores, Total auditors).
  2. **12-Month Trend**: Performance trend (reuses existing `TrendPoint`).
  3. **Top/Bottom Stores**: Store rankings by average score in past 30 days.
  4. **Category Weakness**: Weakest template sections in past 90 days.
  5. **Action Plan Aging**: Open AP count grouped by age buckets (0-7d, 8-30d, 31-90d, 90d+).
  6. **Auditor Productivity**: Completed audits and average score per auditor in past 30 days.
- Uses `try/catch` block for each query. If any query fails, log warning, fill with empty default, and set final `Status = PartiallyFailed`.

### `[NEW]` `server/Features/Analytics/BodReportWorker.cs`
- Background service executing nightly at 02:00 AM (configured Corp TZ).
- Uses `DistributedLockManager` to run safely inside a lock (`Checkly.BodReportWorker`).
- Derives DateOnly using the configured corporate timezone.
- Runs calculator, performs Upsert (`ON CONFLICT (date) DO UPDATE`), and prunes rows older than 90 days.

### `[MOD]` `server/Program.cs`
- Add `builder.Services.AddHostedService<BodReportWorker>();` registration.
- Add `'analytics:bod'` capability to admin in the SQL startup script.

### `[MOD]` `server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs`
- Seed `'analytics:bod'` capability in SQL seed statement inside `EnsureDatabaseCreated`.

### `[NEW]` `server/tests/Checkly.Api.Tests/Features/Analytics/BodReportWorkerTests.cs`
- Integration tests validating the worker execution, calculations, PartiallyFailed fallback, and retention pruning.

## Concept Diagram

```
[Trigger: 02:00 AM OR Admin POST /refresh]
               │
               ▼
   [Acquire Distributed Lock]
    Key: "Checkly.BodReportWorker"
               │
               ▼
[Determine Local Corporate DateOnly]
  Read: "BodWorker:CorporateTimezone"
               │
               ▼
    [Execute BodReportCalculator]
    ├── Query 1: Chain KPIs
    ├── Query 2: 12-Month Trend
    ├── Query 3: Top/Bottom Stores (Last 30d)
    ├── Query 4: Category Weaknesses (Last 90d)
    ├── Query 5: AP Aging Buckets
    └── Query 6: Auditor Productivity (Last 30d)
   (Robust Try/Catch wraps each query independently)
               │
               ▼
[Upsert to DB: public.bod_report_snapshots]
   ON CONFLICT (Date) DO UPDATE
               │
               ▼
    [Retention Pruner Engine]
   DELETE WHERE Date < Today - 90 Days
```

## Execution Slices

### Slice 1 — Data Engine (Micro-Spec)
- **Summary**: Establish the DB table, register the entity, configure index, write the pre-computation calculator with 6 resilient queries, register the background service with distributed locking, implement retention pruning, and test all contracts.
- **Value Delivered**: Highly performant, pre-calculated, timezone-aligned nightly analytics snapshots are safe, idempotent, and fully cached inside the Postgres database.
- **Complexity**: High. Requires precise OLAP aggregation queries across multiple related tables (Submissions, ActionPlans, Profiles, Stores).
- **Entry State**: AppDbContext exists. Test factory runs. Postgres database is active.
- **Exit State**: `bod_report_snapshots` table is seeded, calculator executes safely with resilient query fallback, locking works, and all integration tests pass.
- **Acceptance Criteria**: All 6 contracts (TC-SL1-01 to TC-SL1-06) pass.

---

## Handoff Block
Next Phase: **Write Acceptance Tests**, then **Build Phase** for [Slice 1 — Data Engine].
Plan Path: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_20260524_151500_s1_bod_analytics.md`
Risk Classification: `[Risk: Network/Database]`

Please execute steps **ONE AT A TIME**.
