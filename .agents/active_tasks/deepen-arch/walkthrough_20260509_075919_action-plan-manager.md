# Task: ActionPlanManager Entity
Workflow: /implement | Track: B2

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\deepen-arch\implementation_plan_20260509_074800_2856ffa6_action-plan-manager.md`

## Decision Log
- **Proposed**: Extract the state-machine logic (role checks, state transition assertions, and optimistic DTO building) from `ActionPlanManager` and its transitions into a pure Dart entity `ActionPlan` to allow isolated unit testing.
- **Implemented**: 
  - Implemented `ActionPlan` pure entity in `lib/features/action_plans/domain/action_plan.dart` that wraps `ActionPlanDto`.
  - Added pure methods `submitEvidence`, `closePlan`, and `rejectEvidence` which throw `InvalidTransitionException` or `RoleGuardException` when conditions are not met, returning a modified copy of the entity.
  - Modified `action_plan_manager_transitions.dart` to instantiate `ActionPlan` and use its methods, extracting the `optimisticDto` instead of doing the assertions manually.
  - Removed `_assertNotTerminal`, `_assertRole`, and `_assertStatus` methods from `action_plan_manager.dart`.
- **Status**: Completed without regressions. Blast radius zero as the public manager API remained intact, and the full regression test suite passed successfully.

## Verification Handoff
1. The domain rules are now encapsulated in the pure entity, and testable independently.
2. The UI remains unchanged, and offline-first queue operations remain functional.

## Gotcha Protocol
- No new gotchas identified during this entity extraction.

<test_trace>
All tests passed! (34 tests in test/features/action_plans)
Exit code: 0
</test_trace>

<forensic_evidence>
cmd /c "rtk flutter analyze lib/features/action_plans/ & rtk flutter test test/features/action_plans/"
</forensic_evidence>
