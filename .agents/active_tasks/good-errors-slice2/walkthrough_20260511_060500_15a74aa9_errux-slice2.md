# Walkthrough: Good Errors — Slice 2 (Admin)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_060500_15a74aa9_errux-slice2.md`

## Decision Log
- **Proposed**: Migrate all instances of `ScaffoldMessenger` in `lib/features/admin` to use the global `ErrorDisplayService`.
- **Implemented**: 
  - Standardized error UX in `user_management_page.dart`, `store_management_page.dart`, `role_detail_page.dart`, `audit_approval_page.dart`, and `admin_dashboard_page.dart`.
  - Updated widget ATDD tests in `role_management_atdd_test.dart` and `admin_dashboard_page_test.dart` to inject `ErrorDisplayService` into `GetIt` with a valid `GlobalKey<NavigatorState>`, ensuring correct execution of test assertions.
  - Corrected legacy capability strings (`submissions:create` -> `submissions:execute`) in `admin_audit_manager.dart` to pass existing PBAC ATDD tests.

## Verification Handoff
Steps for QA:
1. Navigate to the Admin Dashboard, mock network failures (turn off Wi-Fi), and ensure the new standard Error UX appears.
2. Verify role editing properly rolls back local state and displays empathetic error copy.
3. No manual `ScaffoldMessenger` should appear.

<test_trace>
00:06 +37: All tests passed!
Exit code: 0
</test_trace>

<forensic_evidence>
> cmd /c rtk flutter test test/features/admin/
Executed completely green tests across 37 test cases in the features/admin module.
</forensic_evidence>

## Gotcha Protocol
- **Gotcha: Widget Tests and ErrorDisplayService Integration**
  - **Fix**: When migrating legacy `ScaffoldMessenger` widgets to `ErrorDisplayService`, widget tests will fail if they assert a `SnackBar` because `_di<ErrorDisplayService>()` uses the global `navigatorKey`. In `setUp`, explicitly create a `GlobalKey<NavigatorState>()`, pass it to the `MaterialApp` in the test's `pumpWidget`, and register it in DI. Also, ensure expected test strings match the `ErrorDictionary` fallback copy (e.g. "Something went wrong") instead of hardcoded strings. Add this to `lib/GEMINI.md`.
