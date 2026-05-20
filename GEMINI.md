# Checkly Global Agent Rules

## 1. Governance Rules

### Rule: Engage Strongly With Structure
- **Rule**: Architecture is law. Inner rings MUST NOT import outer rings. 
- **Enforcement**: Separate Technical Language (DB) from Business Language (UI).

### Rule: Use Mechanical Language
- **Rule**: Do not use human words (like "thought", "forgot") to describe code or system behavior. Be literal and concise.
- **Enforcement**: Describe exactly what the code executes or lacks. (e.g. "The function lacked the instruction to write rows," not "The system forgot to save").

### Rule: Read Before You Write
- **Rule**: Research the code before editing. Never change code you haven't read.
- **Enforcement**: Use `grep_search` and `view_file`. Always check `GEMINI.md` in subfolders for local rules before editing files there.

### Rule: Prove It With Code (No Hallucinations)
- **Rule**: Never answer questions about how a function works, what a file contains, or what tasks are done based on memory or outdated chat history.
- **Enforcement**: When answering questions about the codebase, you MUST provide concrete evidence (e.g., a real code snippet, exact line numbers, or file paths) that you just freshly pulled using your search/read tools to prove your answer reflects the *current* live state of the project.

### Rule: Do Not Fix Unrelated Code
- **Rule**: Only touch what you have to. Do not clean up unrelated code or "improve" adjacent logic.
- **Enforcement**: Match surrounding style perfectly. Preserve quote marks, spacing, and dead code exactly as they are.

### Rule: Keep It Simple
- **Rule**: Write the simplest code that solves the problem. Don't make bad abstractions.
- **Enforcement**: Duplication is cheaper than the wrong abstraction (WET). Do not extract shared helpers unless used in 3+ places.

### Rule: Well Partitioned Modules
- **Rule**: Keep domains strongly partitioned. Reject "God" modules and tightly coupled designs.
- **Enforcement**: Control coupling. Refactor monolithic services by using events (MediatR/EventBus) to decouple.

### Rule: Tightly Controlled Dependencies
- **Rule**: Prove you are using the project's existing tools before building your own. 
- **Enforcement**: Search `server/Common/` or `lib/_shared/` first. Do not install unauthorized packages without whitelist approval.

### Rule: Prune Unwired Code
- **Rule**: Aggressively delete dead code, unused files, and unused dependencies. Less code is better code.
- **Enforcement**: Periodically use language-native dead-code analyzers (e.g., `dotnet format analyzers`, `dart analyze`, or unused reference sweeps) to cut out anything that isn't wired in. If you delete a feature's usage, you MUST delete its underlying implementation.

### Rule: Trust Shared Tools
- **Rule**: When using a shared utility, delete any surrounding guard clauses or boilerplate it already handles internally. Don't write manual checks around it.

### Rule: Massively Overloaded Tests
- **Rule**: If a test fails, fix the code, not the test. Never write tests and main code in the exact same prompt cycle.
- **Enforcement**: Go beyond happy paths. Use property-based and mutation testing for core logic. Never assert raw booleans; print actual error HTTP bodies instead.

### Rule: Testing is Architecture
- **Rule**: Tests verify behavior, not implementation. Do not test business logic through volatile UI layers.
- **Enforcement**: Refactoring internal code should not break tests (Liskov substitution). Keep test-only APIs (e.g., DB seeders) strictly bounded to the test project.

### Rule: Small Discrete Functions & Files
- **Rule**: Files must NEVER exceed 400 lines. Split them to prevent AI confusion.
- **Enforcement**: Functions MUST NOT exceed 30 lines. Max Cyclomatic Complexity is 10. Reduce size by pulling logic into new files, not by deleting comments or whitespace.

### Rule: Use Strong Types
- **Rule**: Use Enums, Unions, or Static Constants instead of plain strings for system identifiers.

### Rule: Fix Warnings First
- **Rule**: Do not add new features if the code has errors. 
- **Enforcement**: Stop and run `de-sloppify` first. Ignore warnings you didn't create.

## 2. Platform Architecture
- **Frontend**: Flutter (Dart) — Offline-first with SQLite. Core UI rules are in `lib/GEMINI.md`.
- **Backend**: ASP.NET Core (.NET 10) Minimal API. Database and endpoint rules are in `server/GEMINI.md`.
- **Database**: PostgreSQL via EF Core.
- **Impact Map**: 
  - 🔴 High Impact (`AppDbContext`, Entities, Sync). 
  - 🟡 Medium (`Common/`, Widgets, Router). 
  - 🟢 Safe Scope (Features).

## 3. Global Gotchas
- **Gotcha: Terminology Map (Audit vs Submission)**
  - **Fix:** In the UI (Business Language), users talk about "Audits" (e.g., Schedule Audit, Assign Task). In the codebase and database (Technical Language), the entity is named "Submission" (e.g., `submissions:create`, `SubmissionApiService`). DO NOT rename these files. Understand that `Audit` in the UI = `Submission` in the DB.
- **Gotcha: The 7 Sync Steps (for PBAC & Data Sync)**
  - **Fix:** Update in order: (1) Entity, (2) DbContext, (3) Server DTO, (4) Endpoint projections, (5) Sync endpoint, (6) Flutter DTO, **(7) If adding a capability, seed it in `Program.cs` and `TestWebApplicationFactory.cs`**.
