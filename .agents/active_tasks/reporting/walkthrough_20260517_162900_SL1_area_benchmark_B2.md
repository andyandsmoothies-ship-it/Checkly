# AreaBenchmarkWorker Implementation Walkthrough (Phase B2)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260517_162900_SL1_area_benchmark.md`

## Decision Log
- **Proposed**: Implement `AreaBenchmarkCalculator` and `AreaBenchmarkWorker`.
- **Implemented**: Created both classes. The worker operates on a configurable interval (default 20 minutes) and leverages `DistributedLockManager` to ensure singleton execution. The calculator performs correct computation of averages, standard deviation, and updates JSONB Category Averages successfully.

## Verification Handoff
1. The background worker is now registered and running.
2. Ensure you have seeded areas with `TotalAuditCount` >= 3 to trigger the calculations.
3. Observe DB rows mapped to `area_benchmark_snapshots` being UPSERTED successfully.

<test_trace>
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ok dotnet test: 2 tests passed, 0 warnings in 1 projects (7.0 s)
</test_trace>

<forensic_evidence>
> rtk dotnet test --filter AreaBenchmarkWorker
Passed!  - Failed:     0, Passed:     2, Skipped:     0, Total:     2, Duration: 7.0 s
</forensic_evidence>

## Gotcha Protocol
None for this slice.
