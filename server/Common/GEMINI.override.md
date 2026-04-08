# Server Common Gotchas

> [!WARNING]
> **Route Registration Order — Specific Before Catch-All**
> **Problem:** Catch-all routes (e.g., `/{id}`) registered before specific routes swallow the request.
> **Fix:** Always register specific named routes BEFORE parameterized/catch-all routes in `*Endpoints.cs`.

> [!WARNING]
> **EF Core Mapping: Explicit `HasColumnName` Required**
> **Problem:** EF will NOT auto-map `ScoringMode` → `scoring_mode`. Missing `HasColumnName` causes silent crashes.
> **Fix:** Add `HasColumnName("snake_case_name")` in `AppDbContext` for every new property before migrating.

> [!WARNING]
> **EF Core LINQ translation fails on JSONB keys**
> **Problem:** EF cannot translate `GroupBy` on dynamic jsonb keys.
> **Fix:** Load jsonb strings into memory and parse in C#, OR use raw SQL with a GIN index (`jsonb_path_ops`).

> [!WARNING]
> **Test Factory Crash: Serilog Bootstrap Logger Freezes**
> **Problem:** `CreateBootstrapLogger()` freezes `Log.Logger`. Re-executing `Program.cs` in xUnit throws `InvalidOperationException`.
> **Fix:** Guard the assignment: `if (Log.Logger.GetType().Name == "SilentLogger")`.

> [!WARNING]
> **Answer.CriteriaId Postgres FK Violation in Tests**
> **Problem:** Seeding an `Answer` with a random GUID `CriteriaId` throws `23503`.
> **Fix:** Seed a valid `Criterion` row first, or test the naturally occurring `null` behavior.

> [!IMPORTANT]
> **Pagination Int32 Overflow → 500 Error (Arithmetic)**
> **Problem:** `?page=2147483647` overflows 32-bit int causing EF Core negative OFFSET. 
> **Fix:** Must append overflow guard after `CountAsync`:
> ```csharp
> if ((long)(page - 1) * pageSize >= total) return TypedResults.Ok(new PagedResult<T>(...));
> ```

> [!WARNING]
> **IFormFile.OpenReadStream() is Non-Seekable**
> **Problem:** Calling `stream.Position = 0` after reading throws `NotSupportedException`.
> **Fix:** Issue separate `file.OpenReadStream()` calls per read attempt.

> [!WARNING]
> **Strict TDD Legacy: Guard Reordering Cascades**
> **Problem:** Reordering security guards (e.g., magic bytes vs extension) changes the returned HTTP status code, failing legacy tests.
> **Fix:** Update legacy test assertions to assert the new correct status code.

> [!WARNING]
> **Drift DAO Test Fakes Must Use `implements`, Not `extends`**
> **Problem:** Subclassing via `extends` and passing `null` to `super()` crash-loops the test suite before body execution due to `AppDatabase` NPEs.
> **Fix:** Always use `class FakeDao implements ActionPlanOutboxDao`.
