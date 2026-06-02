# Failure Modes & Flop-Catcher Review: Action Plan Collaborative Flow (Option C)

```text
[ SubmitEvidenceSheet ] ──(Missing proposed rootCause)──► [ PendingActionPlanUpdates ]
                                                                       │
                                                            (Missing executePush field)
                                                                       │
                                                                       ▼
[ C# API UpdateActionPlan ] ◄──(VerifierName left empty)────── [ ActionPlanSyncModule ]
```

---

## Discovered Flops & Failure Scenarios

### 🔴 Critical: Sync Pipeline Missing Field Flop
* **Trigger**: A Store Manager submits corrective evidence offline, proposing an initial root cause.
* **Failure**: `ActionPlanSyncModule.executePush` completely ignores `item.rootCause` in the JSON request payload sent to the API backend. The server updates the action plan, but the proposed root cause is lost forever.
* **Severity**: `🔴 Critical`
* **Mitigation**: Update `ActionPlanSyncModule.executePush` to serialize `'rootCause': item.rootCause` in the request body.

### 🔴 Critical: Domain Logic Lacked Parameter Flop
* **Trigger**: Store Manager calls `submitEvidence` in the domain layer.
* **Failure**: The `ActionPlan.submitEvidence` domain method lacks a `rootCause` parameter, making it impossible to capture or carry the proposed root cause during transition checks.
* **Severity**: `🔴 Critical`
* **Mitigation**: Add `required String? rootCause` to `ActionPlan.submitEvidence` and assign it to the optimistic DTO.

### 🟡 Warning: Verifier Name Left Empty on Close Flop
* **Trigger**: Auditor/Admin reviews and closes the action plan via `UpdateActionPlan` API endpoint.
* **Failure**: While `UpdateActionPlan` successfully updates fields like `RootCause` and `CorrectionPlan`, it lacks the logic to set `VerifierName` inside the database when the plan is transitioned to `closed`. The verifier's identity remains empty or null.
* **Severity**: `🟡 Warning`
* **Mitigation**: Update `UpdateActionPlan.cs` around line 99 to fetch the verifier's full profile name from the HTTP context/database and assign it to `plan.VerifierName`.

### 🟡 Warning: Drift SQLite Outbox Schema Drift Flop
* **Trigger**: Store Manager enters offline mode and submits evidence with a proposed root cause.
* **Failure**: The offline outbox table `PendingActionPlanUpdates` completely lacks the `rootCause` column, triggering a runtime SQLite database compilation error.
* **Severity**: `🔴 Critical`
* **Mitigation**: Add `TextColumn get rootCause => text().nullable()();` to `PendingActionPlanUpdates` in `tables.dart`, increment `schemaVersion` to `35` in `app_database.dart`, and add a safe column addition migration script.

---

## Verdict: Brittle (But Fully Remediable)
The proposed implementation plan is conceptually solid, but lacks execution-level detail around parameter and serialization maps in both offline sync and domain models. 

---

## Action Plan & Test Guards
1. **Database Schema Integration**: Verify SQLite column addition in widget tests by asserting migration succeeds without table corruptions.
2. **Domain Integration**: Add unit tests in `action_plan_test.dart` to verify that `submitEvidence` maps and carries `rootCause` successfully.
3. **Outbox Sync Integration**: Mock the sync API response and verify that proposed root causes are correctly dispatched.
