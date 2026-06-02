# Task: Action Plan Collaborative Flow

Workflow: /implement | Track: B2/C

*(Note: Track A = Direct Implementation (Tests Written AFTER code). Track B/C = Acceptance/Unit Tests Written BEFORE code. Skipping tests entirely is PROHIBITED unless explicitly stated.)*

## Input Lineage

- **Source Input**: `docs/features/action-plan-collaborative-flow/implementation_plan_action-plan-collaborative-flow_20260601_235600.md`

## Upfront

- [x] Pre-Requisite: Implementation Plan (from Feature Analysis)
- [x] Pre-Requisite: Failing Tests (from ATDD or TDD step)

## Active Slices Checklist

### [x] Slice 1: Local Database & Codegen (Offline Outbox Table)
- [x] Add `rootCause` column to `PendingActionPlanUpdates` table in `tables.dart`
- [x] Increment `schemaVersion` to **35** and append migration block in `app_database.dart`
- [x] Run Drift codegen to update `app_database.g.dart`
- [x] Verify migration logic by running tests or building the DB

### [x] Slice 2: Domain, Transition & Sync Logic
- [x] Update `ActionPlan.submitEvidence` domain method to accept `rootCause` parameter
- [x] Update `ActionPlan.closePlan` domain method to accept revised `rootCause` and `correctionPlan`
- [x] Update transitions in `action_plan_manager_transitions.dart`:
  - `_submitEvidenceLogic` mappings and API payload inclusion
  - `_closePlanLogic` mappings and API payload inclusion
- [x] Update `ActionPlanSyncModule.executePush` to serialize and include `rootCause` in API payload

### [x] Slice 3: Backend API Enhancements
- [x] Update C# backend `UpdateActionPlan` endpoint in ASP.NET Core to automatically resolve and save `VerifierName` from current session on `closed` status

### [x] Slice 4: Frontend UI Dialog Upgrades
- [x] Add text fields for Proposed Root Cause and Proposed Correction Plan in `SubmitEvidenceSheet` (Store Manager)
- [x] Pre-populate Proposed Correction Plan with existing correction plan or default
- [x] Validate and require both fields
- [x] Add text fields for Verified Root Cause and Verified Correction Plan in `Verify & Close` dialog/actions (Auditor/Admin)
- [x] Pre-populate with Proposed values and allow edit before closing
- [x] Lock fields upon final verification

## Wrap Up

- [x] Step 3: Self-Review
- [x] Step 4: Handoff -> Terminate session

## Artifacts

| Status | File Path | Type |
|---|---|---|
| [NEW] | docs/features/action-plan-collaborative-flow/walkthrough_action-plan-collaborative-flow_20260602_055000.md | Walkthrough |
| [NEW] | docs/reports/qa/action-plan-collaborative-flow/green_test_log_action-plan-collaborative-flow_20260602_055000.md | Test Log |
