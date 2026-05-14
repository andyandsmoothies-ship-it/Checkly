# Walkthrough: Mismatch in Program Task Count on SM Dashboard

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260513_190027_mismatch_program_task_count.md`

## Decision Log
- **Proposed**: Update `PendingAssignmentVm` to hold `id` and `title`. Update `DashboardManager.watchActionRequired` to return `List<PendingAssignmentVm>`. Update `ActionRequiredWidget` to render a `Column` of `HeroCard`s.
- **Implemented**: The code was previously micro-experimented and left in place. We verified the code structure matches the proposed fix and validated it by running the global test suite. No new code required modification as it was already accurate and compiling.

## Verification Handoff
- **Steps for QA**: 
  1. Log in as a Store Manager with multiple pending program assignments.
  2. Verify that the Dashboard now displays multiple individual amber banners (one for each task) under "Action Required".
  3. Verify that tapping each banner correctly routes to its specific execution page `/programs/{id}`.

<test_trace>
01:01 +494: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: TC-F1-01: AC_429_ReturnsRetryScheduled_NoDelay
01:03 +495: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: (tearDownAll)
01:03 +495: All tests passed!

Exit code: 0
</test_trace>

<forensic_evidence>
- Terminal command: `flutter test` executed globally.
- Tool call: `view_file` on `pending_assignment_vm.dart`
- Tool call: `view_file` on `dashboard_manager.dart`
- Tool call: `view_file` on `action_required_widget.dart`
- Tool call: `grep_search` for `fail('Implement...')` across the repository to ensure no orphaned stubs.
</forensic_evidence>

## Gotcha Protocol
- No new gotchas identified during this verification task.
