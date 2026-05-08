# PBAC Slice 1 Build Walkthrough

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\implementation_plan_20260508_083700_a736cb_pbac-slice1.md`

## Decision Log
- **Proposed:** Replace hardcoded `role == 'admin'` with `PolicyManager.can()` checks in 3 widgets.
- **Implemented:** 
  - `lib/features/templates/pages/template_list_page.dart`: Replaced role check with `PolicyManager.can(AppCapabilities.templatesCreate)`. Swapped `AuthManager` import for `PolicyManager`.
  - `lib/features/dashboard/pages/widgets/submission_row.dart`: Replaced role check with `PolicyManager.can(AppCapabilities.submissionsReview)`. Renamed `isAdmin` to `canVoid`. Added imports for `PolicyManager` and `AppCapabilities`.
  - `lib/features/audit/pages/widgets/history_list_view.dart`: Replaced ternary condition with `canVoid` locally evaluated via `PolicyManager.can(AppCapabilities.submissionsReview)`. Removed unused `AuthManager` import.
- **Out of Scope Maintained:** `online_capability_grid.dart` line 114 was untouched as planned.

## Verification Handoff
1. Login with an auditor JWT.
2. Verify that the Templates tab FAB is hidden.
3. Verify that the Dashboard submissions feed does not show the "Void Audit" popup menu option.
4. Verify that the History page does not allow voiding audits.
5. Login with an admin JWT.
6. Verify that the Templates tab FAB is visible.
7. Verify that the Dashboard submissions feed shows the "Void Audit" option.

<test_trace>
00:00 +0: loading tests... (No explicit test suite run as this was purely UI visibility changes. Ran analyzer check instead.)
</test_trace>

<forensic_evidence>
cmd /c "rtk flutter analyze lib/features/audit/pages/widgets/history_list_view.dart && rtk flutter analyze lib/" -> 0 issues in the 3 modified files.
grep_search lib/ "role == 'admin'" -> Returned 2 matches (profile_page and online_capability_grid), proving the 3 targeted files are clean.
</forensic_evidence>

## Gotcha Protocol
No new gotchas were discovered during this slice. The PBAC capabilities were cleanly integrated into the widgets.
