# Task: Fix am2 Analytics 403 — Replace Stale AreaId Guard with ProfileStoreAssignment
Workflow: /implement | Track: A (Bug fix — diagnostic report is the contract)

*(Track A: Direct fix. No prior ATDD test exists. Verification test written AFTER code is GREEN.)*

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260518_164958_am2_analytics_area_scope.md`

## Upfront
- [x] Pre-Requisite: Failure Report (diagnostic evidence) — `failure_report_20260518_164958_am2_analytics_area_scope.md`
- [x] Pre-Requisite: Verification test (written AFTER code is GREEN — Track A)

## Active Slice
- [x] Slice 1: Replace AM guard block in `GetAnalytics.cs` lines 54–69 with `ProfileStoreAssignment` pattern

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff → Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [MOD] | server/Features/Analytics/GetAnalytics.cs | Prod code |
| [NEW] | server/tests/Checkly.Api.Tests/Features/Analytics/Analytics_AM_Scope_Tests.cs | Verification test |
| [NEW] | .agents/active_tasks/reporting/walkthrough_20260518_165323_am2scope_reporting.md | Result |
