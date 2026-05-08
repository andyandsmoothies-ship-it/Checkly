## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260506_161106_t1_assign_task_pbac.md`

## Decision Log
- **Proposed**: Update `ChecklyFab` to use a PBAC check for the Assign Task action.
- **Implemented**: Passed `canAssignTask: _di<PolicyManager>().can(AppCapabilities.programsCreate)` directly from `DashboardPage` and `HistoryPage` to `ChecklyFab`. Renamed `isAdmin` to `canAssignTask` in `ChecklyFab`. 
- **Additional Changes**: Cleaned up an unused import (`auth_manager.dart`) in `HistoryPage` that triggered an analyzer warning.

## Verification Handoff
1. Log in as a user with the `programs:create` capability but not the strict 'admin' role (e.g. Area Manager).
2. Verify the "Assign Task" FAB action is visible and functional on the Dashboard and Audits History pages.
3. Log in as a Store Manager without the capability and verify the FAB action is hidden.

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_manager_test.dart
00:00 +0: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_manager_test.dart: DashboardManager IA Overhaul (TC-01...TC-04) TC-02: Should return ManagerDashboardState when stores are empty
00:00 +1: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_manager_test.dart: DashboardManager IA Overhaul (TC-01...TC-04) TC-03 & TC-04: Should set storeName to "Syncing..." and storeId to null when empty
00:00 +2: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_manager_test.dart: DashboardManager IA Overhaul (TC-01...TC-04) TC-05: Should pull personal metrics despite empty store cache
00:00 +3: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:01 +4: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-03: DeadlineBanner border should be removed
00:01 +5: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-04 & VC-05: SubmissionRow score circle and font
00:01 +6: All tests passed!
</test_trace>

<forensic_evidence>
Ran `flutter analyze` ensuring 0 warnings in affected files.
Ran `flutter test ../test/features/dashboard` resulting in 100% pass rate.
Ran `flutter test ../test/features/audit` ensuring no regressions.
</forensic_evidence>

## Gotcha Protocol
- No new gotchas identified during this PBAC migration slice. PBAC checks via `PolicyManager` are functioning natively as designed.
