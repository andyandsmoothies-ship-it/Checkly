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
