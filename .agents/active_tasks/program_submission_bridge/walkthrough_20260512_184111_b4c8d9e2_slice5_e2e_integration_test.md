# Program Submission Bridge E2E Integration Test

## Artifacts Generated
- **E2E Test File**: `server/tests/Checkly.Api.Tests/Features/Submissions/ProgramSubmissionBridge_E2E_Tests.cs`
- **Test Output Log**: `.agents/tmp/executed_tests_20260512_184111_b4c8d9e2_slice5_e2e_integration_test.md`

## Summary of Execution
The goal of this slice was to execute an end-to-end integration test validating the integration between `ProgramAssignments` and `Submissions` (the "Program-Submission Bridge").

I created the `ProgramSubmissionBridge_E2E_Tests.cs` using the `TestWebApplicationFactory` to spin up the local API in `checkly_test` and interact with it exactly as a mobile client would.

### The Test Flow
1. **Arrange**: 
   - Initialized a `Store`, `ChecklyProgram`, `Template`, and a `ProgramAssignment` targeting a Store Manager.
2. **Act 1 (Create Draft)**: 
   - POST to `/api/submissions` passing the `ProgramAssignmentId` and `status=draft`.
3. **Assert 1**:
   - HTTP 201 Created.
   - `ProgramAssignmentId` was correctly persisted on the Submission.
   - The Assignment's status successfully transitioned from `pending` -> `in_progress`.
4. **Act 2 (Finalize)**: 
   - PUT to `/api/submissions/{id}/finalize` passing the required answers and scores.
5. **Assert 2**:
   - HTTP 200 OK.
   - Submission status transitioned to `completed`, and its `ReviewStatus` transitioned to `approved`.
   - The Assignment's status successfully transitioned to `submitted`.

### Result
**The test passed cleanly.** The implementation for Slices 1-4 was already successfully completed in previous phases and fully covers the state transitions required by Slice 5.

## Conclusion
The infrastructure audit and TDD remediation are complete, and the Program-Submission bridge E2E test proves the system acts correctly across API boundaries. 
There are no RED tests left to implement for this epic—the backend bridge is structurally sound and fully integrated!
