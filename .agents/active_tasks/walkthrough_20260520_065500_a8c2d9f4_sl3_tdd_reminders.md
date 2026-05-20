# TDD Walkthrough: SL-3 ReminderService ProfileStoreAssignment Cutover

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260520_070000_a8c2d9f4_sl3_reminders.md`

## Summary of Tests Added
The test suite in `server/tests/Checkly.Api.Tests/Features/Reminders/OverdueEscalationTests.cs` has been rewritten/adapted to verify the new `ProfileStoreAssignment` cutover.

### 🛡️ Test Suite Details:
1. **`SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager`**
   - **Scenario**: Seed an ActionPlan in `overdue` status, register a Store, and link an Area Manager via `ProfileStoreAssignment`.
   - **Expectation**: A notification is successfully sent to the assigned Area Manager.
   - **Current Status**: Failing properly (Red phase) because the query does not check `ProfileStoreAssignments` yet.

2. **`SendOverdueEscalations_AlreadyEscalated_DoesNotDuplicate`**
   - **Scenario**: Seed an overdue ActionPlan with a pre-existing notification already sent to the assigned Area Manager.
   - **Expectation**: The service does not create duplicate notifications.
   - **Current Status**: Passing.

3. **`SendOverdueEscalations_NoAreaManager_SkipsAP`**
   - **Scenario**: Seed an overdue ActionPlan but don't assign any Area Manager to the store.
   - **Expectation**: Escalation is skipped, creating no notifications.
   - **Current Status**: Passing.

4. **`SendOverdueEscalations_ClosedPlan_SkipsAP`**
   - **Scenario**: Seed a `closed` ActionPlan with an assigned Area Manager.
   - **Expectation**: Escalation is skipped, creating no notifications.
   - **Current Status**: Passing.

## Decision Log
- **Decision 1: Removal of Multiple Area Manager Test Case**
  - *Context*: The implementation plan originally called for a test `SendOverdueEscalations_MultipleAreaManagers_SendsToAll` that would assign multiple AMs to a single store and expect notifications to go to all of them.
  - *Finding*: Checking `ProfileStoreAssignmentConfiguration.cs` showed that the DB schema has a unique index on `StoreId` (`e.HasIndex(x => x.StoreId).IsUnique();`), enforcing a strict 1-to-M relationship where a store can only be assigned to a single Area Manager.
  - *Action*: Removed the invalid test case to avoid violating unique constraints on database seeding, ensuring we respect and enforce active DB constraints.

- **Decision 2: Use of Isolated User Registration**
  - *Context*: We registered testing users using `_factory.RegisterUserAsync` instead of using manual mock objects. This ensures that actual persistence and EF Core constraints are fully tested in real integration database runs.

## Verification Handoff
To run this test suite and verify the failures, execute the following command from the `server` directory:

```bash
dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter OverdueEscalationTests
```

<test_trace>
Starting test execution, please wait...
A total of 1 test files matched the specified pattern.
[xUnit.net 00:00:05.26]     Checkly.Api.Tests.Features.Reminders.OverdueEscalationTests.SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager [FAIL]
  Failed Checkly.Api.Tests.Features.Reminders.OverdueEscalationTests.SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager [136 ms]
  Error Message:
   Assert.NotNull() Failure: Value is null
  Stack Trace:
     at Checkly.Api.Tests.Features.Reminders.OverdueEscalationTests.SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager() in C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Reminders\OverdueEscalationTests.cs:line 91
</test_trace>

<forensic_evidence>
Executed command:
dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter OverdueEscalationTests
Results checked:
Failed: 1, Passed: 3, Skipped: 0, Total: 4
Identified correct red-phase failure for overdue Action Plan escalations where ProfileStoreAssignment is not integrated.
</forensic_evidence>
