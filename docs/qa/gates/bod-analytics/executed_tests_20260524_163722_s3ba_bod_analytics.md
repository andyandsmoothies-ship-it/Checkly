# Executed Tests Log: BOD Analytics TDD Run

## Input Lineage
- **Source Input Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_20260524_163000_s3_bod_analytics.md`

## 1. Test Suite Files Created
1. Manager/Domain logic tests: `test/features/analytics/manager/bod_analytics_manager_test.dart`
2. Page/Widget visual tests: `test/features/analytics/pages/bod_analytics_page_test.dart`

---

## 2. Manager/Domain Test Execution Results (RED Phase)
Command executed:
`rtk flutter test ../test/features/analytics/manager/bod_analytics_manager_test.dart` (run from `lib/`)

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/manager/bod_analytics_manager_test.dart

00:00 +0 -1: BodAnalyticsManager Unit Tests TC-BOD-REFRESH-03: HTTP 429 rate limit triggers toast and skips polling [E]
  UnimplementedError
  package:checkly/features/analytics/manager/bod_analytics_manager.dart 17:5  BodAnalyticsManager.loadReport
  test\features\analytics\manager\bod_analytics_manager_test.dart 210:17      main.<fn>.<fn>.<fn>
  package:fake_async/fake_async.dart 182:47                                   FakeAsync.run.<fn>.<fn>
  dart:async                                                                  runZoned
  package:clock/src/default.dart 52:10                                        withClock
  package:fake_async/fake_async.dart 182:15                                   FakeAsync.run.<fn>
  dart:async                                                                  runZoned
  package:fake_async/fake_async.dart 181:52                                   FakeAsync.run
  package:fake_async/fake_async.dart 41:41                                    fakeAsync
  test\features\analytics\manager\bod_analytics_manager_test.dart 208:7       main.<fn>.<fn>
  
00:00 +0 -8: Some tests failed.
</test_trace>

**Conclusion:** All 8 unit tests in the manager test suite fail predictably on the missing core business implementation (`UnimplementedError`).

---

## 3. Page/Widget Visual Test Execution Results (RED Phase)
Command executed:
`rtk flutter test ../test/features/analytics/pages/bod_analytics_page_test.dart` (run from `lib/`)

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/pages/bod_analytics_page_test.dart

00:00 +0 -6: BodAnalyticsPage Widget Tests TC-BOD-UI-03: Verify all 6 chart panels are instances of StrokeCard [E]
  Test failed. See exception logs above.
  The test description was: TC-BOD-UI-03: Verify all 6 chart panels are instances of StrokeCard
  
00:00 +0 -6: Some tests failed.
</test_trace>

**Conclusion:** All widget/page integration tests failed on expected visual layout elements (no StrokeCard present/not implemented yet).

---

<forensic_evidence>
Executed Commands:
- Checked route redirect gating test patterns:
  `grep_search` in `test/router` matched redirect rules in `test/router/app_router_rbac_test.dart`.
- Run tests via terminal:
  `rtk flutter test ../test/features/analytics/manager/bod_analytics_manager_test.dart` -> Exit code 1 (failed with UnimplementedError).
  `rtk flutter test ../test/features/analytics/pages/bod_analytics_page_test.dart` -> Exit code 1 (failed with UnimplementedError / missing StrokeCards).
</forensic_evidence>
