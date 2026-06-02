---
ConversationID: 99faccbc-6112-4ccd-aea4-306dbdfd3452
---

# Task: Action Plan Collaborative Flow Verification

Workflow: /verify | Track: B2/C

## Input Lineage

- **Walkthrough Artifact**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\action-plan-collaborative-flow\walkthrough_action-plan-collaborative-flow_20260602_055000.md`

## Upfront

- [ ] Check walkthrough details and identify all touched files
- [ ] Review implementation requirements and ACs

## Active Verification Slices Checklist

### Slice 1: Database & Drift Verification
- [ ] Verify `rootCause` is defined in `PendingActionPlanUpdates` table inside `tables.dart`
- [ ] Verify Drift schema version is correctly incremented and migration exists in `app_database.dart`
- [ ] Verify `app_database.g.dart` contains the generated `rootCause` column

### Slice 2: Domain, Transition & Sync Logic Verification
- [ ] Verify `rootCause` propagates through the `ActionPlan` submit and close transitions in `action_plan_manager_transitions.dart`
- [ ] Verify serialization of `rootCause` in `ActionPlanSyncModule.executePush`

### Slice 3: Backend API Verification
- [ ] Verify `UpdateActionPlan` endpoint in `ActionPlanController.cs` automatically resolves and persists `VerifierName` from user context on status transition to `closed`

### Slice 4: Frontend UI Widgets Verification
- [ ] Verify fields inside `SubmitEvidenceSheet` (`SubmitEvidenceSheet` has Proposed Root Cause and Proposed Correction Plan fields, validations, pre-population)
- [ ] Verify `VerifyDialog` or related actions (`VerifyDialog` fields for Verified Root Cause/Correction Plan, Proposed pre-population, and locking mechanics)

### Slice 5: Quality & CI Verification
- [ ] Run linter/formatting sweeps on touched files
- [ ] Verify specific tests exist and pass:
  - `action_plan_outbox_dao_stale_test.dart`
  - `action_plan_detail_page_pbac_test.dart`
  - `sync_engine_action_plan_stale_state_test.dart`
- [ ] Run global Flutter unit/widget tests suite to prove zero regression

## Wrap Up

- [ ] Generate final verification report at `docs/reports/qa/verification_action-plan-collaborative-flow_20260602_062032.md`
- [ ] Run the workflow validation script
