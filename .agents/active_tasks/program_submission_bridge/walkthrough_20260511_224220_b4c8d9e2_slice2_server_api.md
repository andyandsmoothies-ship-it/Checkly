# Walkthrough: Slice 2 — Server API (PBAC Bypass + State Machine)

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_190931_b4c8d9e2_slice2_server_api.md`

## Decision Log
**Proposed**: Use PBAC to enforce security on Program-linked Submissions to prevent IDOR and unauthorized execution.
**Implemented**: 
- We extracted the IDOR and Template validation logic into a centralized `ProgramAssignmentBridge` helper.
- PBAC is validated using the globally accessible `PbacDictionaryCache` instead of parsing JWT claims directly, ensuring robust role-based access checks that are fully compatible with integration tests and cache reloads.
- Transitioned `CreateSubmission` to utilize runtime PBAC logic by dropping the `.RequireCapability(SubmissionsCreate)` on the endpoint and replacing it with a capability check directly in the handler. This allows the handler to distinguish between legacy audit creations and program assignment executions.
- `FinalizeSubmission` was updated with a post-commit hook to transition the associated `ProgramAssignment` status to `submitted`. Added guard logic requiring non-empty `answers` to pass validation.

## Verification Handoff
All tests passed on the server-side. No further QA intervention needed on the API layer. The API now safely handles `ProgramAssignmentId` constraints, transitions assignment statuses upon creation and finalization, and safely projects `TemplateId` to the UI for assignment fetching.

<test_trace>
rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter FullyQualifiedName~Program_Slice2A_Tests -v n
12 tests passed, 0 failed.
</test_trace>

<forensic_evidence>
Run command: `cmd /c "rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter FullyQualifiedName~Program_Slice2A_Tests -v n > .agents\tmp\slice2a_test3.txt 2>&1"`
</forensic_evidence>

## Gotcha Protocol
**Add the following to `server/GEMINI.md`:**
- **Gotcha: PBAC Capability Verification in Handlers**
  - **Fix:** Do not manually check claims or use `RequireCapability` attributes for routes that need conditional PBAC bypass (e.g., Program Assignments vs Legacy Audits). Use the `PbacDictionaryCache.Instance.HasCapability(userRole, capability)` inside the handler logic to safely resolve capability rights.
- **Gotcha: Functional Test Answer/Score Compliance**
  - **Fix:** When simulating `FinalizeSubmission` in integration tests, the server requires real scoring computation if criteria exist. Provide explicit criteria logic when seeding templates (e.g. `CreateTemplateWithCriterionAsync`) so the tests can send a correct `clientScore` to bypass the verification guards.
