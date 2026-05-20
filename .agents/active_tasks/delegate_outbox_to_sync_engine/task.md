# Task: Delegate Outbox Boundary to SyncEngine
Workflow: /implement | Track: B2 (TDD — tests already RED)

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_113000_380021a1_delegate_outbox_to_sync_engine.md`
- **TDD Gate**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260503_113459_2c7e5b91-4fdb-45a7-a391-785cb62c7fe0_syncengine_outbox.md`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from Feature Analysis)
- [x] Pre-Requisite: Failing Tests (from /tdd) — 8/8 RED confirmed

## Active Slice: Delegate Outbox Boundary (Single slice, 4 files)

### Turn 1 — sync_engine.dart (ADD OutboxDao + 5 proxy methods)
- [x] Add `OutboxDao` import
- [x] Add `final OutboxDao? _outboxDao` field
- [x] Add named param to constructor
- [x] Add 5 proxy methods

### Turn 2 — locator.dart (WIRE OutboxDao into SyncEngine)
- [x] Pass `outboxDao: di<OutboxDao>()` to SyncEngine

### Turn 3 — main_shell.dart (REPLACE 3 OutboxDao calls)
- [x] Replace 3 calls with SyncEngine delegation
- [x] Remove outbox_dao.dart import

### Turn 4 — sign_out_tile.dart (REPLACE 2 OutboxDao calls)
- [x] Replace 2 calls with SyncEngine delegation
- [x] Remove outbox_dao.dart import

### Turn 5 — Build + Test verify
- [x] flutter analyze lib/
- [x] rtk flutter test (full regression)

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff -> Terminate session

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\delegate_outbox_to_sync_engine\walkthrough_20260503_121500_baca184a-7023-4b15-b605-774cf0458d8a_delegate_outbox_to_sync_engine.md | Result |
| [NEW] | c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260503_113459_2c7e5b91-4fdb-45a7-a391-785cb62c7fe0_syncengine_outbox.md | Test Log |
