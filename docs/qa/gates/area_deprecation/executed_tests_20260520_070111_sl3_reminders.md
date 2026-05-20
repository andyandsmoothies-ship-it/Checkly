# Executed Tests Log: SL-3 ReminderService ProfileStoreAssignment Cutover
- **Timestamp**: 2026-05-20
- **Plan**: `docs\architecture\implementation_plan_20260520_070000_a8c2d9f4_sl3_reminders.md`
- **TDD Tests**: `docs\qa\gates\executed_tests_20260520_065500_a8c2d9f4_sl3_tdd_reminders.md`

## Summary of Executed Tests
All 5 overdue escalation integration tests successfully passed against the local `checkly_test` Postgres database.

## Test Run Results
```
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:     5, Skipped:     0, Total:     5, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
```

## Detailed Test Case Registry
1. **SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager**
   - **Status**: ✅ PASS
   - **Scenario**: Pre-conditions: AM is assigned to store via `ProfileStoreAssignment`. Active AP is overdue >24h. Post-conditions: 1 notification created.
2. **SendOverdueEscalations_AlreadyEscalated_DoesNotDuplicate**
   - **Status**: ✅ PASS
   - **Scenario**: Pre-conditions: Pre-existing notification exists for the overdue AP. Post-conditions: 0 new notifications created (Idempotent).
3. **SendOverdueEscalations_NoAreaManager_SkipsAP**
   - **Status**: ✅ PASS
   - **Scenario**: Pre-conditions: No manager assigned to store. Post-conditions: 0 notifications created (Skips AP).
4. **SendOverdueEscalations_ClosedPlan_SkipsAP**
   - **Status**: ✅ PASS
   - **Scenario**: Pre-conditions: AP is closed. Post-conditions: 0 notifications created (Skips AP).
5. **SendOverdueEscalations_MultipleStores_SendsToRespectiveManagers**
   - **Status**: ✅ PASS
   - **Scenario**: Pre-conditions: Multiple stores each have an overdue action plan and a unique assigned Area Manager. Post-conditions: Both managers receive their respective notifications.
   - **Design Note**: Replaced the theoretical "multiple managers on a single store" scenario which is prohibited by the database constraint `IX_profile_store_assignments_store_id` (enforcing a strict 1-to-M relationship).
