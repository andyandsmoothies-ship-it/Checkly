# Test Contracts: PBAC02 Backend Allowed Actions

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260514_223612_PBAC02_hybrid_entity_ui.md`

## Spec & Acceptance Criteria

| Test Name | Scenario (Gherkin) | Status | Test File |
|-----------|--------------------|--------|-----------|
| TC01_Reviewer_CompletedSubmission_CanFinalize | **Given** a reviewer is requesting a `completed` submission<br>**When** the API returns the DTO<br>**Then** `allowedActions` includes `finalize` | RED (Business) | `SubmissionAllowedActionsTests.cs` |
| TC02_Reviewer_FinalizedSubmission_CannotFinalize | **Given** a reviewer is requesting a `finalized` submission<br>**When** the API returns the DTO<br>**Then** `allowedActions` does NOT include `finalize` | DEFERRED | `SubmissionAllowedActionsTests.cs` |
| TC03_Reviewer_VoidedSubmission_CannotVoid | **Given** a reviewer is requesting a `voided` submission<br>**When** the API returns the DTO<br>**Then** `allowedActions` does NOT include `void` | DEFERRED | `SubmissionAllowedActionsTests.cs` |
| TC04_Creator_DraftSubmission_CanEdit | **Given** the original creator is requesting a `draft` submission<br>**When** the API returns the DTO<br>**Then** `allowedActions` includes `edit` and `submit` | RED (Business) | `SubmissionAllowedActionsTests.cs` |
| TC05_AreaManager_CompletedSubmission_CannotEdit | **Given** an area_manager (not reviewer/creator) is requesting a `completed` submission<br>**When** the API returns the DTO<br>**Then** `allowedActions` does NOT include `edit`, `submit`, or `finalize` | RED (Business) | `SubmissionAllowedActionsTests.cs` |
| TC06_Creator_FinalizedSubmission_CannotEdit | **Given** the creator is requesting a `finalized` submission<br>**When** the API returns the DTO<br>**Then** `allowedActions` does NOT include `edit` | DEFERRED | `SubmissionAllowedActionsTests.cs` |
| TC07_GAP_UnrecognizedStatus_ReturnsOnlyView | **Given** a submission with an unrecognized status<br>**When** the API returns the DTO<br>**Then** `allowedActions` defaults to safe actions only | DEFERRED | `SubmissionAllowedActionsTests.cs` |
| TC08_UnauthorizedUser_GetsEmptyOrNoActions | **Given** a user with no access requests a submission<br>**When** the API responds<br>**Then** it returns a 404 Not Found | GREEN | `SubmissionAllowedActionsTests.cs` |

## Deferred Reason
- `TC02`, `TC03`, `TC06`, and `TC07` use invalid statuses that trigger a database constraint violation on `status_check`. The implementation plan utilizes inaccurate terminologies (`finalized`, `voided`) that contradict the EF Core entities and DB schema (`approved`, `rejected`).
- These tests are skipped at the framework level pending an upstream plan update.

## Test Infrastructure Map
- **Target Project**: `Checkly.Api`
- **Test Project**: `Checkly.Api.Tests`
- **Auth Provider**: `TestWebApplicationFactory` utilizing `RegisterUserAsync`
- **DB Mode**: `checkly_test` PostgreSQL using EF Core Migrations