- **Gotcha: Programs Module Sync Steps**
  - **Fix:** The Sync Steps also apply to Programs: (1) `ProgramAssignment` entity, (2) `AppDbContext`, (3) Server DTOs, (4) Endpoint projections, (5) SM Sync endpoint, (6) Flutter `CachedProgramAssignments` Drift table.
- **Gotcha: Silent Test Failures (Assert.True(response.IsSuccessStatusCode))**
  - **Fix:** Never use raw boolean asserts for HTTP responses. Always read and print the error body on failure so the actual HTTP status and API error message are visible in test logs. Example: `if (!res.IsSuccessStatusCode) Assert.Fail($"Status: {res.StatusCode}. Body: {await res.Content.ReadAsStringAsync()}");`
- **Gotcha: .NET Namespace Collisions**
  - **Fix:** When naming entities with common names like `Program`, `Task`, or `Role`, ALWAYS use fully qualified namespaces (e.g., `Entities.Program`) in `AppDbContext.cs` to prevent collisions with the application's `Program.cs` or system types.
- **Gotcha: Flutter Testing Framework (Mocktail vs Mockito)**
  - **Fix:** Checkly uses `mocktail` exclusively for Flutter tests. Never import `mockito` or use `@GenerateMocks` code generation. Always use `class MockMyService extends Mock implements MyService {}`.
- **Gotcha: Orphaned ATDD Stubs (`fail(...)`)**
  - **Fix:** If a QA agent leaves an ATDD stub like `fail('Implement...')`, the Builder MUST implement the test logic and fulfill the UI/Backend contract in the current slice. Do not leave `fail()` stubs behind for future slices unless explicitly documented.
- **Gotcha: Database Wipes in Integration Tests**
  - **Fix:** NEVER use framework commands that drop or wipe the host database (e.g. `EnsureDeleted()`) without an explicit code-level safeguard. Integration test factories must hardcode an exception throw if the connected database string does not contain `_test` to guarantee the development and production databases cannot be wiped accidentally.
- **Gotcha: Local Testing Environment**
  - **Fix:** The project utilizes Logical Database Separation on the local PostgreSQL instance. The `checkly_test` database **already exists** natively alongside the main `checkly` database. Agents must never try to drop it manually or assume tests need a mocked server. Simply run `dotnet test`, and `TestWebApplicationFactory` will seamlessly route traffic to `checkly_test` and auto-migrate its schema.
- **Gotcha: Interface Drift in Mocks (Compiler Mismatches)**
  - **Fix:** Avoid manual fakes (e.g., `class FakeDao extends RealDao`) which require manual signature rewrites. Use `mocktail` (`class MockDao extends Mock implements RealDao {}`). Whenever you modify a core service, entity, or database DAO, you MUST run the global `flutter test` or `dotnet test` suite before committing to instantly catch drifted interfaces across the entire project.
- **Gotcha: Hardcoded Role Filtering in UI Lists**
  - **Fix:** Do not hardcode role string checks (e.g., `u['role'] == 'auditor'`) in the frontend to filter dropdowns or UI lists, especially when migrating to PBAC. If the UI arbitrarily excludes roles like `area_manager`, dropdowns will appear empty and lead to silent null-reference validation errors. Always prefer backend-driven capability lists or PBAC-aware filtering.
- **Gotcha: Hybrid Entity-Driven UI (HATEOAS) for Actions**
  - **Fix:** Never hardcode UI button visibility or tap gestures based on the user's role on the frontend. The backend MUST compute an `allowedActions` string array (e.g., `["edit", "view_details", "void"]`) on its DTOs. This array is built by combining PBAC capabilities (from JWT) with the entity's current status. The Flutter frontend must wrap actionable widgets in an `ActionGuard` that checks this array to enable/disable interactions.
- **Gotcha: Silent DTO Contract Drift**
  - **Fix:** When building tests for client-side API mapping, DO NOT invent mock JSON based solely on local models. You MUST strictly reflect the actual backend DTO structure (e.g., matching exact property names). Use contract integration tests to verify JSON mapping and prevent silent failures where the frontend models drift from backend DTOs.
- **Gotcha: Strict 1-to-M Store Assignment Unique Constraint**
  - **Fix:** `ProfileStoreAssignmentConfiguration` places a unique index on `StoreId` (`e.HasIndex(x => x.StoreId).IsUnique()`), enforcing that a store can only be assigned to a single profile/manager. Do not write test cases or business logic that assume multiple profiles can be assigned to the same `StoreId` via `ProfileStoreAssignment`, as it will throw a Postgres 23505 duplicate key violation. Test multi-manager scenarios by utilizing separate stores.

## 4. Environment Rules
- **Folders:** Never run commands from the project root. Use `server/` or `lib/`.
- **No Interactive CLI:** Do not run `dotnet run`, `dotnet watch`, or `flutter run`.
- **Zero Bloat:** Do not install packages without permission.
- **RTK Wrapper:** Always prepend `rtk` to terminal commands (e.g., `rtk dotnet build`).
- **Test Logs & Output:** NEVER pipe test output or logs to the project root, `server/`, or `lib/`. Any command output (e.g., `> test_output.txt`) MUST be written exclusively to `.agents/tmp/`.
