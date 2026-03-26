---
name: Checkly Platform Rules
description: Architecture, coding standards, and data conventions for the Checkly mobile audit platform.
trigger: model_decision
---

# Checkly Platform Rules

## 1. Architecture

- **Purpose**: Mobile-first audit/inspection platform with offline-first capabilities.
- **Frontend**: Flutter (Dart) — PWA-ready, offline-first with Dexie.js (IndexedDB).
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
Every feature endpoint follows this exact pattern:
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
Endpoints are registered in `*Endpoints.cs` files using `MapGet`/`MapPost`/`MapPut`.

### Shared Services Pattern (Server)
- **ActionPlanService** (`Features/ActionPlans/ActionPlanService.cs`): Centralized auto-creation of action plans from triggered answers. Called by both `CreateSubmission` and `FinalizeSubmission`. Idempotent — skips if APs already exist.
- **SubmissionAccessGuard** (`Common/SubmissionAccessGuard.cs`): Reusable IDOR guard for all submission-scoped resources. Uses `Guid.TryParse` defense-in-depth.
- **AuditLogger** (`Common/Services/AuditLogger.cs`): Static helper for writing entity-level audit logs to `system_logs`. Uses `Category = "audit"`, tracks `EntityType` + `EntityId`. Participates in the caller's `SaveChangesAsync` transaction.

### Pagination Standard (Server)
All list endpoints MUST use `PagedResult<T>` (`Common/PagedResult.cs`):
- Query params: `page` (default 1), `pageSize` (default 50, max 200)
- Pattern: `CountAsync` + `Skip/Take` + wrap in `PagedResult<T>`
- Reference: `ListSubmissions.cs`, `ListTemplates.cs`, `ListStores.cs`

## 2. Database Conventions

### Column Naming
- All columns use **snake_case** via explicit `HasColumnName()` in `AppDbContext`.
- Every new entity property **MUST** have a corresponding `HasColumnName("snake_case")` mapping.
- Table names are lowercase plural: `templates`, `submissions`, `answers`, `groups`, `criteria`.

### Snapshot Pattern (Denormalization)
Submissions denormalize template/store/auditor data at creation time:
- `TemplateTitle`, `StoreName`, `AuditorName`, `AuditorEmail`, `ApproverName`, `DisplayNoun`
- `TemplateSnapshot` (jsonb) — frozen template tree (groups, criteria, scoring config) at audit creation
- `TemplateVersion` — template version counter at snapshot time
- This ensures history remains accurate even if the source entity is later modified or deleted.
- **Always snapshot new denormalized fields in both `CreateSubmission` AND `FinalizeSubmission`.**

### Scoring Modes
Four modes: `penalty` (default), `accumulation`, `checklist`, `survey`.
- `ScoringMode` is denormalized onto `Submission` for analytics queries.
- Survey mode submissions have `TotalScore = null`.

### Migrations
- Generated via `dotnet ef migrations add <Name>` in `server/`.
- Custom SQL (indexes, backfills) added manually to the `Up()` method.
- Always include a proper `Down()` for rollback.

## 3. Flutter Conventions

### PFA Architecture (Pragmatic Flutter Architecture)
- **Services**: API communication (`*_api_service.dart`) — stateless, injectable.
- **Managers**: Business logic + state (`*_manager.dart`) — `ChangeNotifier` or similar.
- **Pages**: UI widgets (`*_page.dart`) — consume managers via `watch_it`/`get_it`.

### DTO Pattern
- DTOs are plain Dart classes with `final` fields, `const` constructors, and `fromJson` factories.
- Server field names use **camelCase** in JSON (matching C# record property names).
- Always add new fields as **nullable** (`String?`) to avoid breaking existing deserialization.

### Offline Sync
- Delta sync via `GET /api/sync/templates?since={timestamp}`.
- Every new field on Template/Submission DTOs MUST be included in the sync endpoint projection.

## 4. Security

| Concern | Standard |
|:--------|:---------|
| Auth | ASP.NET Identity + JWT Bearer. `SignInManager` with lockout (5 attempts / 15 min) |
| RBAC | `admin`, `auditor`, `store_manager`, `area_manager` |
| CORS | Config-driven `Cors:AllowedOrigins` in appsettings. Middleware: `UseCors()` → `UseAuth()` |
| IDOR | `SubmissionAccessGuard.CanAccessAsync()` for submissions and photos. Role-based: admin→all, auditor→owns, SM→store, AM→area |
| Admin-only | Template CRUD, Area management (POST/PUT), analytics, survey results. `RequireAuthorization("AdminOnly")` at route group |
| Photos | Upload and download enforce IDOR via `SubmissionAccessGuard`. Only submission owner/admin/SM/AM can access |

## 5. Cross-Feature Governance

### Entity Dependency Map (MANDATORY)
- **File**: `docs/reference/entity-dependencies.md`
- When adding a new feature that **reads, writes, or filters** a core entity (Store, Area, Template, Profile, Submission), you MUST update the dependency map with the new consumer.
- When modifying deactivation/deletion logic, check the "Deactivation Impact" section for that entity.

### Shared Guards & Services Pattern
Cross-feature logic MUST be extracted into shared services in `Common/`:
- **Guards** (`Common/` or `Common/Auth/`): Reusable validation that multiple features need (e.g., `SubmissionAccessGuard`, `RoleAssignmentGuard`)
- **Services** (`Common/Services/`): Shared business logic called from multiple handlers (e.g., `AuditLogger`, `ActionPlanService`)
- **Rule**: If the same validation or business logic appears in 2+ feature handlers, extract it into a shared guard or service.
