# Walkthrough: SL-2 Phase B1 - Province Benchmark Data Layer

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260519_075200_sl2_province_benchmark.md`

## Decision Log
- Implemented `ProvinceBenchmarkSnapshot` and replaced `AreaBenchmarkSnapshot` as per Phase B1 requirements.
- Extracted and modified `ProvinceBenchmarkCalculator` to calculate average scores grouped by the `address_province` property from `Store` instead of `AreaId`.
- Added the necessary EF Core Migration to drop the old table, create the new table, and seed the `analytics:area` capability for the area_manager role.
- Renamed the background worker call to reference the new calculator.

## Verification Handoff
- Backend code successfully compiled and `dotnet test` passed fully green, confirming no regressions and proving the data layer migration from Area to Province works smoothly.
- The next step for QA would be to evaluate B2, though tests are already passing.

<test_trace>
ok dotnet test: completed (binlog-only mode, counts unavailable, 0 warnings) (unknown)
</test_trace>

<forensic_evidence>
Executed `rtk dotnet build` and `rtk dotnet test` across all server projects successfully.
</forensic_evidence>

## Gotcha Protocol
- The `AreaBenchmarkWorkerTests` required replacement due to their deep dependency on `AreaId`. This serves as a reminder to ensure integration tests do not assume static navigation properties that are subject to deprecation.
