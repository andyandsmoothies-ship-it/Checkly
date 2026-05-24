# Test Contracts: Fix CanDelegate IDOR

## Context
These tests explicitly define the IDOR vulnerability present in `ResourceAccessGuard.CanDelegate`. The core issue is that `CanDelegate` only checks the string role of the user (whether they are an "admin" or "area_manager") without verifying if the requested store/resource actually falls within the Area Manager's scope. 

## Smoke Gate (RED Phase)

| Test Name | Status | Type | Error Summary |
|---|---|---|---|
| `Checkly.Api.Tests.Submissions.SubmissionDelegationAuthTests.AreaManager_CannotDelegate_OutsideArea_Returns403` | 🔴 FAIL | Business | `Expected: Forbidden. Actual: Created.` The Area Manager successfully delegated a submission for a store they do not manage, proving the IDOR vulnerability exists. |
| `Checkly.Api.Tests.Guards.SubmissionAccessGuardUnitTests.CanDelegate_AreaManager_ReturnsFalse_IfOutsideArea` | 🔴 FAIL | Business | `Expected: False. Actual: True.` The synchronous CanDelegate logic returns true regardless of DB context. |

## Notes for Builder
1. The unit tests inside `SubmissionAccessGuardUnitTests.cs` currently use the old synchronous signature `CanDelegate(user)` so they compile. **You must update these calls** to `CanDelegateAsync(user, scope, db, ct)` once you implement the new signature.
2. The `AreaManager_CannotDelegate_OutsideArea_Returns403` HTTP test ensures that when the Builder wires `CanDelegateAsync` into `CreateSubmission` and `FinalizeSubmission`, the API properly returns `403 Forbidden` and prevents the creation of the submission.
3. You will also need to update the AC-02 success test and the rest of the unit tests to pass the new dependencies into `CanDelegateAsync`.
