# TDD Walkthrough: ActionPlanManager Entity
Workflow: /tdd | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\deepen-arch\implementation_plan_20260509_074800_2856ffa6_action-plan-manager.md`

## What Was Done
1. **Created Test File:** `test/features/action_plans/domain/action_plan_entity_test.dart`
2. **Written Tests:** Implemented the 10 behavioral tests (TC-11-01 to TC-11-10) specified in the implementation plan. Tests cover `RoleGuardException` and `InvalidTransitionException` along with positive state transitions.
3. **Stubbed Entity:** Created `lib/features/action_plans/domain/action_plan.dart` containing empty methods throwing `UnimplementedError()` so the tests compile and fail identically.
4. **Run Results:** All 10 tests fail solely because logic is missing. The tests are syntactically valid.

## Commands for the Builder
You can execute these tests to guide your GREEN phase:
```bash
rtk flutter test test/features/action_plans/domain/action_plan_entity_test.dart
```

When finished, ensure existing manager transition tests pass as well:
```bash
rtk flutter test test/features/action_plans/manager/
```
