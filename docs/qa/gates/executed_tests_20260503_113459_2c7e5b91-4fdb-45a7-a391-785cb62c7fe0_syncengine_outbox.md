# Executed Tests: SyncEngine Outbox Delegation

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_113000_380021a1_delegate_outbox_to_sync_engine.md`

## Terminal Output

<test_trace>
```text
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/sync_engine_outbox_delegation_test.dart
00:00 +0: SyncEngine Outbox Delegation TC-01: watchExhaustedCount() emits 0 when outbox is empty
00:00 +0 -1: SyncEngine Outbox Delegation TC-01: watchExhaustedCount() emits 0 when outbox is empty [E]
  MethodNotFound: watchExhaustedCount is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 109:9  main.<fn>.<fn>
  
00:00 +0 -1: SyncEngine Outbox Delegation TC-02: watchExhaustedCount() emits 2 when 2 exhausted rows exist
00:00 +0 -2: SyncEngine Outbox Delegation TC-02: watchExhaustedCount() emits 2 when 2 exhausted rows exist [E]
  MethodNotFound: watchExhaustedCount is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 124:9  main.<fn>.<fn>
  
00:00 +0 -2: SyncEngine Outbox Delegation TC-03: discardExhausted() removes all exhausted rows from DB
00:00 +0 -3: SyncEngine Outbox Delegation TC-03: discardExhausted() removes all exhausted rows from DB [E]
  MethodNotFound: discardExhausted is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 140:9  main.<fn>.<fn>
  
00:00 +0 -3: SyncEngine Outbox Delegation TC-04: requeueExhausted() resets exhausted rows to pending
00:00 +0 -4: SyncEngine Outbox Delegation TC-04: requeueExhausted() resets exhausted rows to pending [E]
  MethodNotFound: requeueExhausted is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 156:9  main.<fn>.<fn>
  
00:00 +0 -4: SyncEngine Outbox Delegation TC-05: syncableCount() returns 0 for empty outbox
00:00 +0 -5: SyncEngine Outbox Delegation TC-05: syncableCount() returns 0 for empty outbox [E]
  MethodNotFound: syncableCount is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 167:9  main.<fn>.<fn>
  
00:00 +0 -5: SyncEngine Outbox Delegation TC-06: syncableCount() returns 1 when 1 pending submission exists
00:00 +0 -6: SyncEngine Outbox Delegation TC-06: syncableCount() returns 1 when 1 pending submission exists [E]
  MethodNotFound: syncableCount is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 180:9  main.<fn>.<fn>
  
00:00 +0 -6: SyncEngine Outbox Delegation TC-07: exhaustedCount() returns 0 for empty outbox
00:00 +0 -7: SyncEngine Outbox Delegation TC-07: exhaustedCount() returns 0 for empty outbox [E]
  MethodNotFound: exhaustedCount is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 191:9  main.<fn>.<fn>
  
00:00 +0 -7: SyncEngine Outbox Delegation TC-08: exhaustedCount() returns 1 when 1 exhausted submission exists
00:00 +0 -8: SyncEngine Outbox Delegation TC-08: exhaustedCount() returns 1 when 1 exhausted submission exists [E]
  MethodNotFound: exhaustedCount is missing from SyncEngine
  package:matcher                                                      fail
  test\_shared\services\sync_engine_outbox_delegation_test.dart 204:9  main.<fn>.<fn>
  
00:00 +0 -8: Some tests failed.
```
</test_trace>

<forensic_evidence>
rtk flutter test test/_shared/services/sync_engine_outbox_delegation_test.dart --reporter=expanded
</forensic_evidence>
