# The Dirty Database Trap (Ghost Migrations)

**[HYPOTHESIS]**
- **Problem**: When an AI Agent adds a new database column (e.g., `VoidReason`) and generates an EF Core migration (`dotnet ef migrations add`), the agent frequently fails to formally *apply* that migration to the live PostgreSQL database because the local terminal is locked by `dotnet run`. This causes a fatal desync where the new C# code immediately crashes with `Npgsql.PostgresException: 42703 column does not exist` because EF Core queries the ghost column.
- **Fix Pipeline**:
  1. We have added `db.Database.Migrate();` to `Program.cs` so that simply restarting the server (`dotnet run`) will seamlessly auto-apply any pending migrations on startup in the `Development` environment.
  2. **Agent Mandate**: Whenever you create an EF Core migration, you MUST output a Github Alert `> [!WARNING]` explicitly telling the user to restart their server to trigger the auto-migration. Do not silently handoff the code.

# NpgsqlRetryingExecutionStrategy + BeginTransactionAsync (CONFIRMED)

- **Problem**: Any code that calls `db.Database.BeginTransactionAsync()` directly will throw `InvalidOperationException: The configured execution strategy 'NpgsqlRetryingExecutionStrategy' does not support user-initiated transactions` at both runtime and in integration tests.
- **Fix**: Always wrap `BeginTransactionAsync` + all SQL inside `db.Database.CreateExecutionStrategy().ExecuteAsync(...)`. Capture opened transaction to a variable declared *outside* the closure so it can be returned to callers. Pattern seen in: `VoidSubmission.HandleAsync`, `DistributedLockManager.TryAcquireAsync`.
