# Checkly Global Agent Rules
> **Scope**: Project-wide architecture, governance, global platform gotchas, and testing rules.
> **Out of Scope**: Language/framework-specific standards (use subfolder rules) and design specs.

## 1. Documentation Map
- **General Architecture & Design**: `docs/`
- **Agile Epics & Slices**: `docs/epics/` (refer to `_epic_ledger.md` for progress tracking)
- **Feature Specifications**: `docs/features/`
- **Audit & Diagnostics Reports**: `docs/reports/`
- **AI Agent Skills**: `.agents/skills/`
- **AI Workflows**: `.agents/workflows/`

## 2. Governance & Architecture Rules
- **Structure**: Architecture is law. Inner rings MUST NOT import outer rings. Separate Technical Language (DB) from Business Language (UI).
- **Tightly Controlled Dependencies**: Prove you are using the project's existing tools before building your own. Search `server/Common/` or `lib/_shared/` first. Do not install unauthorized packages without whitelist approval.

## 3. Global Gotchas
- **Gotcha: Terminology Map (Audit vs Submission)**
  - **Fix:** In the UI (Business Language), users talk about "Audits" (e.g., Schedule Audit, Assign Task). In the codebase and database (Technical Language), the entity is named "Submission" (e.g., `submissions:create`, `SubmissionApiService`). DO NOT rename these files. Understand that `Audit` in the UI = `Submission` in the DB.
- **Gotcha: The 7 Sync Steps (for PBAC & Data Sync)**
  - **Fix:** Update in order: (1) Entity, (2) DbContext, (3) Server DTO, (4) Endpoint projections, (5) Sync endpoint, (6) Flutter DTO, **(7) If adding a capability, seed it in `Program.cs` and `TestWebApplicationFactory.cs`**.
- **Gotcha: Programs Module Sync Steps**
  - **Fix:** The Sync Steps also apply to Programs: (1) `ProgramAssignment` entity, (2) `AppDbContext`, (3) Server DTOs, (4) Endpoint projections, (5) SM Sync endpoint, (6) Flutter `CachedProgramAssignments` Drift table.
- **Gotcha: Orphaned ATDD Stubs (`fail(...)`)**
  - **Fix:** If a QA agent leaves an ATDD stub like `fail('Implement...')`, the Builder MUST implement the test logic and fulfill the UI/Backend contract in the current slice. Do not leave `fail()` stubs behind for future slices unless explicitly documented.
- **Gotcha: Hybrid Entity-Driven UI (HATEOAS) for Actions**
  - **Fix:** Never hardcode UI button visibility or tap gestures based on the user's role on the frontend. The backend MUST compute an `allowedActions` string array (e.g., `["edit", "view_details", "void"]`) on its DTOs. This array is built by combining PBAC capabilities (from JWT) with the entity's current status. The Flutter frontend must wrap actionable widgets in an `ActionGuard` that checks this array to enable/disable interactions.
- **Gotcha: Silent DTO Contract Drift**
  - **Fix:** When building tests for client-side API mapping, DO NOT invent mock JSON based solely on local models. You MUST strictly reflect the actual backend DTO structure (e.g., matching exact property names). Use contract integration tests to verify JSON mapping and prevent silent failures where the frontend models drift from backend DTOs.
- **Gotcha: Live Area Boardroom Analytics (No Caching/Polling)**
  - **Fix:** Area Boardroom Analytics are calculated dynamically from live database queries on `Submissions` and return `IsLiveData = true` immediately. The `bod_report_snapshots` table was dropped in migration `DropBodReportSnapshotTable`. Polling is no longer implemented or required for the frontend.
- **Gotcha: BOD Section Scores Key Mismatch**
  - **Fix:** Do not assume `SubmissionSectionScores` JSON uses raw names or simple keys. The Flutter frontend `_buildSectionScoresJson()` serializes group details under distinct keys (the group UUIDs) with nested `title`, `score`, and `maxScore`/`maxPoints` properties. The backend `SectionScoreExploder.cs` extracts the human-readable section title from this nested `"title"` property to match UI category queries, falling back to the property name key for older or simpler payloads.
