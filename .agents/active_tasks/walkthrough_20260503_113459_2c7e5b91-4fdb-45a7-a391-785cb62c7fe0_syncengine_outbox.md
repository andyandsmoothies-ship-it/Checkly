# Walkthrough: SyncEngine Outbox Delegation Test Generation

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_113000_380021a1_delegate_outbox_to_sync_engine.md`

## Summary of Tests Authored

I have created `test/_shared/services/sync_engine_outbox_delegation_test.dart` to fulfill the TDD Red Phase for the Outbox Delegation implementation plan.

The following test cases have been added and verified to fail gracefully with `MethodNotFound` errors (because the `SyncEngine` proxy methods do not exist yet):

- **TC-01:** `watchExhaustedCount()` emits 0 when outbox is empty
- **TC-02:** `watchExhaustedCount()` emits 2 when 2 exhausted rows exist
- **TC-03:** `discardExhausted()` removes all exhausted rows from DB
- **TC-04:** `requeueExhausted()` resets exhausted rows to pending
- **TC-05:** `syncableCount()` returns 0 for empty outbox
- **TC-06:** `syncableCount()` returns 1 when 1 pending submission exists
- **TC-07:** `exhaustedCount()` returns 0 for empty outbox
- **TC-08:** `exhaustedCount()` returns 1 when 1 exhausted submission exists

> **Note to Builder:** The tests instantiate `SyncEngine` *without* passing `outboxDao` into the constructor, because doing so would cause a hard compilation failure preventing the test runner from completing. Once you add `outboxDao` to the `SyncEngine` constructor, you will need to update the `createEngine` factory function in the test file to supply `outboxDao: outboxDao`.

## Decision Log
- Decided to instantiate SyncEngine normally and expect MethodNotFound exceptions, to gracefully verify the RED phase without compiler errors aborting the test suite prematurely.

## Verification Handoff
Tests are written and fail correctly for the missing SyncEngine methods.

<test_trace>
00:00 +0 -8: Some tests failed.
</test_trace>

<forensic_evidence>
rtk flutter test test/_shared/services/sync_engine_outbox_delegation_test.dart --reporter=expanded
</forensic_evidence>

## Commands to Run Tests

```bash
rtk flutter test test/_shared/services/sync_engine_outbox_delegation_test.dart --reporter=expanded
```
