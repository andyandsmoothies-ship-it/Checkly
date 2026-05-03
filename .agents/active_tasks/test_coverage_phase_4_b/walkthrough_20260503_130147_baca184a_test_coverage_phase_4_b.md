## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_125300_baca184a_test_coverage_phase_4.md`

## Summary
I have implemented the test coverage backfill for Phase B: `ActionPlanManagerTransitions` (Step 10 of the consolidated plan).

### Tests Written
- **TC-10-01**: Verified `submitEvidence` enforces `store_manager` role and `open` status.
- **TC-10-02**: Verified `submitEvidence` triggers API and updates in-memory array correctly when online.
- **TC-10-03**: Verified `submitEvidence` writes to `ActionPlanOutboxDao` and patches UI optimism when offline.
- **TC-10-04**: Verified `closePlan` enforces `auditor` or `admin` role and `pending_verify` status.
- **TC-10-05**: Verified `closePlan` triggers API and updates status.
- **TC-10-06**: Verified `rejectEvidence` enforces `auditor` or `admin` role and `pending_verify` status.
- **TC-10-07**: Verified `rejectEvidence` triggers API and returns status to `open`.
- **TC-10-08**: Verified terminal transitions (from `closed` status) accurately throw `InvalidTransitionException`.

### Modifications
- Used `mocktail` to inject implementations for `ActionPlanApi`, `UserRoleProvider`, `ConnectivityService`, and `ActionPlanOutboxDao`.
- Evaluated both happy path operations and explicitly expected `RoleGuardException` and `InvalidTransitionException` upon failure.

### Execution Command
The Builder can run these tests via:
```bash
rtk flutter test test/features/action_plans/manager/action_plan_manager_transitions_test.dart
```

## Decision Log
- Decided to register a fake fallback value for `PendingActionPlanUpdatesCompanion` in `setUpAll` because `OutboxDao.enqueue` takes a drift Companion object that `mocktail` cannot automatically generate a dummy for in `any()` matchers.

## Verification Handoff
Tests have been executed and passed, validating the Action Plan state transitions, role guards, and online/offline behavior.

<forensic_evidence>
<test_trace>
```text
C:\Users\HP\Documents\GitHub\Checkly> rtk flutter test test/features/action_plans/manager/action_plan_manager_transitions_test.dart
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_transitions_test.dart
00:00 +8: All tests passed!
```
</test_trace>
</forensic_evidence>
