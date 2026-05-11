# Walkthrough: Good Errors — Slice 3 (Profile & Auth)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_062500_15a74aa9_errux-slice3.md`

## Decision Log

| Proposed | Implemented |
|---|---|
| Remove `_parseError` + `_errorMessage` from `login_page.dart`, replace with `ErrorDisplayService`. | Done. Also removed inline error `Container` widget from the build tree. Catch block split into `on DioException` + generic `catch (_)`. |
| Replace `error = 'Failed to load activity'` in `profile_manager.dart` with `ErrorDisplayService`. | Done. Also removed the `error` state property and `error = null` reset line entirely, since `ActivityHistoryPage` does not read it. |
| Check `activity_history_page.dart` for `_manager.error` before removing the field. | Checked. The page only binds to `isLoading` and `items`. Removing `error` is safe. |

## Verification Handoff
Steps for QA:
1. Launch app, enter wrong credentials → a SnackBar with empathetic copy should appear (via `ErrorDisplayService`). The old red inline error container should be **gone**.
2. Open Activity History page while the device is offline → a SnackBar should appear; the page should show empty list (not crash, no inline error label).
3. Search the codebase for `_parseError` — must return 0 results.

## Gotcha Protocol
- **Gotcha: Login page had a custom `_parseError` string-matching method**
  - This was a hidden technical debt: raw `msg.contains('401')` checks that will fail silently when server error formats change. The `ErrorDictionary` approach using `AppError.fromDioException` is strictly safer. Future agents should NOT re-introduce local string parsing for errors.

<test_trace>
00:06 +56: All tests passed!
Exit code: 0
</test_trace>

<forensic_evidence>
> cmd /c rtk flutter analyze lib/features/auth/pages/login_page.dart lib/features/profile/manager/profile_manager.dart
No issues found! (ran in 9.7s)
Exit code: 0

> cmd /c rtk flutter test test/features/admin/ test/features/auth/ test/features/profile/
56 tests, all passed.
Exit code: 0
</forensic_evidence>
