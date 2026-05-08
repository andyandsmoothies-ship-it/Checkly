# Task: Fix CRIT-3 — Remove Drift Type from ActionRequiredWidget
Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_185858_4cf3f41a_audit-code-crit3.md`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from /analyze-feature)
- [x] Pre-Requisite: Failing Tests — N/A (architectural refactor, no logic change)

## Active Slice
- [x] Slice 1: Extract VM and Update Widget
  - [x] Step 1: Create `lib/features/programs/model/pending_assignment_vm.dart`
  - [x] Step 2: Add `watchActionRequired()` to `DashboardManager`
  - [x] Step 3: Update `ActionRequiredWidget` to consume VM stream
  - [x] Step 4: Run `flutter analyze` + `flutter test`

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff -> Terminate session

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/audit-code/walkthrough_20260508_190404_audit-code-crit3.md | Result |
| [NEW] | docs/qa/gates/audit-code/executed_tests_20260508_190404_audit-code-crit3.md | Test Log |
