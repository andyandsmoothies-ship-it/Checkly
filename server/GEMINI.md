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

## Build & Infrastructure Gotchas
- **Gotcha: Nested Projects in MSBuild**: Because `tests/` and other mini-projects (like `Hasher/`) are nested *inside* the `server/` directory, the root `Checkly.Api.csproj` will accidentally compile their files, causing `CS8802` (duplicate top-level statements) and `CS0579` (duplicate assembly attributes) errors.
  - **Fix:** `DefaultItemExcludes` using `folder\**` is not recursive enough. Always use strict, explicit MSBuild exclusions for any nested project: `<Compile Remove="tests\**" />` and `<Compile Remove="Hasher\**" />` inside an `<ItemGroup>` in the root `.csproj`.

## Data Model Gotchas
- **Gotcha: Deprecated AreaId Authorization**: The system has migrated from an Area-based hierarchy to **Pure Direct Store Assignment**. The `AreaId` field on `Profile` is deprecated for authorization purposes. 
  - **Fix:** NEVER use `AreaId` checks (e.g., in `OwnershipScopeFilter` or `ResourceAccessGuard`) to determine if an Area Manager has access to a store. ALWAYS query the `ProfileStoreAssignment` junction table or verify `StoreId` exists in the user's `AssignedStoreIds` list.

## Testing Gotchas
- **Gotcha: Test Data Isolation for Boundary Conditions**: If testing a boundary condition for a child entity (e.g., Store audit count < 3), its parent entity (e.g., Area) MUST explicitly fall *outside* that boundary condition (Area audit count > 3). If both the parent and child trigger the boundary, the test may silently pass for the wrong reason (False Positive), masking logic regressions where the wrong scope was passed.
  - **Fix:** Always explicitly isolate variables. Seed parent entities with sufficient data to bypass guards, so you strictly test the child guard logic.

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

