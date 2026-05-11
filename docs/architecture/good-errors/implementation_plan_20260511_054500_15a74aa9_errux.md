<latent_space_scratchpad>
KEY DECISION: How does ErrorDisplayService show UI without BuildContext?
- Option 1: GlobalKey<ScaffoldMessengerState> injected at app start.
- Option 2: GlobalKey<NavigatorState> from go_router (appRouter.routerDelegate.navigatorKey).

Analysis:
- The `appRouter` is a GoRouter. GoRouter exposes `routerDelegate.navigatorKey` which is a GlobalKey<NavigatorState>.
- From NavigatorState we can get a BuildContext via `.overlay?.context` — this is the CLEANEST and most correct approach for Flutter.
- We do NOT need a separate ScaffoldMessengerState key. We can use `ScaffoldMessenger.of(routerKey.currentContext!)` — BUT only if a Scaffold is present.
- The safest approach: pass GoRouter's navigatorKey to the service. For SnackBars use `ScaffoldMessenger.of(navigatorKey.currentContext!)`. For dialogs use `showDialog(context: navigatorKey.currentContext!)`.

KEY DECISION: AppError model location
- ADR says: `lib/_shared/` — confirmed. The `_shared/exceptions/` folder is EMPTY — perfect clean landing spot.
- Model: `lib/_shared/exceptions/app_error.dart` — a simple Dart `final class AppError` (not an Exception subtype, just a data record).

KEY DECISION: ErrorDictionary — how many codes?
- We need enough to cover the most common production cases now:
  1. `network_timeout` / connection error → "We couldn't connect. Check your connection."
  2. `unauthorized` (401) → handled by auto-logout interceptor, service should still support it
  3. `forbidden` (403) → "You don't have permission to do that."
  4. `not_found` (404) → "We couldn't find what you were looking for."
  5. `conflict` (409) → "This record was changed by someone else. Refresh and try again."
  6. `validation_error` (400) → (use server detail string if available)
  7. `server_error` (500+) → "Something went wrong on our end. Try again shortly."
  8. `unknown` → fallback

DEBOUNCE: Per prior opinion, we need SnackBar spam prevention.
- Simplest: track `_lastShownAt` DateTime + `_lastCode` String. If same code shown < 1 second ago, skip.

OFFLINE-FIRST: isOptimisticOffline flag.
- Managers that do optimistic writes should NOT call ErrorDisplayService for connectivity failures when data is already saved locally.
- The service accepts an optional `isOfflineExpected: bool` parameter. If true + the error is a network error, it suppresses the scary message and instead shows "Saved offline — will sync when connected." or simply nothing (silent).

SLICE SCOPE: This plan = Slice 1 ONLY (Foundation).
- 3 new files: app_error.dart, error_dictionary.dart, error_display_service.dart
- 1 modified file: locator.dart (register the service)
- 0 existing catch blocks changed
Total blast radius: ~150 lines across 4 files. Well under 400 limit.
</latent_space_scratchpad>

# Implementation Plan: Empathetic Error UX — Slice 1 (Foundation)

