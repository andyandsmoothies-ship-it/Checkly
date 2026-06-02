---
conversation_id: dcbfac81-a3e9-4fad-af42-bc281b403b75
type: implementation_plan
topic: action-plan-collaborative-flow
date: 2026-06-01
---

# Implementation Plan: Action Plan Collaborative Flow (Option C)

[Store Manager UI] --(Propose Cause & Plan)--> [Drift Offline Outbox] --> [Sync Engine]
                                                                               |
                                                                               v
[Auditor/Admin UI] <--(Verify/Refine & Close)---------------------------- [Backend API]

---

## 1. Goal
Implement **Option C (Collaborative Proposal & Verification)** where:
1. **Store Manager** submits evidence, proposing the *initial* **Root Cause** and **Correction Plan** (via `submit_evidence_sheet.dart`).
2. **Auditor / Admin** reviews and closes the Action Plan, seeing these pre-populated. They can edit and refine them, permanently locking them upon final verification (via `action_plan_detail_actions.dart`).

---

## 2. Technical Scope & Slices

### Slice 1: Local Database & Codegen (Offline Outbox Table)
* Modify `tables.dart` to add `rootCause` to `PendingActionPlanUpdates`.
* Modify `app_database.dart` to increment `schemaVersion` to **35** and append the migration step.
* Run Drift codegen: `rtk dart run build_runner build --delete-conflicting-outputs`.

### Slice 2: Domain, Transition & Sync Logic
* Update `ActionPlan.submitEvidence` domain method to accept `rootCause`.
* Update `ActionPlan.closePlan` domain method to accept revised `rootCause` and `correctionPlan`.
* Update `ActionPlanManager` transitions (`_submitEvidenceLogic` and `_closePlanLogic`) in `action_plan_manager_transitions.dart`:
  * Map `rootCause` parameter to `PendingActionPlanUpdatesCompanion`.
  * Send `rootCause` in API payload for `_submitEvidenceLogic`.
  * Send revised `rootCause` and `correctionPlan` in `_closePlanLogic` API payload.
* Update `ActionPlanSyncModule` to process queued offline items and send the proposed `rootCause`.

### Slice 3: Backend API Enhancements
* Update C# backend `UpdateActionPlan` endpoint:
  * Automatically resolve and save `VerifierName` when status is set to `closed`.

### Slice 4: Frontend UI Dialog Upgrades
* **Store Manager (SubmitEvidenceSheet)**:
  * Add a Form with text fields for "Proposed Root Cause" and "Proposed Correction Plan".
  * Pre-populate "Proposed Correction Plan" with the existing plan's correction plan (if any) or a default.
  * Require the user to fill them out.
* **Auditor/Admin (ActionPlanDetailActions)**:
  * When executing `Verify & Close`, display a modal/dialog with text fields for "Verified Root Cause" and "Verified Correction Plan", pre-populated with the manager's proposals.
  * Allow editing/refining before closing.
  * Lock values on final verification.

## 3. SRE Fail-Safe Safeguards (Mitigations)

We have added four specific guards to prevent the application from losing data, crashing, or failing to sync:

### Guard A: Safe Database Upgrades (SQLite)
* **Problem**: If we add the new `rootCause` field, older devices might crash when the app opens because the local database structure does not match.
* **Mitigation**: 
  * We will increment the local database version to `35` inside `app_database.dart`.
  * We will add an explicit migration block that only adds the new column if it is missing:
    ```dart
    if (from < 35) {
      await m.addColumn(pendingActionPlanUpdates, pendingActionPlanUpdates.rootCause);
    }
    ```

### Guard B: Sync Pipeline Safeguard
* **Problem**: In the existing code, when the app syncs pending items, it leaves out the `rootCause` field completely:
  ```text
  [Local Outbox] --(Has rootCause)--> [Sync Engine] --(Leaves out rootCause)--> [Backend API]
  ```
* **Mitigation**: We will modify `ActionPlanSyncModule.executePush` to explicitly serialize and include `rootCause`:
  ```dart
  await _api.updateActionPlan(item.actionPlanId, {
    'status': 'pending_verify',
    'correctionPlan': item.correctionPlan,
    'rootCause': item.rootCause, // Added this line to prevent data loss!
    'evidenceNote': item.evidenceNote,
    'evidencePhotoUrl': photoUrl,
  });
  ```

### Guard C: Domain Parameter Rule
* **Problem**: The business domain model `ActionPlan.submitEvidence(...)` lacks a `rootCause` parameter, making it impossible to capture what the user wrote.
* **Mitigation**: We will update the function signature:
  ```dart
  ActionPlan submitEvidence({
    required String role,
    required String correctionPlan,
    required String? rootCause, // Added this parameter!
    required String currentUserName,
    String? evidenceNote,
    String? photoPath,
  })
  ```

### Guard D: Verifier Name Safety
* **Problem**: When the Auditor closes a plan, the API changes the status to `closed` but leaves the `VerifierName` column empty inside the PostgreSQL database.
* **Mitigation**: When updating a plan's status to `closed`, the backend code will look up the Auditor's full name from the current user session:
  ```csharp
  if (plan.Status == "closed") {
      plan.VerifierName = _currentUser.FullName; // Protects identity tracking!
  }
  ```
