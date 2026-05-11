# Walkthrough: Fix Admin Cannot Assign Task
Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260511_102800_diagnose_assign_auditor.md`

## Decision Log
- **Proposed**: Update `AdminAuditManager` to use `submissions:create` instead of `submissions:execute`.
- **Implemented**: 
  - Updated `AdminAuditManager` to use the strongly typed constant `AppCapabilities.submissionsCreate`.
  - Updated the test suite to assert the correctness of using `submissions:create`.

## Verification Handoff
- Check that the application runs and the 'Assign Task' dropdown works.
- Verify that `flutter test test/features/admin/manager/admin_audit_manager_pbac_test.dart` passes.

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/admin_audit_manager_pbac_test.dart
00:00 +0: TC-PBAC-04a: LoadScheduleData_CallsBackend_WithSubmissionsCreateCapability
00:00 +1: TC-PBAC-04b: LoadScheduleData_DoesNotCallBackend_WithSubmissionsExecuteCapability
00:00 +2: TC-PBAC-04c: LoadScheduleData_PopulatesAllAuditors_DirectlyFromApiResult
00:00 +3: TC-PBAC-04d: LoadScheduleData_EmptyApiResult_AllAuditorsIsEmpty
00:00 +4: TC-PBAC-04e: LoadScheduleData_ApiThrows_SetsScheduleError
00:00 +5: TC-PBAC-04f: LoadScheduleData_AfterCompletion_SetsIsScheduleLoadingFalse
00:00 +6: All tests passed!
</test_trace>

<forensic_evidence>
cmd /c "cd /d C:\Users\HP\Documents\GitHub\Checkly && rtk flutter analyze && rtk flutter test"
</forensic_evidence>

## Gotcha Protocol
None.