- **Gotcha: Linter Rule Drift & HTTP 422 Mapping**
  - **Fix:** The frontend linter and backend linter might drift. When mapping HTTP 422 response bodies to the frontend, ensure that `LintResult` parsing is resilient to missing fields and can display server-side linter errors gracefully in the linter panel.
- **Gotcha: Nesting Depth Constraints**
  - **Fix:** Scoring calculation engines (`VerifyPenalty` in C# and `ScoringInputMapper` in Dart) only support up to 2 levels of group hierarchy (Sections and Subsections). Nesting beyond this depth results in incorrect calculations because intermediate groups are bypassed or ignored.
- **Gotcha: Progressive Repeat Decimal Overflow Safeguards**
  - **Fix:** Always cast progressive repeat fault counts to `decimal` *before* multiplication (`(decimal)repeatedFaults * (decimal)repeatedFaults`) to prevent 32-bit integer overflow exceptions on high fault counts (above 46,340 faults).
- **Gotcha: TemplateDto and TemplateTreeDto optional params**
  - **Fix:** When extending DTO parameters, make new parameters optional in default constructors with safe fallbacks rather than strictly `required` to prevent breaking existing test cases, seeder models, and mock builders.
- **Gotcha: Clearing Area Manager Store Assignments (Explicit Empty Array)**
  - **Fix:** To clear all store assignments for an Area Manager, the frontend must explicitly transmit the `assignedStoreIds` field as an empty list (`[]`) instead of mapping it to `null` or omitting it. If mapped to `null` or omitted, the backend's presence checks (`TryGetProperty`) will treat the field as omitted and preserve the existing assignments.

## 4. Environment Rules
- **Folders:** Never run commands from the project root. Use `server/` or `lib/`.
- **No Interactive CLI:** Do not run `dotnet run`, `dotnet watch`, or `flutter run`.
- **Zero Bloat:** Do not install packages without permission.
- **RTK Wrapper:** Always prepend `rtk` to terminal commands (e.g., `rtk dotnet build`). *Exception:* For running test suites (e.g., `dotnet test`) where detailed failure traces or assertion outputs are required to debug, always use the `rtk proxy` prefix (e.g., `rtk proxy dotnet test ...`) to bypass RTK output filtering/compression.
- **Historical Tracking (Logs & Scratchpads):** NEVER leave test logs (`.log`), scratch queries (`.sql`), or text outputs in the project root, `server/`, or `lib/`. For historical tracking: Route all test outputs/logs to `.agents/logs/`. Route all scratch database scripts to `dbquery/`. Compiler dumps (`.xml`) must be deleted, not saved.

## 5. Development Speed & Tooling Mitigations
- **Mitigation: API Executable File Locks (Windows)**
  - **Action:** Terminate any running backend API executable before compiling to prevent file locks:
    ```cmd
    taskkill /f /im Checkly.Api.exe 2>nul
    ```
- **Mitigation: Central Solution File**
  - **Action:** A central solution file is located at `server/Checkly.slnx`. Build and test at the solution level:
    ```cmd
    rtk dotnet build Checkly.slnx
    rtk proxy dotnet test Checkly.slnx
    ```
- **Mitigation: Rapid Drift Code Generation**
  - **Action:** Run the generator in watch mode to automatically rebuild on save, or filter by file to speed up regeneration:
    ```cmd
    dart run build_runner watch --delete-conflicting-outputs
    # OR build only the database schema file:
    dart run build_runner build --build-filter="lib/core/database/app_database.dart"
    ```
- **Mitigation: Targeted Flutter Test Execution**
  - **Action:** Run targeted test folders or files during development instead of running all 878 tests:
    ```cmd
    flutter test test/features/audit/widgets/header_card_test.dart
    ```

