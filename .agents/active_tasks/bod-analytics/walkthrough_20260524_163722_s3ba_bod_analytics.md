# Walkthrough: BOD Analytics TDD Phase Summary

## Input Lineage
- **Source Input Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_20260524_163000_s3_bod_analytics.md`

## 1. Executive Summary
This document outlines the unit and visual page test suites constructed for the Boardroom (BOD) Analytics feature slice. As the Sentinel QA Engineer, I have generated failing unit and widget integration tests (compilation-valid RED-phase) that verify the complete manager state machine, dynamic capability routing, error and offline handling, and the visually stunning visual reskin guidelines.

---

## 2. Test Specifications & Strategy

### A. Manager Logic Tests (`test/features/analytics/manager/bod_analytics_manager_test.dart`)
- **TC-BOD-LOAD-01 (Happy Path)**: Verifies successful HTTP 200 data fetch, JSON mapping, and state transition to loaded.
- **TC-BOD-LOAD-02 (Error Handling)**: Asserts correct error messaging on standard HTTP errors (e.g., HTTP 500).
- **TC-BOD-LOAD-03 (Offline Recovery)**: Asserts offline detection when `SocketException` or network failure occurs.
- **TC-BOD-LOAD-04 (Empty State)**: Asserts custom handling when the server returns HTTP 404 (indicating no nighttime pre-computed snapshot has run yet).
- **TC-BOD-REFRESH-01**: Verifies pull-to-refresh execution flow.
- **TC-BOD-REFRESH-02**: Asserts polling behavior for `Processing` state snapshots every 5 seconds up to 3 attempts.
- **TC-BOD-REFRESH-03 (Rate Limiting)**: Asserts that HTTP 429 triggers a toast message and halts further polling.
- **TC-BOD-POLL-01**: Asserts terminal timeout and transition to standard error state if polling exhausts all retries.

### B. Widget & Page Tests (`test/features/analytics/pages/bod_analytics_page_test.dart`)
- **TC-BOD-ROUTING-01**: Dynamic GoRouter redirect guard verification utilizing `authRedirect` from `package:checkly/_shared/router/auth_redirect.dart`.
- **TC-BOD-UI-01**: Verifies localized ComputedAt timestamps rendering.
- **TC-BOD-UI-02**: Asserts a prominent yellow alert warning banner is displayed when `snapshotStatus` is `PartiallyFailed`.
- **TC-BOD-UI-03**: Asserts that all 6 executive chart components are correctly wrapped in a `StrokeCard` design primitive.
- **TC-BOD-OFFLINE-01**: Connection-required empty state rendering with standard try-again callback execution.
- **TC-BOD-EMPTY-01**: Dashboard empty boardroom state with manual "Trigger Recomputation" action.

---

## 3. How to Run the Tests

To execute the newly created test suites, the Builder Agent must execute the following commands from the `lib` folder of the repository:

```bash
# Execute manager/domain logic unit tests
rtk flutter test ../test/features/analytics/manager/bod_analytics_manager_test.dart

# Execute UI/widget visual tests
rtk flutter test ../test/features/analytics/pages/bod_analytics_page_test.dart
```

---

## Decision Log
- **Decision: Use Mocktail over Mockito**
  - Justification: Following sub-module gotcha rule that Checkly strictly uses `mocktail` for Dart/Flutter tests without build runner code generation.
- **Decision: Separate Router redirect tests from visual page rendering tests**
  - Justification: Allows isolated testing of the navigation gates without dependency on route definitions or context nesting in unit widget testing.
- **Decision: Avoid stubbing private listeners**
  - Justification: Standard mocking practice avoids mocking `@protected` lifecycle items of Flutter `ChangeNotifier` to prevent runtime mock exceptions.

---

## Verification Handoff
- Tests have been fully written, run, and verified to be structurally sound, compilation-valid, and properly failing on missing business features.
- The logs are persisted inside `docs/qa/gates/bod-analytics/executed_tests_20260524_163722_s3ba_bod_analytics.md`.
- Next step is Builder's implementation phase to implement `BodAnalyticsManager` and `BodAnalyticsPage` to satisfy the tests.

---

<test_trace>
Running Manager Tests:
00:00 +0 -8: Some tests failed. (All tests compiled and threw expected UnimplementedError)

Running Page Widget Tests:
00:00 +0 -6: Some tests failed. (All tests compiled and threw expected UnimplementedError/StrokeCard assertion errors)
</test_trace>

<forensic_evidence>
Verification commands:
- cmd /c rtk flutter test ../test/features/analytics/manager/bod_analytics_manager_test.dart
- cmd /c rtk flutter test ../test/features/analytics/pages/bod_analytics_page_test.dart
</forensic_evidence>
