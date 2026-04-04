# Server Common rules & Gotchas

- **Gotcha 3: Route Registration Order — Specific Before Catch-All**
  - **Problem:** A catch-all route (e.g., `/{id}`) registered before a specific route swallows the request and tries to parse the path segment as a GUID.
  - **Fix:** Always register specific named routes BEFORE parameterized/catch-all routes in `*Endpoints.cs`.

- **Gotcha 4: Every Column Needs Explicit `HasColumnName` in AppDbContext**
  - **Problem:** EF will NOT auto-map `ScoringMode` → `scoring_mode`; missing `HasColumnName` causes silent column mismatches.
  - **Fix:** Add `HasColumnName("snake_case_name")` in `AppDbContext` for every new entity property before migrating.

- **Gotcha 8: SectionScores is JSONB — Cannot Use EF GroupBy**
  - **Problem:** EF cannot translate `GroupBy` on dynamic jsonb keys — it will fail at runtime.
  - **Fix:** Load the jsonb strings and parse in C#. Use a GIN index (`jsonb_path_ops`) for future raw SQL.

- **Gotcha 27: Serilog Bootstrap Logger Freezes — Test Factory Re-Entry Crash**
  - **Problem:** `CreateBootstrapLogger()` freezes the static `Log.Logger`. When xUnit runs multiple tests, re-executing `Program.cs` throws `InvalidOperationException: The logger is already frozen`.
  - **Fix:** Guard the bootstrap logger assignment with `if (Log.Logger.GetType().Name == "SilentLogger")` so it only runs on first entry.

- **Gotcha 29: `Answer.CriteriaId` Has a Hard Postgres FK — Cannot Use Random GUID in Test Seeding**
  - **Problem:** Inserting an `Answer` row with a random `CriteriaId` for test isolation throws `23503 FK violation` on `answers.criteria_id`. The EF property is named `CriteriaId` (not `CriterionId`).
  - **Fix:** Either seed a valid `Criterion` row first, OR test the behavior that naturally produces a `null` answer lookup (e.g., pass a non-existent `answerId` GUID to the API endpoint — the `FindAsync` returns null and no patch occurs, satisfying the same security assertion without any FK).

- **Gotcha 28: Pagination `page` Int32 Overflow → 500 on OFFSET Arithmetic**
  - **Problem:** `Math.Max(1, p)` floors at 1 but has NO upper bound. `?page=2147483647` causes `(page - 1) * pageSize` to overflow 32-bit int. EF Core passes a negative OFFSET to Npgsql → `ArgumentOutOfRangeException` → 500 Internal Server Error.
  - **FIX (MANDATORY):** After `CountAsync`, add an overflow-safe guard before `.Skip()`:
    ```csharp
    if ((long)(page - 1) * pageSize >= total)
        return TypedResults.Ok(new PagedResult<T>([], total, page, pageSize));
    ```
  - **Files:** `ListTemplates.cs`, `ListSubmissions.cs`, `ListStores.cs`, `ListActionPlans.cs` — all patched 2026-04-03.

- **Gotcha 30: IFormFile.OpenReadStream() Is Non-Seekable — Cannot Rewind**
  - **Problem:** After reading bytes from `file.OpenReadStream()`, calling `stream.Position = 0` throws `NotSupportedException`. The ASP.NET Core multipart stream is forward-only.
  - **Fix:** Use two separate `file.OpenReadStream()` calls: one for the header bytes inspection, one for `CopyToAsync` (or just call `file.CopyToAsync()` directly after the header read). `IFormFile` supports multiple stream opens.

- **Gotcha 31: Changing Guard Ordering Cascades to Legacy Test Status Codes**
  - **Problem:** When the magic byte check was moved BEFORE the extension check, the legacy test `UploadPhoto_WithExecutableExtension_ReturnsBadRequest` broke because null-byte payloads now hit the magic check first and return 415 instead of 400.
  - **Fix:** Apply the Strict TDD Legacy clause — update the legacy test assertion to match the new correct status code. Always recheck `PhotoSecurityTests.cs` after any guard reordering in `UploadPhoto.cs`.

- **Gotcha 32: Drift DAO Test Fakes Must Use `implements`, Never `extends`**
  - **Problem:** Subclassing a Drift DAO (e.g., `class FakeDao extends ActionPlanOutboxDao`) and passing `null as dynamic` to the `super()` for the `AppDatabase` parameter causes a `LateInitializationError: Local 'engine' has not been initialized` at `setUp` time. The non-nullable `AppDatabase _db` field receives `null`, and any field access triggers an NPE before any test body runs.
  - **Fix:** Always use `implements` for DAO test doubles: `class FakeDao implements ActionPlanOutboxDao { ... }`. Implement every method directly — no parent constructor is called, no DB is needed.
