# Walkthrough: TDD Phase A — Foundation (Good Errors) Slice 1

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_054500_15a74aa9_errux.md`

## Architecture Flow
```
[DioException] --> [AppError.fromDioException] --> [ErrorDisplayService.show]
                                                          |
                 [navigatorKey.currentContext!] <-- [ErrorDictionary.lookup]
```

## What Was Written

### File 1: TC-01 to TC-08 (8 tests)
`C:\Users\HP\Documents\GitHub\Checkly\test\unit\error_display_service_test.dart`

| Test ID | What it proves |
|---------|---------------|
| TC-01 | Proper `conflict` code mapping from ProblemDetails. |
| TC-02 | Unrecognized code falls back to `unknown` handling with a generic empathetic message. |
| TC-03 | HTML payload from an NGINX 502 fails JSON parsing smoothly and creates a `network_error`. |
| TC-04 | Raw connection timeout without body translates to `network_timeout`. |
| TC-05 | `onRetry` callback maps correctly to a `SnackBarAction` button that executes when tapped. |
| TC-06 | `isOfflineExpected` suppresses network errors (no `SnackBar` shown). |
| TC-07 | Calling `show()` rapidly multiple times within the 800ms window creates only **one** `SnackBar`. |
| TC-08 | `ErrorDisplayService` successfully resolves from `get_it` via `locator.dart`. |

## What the Builder (Forge) Must Do

### Step 1: `lib/_shared/exceptions/app_error.dart`
Create an `AppError` record/model. Add `fromDioException()` factory that parses RFC 9457 ProblemDetails. Ensure `response?.data` parsing doesn't throw on HTML responses. Set `code`, `message`, `details`, and `isOfflineExpected`.

### Step 2: `lib/_shared/exceptions/error_dictionary.dart`
Create a static lookup class for `ErrorDictionary.lookup(String code)`. Ensure strings strictly follow the `ux-copywriting` skill (e.g. no jargon, empathetic tone).

### Step 3: `lib/_shared/services/error_display_service.dart`
Create the `ErrorDisplayService(GlobalKey<NavigatorState> navigatorKey)` class.
- Provide `show(AppError error, {VoidCallback? onRetry})`.
- Apply an 800ms debounce track mechanism (use `_lastShownAt` and `_lastCode`).
- Suppress messages if `isOfflineExpected == true` and the error is a connectivity issue.
- Display `SnackBar` strictly using `ScaffoldMessenger.of(navigatorKey.currentContext!)`.

### Step 4: `lib/locator.dart`
Register the service: `di.registerLazySingleton(() => ErrorDisplayService(appRouter.routerDelegate.navigatorKey));`

## Commands to Run Tests
```
# Run only Slice 1 tests
rtk flutter test test/unit/error_display_service_test.dart

# Run full suite
rtk flutter test
```