```
[DioException] --> [AppError mapper] --> [ErrorDisplayService]
                                              |
                              +---------------+---------------+
                              |                               |
                    [ErrorDictionary lookup]       [onRetry callback]
                              |                               |
                    [SnackBar via NavigatorKey]    [User taps "Retry"]
```

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260510_185956_errux_good-errors.md`

## Executive Summary & Out of Scope

**Goal:** Build the error UX foundation — the three-class infrastructure (`AppError`, `ErrorDictionary`, `ErrorDisplayService`) that will eventually replace all 243+ raw `catch (e)` SnackBars in the app. This slice builds and registers the service only. No existing code is changed yet.

**Out of Scope (this slice):**
- Migrating any of the 243+ existing catch blocks (Slices 2–4)
- Localization / translations
- Any backend changes
- Any new API endpoint or database table
- The `showAsDisabled` PBAC-related patterns (separate epic)

---

## System Context

| Item | Value |
|---|---|
| **Architecture Mode** | Offline-first hybrid (ConnectivityService gates all network calls) |
| **DI Framework** | `get_it` (`registerLazySingleton`) — all services follow this pattern |
| **HTTP Client** | `Dio` — all network errors arrive as `DioException` |
| **Backend Error Format** | RFC 9457 `ProblemDetails` with optional `code` extension field |
| **RBAC** | None — this is cross-cutting infrastructure, no capability gate |
| **Router** | `go_router` — `appRouter` exposes `routerDelegate.navigatorKey` |
| **UI Display** | `ScaffoldMessenger` (SnackBars) + `showDialog` (blocking alerts) |

---

## Lifecycle Context (4-State Matrix)

The `ErrorDisplayService` itself is always "ready" after `configureDependencies()`. The states apply to the display layer:

| State | What the user sees |
|---|---|
| **Success** | No error shown. |
| **Transient Error** | SnackBar appears at bottom with empathetic message. If `onRetry` is provided, a `[Retry]` action button appears. Auto-dismisses after 4 seconds. |
| **Critical Error** | A blocking dialog with a single `[OK]` button. Used for session expiry or data corruption. |
| **Offline Expected** | If `isOfflineExpected: true` and error is a connectivity failure, service is silent (data already saved locally). |

---

## Test Contracts

| ID | Scenario | Input | Expected Output | Why it fails first |
|---|---|---|---|---|
| TC-01 | Valid ProblemDetails `code: "conflict"` | `DioException` with status 409 and `{"code":"conflict"}` body | `AppError(code: 'conflict')` → SnackBar text = `"This record was changed by someone else. Refresh and try again."` | `ErrorDictionary` map doesn't exist yet |
| TC-02 | Unknown error code | `DioException` with status 500 and `{"code":"new_mystery_code"}` body | SnackBar text = `"Something went wrong. Please try again."` (generic fallback) | `ErrorDictionary.lookup()` returns null for unknown codes |
| TC-03 | Non-JSON response (HTML from NGINX) | `DioException` with HTML body | Fallback `AppError(code: 'network_error')` → SnackBar text = `"We couldn't connect. Check your connection and try again."` | JSON parse throws, fallback path doesn't exist |
| TC-04 | Connection timeout | `DioException(type: DioExceptionType.connectionTimeout)` | `AppError(code: 'network_timeout')` → SnackBar with `[Retry]` button | `AppError.fromDioException()` mapper doesn't exist |
| TC-05 | `onRetry` callback provided | Valid `AppError` + `onRetry: () => submitForm()` | SnackBar has `[Retry]` action. Tapping it calls the callback. | `ErrorDisplayService.show()` ignores callbacks |
| TC-06 | Offline expected (sync failure) | `AppError(code: 'network_timeout')` + `isOfflineExpected: true` | **No SnackBar shown** | `isOfflineExpected` flag not implemented |
| TC-07 | Duplicate error spam | Same `AppError(code: 'server_error')` called 5x within 500ms | SnackBar shown **once** only | Debounce logic not implemented |
| TC-08 | Service registers in `get_it` | `configureDependencies()` called | `di<ErrorDisplayService>()` returns a non-null instance | Not registered in `locator.dart` |

---

## Test Fixture & Payloads

**No backend fixture needed** (pure unit tests + widget tests).

**Sample DioException data payloads:**

```json
// TC-01: Conflict 409
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.10",
  "title": "Conflict",
  "status": 409,
  "detail": "State conflict",
  "code": "conflict"
}

// TC-03: NGINX HTML (non-JSON)
"<html><body><h1>502 Bad Gateway</h1></body></html>"

// TC-04: Dio connection timeout (no body)
DioExceptionType.connectionTimeout — response is null
```

---

## Tools & Commands

| Tool | Purpose |
|---|---|
| `flutter_test` | Unit tests for `AppError.fromDioException()` and `ErrorDictionary.lookup()` |
| `mocktail` | Mock `NavigatorKey` context for `ErrorDisplayService` display tests |

**Test commands:**
```
rtk flutter test test/unit/error_display_service_test.dart
rtk flutter analyze
```

---

## Proposed Changes

| Op | File | Reason |
|---|---|---|
| `[NEW]` | `lib/_shared/exceptions/app_error.dart` | Typed error model: `code`, `message`, `details`, `isOfflineExpected` + `fromDioException()` factory |
| `[NEW]` | `lib/_shared/exceptions/error_dictionary.dart` | Static map of `code → empathetic string`. Enforces UX copywriting rules. |
| `[NEW]` | `lib/_shared/services/error_display_service.dart` | Singleton service: `show(AppError, {VoidCallback? onRetry})`. Uses injected NavigatorKey. |
| `[MOD]` | `lib/locator.dart` | Register `ErrorDisplayService` as `registerLazySingleton`. Pass `appRouter.routerDelegate.navigatorKey`. |
| `[NEW]` | `test/unit/error_display_service_test.dart` | Unit tests for TC-01 through TC-08 |

---

## Concept Diagram

```
[Widget catches DioException]
        |
        v
[AppError.fromDioException(e)]
        |
        +--> status 409 → code='conflict'
        +--> connection timeout → code='network_timeout'
        +--> HTML body parse fail → code='network_error' (fallback)
        |
        v
[di<ErrorDisplayService>().show(appError, onRetry: () => doThing())]
        |
        +--> isOfflineExpected=true + network error? → SILENT (no UI)
        +--> Same code shown <1s ago? → DEBOUNCED (skip)
        |
        v
[ErrorDictionary.lookup(appError.code)]
        |
        +--> 'conflict' → "This record was changed by someone else..."
        +--> 'network_timeout' → "We couldn't connect..."
        +--> null / unknown → "Something went wrong. Please try again."
        |
        v
[ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
    SnackBar(
      content: Text(message),
      action: onRetry != null
          ? SnackBarAction(label: 'Retry', onPressed: onRetry)
          : null,
    )
)]
```

---

## Execution Phase

**Slice 1: Foundation (this plan)**

- **Plain English Summary:** Create the three-class error UX engine. This is pure new code with zero changes to any existing feature. Think of it as installing a new electrical panel in a building — we're not rewiring the rooms yet, just putting the panel in place.
- **Why this step now?** Every future migration slice depends on this. It must exist and be tested before any widget can use it.
- **Scenario Focus:** Basic Scenario (Happy Path — error is shown correctly).
- **Value Delivered:** After this slice, any developer can write `di<ErrorDisplayService>().show(appError)` instead of a raw SnackBar. The pattern works end-to-end.
- **Entry State Required:** `configureDependencies()` exists in `locator.dart`. `appRouter` is a `GoRouter` instance.
- **Exit State Guaranteed:** `ErrorDisplayService` is registered in `get_it`. TC-01 through TC-08 all pass.
- **Architectural Scope:**
  - `lib/_shared/exceptions/` — 2 new files
  - `lib/_shared/services/` — 1 new file
  - `lib/locator.dart` — 1 addition
  - `test/unit/` — 1 new test file
- **Complexity:** Low. Pure new code. No existing logic is modified except 1 line in `locator.dart`.
- **Acceptance Criteria:** All 8 test contracts (TC-01 to TC-08) pass. `flutter analyze` returns 0 issues.

**Gotchas the Builder MUST NOT ignore:**
1. **NavigatorKey source:** Use `appRouter.routerDelegate.navigatorKey` — NOT a new `GlobalKey`. `appRouter` is the existing GoRouter in `lib/_shared/router/app_router.dart`.
2. **`currentContext` null guard:** Before calling `ScaffoldMessenger.of(ctx)`, check `navigatorKey.currentContext != null`. If the context is null (app not fully mounted), log a warning and silently drop the error display.
3. **ErrorDictionary strings MUST comply with the UX Copywriting skill rules:** no developer jargon, no blame language, every actionable string must use a verb (e.g., "Try again", not "Error occurred").
4. **`fromDioException()` must never throw.** Wrap the JSON parse of `response?.data` in a `try/catch`. If the body is HTML or unparseable, fall back to `code: 'network_error'`.
5. **Debounce window:** 800ms. Track `DateTime? _lastShownAt` and `String? _lastCode` as private fields on the service.

---

<command_logs>
- grep_search "ErrorDisplayService" in lib/_shared → No results (confirmed does not exist)
- grep_search "AppError" in lib/_shared → No results (confirmed does not exist)
- list_dir lib/_shared → Folder structure mapped
- view_file lib/_shared/services/api_client.dart → DioException confirmed as error type
- view_file lib/locator.dart → DI registration pattern confirmed: registerLazySingleton
- view_file lib/main.dart → GoRouter + no existing GlobalKey<ScaffoldMessengerState>
- view_file lib/_shared/router/app_router.dart → appRouter is GoRouter (has routerDelegate.navigatorKey)
- grep_search "GlobalKey|navigatorKey|scaffoldKey" → No existing NavigatorKey/ScaffoldMessengerKey
- grep_search "context.mounted" → Confirmed as established guard pattern across the codebase
- list_dir lib/_shared/exceptions → EMPTY directory (clean landing spot for AppError)
</command_logs>

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `navigatorKey.currentContext` is null when service is called before first frame | Medium | Guard with `if (navigatorKey.currentContext == null) { debugPrint(...); return; }` |
| HTML body from NGINX causes `fromDioException()` to throw | High | Wrap JSON parse in `try/catch`, fall back to `AppError(code: 'network_error')` |
| SnackBar spam from simultaneous failures (sync batch) | Medium | 800ms debounce per error code in service |
| Developer adds new error code not in `ErrorDictionary` | Low | `lookup()` falls back to generic message — no crash, just a generic UX |

---

## Verification Plan

1. `rtk flutter test test/unit/error_display_service_test.dart` → All 8 TCs pass.
2. `rtk flutter analyze` → 0 issues.
3. Manual smoke: Trigger a network error in the app → Empathetic SnackBar appears (not a raw `DioException` string).
4. Manual smoke: Same network error triggered twice in < 1 second → SnackBar shown once only.

---



## Handoff Block

**Summary:** Build the 3-class error UX foundation in Flutter. Zero existing code changes except 1 registration line in `locator.dart`. The existing 243+ catch blocks are NOT touched in this slice.

**Strict Constraints for Next Agent:**
1. Use `appRouter.routerDelegate.navigatorKey` as the NavigatorKey source — do not create a new GlobalKey.
2. `fromDioException()` must never throw — always catch JSON parse errors and fall back.
3. All `ErrorDictionary` strings must comply with the `ux-copywriting` skill: blame-free, no jargon, verb-driven CTA.
4. Debounce identical error codes within 800ms window.
5. If `isOfflineExpected: true` and error is a connectivity type, show nothing.

**Route:** Logic/Standard → Unit Tests First (Route 1)

```
Step 1 — Tests first:
@[/tdd] Execute tests for Slice 1 (Foundation): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_054500_15a74aa9_errux.md

Step 2 — Build:
@[/implement] Execute build for Slice 1 (Foundation): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_054500_15a74aa9_errux.md
```

**Concurrency:** Step 1 must complete before Step 2.
