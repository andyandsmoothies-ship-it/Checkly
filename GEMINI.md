# Checkly Global Agent Rules
> **Scope**: Project-wide architecture, governance, global platform gotchas, and testing rules.
> **Out of Scope**: Language/framework-specific standards (use subfolder rules) and design specs.

## 1. Documentation Map
- **Technical Architecture & ADRs**: `docs/architecture/`
- **Agile Epics & Slices**: `docs/epics/` (refer to `_epic_ledger.md` for progress tracking)
- **Feature Specifications**: `docs/features/`
- **Project Setup & Database Schema**: `docs/project/`
- **Platform Reference & Guides**: `docs/reference/`
- **Product Options & Design Synthesis**: `docs/product/`
- **Audit & Diagnostics Reports**: `docs/reports/`
- **AI Agent Skills**: `.agents/skills/`
- **AI Workflows**: `.agents/workflows/`

## 2. Governance & Architecture Rules
- **Structure**: Architecture is law. Inner rings MUST NOT import outer rings.
  - **Do**: Separate Technical Language (DB) from Business Language (UI) at the ring level.
  - **Don't**: Import outer rings into inner rings, or mix business terminology into DB/data layer classes.
- **Dependencies**: Tightly controlled dependencies.
  - **Do**: Search `server/Common/` or `lib/_shared/` first to reuse existing tools.
  - **Don't**: Install unauthorized external packages without whitelist approval.

## 3. Global Gotchas (with Do/Don't Actions)

- **Gotcha: Terminology Map (Audit vs Submission)**
  - **Do**: Use "Submission" for backend entities, endpoints, databases, and network DTOs. Use "Audit" only for user-facing UI labels.
  - **Don't**: Rename files, tables, or database fields from "Submission" to "Audit".

- **Gotcha: The 7 Sync Steps (for PBAC & Data Sync)**
  - **Do**: Execute sync updates strictly in this order: (1) Entity, (2) DbContext, (3) Server DTO, (4) Endpoint projections, (5) Sync endpoint, (6) Flutter DTO, (7) Seed capabilities in `Program.cs` and `TestWebApplicationFactory.cs`.
  - **Don't**: Skip steps or change the order of implementation during synchronization changes.

- **Gotcha: Programs Module Sync Steps**
  - **Do**: Apply the sync steps to the Programs module in this order: (1) `ProgramAssignment` entity, (2) `AppDbContext`, (3) Server DTOs, (4) Endpoint projections, (5) SM Sync endpoint, (6) Flutter `CachedProgramAssignments` Drift table.

- **Gotcha: Orphaned ATDD Stubs (`fail(...)`)**
  - **Do**: Always fully implement the test logic and fulfill the UI/Backend contract in the current slice if a QA agent leaves an ATDD stub like `fail('Implement...')`.
  - **Don't**: Leave `fail()` stubs behind for future slices unless explicitly documented.

- **Gotcha: Hybrid Entity-Driven UI (HATEOAS) for Actions**
  - **Do**: Compute an `allowedActions` string array (e.g., `["edit", "view_details", "void"]`) on the backend DTOs by combining PBAC capabilities with the entity's current status. Wrap actionable Flutter widgets in an `ActionGuard` checking this array.
  - **Don't**: Hardcode UI button visibility or tap gestures based on the user's role on the frontend.

- **Gotcha: Silent DTO Contract Drift**
  - **Do**: Strictly reflect the actual backend DTO structure (matching exact property names) on the frontend. Use contract integration tests to verify JSON mapping.
  - **Don't**: Invent mock JSON based solely on local frontend models.

- **Gotcha: Live Area Boardroom Analytics (No Caching/Polling)**
  - **Do**: Calculate analytics dynamically from live database queries on `Submissions` and return `IsLiveData = true` immediately.
  - **Don't**: Implement polling on the frontend or attempt to read from the deleted `bod_report_snapshots` table.

- **Gotcha: BOD Section Scores Key Mismatch**
  - **Do**: Serialize group details using the group UUID as the key, nesting the `title`, `score`, and `maxScore`/`maxPoints` properties (e.g., in `_buildSectionScoresJson()`).
  - **Don't**: Use raw names or simple keys for the root dictionary, which prevents `SectionScoreExploder.cs` from matching UI categories.

