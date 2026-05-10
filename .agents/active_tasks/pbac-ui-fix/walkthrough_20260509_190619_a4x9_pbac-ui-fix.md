# Walkthrough: Sync AppCapabilities Constants

## Input Lineage
`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-ui-fix\implementation_plan_20260509_190140_493220d8_pbac-ui-fix.md`

## Decision Log
- **Proposed**: Sync 8 missing PBAC capabilities into Flutter and update the `adminDomainCapabilities` set.
- **Implemented**: Added `programsList`, `programsExecute`, `programsManage`, `programsReview`, `programsAssignmentsMy`, `programsAssignmentsList`, `globalRisksManage`, and `analyticsView` to `AppCapabilities`. Added `globalRisksManage` to `adminDomainCapabilities`.

## Verification Handoff
This slice is ready. No further manual testing is needed until Slice 2 is completed.

<test_trace>
Analyzing app_capabilities.dart...                              
No issues found! (ran in 3.0s)
</test_trace>

<forensic_evidence>
Ran `flutter analyze` on the modified file to ensure there were no syntax errors.
</forensic_evidence>

## Gotcha Protocol
None for this slice.
