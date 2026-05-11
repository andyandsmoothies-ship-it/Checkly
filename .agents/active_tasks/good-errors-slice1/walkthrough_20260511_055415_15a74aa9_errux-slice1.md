# Walkthrough — Good Errors Slice 1 (Foundation)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_054500_15a74aa9_errux.md`

## Decision Log

| Proposed | Implemented | Reason |
|---|---|---|
| 3 new files + 1 locator change | ✅ Same — 3 new files + 1 locator change | No deviation |
| `appRouter.routerDelegate.navigatorKey` as NavigatorKey source | ✅ Used as-is | Plan constraint honored |
| 800ms debounce window | ✅ Implemented via `_lastCode` + `_lastShownAt` | Plan constraint honored |
| `fromDioException` must never throw | ✅ All JSON parse wrapped in try/catch | Plan constraint honored |
| Remove dead `MockScaffoldMessengerState` class | Not in plan — was a compile blocker in the QA test file | Class was declared but never referenced in any assertion; mocktail import also removed |

**Test file change justification:** The QA-written test had a dead class (`MockScaffoldMessengerState`) that was never used in any test body. It caused a compile-time `invalid_implementation_override` error (Diagnosticable.toString signature mismatch). The class was not part of any test assertion — removing it and its unused import is dead-code pruning, not changing test logic.

## Verification Handoff

To verify manually:
1. Run the app and trigger a network error (e.g. disable WiFi and refresh).
2. Confirm an empathetic SnackBar appears (not a raw `DioException` message).
3. Trigger the same error twice within 1 second — confirm SnackBar appears only once.
4. In an offline-first manager that has written data locally, pass `isOfflineExpected: true` to `AppError` — confirm no SnackBar appears.

<test_trace>
```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/unit/error_display_service_test.dart
00:00 +0: AppError & ErrorDictionary Tests TC-01: Valid ProblemDetails code: "conflict"
00:00 +1: AppError & ErrorDictionary Tests TC-02: Unknown error code fallback
00:00 +2: AppError & ErrorDictionary Tests TC-03: Non-JSON response (HTML from NGINX)
00:00 +3: AppError & ErrorDictionary Tests TC-04: Connection timeout
00:00 +4: ErrorDisplayService Tests TC-05: onRetry callback provided
00:00 +5: ErrorDisplayService Tests TC-06: Offline expected (sync failure)
00:00 +6: ErrorDisplayService Tests TC-07: Duplicate error spam (debounce)
00:00 +7: ErrorDisplayService Tests TC-08: Service registers in get_it
00:01 +8: All tests passed!

Global suite (rtk flutter test): 477 passed, 5 pre-existing failures in
test/widgets/permission_guard_disabled_test.dart (PermissionGuard.showAsDisabled
parameter not implemented — pre-existing; not caused by this slice).
```
</test_trace>

<forensic_evidence>
```
c:\Users\HP\Documents\GitHub\Checkly> rtk flutter analyze  
→ 3 pre-existing errors (permission_guard_disabled_test.dart × 2, checkly_lints × 1). Zero new errors introduced by this slice.

c:\Users\HP\Documents\GitHub\Checkly> rtk flutter test test/unit/error_display_service_test.dart
→ 8/8 passed

c:\Users\HP\Documents\GitHub\Checkly> rtk flutter test
→ 477 passed, 5 pre-existing failures (permission_guard_disabled_test.dart compile error — unrelated to this slice)
```
</forensic_evidence>

## Gotcha Protocol

**New gotcha for `lib/GEMINI.md`:**

> **Gotcha: `Diagnosticable.toString` conflict in Mocktail mocks**
> - **Problem**: If a QA test writes `class MockXxx extends Mock implements SomeFlutterWidget {}` where `SomeFlutterWidget` extends `Diagnosticable`, the `toString` signature `String Function({DiagnosticLevel minLevel})` conflicts with `Mock.toString` (`String Function()`), causing a compile-time `invalid_implementation_override` error.
> - **Fix**: Remove the unused mock class if it was never referenced in any test assertion. If the mock IS used, change `implements SomeFlutterWidget` to mock a leaner interface that doesn't extend `Diagnosticable`.