- **Gotcha: Linter Rule Drift & HTTP 422 Mapping**
  - **Do**: Make `LintResult` parsing on the frontend resilient to missing fields so that server-side linter errors display gracefully.
  - **Don't**: Assume the frontend linter and backend linter have identical rules.

- **Gotcha: Nesting Depth Constraints**
  - **Do**: Enforce a flat or maximum 2-level hierarchy (Sections and Subsections) when configuring scoring templates.
  - **Don't**: Nest beyond 2 levels, since the scoring calculation engines (`VerifyPenalty` in C# and `ScoringInputMapper` in Dart) bypass intermediate groups.

- **Gotcha: Progressive Repeat Decimal Overflow Safeguards**
  - **Do**: Always cast progressive repeat fault counts to `decimal` *before* multiplication to prevent 32-bit integer overflow exceptions:
    ```csharp
    (decimal)repeatedFaults * (decimal)repeatedFaults
    ```
  - **Don't**: Multiply raw 32-bit integers when calculating progressive repeat faults.

- **Gotcha: TemplateDto and TemplateTreeDto optional params**
  - **Do**: Make new parameters optional in default constructors with safe fallbacks.
  - **Don't**: Make new parameters strictly `required`, as it breaks existing test cases, seeders, and mocks.

- **Gotcha: Clearing Area Manager Store Assignments (Explicit Empty Array)**
  - **Do**: Explicitly transmit `assignedStoreIds` as an empty list (`[]`) from the frontend when clearing assignments.
  - **Don't**: Map the field to `null` or omit it, as the backend presence check (`TryGetProperty`) will preserve the old assignments.

## 4. Development Operations & Tooling Decisions

| Intent | Command / Action | Context |
| :--- | :--- | :--- |
| Build backend solution | `rtk dotnet build server/Checkly.slnx` | Run at solution level. Terminate API process first to prevent locks. |
| Run backend tests | `rtk proxy dotnet test server/Checkly.slnx` | Bypass RTK filtering via `proxy` to view error details. |
| Kill locked API process | `taskkill /f /im Checkly.Api.exe 2>nul` | Prevents Windows file locks during compilation. |
| Watch & generate Drift files | `dart run build_runner watch --delete-conflicting-outputs` | Auto-rebuild on save. |
| Generate DB schema only | `dart run build_runner build --build-filter="lib/core/database/app_database.dart"` | Faster target regeneration. |
| Run targeted Flutter tests | `flutter test test/features/audit/widgets/header_card_test.dart` | Avoid running all 878 tests. |
| Apply database migrations | `rtk dotnet ef database update` | Run from `server/` folder to update PostgreSQL schema. |
| Add database migration | `rtk dotnet ef migrations add <MigrationName>` | Run from `server/` folder to generate a new EF migration. |

- **No Interactive CLI**: Do not run `dotnet run`, `dotnet watch`, or `flutter run`.
- **Zero Bloat**: Do not install packages without permission.
- **Historical Tracking**:
  - **Do**: Route all test outputs/logs to `.agents/logs/` and scratch database scripts to `dbquery/`. Delete compiler dumps (`.xml`).
  - **Don't**: Leave random log, query, or text files in the project root, `server/`, or `lib/`.

## 5. Definition of Done (DoD)
A task is complete only when ALL of the following commands execute with exit code 0:
1. **Compilation**: `rtk dotnet build server/Checkly.slnx` runs with zero errors.
2. **Backend Tests**: `rtk proxy dotnet test server/Checkly.slnx` (or the targeted tests for the modified slice) passes with zero failures.
3. **Flutter Tests**: `flutter test` targeted to modified files passes.
4. **Drift Schemas**: Drift build runner compiles successfully if local database models were modified.

## 6. Escalation Rules & Bans ("When Blocked" and "Never")
- **If Compilation Fails**: Check if a locked process exists and run `taskkill /f /im Checkly.Api.exe 2>nul`, then rebuild.
- **If Tests Fail**: Never mute or bypass assertions. Stop and run `rtk proxy dotnet test server/Checkly.slnx` targeted to the failing class, inspect the output, and fix the production code.
- **Git Operations**: NEVER run any `git` commands (e.g. `git add`, `git commit`, `git push`, `git checkout`). The user controls source control.
- **Destructive Actions**: NEVER delete or clear workspace lock files, source code files, or test assets to bypass compiler/lint errors.

