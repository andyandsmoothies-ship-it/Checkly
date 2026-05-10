# Walkthrough: Router & Shell Guards (Phase A)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260509_202121_a4x9_pbac-ui-fix-leaks.md`

## Decision Log
- **Proposed**: Add route guards for analytics, activity, and programs in `app_router.dart`. Hide ACTIVITY tab if no `submissions:list` in `main_shell.dart`.
- **Implemented**: Added granular capability checks in `authRedirect` inside `app_router.dart` for paths starting with `/analytics`, `/activity`, and `/programs`. In `main_shell.dart`, imported `PolicyManager` and `AppCapabilities` to conditionally render the `ACTIVITY` nav item if the user has the `submissions:list` capability. The UI dynamically accommodates the hidden tab using `MainAxisAlignment.spaceBetween`.

## Verification Handoff
1. Start the app and log in as a user with partial capabilities.
2. Confirm that attempting to navigate to `/analytics`, `/activity`, or any unauthorized `/programs` route directly via deep links redirects to `/home`.
3. Confirm that the 'ACTIVITY' tab is completely hidden from the bottom navigation bar if the user lacks the `submissions:list` capability.

<test_trace>
```text
Analyzing Checkly...                                            
No issues found! (ran in 3.0s)

01:06 +467: All tests passed!
Exit code: 0
```
</test_trace>

<forensic_evidence>
- `rtk flutter analyze` and `rtk flutter test` executed successfully.
- Modifications made in `lib/_shared/router/app_router.dart` and `lib/_shared/router/main_shell.dart`.
</forensic_evidence>

## Gotcha Protocol
No new gotchas were identified during this phase.
