# Backend Baseline Rules (.NET Minimal API)
> **Scope**: Database migrations/naming, Minimal API endpoint patterns, backend testing, and service gotchas.
> **Out of Scope**: Global governance rules, Flutter UI rules, or deployment orchestration.

## Database & EF Core

### Rule: 3-Step Database Updates
Do not use auto-migration. Use this strict 3-step process:
1. **Generate:** `dotnet ef migrations script -i -o update.sql`
2. **Apply:** Run the SQL script manually using a DB tool.
3. **Deploy:** Start the server only *after* the schema changes.

### Database Rules
- **Column Naming**: Use **snake_case** via `HasColumnName()` in `AppDbContext`.
- **Migrations**: Generated via `dotnet ef migrations add <Name>` inside `server/`.
- **Gotcha 9**: `dotnet ef migrations add` grabs all pending changes. Split them if necessary.
- **Gotcha: .NET Namespace Collisions**
  - **Fix:** When naming entities with common names like `Program`, `Task`, or `Role`, ALWAYS use fully qualified namespaces (e.g., `Entities.Program`) in `AppDbContext.cs` to prevent collisions with the application's `Program.cs` or system types.
- **Gotcha: PostgreSQL Null Inequality Translation Bug**
  - **Fix:** In EF Core queries targeting PostgreSQL, any inequality comparison like `s.ReviewStatus != "rejected"` will silently exclude all records where the column value is `NULL`. This happens because Postgres evaluates `NULL != 'rejected'` as `NULL` (falsy in WHERE clauses). To correctly query all records that are not rejected (including both null/unreviewed and non-rejected records), you must always write `(s.ReviewStatus == null || s.ReviewStatus != "rejected")`.

## API Architecture

### Endpoint Pattern
Endpoints are registered in `*Endpoints.cs` files using `MapGet`/`MapPost`/`MapPut`.
```csharp
public static class DoSomething
{
    public static async Task<IResult> HandleAsync(AppDbContext db, CancellationToken ct) { ... }
}
```
- **Gotcha 12**: Every new handler needs a success test (200/201) and an error test (404/403/400).

### Pagination Standard
All list endpoints MUST use `PagedResult<T>` (`Common/PagedResult.cs`). Query params: `page` (default 1), `pageSize` (default 50, max 200).

### Security & Architecture Verification
- **Explicit Scoping Rule**: Do not use global query filters. Check access explicitly in each handler using `ResourceAccessGuard.CanAccessAsync` to prevent breaking admin/sync APIs.
- **Architecture Tests**: Every query/command endpoint handler accessing submissions, stores, or photos must be scanned via automated reflection tests to ensure `CanAccessAsync` is called, preventing silent security regressions.

### Shared Services Pattern
- **ActionPlanService**: Call safely to automatically create action plans from answers.
- **ResourceAccessGuard**: Reusable IDOR guard. Use `new ResourceScope(StoreId: ..., OwnerId: ..., AreaId: ...)` to scope access.
- **AuditLogger**: Helper for writing to `system_logs`.

## Business Logic Gotchas
- **Gotcha 5: Survey Mode**: Submissions have `TotalScore = null`. Filter `WHERE scoring_mode != 'survey'` before averaging scores.
- **Gotcha 13: PBAC Route Authorization**: Minimal APIs in this project require using `.RequireAuthorization("PolicyName")` (e.g., `"AdminOnly"`) rather than chainable role methods. Always prefer `.RequireCapability(AppCapabilities.X)` where possible.
- **Gotcha: Default pass_fail minusImpact**
  - **Fix:** For scoring engine simulators, a failed `pass_fail` criterion with no explicit `minusImpact` set should fall back to `1.0` to match expected test deductions (e.g. dropping score from `100.00%` to `90.00%` under a standard `10` points weight).

## Build & Infrastructure Gotchas
- **Gotcha: Nested Projects in MSBuild**: Because `tests/` and other mini-projects (like `Hasher/`) are nested *inside* the `server/` directory, the root `Checkly.Api.csproj` will accidentally compile their files, causing `CS8802` (duplicate top-level statements) and `CS0579` (duplicate assembly attributes) errors.
  - **Fix:** `DefaultItemExcludes` using `folder\**` is not recursive enough. Always use strict, explicit MSBuild exclusions for any nested project: `<Compile Remove="tests\**" />` and `<Compile Remove="Hasher\**" />` inside an `<ItemGroup>` in the root `.csproj`.
- **Gotcha: Unregistered OLAP Background Worker**
  - **Fix:** Although `AreaBenchmarkWorker` exists in the codebase to calculate province-level benchmark snapshots, it is not registered as a hosted service in `Program.cs`. Province benchmarks will not automatically update in the background.
