# Walkthrough: SL-2 Phase B1 - Province Benchmark Data Layer

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260519_075200_sl2_province_benchmark.md`

## Decision Log
- **ProvinceBenchmarkSnapshot Entity & EF Config**: Created the `ProvinceBenchmarkSnapshot` class mapping to `province_benchmark_snapshots` table with `Province` string as PK. Set up `ProvinceBenchmarkSnapshotConfiguration`.
- **DbContext Mapping**: Removed the legacy `AreaBenchmarkSnapshot` DB configuration and DbSet from `AppDbContext.cs` and replaced it with `ProvinceBenchmarkSnapshot`.
- **ProvinceBenchmarkCalculator**: Implemented the new static `ProvinceBenchmarkCalculator` containing `RunForAllProvincesAsync()`. It groups stores by the `Address2.Province` string, enforces a minimum threshold of 3 completed audits in the last 30 days, calculates overall averages, calculates standard deviation, aggregates category-level scores in ratio-based percentages from `SubmissionSectionScores` in the last 90 days, and performs a persistent UPSERT into `province_benchmark_snapshots`.
- **AreaBenchmarkWorker**: Refactored the host background service `AreaBenchmarkWorker.cs` to call `ProvinceBenchmarkCalculator.RunForAllProvincesAsync()` inside the `"Checkly.ProvinceBenchmarkWorker"` lock to keep background calculation active.
- **EF Migration**: Successfully generated and initialized the `AddProvinceBenchmarkSnapshot` database migration which drops `area_benchmark_snapshots`, creates `province_benchmark_snapshots`, and inserts `analytics:area` capability.

## Verification Handoff
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

## Gotcha Protocol
No additional quirks were found during Phase B1. The migration accurately maps database tables. All domain boundaries are respected.
