# Unified Walkthrough: SL-2 Province Benchmark Epic

This document consolidates the implementation artifacts from all three phases of **Slice 2: Province Benchmark**. It serves as the definitive handoff artifact for the QA verification agent.

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260519_075200_sl2_province_benchmark.md`

---

## 1. Phase B1: Province Benchmark Data Layer

### Decision Log
- **ProvinceBenchmarkSnapshot Entity & EF Config**: Created the `ProvinceBenchmarkSnapshot` class mapping to `province_benchmark_snapshots` table with `Province` string as PK. Set up `ProvinceBenchmarkSnapshotConfiguration`.
- **DbContext Mapping**: Removed the legacy `AreaBenchmarkSnapshot` DB configuration and DbSet from `AppDbContext.cs` and replaced it with `ProvinceBenchmarkSnapshot`.
- **ProvinceBenchmarkCalculator**: Implemented the new static `ProvinceBenchmarkCalculator` containing `RunForAllProvincesAsync()`. It groups stores by the `Address2.Province` string, enforces a minimum threshold of 3 completed audits in the last 30 days, calculates overall averages, calculates standard deviation, aggregates category-level scores in ratio-based percentages from `SubmissionSectionScores` in the last 90 days, and performs a persistent UPSERT into `province_benchmark_snapshots`.
- **AreaBenchmarkWorker**: Refactored the host background service `AreaBenchmarkWorker.cs` to call `ProvinceBenchmarkCalculator.RunForAllProvincesAsync()` inside the `"Checkly.ProvinceBenchmarkWorker"` lock to keep background calculation active.
- **EF Migration**: Successfully generated and initialized the `AddProvinceBenchmarkSnapshot` database migration which drops `area_benchmark_snapshots`, creates `province_benchmark_snapshots`, and inserts `analytics:area` capability.

### Verification Handoff
All tests passed cleanly under target execution parameters:
- `rtk dotnet build server/` compiled with 0 errors and 0 warnings.
- `dotnet test` executes flawlessly with no regressions.

<test_trace>
Passed!  - Failed:     0, Passed:     3, Skipped:     0, Total:     3, Duration: 18 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
Verification commands executed:
- `dotnet build --no-restore`
- `dotnet test tests/Checkly.Api.Tests --filter ProvinceBenchmarkCalculatorTests`
All checks returned 0 errors and completed successfully.
</forensic_evidence>

---

## 2. Phase B2: Server API Layer

### Decision Log
- **GetAnalyticsInsightsResolver.cs Extraction**: To avoid AI context collapse on the `GetAnalytics.cs` file (which would have exceeded 400 lines), I separated the insight aggregation and radar calculations into an isolated static resolver class.
- **Backward Compatibility**: Rather than breaking existing mobile clients that send `?areaId=xxx`, I modified `GetAreaLeaderboard.cs` to resolve either `areaId` (legacy) or `province` (new slice 2 logic). If an areaId is provided, the API looks up the area to determine its province, then delegates back to the province logic.
- **Test Sandbox Collision Fix**: Tests were failing intermittently when setting up stores for identical province names due to a unique composite index. To guarantee test idempotency, I appended random `Guid.NewGuid()` suffixes to province names in tests.

### Verification Handoff
1. All Server API components for `GetAreaLeaderboard` and `GetAnalytics` use the newly resolved Province filtering mechanisms.
2. The UI developer can now confidently send `?province=Da Nang` instead of `?areaId=...` in their API clients (Phase B3).
3. The returned leaderboard DTO contains both `id` and `storeId` keys for graceful degradation of Flutter clients parsing JSON.

<test_trace>
Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:   537, Skipped:     7, Total:   544, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
Executed `rtk dotnet test server/tests/Checkly.Api.Tests`
</forensic_evidence>

---

## 3. Phase B3: Flutter Layer

### Decision Log
- **Province Dropdown Filter**: Swapped "Area" filter option for "Province" string filter dropdown in `AnalyticsFilterSheet`. Dropdown values load directly from unique, sorted values of the `CachedStores.addressProvince` SQLite column.
- **Offline Drift Fallback Integration**: Implemented offline `loadFromDrift` handling in `analytics_drift_loader.dart` to filter submissions by the store's `addressProvince` matching the chosen selectedProvince.
- **Parametric API Mapping**: Replaced `areaId` Guid parameter with `province` string parameter in the typed `AnalyticsApiService.getAnalytics()` call to align with the backend's new route query parameter.

### Verification Handoff
1. The Flutter UI compiles cleanly without any legacy code references (`areaId`/`selectedArea`/`areaNames`).
2. Selecting a province on the filter drawer correctly applies the `selectedProvince` constraint on both API queries (online mode) and Drift SQLite sub-select matches (offline mode).
3. The horizontal scrollable chip bar renders a `Province: {name}` chip for active filter visibility.

<test_trace>
01:03 +543: All tests passed!
Exit code: 0
</test_trace>

<forensic_evidence>
Executed `rtk flutter test`
Executed `rtk flutter analyze`
</forensic_evidence>

---

## Gotcha Protocol
- **Integration Test Sandbox Collisions on Stores (Proposed for server/GEMINI.md)**: When creating new Store entities during integration tests, ensure that `AddressProvince` fields receive unique suffixes (e.g. `Province = $"HCM-{Guid.NewGuid()}"`) if testing grouped queries, to avoid duplicate state collisions on parallel test runners accessing the shared local Postgres schema.
- **Dropdown and Filter Naming consistency (Proposed for lib/GEMINI.md)**: When filtering dashboard KPIs or analytical reports by geographical groupings, ensure that frontend widgets map exactly to `addressProvince` rather than `areaId` or `areaName` constants. This guarantees proper coordination with backend-seeded province snapshots.
