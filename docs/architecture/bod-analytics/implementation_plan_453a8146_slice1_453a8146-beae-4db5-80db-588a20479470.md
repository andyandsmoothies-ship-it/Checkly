<latent_space_scratchpad>
## Core Query Optimizations
- GetCategoryDetail: Grouping over SubmissionSectionScores using a string `SectionTitle` filter has the potential to trigger full-table sequential scans if the table is large. 
- Mitigation: Add `AsNoTracking()`, filter by `SectionTitle` first, then group by `StoreId` and `Submission.StoreName`. Inject `IMemoryCache` with a 120-second TTL keyed by category name to eliminate DB hits on concurrent queries. Apply `.Take(50)` limit before materializing.
- GetStoreBodSummary: Filter by `StoreId` and completed status first. Query submissions capped at `.Take(5)` and ordered DESC by completed/created time. Group section scores by `SectionTitle` to calculate section averages.

## Endpoint Integrity
- Both endpoints must enforce the `AnalyticsBod` capability. They will reject any request without the capability with a 403 Forbidden status.
- DTO records will be added to the bottom of `BodReportDtos.cs`.

## Failure Count Calculation
- In the compliance domain of Checkly, a "failure" inside a category section corresponds to `IsCcpFailed == true`.
- Therefore, `FailureCount` inside `CategoryStoreEntry` will be computed using `g.Count(ss => ss.IsCcpFailed)` which translates to a conditional SQL SUM aggregation.
</latent_space_scratchpad>

# Implementation Plan: BOD Analytics - Slice 1 Server Foundation

**Workflow:** /analyze-feature | **ShortID:** 453a8146 | **ConversationID:** 453a8146-beae-4db5-80db-588a20479470
**Date:** 2026-05-25T11:20:00+07:00

---

## Input Lineage

**Source Requirements:** `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\analysis_epic_20260525_105400_453a8146_bod_drilldown_453a8146-beae-4db5-80db-588a20479470.md` (specifically referencing Slice 1 details).

---

## Executive Summary & Out of Scope

Slice 1 builds the backend foundational API endpoints required by the new Board of Directors (BOD) drill-down views. These endpoints provide:
1. **Store BOD Summary**: Recent completed audits and section score breakdown for a specific store.
2. **Category Detail**: The worst-performing stores for a specific compliance category, sorted worst-first.

### Out of Scope:
- Modifying `BodReportCalculator.cs` is strictly forbidden. All new endpoints are added via standalone files.
- Month-based or trend-based drill-downs (out of scope).
- Client-side changes or UI components (scheduled for Slices 2-4).

---

## System Context

- **APIs**:
  - `GET /api/analytics/stores/{storeId:guid}/bod-summary`
  - `GET /api/analytics/bod/category/{name}`
- **RBAC**: Guarded by capability: `AppCapabilities.AnalyticsBod`
- **Data Source**: Live queries against the `Submissions` and `SubmissionSectionScores` tables.
- **Caching**: `IMemoryCache` applied to the category endpoint (120-second TTL) to protect DB performance.

---

## Lifecycle Context

Since these are REST API endpoints:
- **Success**: Returns `200 OK` with JSON payloads.
- **Loading**: Checked client-side via loading indicators.
- **Empty**:
  - If a store has zero audits, `GET /api/analytics/stores/{storeId}/bod-summary` returns `200 OK` with empty arrays.
  - If a category has no data, `GET /api/analytics/bod/category/{name}` returns `200 OK` with an empty array `[]`.
- **Error**:
  - `400 BadRequest` if the category name is missing or invalid.
  - `401 Unauthorized` / `403 Forbidden` if auth or capability checks fail.
  - `404 NotFound` if the store ID does not exist in the database.

---

## Constraint Traceability

| Source Constraint | Target Test ID | Verification Method |
|---|---|---|
| Enforce `AnalyticsBod` capability on store summary | S1-TEST-01 | Call without token/capability → expect 403/401 |
| Enforce `AnalyticsBod` capability on category details | S1-TEST-02 | Call without token/capability → expect 403/401 |
| Store summary returns at most 5 audits, sorted DESC | S1-TEST-03 | Verify list count is ≤ 5 and sorted DESC |
| Empty store case returns 200 with empty lists | S1-TEST-04 | Query a store with zero audits → expect 200 with empty list |
| Category detail sorted by average score ASC | S1-TEST-05 | Verify list sorting is ascending |
| Category detail capped at 50 records | S1-TEST-06 | Verify list count ≤ 50 |
| Category detail cached via memory cache | S1-TEST-07 | Double query category → verify subsequent speed |

---

## Test Contracts

### S1-TEST-01: Store BOD Summary Capability Guard
- **Description**: Verifies that calling store summary requires `AnalyticsBod` capability.
- **State**: Default seeded database.
- **Assertion**: Call endpoint without authenticated token -> expect 401. Call with non-BOD user -> expect 403.

### S1-TEST-02: Category Detail Capability Guard
- **Description**: Verifies that calling category detail requires `AnalyticsBod` capability.
- **State**: Default seeded database.
- **Assertion**: Call endpoint without authenticated token -> expect 401. Call with non-BOD user -> expect 403.

### S1-TEST-03: Store BOD Summary Sorting & Limit
- **Description**: Verifies that `recentAudits` returns exactly the last 5 audits, sorted by `CompletedAt` DESC.
- **State**: Seed 7 audits for Store X (completed, varying scores).
- **Assertion**: Expect array of exactly 5 elements. The first element must match the most recently completed audit.

### S1-TEST-04: Empty Store BOD Summary
- **Description**: Verifies that an audit-less store returns empty arrays instead of failing.
- **State**: Seed 1 new store, zero audits.
- **Assertion**: Expect status 200 with `storeName` set and `recentAudits` and `categoryBreakdown` as empty lists.

