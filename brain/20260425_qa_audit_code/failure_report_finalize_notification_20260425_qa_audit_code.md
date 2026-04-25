# Failure Report: Finalize Notification Flow

Topic: `FinalizeSubmission` false-success notification side effect
Date: 2026-04-25

## Root Cause
- File: [server/Features/Submissions/FinalizeSubmission.cs](C:\Users\HP\Documents\GitHub\Checkly\server\Features\Submissions\FinalizeSubmission.cs:233)
- Fault line: notification side effects at [lines 282-303](C:\Users\HP\Documents\GitHub\Checkly\server\Features\Submissions\FinalizeSubmission.cs:282)
- Reason:
  - `strategy.ExecuteAsync<IResult>(...)` can return a non-success result, including the explicit concurrency `409 Conflict` path at [lines 251-258](C:\Users\HP\Documents\GitHub\Checkly\server\Features\Submissions\FinalizeSubmission.cs:251).
  - The method then executes the notification insert and FCM dispatch block regardless of whether `result` represents success.
  - That creates a mismatch between persisted submission state and downstream notification state.

## Input -> Failure Path
1. Two finalize requests race on the same submission.
2. One request wins the save.
3. The second request hits `DbUpdateConcurrencyException` and returns `Conflict`.
4. Post-transaction code still inserts `audit_submitted` notification and dispatches FCM.
5. Store manager receives a false signal for a request that failed.

## Layer Classification
- API layer: incorrect post-result side effect.
- Data layer: notification write occurs outside the guarded success path.

## Fix Path Suggestion
- Preferred:
  - Only create notification/push side effects after confirming the returned `IResult` is a success result.
  - Add a regression test that forces the non-success path and asserts zero notification rows and zero dispatch attempts.
- Alternative:
  - Move notification creation into the transaction success branch and keep FCM dispatch after commit.

## Trade-offs
- Success gating after `result`:
  - Pros: minimal code movement, easy to review.
  - Cons: depends on how success is represented by the returned result type.
- Moving the write into the success branch:
  - Pros: side-effect ordering is easier to understand.
  - Cons: risks expanding transaction responsibilities if not kept careful.

## Strict Implementation Constraints & Human Reminders
- Do not broaden this into a general notification refactor.
- Preserve existing delegated-finalization authorization behavior.
- Add test coverage before changing logic so the failure is proven.

<forensic_evidence>
view_file evidence:
- server/Features/Submissions/FinalizeSubmission.cs lines 233-307
- server/tests/Checkly.Api.Tests/Features/Submissions/FinalizeNotificationTests.cs lines 1-140
</forensic_evidence>
