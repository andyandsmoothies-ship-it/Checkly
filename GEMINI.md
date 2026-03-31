# Checkly Baseline Rules

## 1. Governance Rules

### The Anti-MacGyver Protocol (STRICT)
Before implementing ANY local utility, routing logic, data transformation, or UI component:
- **Rule**: Run `grep_search` within `server/Common/` or `lib/_shared/` first.
- **Purpose**: Prove you are using the project's existing canonical tools before building custom logic.
- **Prohibition**: No custom date parsers, unauthorized navigation extensions, or ad-hoc security guards.

### The Marking Your Own Homework Paradox (STRICT)
Under no circumstances may you write or modify a test and its corresponding implementation in the exact same prompt cycle or workflow phase.
- **Rule**: Tests are immutable constraints during implementation. If a test is failing, fix the code, not the test. 
- **Purpose**: Prevents AI agents from unconsciously writing meaningless, self-fulfilling tests that echo their own buggy logic to achieve a false "green build."

### Post-Task Self-Curation (ALWAYS-ON)
After any significant implementation, debug, or refactor, assess whether a new lesson was discovered.
- **Target file**: Create or update a `GEMINI.override.md` file physically adjacent to the feature/module you just modified. Do NOT use `project-gotchas.md`.
- **DO ADD**: Project-breaking quirks, vendor-specific edge cases, architectural deviations.
- **DO NOT ADD**: Generic C#/Dart/Flutter knowledge, one-off syntax errors.

---

## 2. Platform Architecture

- **Purpose**: Mobile-first audit/inspection platform with offline-first capabilities.
- **Frontend**: Flutter (Dart) — Mobile-first, offline-first with Drift (ORM) + SQLite (sqlite3) for local persistence.
- **Backend**: ASP.NET Core (.NET 10) Minimal API — feature-sliced, no controllers.
- **Database**: PostgreSQL (Self-Hosted), accessed through EF Core.
- **Auth**: ASP.NET Core Identity (JWT Bearer) for authentication and server-side RBAC.

### Project Structure
| Layer | Path | Purpose |
|:------|:-----|:--------|
| Server | `server/` | ASP.NET Core Minimal API |
| Server Features | `server/Features/{Feature}/` | Feature folders (endpoints, DTOs) |
| Server Entities | `server/Common/Persistence/Entities/` | EF Core entity classes |
| Server DbContext | `server/Common/Persistence/AppDbContext.cs` | Central DbContext with explicit `HasColumnName` |
| Flutter App | `lib/` | Feature-Sliced Design (FSD) |
| Flutter Features | `lib/features/{feature}/` | Pages, models, managers, services |
| Flutter Shared | `lib/_shared/` | Router, widgets, database, services |
| Docs | `docs/` | Reference documentation |

### Endpoint Pattern (Server)
Every feature endpoint follows this exact pattern. Endpoints are registered in `*Endpoints.cs` files using `MapGet`/`MapPost`/`MapPut`.
```csharp
public static class DoSomething
{
    public static async Task<IResult> HandleAsync(
        /* parameters injected by DI */
        AppDbContext db, CancellationToken ct)
    {
        // Logic here
        return TypedResults.Ok(result);
    }
}
```

### Shared Services Pattern (Server)
- **ActionPlanService**: Centralized auto-creation of action plans from triggered answers. Called by both `CreateSubmission` and `FinalizeSubmission`. Idempotent.
- **SubmissionAccessGuard**: Reusable IDOR guard for all submission-scoped resources.
- **AuditLogger**: Static helper for writing entity-level audit logs to `system_logs`. Participates in caller's transaction.

### Pagination Standard (Server)
All list endpoints MUST use `PagedResult<T>` (`Common/PagedResult.cs`):
- Query params: `page` (default 1), `pageSize` (default 50, max 200)

### Database Conventions
- **Column Naming**: All columns use **snake_case** via explicit `HasColumnName()` in `AppDbContext`.
- **Snapshots**: Submissions denormalize template/store/auditor data at creation time (`TemplateTitle`, `StoreName`, `TemplateSnapshot`).
- **Scoring Modes**: `penalty` (default), `accumulation`, `checklist`, `survey`.
- **Migrations**: Generated via `dotnet ef migrations add <Name>` in `server/`.

### Flutter Conventions
- **PFA Architecture**: Services (API), Managers (State/Logic), Pages (UI).
- **DTO Pattern**: DTOs are plain Dart classes. Server JSON uses camelCase. Add new fields as nullable.
- **Offline Sync**: Delta sync via `GET /api/sync/templates?since={timestamp}`.

### Cross-Feature Governance
- **Entity Dependency Map**: When modifying entities, check `docs/reference/entity-dependencies.md`.
- **Shared Guards Pattern**: Extract cross-feature logic into `Common/`.

---

## 3. High-Level Project Gotchas

- **Gotcha 6: New DTO Fields Must Flow Through All 6 Sync Pipeline Steps**
  - **Problem:** Missing any one of 6 steps causes the field to silently drop during offline sync.
  - **Fix:** Update in order: (1) Entity, (2) DbContext, (3) Server DTO, (4) Endpoint projections, (5) Sync endpoint, (6) Flutter DTO.
- **Gotcha 5: Survey Mode = null TotalScore**
  - **Problem:** Survey submissions have `TotalScore = null`. Averaging them causes errors.
  - **Fix:** Filter `WHERE scoring_mode != 'survey'` before averaging scores.
- **Gotcha 9: EF Migration Generator Captures ALL Pending Changes**
  - **Problem:** `dotnet ef migrations add` bundles all unmigrated DbContext changes.
  - **Fix:** Review generated migration immediately and split if needed.
- **Gotcha 12: Every New Handler Requires at Least 2 Tests**
  - **Problem:** A green test suite doesn't cover new handler behavior.
  - **Fix:** Every new handler needs a happy-path test (200/201) and error-path test (404/403/400).
- **Gotcha 15: Navigation from Outside ShellRoute Must Restore Shell First**
  - **Problem:** `context.go('/route')` outside a ShellRoute renders without the bottom nav.
  - **Fix:** Capture `GoRouter.of(context)`, go to `/shell-root`, then microtask `push('/target')`.