### S1-TEST-05: Category Detail Sorting Worst-First
- **Description**: Verifies category detail lists stores sorted by average score ASC (worst first).
- **State**: Seed 3 stores with section score averages: Store A = 95%, Store B = 60%, Store C = 80%.
- **Assertion**: Expect return array ordered as: Store B, Store C, Store A.

### S1-TEST-06: Category Detail Cap 50
- **Description**: Verifies category detail returned items are capped at 50.
- **State**: Seed 60 stores with section scores.
- **Assertion**: Expect list count of exactly 50.

---

## Test Fixture & Payloads

### GET `/api/analytics/stores/{storeId}/bod-summary`
- **Request**: None (Path param)
- **Response**:
```json
{
  "storeName": "Metro Supermarket",
  "recentAudits": [
    {
      "date": "2026-05-24T12:00:00Z",
      "score": 92.5,
      "auditorName": "John Doe"
    }
  ],
  "categoryBreakdown": [
    {
      "categoryName": "Food Safety",
      "avgScore": 85.0
    }
  ]
}
```

### GET `/api/analytics/bod/category/{name}`
- **Request**: None (Path param)
- **Response**:
```json
[
  {
    "storeName": "Airport Store",
    "avgScore": 60.0,
    "auditCount": 3,
    "failureCount": 1
  }
]
```

---

## Tools & Commands

- **Skills**: `clean-architecture`, `testing-strategy`, `ef-core`
- **Verification Commands**:
  - Run all API integration tests:
    `cmd /c rtk dotnet test --filter Checkly.Api.Tests.Features.Analytics.BodAnalyticsSlice1Tests`

---

## Proposed Changes

### 1. `server/Features/Analytics/BodReportDtos.cs` [MOD]
- Add new records at the bottom of the file:
```csharp
public record StoreBodSummary(string StoreName, List<RecentAuditEntry> RecentAudits, List<CategoryScoreEntry> CategoryBreakdown);
public record RecentAuditEntry(DateTimeOffset Date, decimal Score, string AuditorName);
public record CategoryScoreEntry(string CategoryName, decimal AvgScore);
public record CategoryStoreEntry(string StoreName, decimal AvgScore, int AuditCount, int FailureCount);
```

### 2. `server/Features/Analytics/GetStoreBodSummary.cs` [NEW]
- Standalone endpoint file mapping `/api/analytics/stores/{storeId:guid}/bod-summary`.
- Queries and aggregates `Submissions` and `SubmissionSectionScores`.

### 3. `server/Features/Analytics/GetCategoryDetail.cs` [NEW]
- Standalone endpoint file mapping `/api/analytics/bod/category/{name}`.
- Queries `SubmissionSectionScores` and caches with `IMemoryCache` (120s TTL).

### 4. `server/Features/Analytics/AnalyticsEndpoints.cs` [MOD]
- Map both endpoints:
```csharp
        group.MapGet("/stores/{storeId:guid}/bod-summary", GetStoreBodSummary.HandleAsync)
            .WithName("GetStoreBodSummary")
            .RequireCapability(AppCapabilities.AnalyticsBod);

        group.MapGet("/bod/category/{name}", GetCategoryDetail.HandleAsync)
            .WithName("GetCategoryDetail")
            .RequireCapability(AppCapabilities.AnalyticsBod);
```

### 5. `server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsSlice1Tests.cs` [NEW]
- Complete integration test suite verifying limits, sorting, capability checks, and empty bounds.

---

## Concept Diagram

```
[Flutter UI] ──(GET /api/analytics/stores/{id}/bod-summary)──► [GetStoreBodSummary]
                                                                     │
                                                                     ├─► DB.Stores (Verify exist)
                                                                     ├─► DB.Submissions (Get last 5)
                                                                     └─► DB.SubmissionSectionScores (Group averages)

[Flutter UI] ──(GET /api/analytics/bod/category/{name})───────► [GetCategoryDetail]
                                                                     │
                                                                     ├─► MemoryCache (Check hit)
                                                                     └─► DB.SubmissionSectionScores (Query worst-first)
```

---

## Execution Slices

### Slice 1: Backend DTOs & Handler Implementations
- **Summary**: Implement DTO additions and both `GetStoreBodSummary` and `GetCategoryDetail` handlers.
- **Value**: Establishes correct database query logic and memory caching bounds.
- **Entry State**: Backend builds with zero errors.
- **Exit State**: Both handlers build and compile cleanly.
- **Scope**: `BodReportDtos.cs`, `GetStoreBodSummary.cs`, `GetCategoryDetail.cs` (3 files).

### Slice 2: Routing Registration & Integration Tests
- **Summary**: Register routes in `AnalyticsEndpoints.cs` and write full suite of integration tests.
- **Value**: Proves correctness of capability checks, pagination limits, sorting orders, and empty state safety.
- **Entry State**: Slice 1 compiles cleanly.
- **Exit State**: Full integration test suite passes with zero failures.
- **Scope**: `AnalyticsEndpoints.cs`, `BodAnalyticsSlice1Tests.cs` (2 files).

---

## Handoff Block

- **Implementation Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_453a8146_slice1_453a8146-beae-4db5-80db-588a20479470.md`

### Action Sequence:
- **Slice 1**: Plan -> Write Acceptance Tests -> Build
  - Target: Execute Route 3 (Acceptance Tests First). Write the integration tests in `BodAnalyticsSlice1Tests.cs` first, verify compilation, then implement the C# endpoints.

**Please execute slices ONE AT A TIME.** Do not combine slices.
