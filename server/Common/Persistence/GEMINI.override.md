# The Dirty Database Trap (Ghost Migrations)

**[HYPOTHESIS]**
- **Problem**: When an AI Agent adds a new database column (e.g., `VoidReason`) and generates an EF Core migration (`dotnet ef migrations add`), the agent frequently fails to formally *apply* that migration to the live PostgreSQL database because the local terminal is locked by `dotnet run`. This causes a fatal desync where the new C# code immediately crashes with `Npgsql.PostgresException: 42703 column does not exist` because EF Core queries the ghost column.
- **Fix Pipeline**:
  1. We have added `db.Database.Migrate();` to `Program.cs` so that simply restarting the server (`dotnet run`) will seamlessly auto-apply any pending migrations on startup in the `Development` environment.
  2. **Agent Mandate**: Whenever you create an EF Core migration, you MUST output a Github Alert `> [!WARNING]` explicitly telling the user to restart their server to trigger the auto-migration. Do not silently handoff the code.


# NpgsqlRetryingExecutionStrategy — Delegate Mandate (CONFIRMED, PRODUCTION-PROVEN)

- **Problem**: Any code that calls `db.Database.BeginTransactionAsync()` directly will throw `InvalidOperationException: The configured execution strategy 'NpgsqlRetryingExecutionStrategy' does not support user-initiated transactions`. Furthermore, **capturing a transaction inside `strategy.ExecuteAsync()` and returning it to the caller** causes the same crash on the NEXT EF Core query run by the caller — because a new strategy instance sees an open transaction it doesn't own.
- **❌ PROHIBITED Anti-Pattern (The Scope Leak)**:
  ```csharp
  // DO NOT DO THIS: transaction leaks outside the strategy closure
  IDbContextTransaction? tx = null;
  await strategy.ExecuteAsync(async () => { tx = await db.Database.BeginTransactionAsync(); });
  await db.SomeTable.ToListAsync(); // CRASHES — new strategy sees orphaned transaction
  ```
- **✅ MANDATORY Pattern (Delegate / Ruby-block)**:
  ```csharp
  // ALL EF Core queries must run INSIDE the same strategy.ExecuteAsync() closure
  await strategy.ExecuteAsync(async () =>
  {
      await using var tx = await db.Database.BeginTransactionAsync();
      // Run ALL queries here — lock acquisition, business work, SaveChanges
      await criticalSection(ct); // pass work in as a delegate
      await tx.CommitAsync();
  });
  ```
- **Rule**: When implementing distributed locks or any transactional guard, the manager MUST accept a `Func<CancellationToken, Task>` delegate and execute it inside its own `strategy.ExecuteAsync()`. Never export an open transaction outside the closure. Pattern: `DistributedLockManager.TryExecuteInLockAsync`.

