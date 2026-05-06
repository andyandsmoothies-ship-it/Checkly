# Task: AM2 Cannot Verify Action Plan
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: User report & screenshot indicating permission denied on Verify/Reject actions for an Action Plan.

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Phase 1: Hypotheses
1. **Hypothesis 1:** The `ActionPlanManager` still relies on hardcoded RBAC roles (`_assertRole`) instead of the new PBAC `PolicyManager`, and `area_manager` is omitted from the allowed verifier roles. Proving this: Adding `area_manager` to the allowed list in `action_plan_manager_transitions.dart` will bypass the error.
2. **Hypothesis 2:** The backend API denies the request and throws a `RoleGuardException`. Proving this: The crash trace would point to HTTP 403 handling. However, the manager code explicitly states the backend has NO role validation.
3. **Hypothesis 3:** The UI `ActionPlanActionBar` erroneously evaluates `canVerify` as true for `area_manager` due to a caching issue. Proving this: Logging the policy evaluation would show it is false. (Unlikely, since the PBAC system deliberately assigns this capability).

## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | docs/diagnostics/failure_report_20260506_144637_diag2_verify_plan.md | Report |
