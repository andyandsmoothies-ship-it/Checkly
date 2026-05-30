# TDD Executed Tests: ActionPlanManager Entity
Workflow: /tdd | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\deepen-arch\implementation_plan_20260509_074800_2856ffa6_action-plan-manager.md`

## Test Results
```text
00:00 +0 -1: ActionPlan Entity Tests submitEvidence() throws RoleGuardException if role is not store_manager
00:00 +0 -1: ActionPlan Entity Tests submitEvidence() throws RoleGuardException if role is not store_manager [E]
  Expected: throws <Instance of 'RoleGuardException'>
    Actual: <Closure: () => ActionPlan>
     Which: threw UnimplementedError:<UnimplementedError: submitEvidence not implemented>

00:00 +0 -2: ActionPlan Entity Tests submitEvidence() throws InvalidTransitionException if status is not open
00:00 +0 -2: ActionPlan Entity Tests submitEvidence() throws InvalidTransitionException if status is not open [E]
  Expected: throws <Instance of 'InvalidTransitionException'>
    Actual: <Closure: () => ActionPlan>
     Which: threw UnimplementedError:<UnimplementedError: submitEvidence not implemented>

00:00 +0 -3: ActionPlan Entity Tests submitEvidence() throws InvalidTransitionException if status is closed
00:00 +0 -3: ActionPlan Entity Tests submitEvidence() throws InvalidTransitionException if status is closed [E]
  Expected: throws <Instance of 'InvalidTransitionException'>
    Actual: <Closure: () => ActionPlan>
     Which: threw UnimplementedError:<UnimplementedError: submitEvidence not implemented>

00:00 +0 -4: ActionPlan Entity Tests closePlan() throws RoleGuardException if role is store_manager
00:00 +0 -4: ActionPlan Entity Tests closePlan() throws RoleGuardException if role is store_manager [E]
  Expected: throws <Instance of 'RoleGuardException'>
    Actual: <Closure: () => ActionPlan>
     Which: threw UnimplementedError:<UnimplementedError: closePlan not implemented>

00:00 +0 -5: ActionPlan Entity Tests closePlan() throws InvalidTransitionException if status is not pending_verify
00:00 +0 -5: ActionPlan Entity Tests closePlan() throws InvalidTransitionException if status is not pending_verify [E]
  Expected: throws <Instance of 'InvalidTransitionException'>
    Actual: <Closure: () => ActionPlan>
     Which: threw UnimplementedError:<UnimplementedError: closePlan not implemented>

00:00 +0 -6: ActionPlan Entity Tests rejectEvidence() throws RoleGuardException if role is store_manager
00:00 +0 -6: ActionPlan Entity Tests rejectEvidence() throws RoleGuardException if role is store_manager [E]
  Expected: throws <Instance of 'RoleGuardException'>
    Actual: <Closure: () => ActionPlan>
     Which: threw UnimplementedError:<UnimplementedError: rejectEvidence not implemented>

00:00 +0 -7: ActionPlan Entity Tests rejectEvidence() throws InvalidTransitionException if status is not pending_verify
00:00 +0 -7: ActionPlan Entity Tests rejectEvidence() throws InvalidTransitionException if status is not pending_verify [E]
  Expected: throws <Instance of 'InvalidTransitionException'>
    Actual: <Closure: () => ActionPlan>
     Which: threw UnimplementedError:<UnimplementedError: rejectEvidence not implemented>

00:00 +0 -8: ActionPlan Entity Tests submitEvidence() returns a new ActionPlan with status = pending_verify
00:00 +0 -8: ActionPlan Entity Tests submitEvidence() returns a new ActionPlan with status = pending_verify [E]
  UnimplementedError: submitEvidence not implemented

00:00 +0 -9: ActionPlan Entity Tests closePlan() returns a new ActionPlan with status = closed and verifierName set
00:00 +0 -9: ActionPlan Entity Tests closePlan() returns a new ActionPlan with status = closed and verifierName set [E]
  UnimplementedError: closePlan not implemented

00:00 +0 -10: ActionPlan Entity Tests rejectEvidence() returns a new ActionPlan with status = open and evidence cleared
00:00 +0 -10: ActionPlan Entity Tests rejectEvidence() returns a new ActionPlan with status = open and evidence cleared [E]
  UnimplementedError: rejectEvidence not implemented
```

## Verdict
The 10 RED tests compile successfully but fail entirely due to `UnimplementedError` in the `ActionPlan` entity stub. The Builder is ready to implement the `ActionPlan` logic.
