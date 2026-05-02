# Task: DI Wiring and Test Migration (Slice C)
Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_232410_380021a1_deepen_sync_engine_plugin.md`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from /analyze-feature)
- [x] Pre-Requisite: Failing Tests (from /atdd or /tdd)

## Active Slice
- [x] Slice C: DI Wiring and Test Migration
  - [x] Delete `sync_engine_drains.dart`.
  - [x] Register the modules in `locator.dart`.
  - [x] Update `SyncEngine` to accept `List<SyncModule>`.
  - [x] Migrate all 8 integration/unit tests to mock and assert against the new module structure directly.

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff -> Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/walkthrough_20260502_133600_380021a1_deepen_sync_engine_plugin_slice_c.md | Result |
| [NEW] | docs/qa/gates/executed_tests_20260502_133600_380021a1_deepen_sync_engine_plugin_slice_c.md | Test Log |
