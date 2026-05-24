# Task: BOD boardroom analytics province filtering, golden store, TTR KPIs, LastSyncedAt, and memory caching

Workflow: /implement | Track: C

## Input Lineage

- **Source Input**: `docs/architecture/bod-analytics/implementation_plan_20260524_200621_1eb2d30e_bod_analytics_extended_1eb2d30e-2365-48bd-af96-fc489f276027.md`
- **Test Contracts**: `docs/qa/contracts/bod-analytics/test_contracts_20260524_220600_1eb2d30e_atdd_slice1_1eb2d30e-2365-48bd-af96-fc489f276027.md`

## Upfront

- [x] Pre-Requisite: Implementation Plan (from Feature Analysis)
- [x] Pre-Requisite: Failing Tests (from ATDD or TDD step)

## Active Slice

- [x] Slice 1: Server Foundation (Read Tests -> Code -> Verify)
  - [x] Add `LastSyncedAt` column to `Store` entity.
  - [x] Map `LastSyncedAt` column in `StoreConfiguration`.
  - [x] Support `LastSyncedAt` in `BodReportDtos` / `BodStoreRankEntry`.
  - [x] Register memory cache in `Program.cs`.
  - [x] Implement `GetBodReportFiltered` or support province/district filtering inside `GetBodReport.cs` (or via separate handler file).
  - [x] Compute `goldenStore` representing highest-scoring store globally in last 30d.
  - [x] Compute `avgTtrDays` for closed Action Plans in the filtered province.
  - [x] Support `IMemoryCache` TTL=60s on filtered responses, keyed by province + district.
  - [x] Run migration `AddStoreLastSyncedAt`.
  - [x] Verify all 5 tests in `BodAnalyticsFilteredEndpointTests.cs` pass.

## Wrap Up

- [x] Step 3: Self-Review
- [x] Step 4: Handoff -> Terminate session

## Artifacts

| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/bod-analytics/walkthrough_20260524_221300_1eb2d30e_bod_analytics_slice1_1c10a0a8.md | Walkthrough |
| [NEW] | docs/qa/gates/bod-analytics/green_test_log_20260524_221300_1eb2d30e_bod_analytics_slice1_1c10a0a8.md | Test Log |
