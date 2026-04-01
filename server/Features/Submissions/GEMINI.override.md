# Submission Overrides & Gotchas

- **Gotcha 7: Snapshot Fields Need Dual Writes — Create AND Finalize**
  - **Problem:** Writing only in `CreateSubmission` OR `FinalizeSubmission` leaves the field null for one of the two submission flows.
  - **Fix:** Always write new snapshot fields in BOTH `CreateSubmission` AND `FinalizeSubmission`.
 
- **Gotcha: NpgsqlRetryingExecutionStrategy + User Transactions**
  - **Problem:** `NpgsqlRetryingExecutionStrategy` does not support user-initiated transactions. Calling `BeginTransactionAsync` directly throws `InvalidOperationException` at runtime when Npgsql retry resiliency is configured.
  - **Fix:** Any handler opening an explicit `BeginTransactionAsync` MUST wrap the entire transaction block inside `db.Database.CreateExecutionStrategy().ExecuteAsync(...)`. Pattern: see `VoidSubmission.HandleAsync`.
