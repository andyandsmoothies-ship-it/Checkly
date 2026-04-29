# Submission Overrides & Gotchas

- **Gotcha 7: Snapshot Fields Need Dual Writes — Create AND Finalize**
  - **Problem:** Writing only in `CreateSubmission` OR `FinalizeSubmission` leaves the field null for one of the two submission flows.
  - **Fix:** Always write new snapshot fields in BOTH `CreateSubmission` AND `FinalizeSubmission`.
 
- **Gotcha: NpgsqlRetryingExecutionStrategy + User Transactions**
  - **Problem:** `NpgsqlRetryingExecutionStrategy` does not support user-initiated transactions. Calling `BeginTransactionAsync` directly throws `InvalidOperationException` at runtime when Npgsql retry resiliency is configured.
  - **Fix:** Any handler opening an explicit `BeginTransactionAsync` MUST wrap the entire transaction block inside `db.Database.CreateExecutionStrategy().ExecuteAsync(...)`. Pattern: see `VoidSubmission.HandleAsync`.

- **Gotcha 8: Admin Submission Finalization Bypass**
  - **Problem:** `FinalizeSubmission.cs` has a strict ownership check (`submission.AuditorId != auditorId`). Any privileged user (admin, area_manager) who opens and submits a scheduled audit assigned to a different user will receive a silent 403, leading to an `exhausted` state in the Flutter outbox.
  - **Fix:** The ownership guard must include an explicit bypass using `SubmissionAccessGuard.CanDelegate(user)` to permit authorized delegates to finalize the submission.
