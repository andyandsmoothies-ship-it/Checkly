# Task Handoff: Slice 1 - Backend Dynamic Filtering & Advanced Metrics (Sentinel QA → Builder)
**Date**: 2026-05-24T20:08:30Z | **ShortID**: 1eb2d30e | **Epic/Feature**: BOD Boardroom Analytics Drill-Down

## 1. Progress Summary
Sentinel (QA Agent) has successfully completed **Phase A (Acceptance Test-Driven Development)** for Slice 1 of the Boardroom Analytics Epic.
We have written the complete set of failing integration/acceptance tests to verify all 5 critical dynamic data boardroom features:
1. **Dynamic Province/District Filtering**: Live mathematical aggregation when queried with `?province=Hanoi` or `?district=HoanKiem`.
2. **Golden Store Flagship Benchmark**: Regional vs Global flagship store comparison.
3. **Time-To-Resolution (TTR Velocity)**: Average speed to close corrective action plans.
4. **Offline Sync LastSyncedAt**: Exposing `lastSyncedAt` in store leaderboard entries.
5. **Memory Caching**: 60-second server cache to prevent OLAP thundering herd.

To ensure pristine compliance, the test files utilize dynamic JSON parsing via `JsonElement` and native SQL queries. This guarantees that:
- **The test suite compiles with 100% SUCCESS** (0 errors, 0 warnings) in Gate 1.
- **The tests FAIL AT RUNTIME (RED)** in Gate 2, waiting for the Builder to implement the production code.

---

## 2. Test Specifications & Artifact Locations
All tests have been written directly to the test project:
- **Test File**: [BodAnalyticsFilteredEndpointTests.cs](file:///C:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsFilteredEndpointTests.cs)
- **Failing Tests (RED)**:
  - `GetBodReport_WithProvinceFilter_ReturnsDynamicLiveData`
  - `GetBodReport_WithProvinceFilter_ReturnsGoldenStoreBenchmark`
  - `GetBodReport_WithProvinceFilter_CalculatesActionPlanTtr`
  - `GetBodReport_WithProvinceFilter_ReturnsStoreLastSyncedAt`
  - `GetBodReport_WithProvinceFilter_ServesFromCacheAndBypassesDatabase`

---

## 3. Success Criteria & Implementation Plan for the Builder (Slice 1)
The Builder must now step in to make these tests **GREEN** by performing the following contiguous edits to the C# codebase:

### 1. Database Migration & Entities (The 7 Sync Steps)
- Add the `LastSyncedAt` property to the `Store` entity in [Store.cs](file:///C:/Users/HP/Documents/GitHub/Checkly/server/Common/Persistence/Entities/Store.cs):
  ```csharp
  public DateTimeOffset? LastSyncedAt { get; set; }
  ```
- Configure the EF mapping inside [StoreConfiguration.cs](file:///C:/Users/HP/Documents/GitHub/Checkly/server/Common/Persistence/Configurations/StoreConfiguration.cs):
  ```csharp
  e.Property(x => x.LastSyncedAt).HasColumnName("last_synced_at");
  ```
- Create a database migration to add `last_synced_at` (nullable `timestamp with time zone`) to the `stores` table:
  ```powershell
  rtk dotnet ef migrations add AddStoreLastSyncedAt --project Common/Persistence/ --startup-project Api/
  ```

### 2. DTO Additions in `BodReportDtos.cs`
- Add `lastSyncedAt` (nullable `DateTimeOffset?` or string representation) to `BodStoreRankEntry`.
- Add `goldenStore` benchmark information (`BodGoldenStoreEntry`) to `BodReportResponse`:
  ```csharp
  public sealed class BodGoldenStoreEntry
  {
      public Guid StoreId { get; set; }
      public string StoreName { get; set; } = string.Empty;
      public decimal AvgScore { get; set; }
      public string Province { get; set; } = string.Empty;
  }
  ```
- Add `avgTtrDays` to `BodChainKpis`.
- Add `isLiveData` (boolean) to the top-level response DTO to let the frontend know whether it's displaying live dynamic calculations or nightly snapshots.

### 3. Live Query Controller Layer in `GetBodReport.cs`
- Add query parameters `province` and `district` to the endpoint handler (`GET /api/analytics/bod`).
- **Conditional Routing**:
  - **No parameters**: If both `province` and `district` are null/empty, continue to fetch the pre-calculated nightly snapshot as before (zero performance impact).
  - **With parameters**: If `province` or `district` are provided, bypass snapshot loading and run **Live Dynamic Calculations**:
    - Filter `stores` where province/district matches.
    - Filter completed `submissions` for those stores.
    - Compute `avgTtrDays` using closed action plans (`ClosedAt.HasValue`, `Status == "closed"`) associated with those stores, averaging `(ClosedAt - CreatedAt).TotalDays` in-memory.
    - Compute `goldenStore` benchmark by selecting the top-performing store *globally* in the entire chain (all stores) with at least 1 completed submission in the last 30 days.
    - Expose `lastSyncedAt` from the store model.
    - Enable 60-second caching using `IMemoryCache` with a compound key `bod-report-{province}-{district}`.

---

## 4. How to Verify
Run the test runner to ensure all Slice 1 tests compile and pass successfully:
```powershell
rtk dotnet test --filter "FullyQualifiedName~Checkly.Api.Tests.Features.Analytics.BodAnalyticsFilteredEndpointTests"
```
Once this test suite runs 100% green, Slice 1 is complete!
Task ready for handoff.