- **Gotcha: PowerShell UTF-8 ANSI Double-Encoding (Vietnamese/Unicode Corruption)**
  - **Fix:** Windows PowerShell 5.1 loads files in ANSI by default if they lack a BOM, which corrupts multi-byte UTF-8 sequences (like Vietnamese `Đ` and `á`) during seeder generation. To prevent string corruption, NEVER use raw non-ASCII unicode literal strings in script templates or heredocs. Always express non-ASCII characters inside string literals using their safe C# escape sequence representation (e.g., `\u0110\u00e1nh gi\u00e1` for `Đánh giá`).

## Data Model Gotchas
- **Gotcha: Deprecated AreaId Authorization**: The system has migrated from an Area-based hierarchy to **Pure Direct Store Assignment**. The `AreaId` field on `Profile` is deprecated for authorization purposes. 
  - **Fix:** NEVER use `AreaId` checks (e.g., in `OwnershipScopeFilter` or `ResourceAccessGuard`) to determine if an Area Manager has access to a store. ALWAYS query the `ProfileStoreAssignment` junction table or verify `StoreId` exists in the user's `AssignedStoreIds` list.
- **Gotcha: Strict 1-to-M Store Assignment Unique Constraint**
  - **Fix:** `ProfileStoreAssignmentConfiguration` places a unique index on `StoreId` (`e.HasIndex(x => x.StoreId).IsUnique()`), enforcing that a store can only be assigned to a single profile/manager. Do not write test cases or business logic that assume multiple profiles can be assigned to the same `StoreId` via `ProfileStoreAssignment`, as it will throw a Postgres 23505 duplicate key violation. Test multi-manager scenarios by utilizing separate stores.

## Testing Gotchas
- **Gotcha: Test Data Isolation for Boundary Conditions**: If testing a boundary condition for a child entity (e.g., Store audit count < 3), its parent entity (e.g., Area) MUST explicitly fall *outside* that boundary condition (Area audit count > 3). If both the parent and child trigger the boundary, the test may silently pass for the wrong reason (False Positive), masking logic regressions where the wrong scope was passed.
  - **Fix:** Always explicitly isolate variables. Seed parent entities with sufficient data to bypass guards, so you strictly test the child guard logic.
- **Gotcha: Silent Test Failures (Assert.True(response.IsSuccessStatusCode))**
  - **Fix:** Never use raw boolean asserts for HTTP responses. Always read and print the error body on failure so the actual HTTP status and API error message are visible in test logs. Example: `if (!res.IsSuccessStatusCode) Assert.Fail($"Status: {res.StatusCode}. Body: {await res.Content.ReadAsStringAsync()}");`
- **Gotcha: Database Wipes in Integration Tests**
  - **Fix:** NEVER use framework commands that drop or wipe the host database (e.g. `EnsureDeleted()`) without an explicit code-level safeguard. Integration test factories must hardcode an exception throw if the connected database string does not contain `_test` to guarantee the development and production databases cannot be wiped accidentally.
- **Gotcha: Local Testing Environment**
  - **Fix:** The project utilizes Logical Database Separation on the local PostgreSQL instance. The `checkly_test` database **already exists** natively alongside the main `checkly` database. Agents must never try to drop it manually or assume tests need a mocked server. Simply run `dotnet test`, and `TestWebApplicationFactory` will seamlessly route traffic to `checkly_test` and auto-migrate its schema.
- **Gotcha: Shared Database Testing & Analytics Pollution**
  - **Fix:** Integration tests running against a shared database must never assume the database is empty or calculate absolute aggregates against mutable seeded tables. Always isolate test calculations using unique query anchors (e.g., unique tags, isolated IDs, or far-past/far-future dates) to prevent other tests' persistent records from corrupting mathematical assertions.

## Schema Migration Gotchas
- **Gotcha: Safe Non-Nullable Column Migration & Backfill**: When adding a new non-nullable column (like `score_direction`) to an existing database with production data, adding it directly as non-nullable in the migration step can cause issues or fill with a generic default.
  - **Fix:** Always add the column as `nullable: true` first, execute custom SQL to backfill values based on existing states (e.g., mapping `scoring_mode` using CASE), and then alter the column to `nullable: false` with its final default value constraint. This guarantees historical correctness and zero data corruption.

## Code Style & Compiler Warnings
- **Gotcha: Nullable Structs in ADO.NET Binding**
  - **Problem:** Direct cast of nullable structs (like `Guid?`) to `object` triggers compiler warnings (CS8600/CS8604) for potential null reference.
  - **Fix:** Explicitly check `.HasValue` or cast to `object?` before null-coalescing.
    ```csharp
    myId.HasValue ? (object)myId.Value : DBNull.Value
    // OR:
    (object?)myId ?? DBNull.Value
    ```
- **Gotcha: Tuple Deconstruction**
  - **Problem:** Accessing values via `.Item1`/`.Item2` triggers code style warning `IDE0042`.
  - **Fix:** Deconstruct tuples into named local variables.
    ```csharp
    var (id, name) = tuple;
    ```
- **Gotcha: Target-Typed New**
  - **Problem:** Redundantly naming the type in `new` expressions triggers style warning `IDE0090`.
  - **Fix:** Use simplified `new(...)` syntax.
