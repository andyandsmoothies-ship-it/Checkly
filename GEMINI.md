# Checkly Baseline Rules

## 1. Governance Rules

### The "Read Before You Write" Mandate (STRICT)
<SYSTEM_GUARD type="STRICT" name="ReadBeforeYouWrite">
- **Rule**: Research the codebase before editing. Never change code you haven't read.
- **Enforcement**: You must use `grep_search` and `view_file` to thoroughly understand the context, dependencies, and structure of the code. **CRITICAL:** You must also search for and read any `GEMINI.override.md` file located in the target directory before making modifications, as it contains mandatory, module-specific constraints. Blind code changes are prohibited.
</SYSTEM_GUARD>

### The Anti-Drive-By Mandate (STRICT)
<SYSTEM_GUARD type="STRICT" name="AntiDriveByRefactoring">
- **Rule**: Touch only what you must. Clean up only your own mess. Drive-by refactoring is strictly prohibited.
- **Enforcement**: Match the existing style perfectly, even if technically inferior, to keep PR diffs surgically clean. Do not format, refactor, or "improve" adjacent code while fixing a bug. Preserve quote marks, spacing, and existing docstrings exactly as they are. If you notice unrelated dead code, mention it to the user — don't delete it.
</SYSTEM_GUARD>

### The Simplicity First Mandate (STRICT)
<SYSTEM_GUARD type="STRICT" name="SimplicityFirst">
- **Rule**: Minimum code that solves the problem. Avoid Hasty Abstractions (AHA).
- **Enforcement**: Duplication is cheaper than the wrong abstraction (WET - Write Everything Twice). You are strictly forbidden from extracting shared helpers, base classes, or interfaces for leaf nodes unless you see the exact same logic used in at least 3 different places. If you write 200 lines and it could be 50 simple lines, rewrite it without complex patterns.
</SYSTEM_GUARD>

### The 3-Step Database Migration Pipeline (STRICT)
<SYSTEM_GUARD type="STRICT" name="DatabaseMigrationPipeline">
Under no circumstances may you rely on auto-migration (`db.Database.Migrate()`) or use `dotnet ef database update` blindly. We enforce the strict 3-Step Production Practice for all database schema changes:
1. **Generate Script:** Run `dotnet ef migrations script -i -o update.sql` to export the raw SQL.
2. **Apply Script:** Manually run the SQL script against the database using a DB tool.
3. **Deploy Code:** Only start the server (`dotnet run`) *after* the DB schema has been strictly modified out-of-band.
</SYSTEM_GUARD>

### The Anti-MacGyver Protocol (STRICT)
<SYSTEM_GUARD type="STRICT" name="AntiMacGyverProtocol">
Before implementing ANY local utility, routing logic, data transformation, or UI component:
- **Rule**: Run `grep_search` within `server/Common/` or `lib/_shared/` first.
- **Purpose**: Prove you are using the project's existing canonical tools before building custom logic.
- **Prohibition**: No custom date parsers, unauthorized navigation extensions, or ad-hoc security guards.
</SYSTEM_GUARD>

### The Marking Your Own Homework Paradox (STRICT)
<SYSTEM_GUARD type="STRICT" name="MarkingYourOwnHomeworkParadox">
Under no circumstances may you write or modify a test and its corresponding implementation in the exact same prompt cycle or workflow phase.
- **Rule**: Tests are immutable constraints during implementation. If a test is failing, fix the code, not the test. 
- **Purpose**: Prevents AI agents from unconsciously writing meaningless, self-fulfilling tests that echo their own buggy logic to achieve a false "green build."
</SYSTEM_GUARD>

### Post-Task Self-Curation (ALWAYS-ON)
After any significant implementation, debug, or refactor, assess whether a new lesson was discovered.
- **Target file**: Create or update a `GEMINI.override.md` file physically adjacent to the feature/module you just modified. Do NOT use `project-gotchas.md`.
- **DO ADD**: Project-breaking quirks, vendor-specific edge cases, architectural deviations.
- **DO NOT ADD**: Generic C#/Dart/Flutter knowledge, one-off syntax errors.



