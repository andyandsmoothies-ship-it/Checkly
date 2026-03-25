# 🚀 Backend Stack Rules (ASP.NET Core)

> [!IMPORTANT]
> The rules in this file apply ONLY when writing or modifying C# code in the `server/` directory.

## 1. Architecture Constraints
- **Framework**: ASP.NET Core (.NET 10).
- **Controllers**: Strictly FORBIDDEN. Use Feature-Sliced Design (e.g., `server/Features/{Feature}/`).
- **Endpoint Pattern**: Every endpoint MUST follow the static class `HandleAsync` pattern returning `IResult` and using `TypedResults`.
- **Pagination Standard**: All list endpoints MUST use `PagedResult<T>` with `page` and `pageSize`.

## 2. Infrastructure & Database (EF Core)
- **Database**: PostgreSQL (Self-Hosted via EF Core).
- **Mandatory Mapping**: ALL columns must use explicit `HasColumnName("snake_case")` in the central `AppDbContext`. EF will NOT auto-map `ScoringMode` -> `scoring_mode`.
- **Snapshot Pattern (Crucial)**: Submissions denormalize template/store/auditor data at creation time (e.g. `TemplateSnapshot`, `TemplateTitle`, `DisplayNoun`). **Always** snapshot new denormalized fields in BOTH `CreateSubmission` AND `FinalizeSubmission`.
- **SectionScores Storage**: `SectionScores` is a `jsonb` column. You cannot use EF `GroupBy` on dynamic keys — load the strings and parse in C#.

## 3. Shared Services & Cross-Cutting (Anti-MacGyver)
- Before writing custom routing, guards, or audit logging logic, you MUST run `grep_search` on `server/Common/`.
- Reusable Services:
  - `SubmissionAccessGuard`: Use for all submission-scoped IDOR checks.
  - `AuditLogger`: Use for writing entity-level audit logs to `system_logs`.
  - `ActionPlanService`: Centralized auto-creation of action plans.

## 4. Security
- **Auth**: ASP.NET Identity + JWT Bearer. 
- **Administration**: Admin-only routes must use `RequireAuthorization("AdminOnly")`.

## 5. Development Gotchas
- **Testing**: Every [NEW] handler requires at least 2 passing tests before handoff (happy path + primary error path 404/403/409/400).
- **Migration Generation**: Review generated `Up()` files. `dotnet ef migrations add` picks up ALL pending unmigrated model changes across the project. Remove unrelated changes before committing.
