# Test Contracts: Program Submission Bridge (Slice 2)

**Test File:** `server/tests/Checkly.Api.Tests/Program_Slice2A_Tests.cs`
**Status:** RED (10 Failed, 2 Passed)

## Objective
Establish the ATDD (Acceptance Test-Driven Development) test suite for the Program Submission Bridge, verifying PBAC bypass logic, IDOR protections, state machine transitions, and DTO updates prior to implementation.

## Phase A & D: DTO Extraction & Validation
| Test Case | Objective | Current RED State | Expected GREEN State |
| :--- | :--- | :--- | :--- |
| `TC1_GetMyAssignments_AsStoreManager_ReturnsAssignments` | Verify `TemplateId` is returned in the assignment DTO. | Fails with `KeyNotFoundException` for `templateId`. | Returns the populated `TemplateId` from the underlying program. |

## Phase B: PBAC Bridge & IDOR Security
| Test Case | Objective | Current RED State | Expected GREEN State |
| :--- | :--- | :--- | :--- |
| `TC_S2_01_SM_With_ProgramsExecute_Creates_Draft_For_Valid_Assignment` | Manager with `programs:execute` can create a submission linked to a valid assignment. | Fails with `Forbidden` (`403`). | Returns `Created` (`201`) and sets Assignment to `in_progress`. |
| `TC_S2_04_IDOR_SM_From_StoreB_Cannot_Use_StoreA_Assignment` | A manager from another store cannot hijack an assignment ID belonging to a different store. | Fails with `Forbidden` (`403`). | Explicitly asserts `Forbidden` (`403`) against the IDOR attempt. |
| `TC_S2_06_NonExistent_AssignmentId_Returns_404` | Supplying a garbage `AssignmentId` returns NotFound. | Fails with `Forbidden` (`403`) due to baseline policy. | Returns `NotFound` (`404`). |
| `TC_S2_07_SM_Without_ProgramsExecute_Is_Rejected` | Manager lacking `programs:execute` capability cannot execute the bridge. | Fails with `Created` (Requires updating test roles in setup, but failed correctly). | Returns `Forbidden` (`403`). |
| `TC_S2_10_DoubleTap_Guard_Returns_Same_Submission` | If a draft submission is already mapped to the assignment, return the existing draft instead of creating a new one. | Fails with `Forbidden` (`403`). | Returns `OK` (`200`) instead of `201`, returning the existing submission ID. |

## Phase C: State Machine Post-Commit Hooks
| Test Case | Objective | Current RED State | Expected GREEN State |
| :--- | :--- | :--- | :--- |
| `TC_S2_02_Valid_Template_Must_Match_Program_Template` | Validation check: The `TemplateId` supplied must match the Program's configured `TemplateId`. | Fails with `Forbidden` (`403`). | Returns `BadRequest` (`400`). |
| `TC_S2_03_Finalize_Transitions_Assignment_To_Submitted` | Calling `/api/submissions/{id}/finalize` transitions both the Submission to `approved` and the parent Assignment to `submitted`. | Fails with `Forbidden` (`403`). | Both DB entities reflect the transition. |

## Next Steps for the Builder
1. **Remove Route-Level Policy**: Remove `.RequireCapability("submissions:create")` from the Create Submission endpoint.
2. **Implement Bridge Logic**: Within `CreateSubmission.cs`, invoke `ProgramAssignmentBridge` to validate the `programs:execute` capability, assignment ownership, and double-tap prevention.
3. **Add Post-Commit Hook**: Update `FinalizeSubmission.cs` to detect parent assignments and transition them to `submitted`.
4. **Update DTO**: Add `TemplateId` to `AssignmentSummaryDto` and populate it in `ProgramEndpoints`.
5. **Execute**: Run `rtk dotnet test` and ensure all tests turn GREEN. Do not alter the tests to pass. Fix the implementation.