### Artifact Density & Formatting
<SYSTEM_GUARD type="STRICT" name="ArtifactDensityFormatting">
- **Rule**: Keep artifacts organized and easy to read.
- **Enforcement**: Eradicate unnecessary filler words. Use structured tables and markdown alerts to make reading easy for the user.
- **Diagramming Protocol**: When responding to the user or explaining ideas (if/else, who/what/when), actively use simple text-based flowcharts to demonstrate the basic idea. Use simple notations like `-->`, `<`, `[ ]`. Keep the wording in these diagrams short and concise.
</SYSTEM_GUARD>

### The Anti-Magic-String Mandate (STRICT)
<SYSTEM_GUARD type="STRICT" name="AntiMagicStringMandate">
- **Rule**: Never use naked string literals for system constants (capabilities, roles, route paths, status codes).
- **Enforcement**: You must extract cross-boundary strings into strongly-typed Enums or static constant classes (e.g., `AppCapabilities.manageRoles` instead of `'admin:manage_roles'`).
- **Purpose**: Naked string typos bypass TDD mocks and `flutter analyze` structural checks. Strong typing forces the compiler to instantly catch and crash on AI string hallucinations during the `/verify` phase.
</SYSTEM_GUARD>

### The Strict Constructor Injection Mandate (STRICT)
<SYSTEM_GUARD type="STRICT" name="StrictConstructorInjection">
- **Rule**: Never use hidden fallback logic (`?? _di<Service>()`) inside a class constructor.
- **Enforcement**: All dependencies MUST be explicitly passed via `required` constructor parameters. Do not mix constructor parameters with hidden `GetIt` lookups. 
- **Purpose**: Prevents silent crashes in isolated test environments by forcing the compiler to demand every mock parameter upfront.
</SYSTEM_GUARD>

### First-Step Logical Reasoning (FSLR)
<SYSTEM_GUARD type="STRICT" name="FirstStepLogicalReasoning">
- **Rule**: Never generate code immediately during diagnostics or planning.
- **Enforcement**: Your absolute first step MUST be a Boolean Logic Tree (the "Rationality Peak") proving you understand the state boundaries. Execute code only after the tree is mapped.
</SYSTEM_GUARD>

### Scientific Method / Debugging (STRICT)
<SYSTEM_GUARD type="STRICT" name="ScientificDebugging">
- **Rule**: During active diagnostics, an experimental code change MUST NOT exceed 5 lines. 
- **Enforcement**: If a test fails twice under the same hypothesis, you are forbidden from trying a third time. You must formally reject the hypothesis in `.agents/tmp/DEBUG.md` and pivot to a new theory.
</SYSTEM_GUARD>

### The Zero-Ghost Policy (STRICT)
<SYSTEM_GUARD type="STRICT" name="ZeroGhostPolicy">
- **Rule**: Do not write new features in an environment with existing errors or warnings.
- **Enforcement**: If you open a codebase and the baseline build has existing warnings (ghosts), you MUST halt feature work and run the `de-sloppify` skill to fix them. If you see a warning during implementation, ignore it unless it was created in the current slice, preventing you from spiraling into unrelated code.
</SYSTEM_GUARD>

---

## 2. Platform Architecture

- **Purpose**: Mobile-first audit/inspection platform with offline-first capabilities.
- **Frontend**: Flutter (Dart) — Mobile-first, offline-first with Drift (ORM) + SQLite (sqlite3) for local persistence.
- **Backend**: ASP.NET Core (.NET 10) Minimal API — feature-sliced, no controllers.
- **Database**: PostgreSQL (Self-Hosted), accessed through EF Core.
- **Auth**: ASP.NET Core Identity (JWT Bearer) for authentication and server-side RBAC.

