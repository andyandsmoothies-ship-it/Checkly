# Task: BUG-1 Fix ActionPlanSyncModule — Migrate to processQueue()
Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `docs/diagnostics/audit_code_report_20260502_161200_sentinel_pr_batch.md`

## Upfront
- [x] Pre-Requisite: Audit Report (BUG-1 identified by Sentinel)
- [x] Pre-Requisite: Code read — action_plan_sync_module.dart + tables.dart + sync_module.dart all read

## Active Slice
- [x] Step 1: Add retryCount + nextRetryAt columns to PendingActionPlanUpdates table (tables.dart)
- [x] Step 2: Bump schemaVersion to 24 and add migration block (app_database.dart)
- [x] Step 3: Add updateRetry() method to ActionPlanOutboxDao
- [x] Step 4: Migrate ActionPlanSyncModule.executePush() to use processQueue()
- [x] Step 5: Run build_runner to regenerate app_database.g.dart
- [x] Step 6: flutter analyze — zero warnings
- [x] Step 7: flutter test — all green

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff -> Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/walkthrough_20260502_163500_baca184a_bug1_action_plan_sync.md | Result |
| [NEW] | docs/qa/gates/executed_tests_20260502_163500_baca184a_bug1_action_plan_sync.md | Test Log |
