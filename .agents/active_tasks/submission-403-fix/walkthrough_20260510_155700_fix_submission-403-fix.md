# Walkthrough: Submission Finalize PBAC Sync Fix

## Input Lineage
- Source: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260510_152716_submission-403.md`

## Decision Log
**Proposed**: Remove the `.RequireCapability(AppCapabilities.SubmissionsCreate)` mapping from the `FinalizeSubmission` PUT route in `SubmissionEndpoints.cs`.
**Implemented**: Exactly as proposed. This aligns the backend's finalize logic with the frontend's explicit decision to allow users to "Resume" and submit drafts even if they lack the active permission to create new ones (preventing data loss).

## Verification Handoff
1. **QA Test Protocol**: 
   - Login as an Area Manager who has an assigned, pending draft audit.
   - Revoke the Area Manager's `submissions:create` capability via the Admin portal.
   - Have the Area Manager resume the pending draft audit and click "Submit".
   - **Expected**: Submission syncs successfully (200 OK), no 403 error.

<test_trace>
C:\Users\HP\Documents\GitHub\Checkly\server> dotnet test tests/Checkly.Api.Tests/ --filter FullyQualifiedName~FinalizeSubmission
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:    16, Skipped:     0, Total:    16, Duration: 9 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
- Modified `SubmissionEndpoints.cs` line 40-42.
- Verified that `FinalizeSubmission.cs` still safely applies `ResourceAccessGuard` and `AuditorId` boundary checks.
- Executed `dotnet test` with filter for `FinalizeSubmission` and confirmed all 16 slice tests passed.
- Note: Global test suite contains a known failure in `GetCapabilityCatalog_Returns17Capabilities_IncludingProgramExecution` due to unrelated PBAC Track B expansions, outside this micro-fix's blast radius.
</forensic_evidence>

## Gotcha Protocol
- No new gotcha. This fixes a strictness mismatch between frontend and backend.