### Project Structure & Blast Radius Map
AI Agents MUST use this map during Discovery (`/analyze-feature`) to immediately assess the risk of proposed file modifications.

**🔴 High Blast Radius (Core State & Infrastructure)**
*Extreme Caution: Modifying these impacts global data integrity, distributed sync, or system-wide auth.*
- `server/Common/Persistence/AppDbContext.cs` — The central EF Core / Postgres mapping schema.
- `server/Common/Persistence/Entities/` — Global database models.
- `lib/_shared/database/` — Flutter local SQLite schemas and Drift migrations.
- `lib/_shared/services/` — Global background services (e.g., Sync Engine, Connectivity).

**🟡 Medium Blast Radius (Cross-Feature Shared Logic)**
*Caution: Modifying these changes UI behavior or routing sequences across multiple independent features.*
- `server/Common/` (excluding DB) — Shared guards, error handlers, and middleware.
- `lib/_shared/widgets/` — Universal UI components.
- `lib/_shared/router/` — Global navigation.

**🟢 Isolated Scope (Feature-Sliced Design)**
*Safe: Fully encapsulated. Modifying one feature does not break another. Focused tests apply.*
- `server/Features/{Name}/` — Backend handlers, endpoints, and localized DTOs.
- `lib/features/{name}/` — Frontend UI pages, dedicated managers, and API services.

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
- **Gotcha 17: Offline-First Distributed Sync Requires Full-Stack Verification**
  - **Fix:** ALWAYS verify the backend API endpoints explicitly support the sequence inversion. Do not assume the backend handles out-of-order data associations automatically. Verify route signatures (segment vs query) and DTO payload mutability before approving an architectural plan.

---

## 4. AI Environment & Tooling Protocols

### Monorepo Directory Activation (STRICT)
<SYSTEM_GUARD type="STRICT" name="MonorepoDirectoryActivation">
- **Rule:** NEVER run terminal commands from the project root. 
- **Backend Tasks:** Must run with `Cwd: server/`.
- **Frontend Tasks:** Must run with `Cwd: lib/` (or wherever `pubspec.yaml` lives).
</SYSTEM_GUARD>

### Anti-Hang CLI Protocol (STRICT)
<SYSTEM_GUARD type="STRICT" name="AntiHangCLIProtocol">
- **Rule:** Interactive commands freeze headless AI terminals permanently, burning credits.
- **PROHIBITED:** `dotnet run`, `dotnet watch`, `flutter run`.
- **MANDATORY:** Check code safely via `dotnet build --no-restore`, `flutter analyze`, or `flutter test`.
</SYSTEM_GUARD>

### Zero-Bloat Dependencies (STRICT)
<SYSTEM_GUARD type="STRICT" name="ZeroBloatDependencies">
- **Rule:** PROHIBITED from running `dotnet add package` or `flutter pub add` without explicit user approval.
- **Action:** If solving logic problems, use existing utilities in `server/Common/` or `lib/_shared/`. Do not implicitly install third-party libraries.
</SYSTEM_GUARD>

### RTK Command Wrapper Mandate (STRICT)
<SYSTEM_GUARD type="STRICT" name="RTKCommandWrapper">
- **Rule:** Each shell command must put `rtk` ahead of it (e.g., `rtk dotnet build`, `rtk flutter analyze`) so that the RTK token optimization proxy can compress the outputs.
- **Enforcement:** Always prefix execution commands with `rtk`.
</SYSTEM_GUARD>

### The Anti-Hallucination Type Mandate (STRICT)
<SYSTEM_GUARD type="STRICT" name="AntiHallucinationTypes">
- **Rule**: Never use naked strings (`string`) for statuses, roles, or categories that have strict database constraints.
- **Enforcement**: You MUST use strongly-typed Enums, Unions, or Static Constants.
- **Purpose**: AI agents will hallucinate plain text strings causing silent crashes. Strong types force the compiler to guide the AI to the exact allowed values during the TDD RED phase.
</SYSTEM_GUARD>
