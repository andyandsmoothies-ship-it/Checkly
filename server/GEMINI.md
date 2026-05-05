# Backend Baseline Rules (.NET Minimal API)

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
