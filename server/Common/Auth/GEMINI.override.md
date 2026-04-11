# GEMINI.override.md — server/Common/Auth/

## Module-Specific Gotchas

### Gotcha: `foreach var _` Conflicts with `TryRead(out _)` in Same Scope (CS1657)
- **Problem:** When using `await foreach (var _ in reader.ReadAllAsync(ct))`, the C# compiler binds `_` as a **named local variable** (not a discard). Any subsequent use of `out _` inside that `foreach` body fails with:
  > `CS1657: Cannot use '_' as a ref or out value because it is a 'foreach iteration variable'`
- **Fix:** Pre-declare a named variable **outside** the loop body:
  ```csharp
  bool drained; // declared outside the foreach
  await foreach (var _ in reader.ReadAllAsync(ct))
  {
      while (reader.TryRead(out drained)) { }  // ← no conflict
  }
  ```
- **Confirmed:** Applied in `PbacCacheListenerService.cs` (2026-04-11, Slice 2).

---

### Gotcha: 4-Param Test Constructor Must Stay Bindable
- **Problem:** `PbacCacheListenerServiceTests.cs` constructs `PbacCacheListenerService` with exactly 4 params (`cache, config, logger, sp`). If `IOptions<PbacListenerOptions>` is added as a **required** 5th constructor param, the tests break with a compile error.
- **Fix:** Declare `IOptions<PbacListenerOptions>? options = null` (optional, nullable) with a fallback:
  ```csharp
  _options = options?.Value ?? new PbacListenerOptions();
  ```
- **Rule:** Do NOT modify the test file to add the 5th param (Anti-Bias Protocol). The production code adapts to the contract boundary.

---

### Gotcha: `++attempt` Double-Increment When Used as Both Side-Effect and Argument
- **Problem:** `logger.LogWarning(ex, "...", ++attempt, delay.TotalSeconds)` increments `attempt` as a side-effect AND passes the result as an argument. If the same incremented value is needed downstream (e.g., for a conditional branch or a second log call), the variable is already at the wrong value.
- **Fix:** Always capture into a named variable first:
  ```csharp
  var currentAttempt = ++attempt;
  if (currentAttempt >= 3) { logger.LogError(..., currentAttempt, ...); }
  else                      { logger.LogWarning(..., currentAttempt, ...); }
  ```
- **Confirmed:** Applied in `PbacCacheListenerService.cs` catch block (2026-04-11, Slice 3).

---

### Gotcha: `--filter` Isolated Runs Cause WAF Migration Race (False Failure)
- **Problem:** Running `dotnet test --filter FullyQualifiedName~SomeTestClass` in isolation spins up a SEPARATE `WebApplicationFactory` (WAF) instance for each test class. Each WAF calls `EnsureDatabaseCreated()` which calls `db.Database.Migrate()`. When multiple WAF instances run concurrently against the same `checkly_test` database, migrations race and fail with:
  - `42701: column "X" of relation "Y" already exists` (migration already applied)
  - `3D000: database "checkly_test" does not exist` (DB dropped & recreated mid-run)
- **Root Cause:** `[Collection("ApiCollection")]` forces sequential execution via a SHARED WAF — but only when ALL tests run together. Filtered runs break the shared-fixture contract.
- **Fix:** ALWAYS run the full suite for integration test verification: `dotnet test --no-build`. Never use `--filter` alone to verify WAF-dependent tests in isolation.
- **Safe Use of `--filter`:** Fine for pure unit tests (no WAF, no DB) or single-class filters where only ONE WAF is instantiated.
- **Confirmed:** Discovered during PBAC S-2 verification run (2026-04-11).
