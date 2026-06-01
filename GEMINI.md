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

### Rule: Failure Modes Over Happy Paths
- **Rule**: The happy path is easy; always identify how the system crashes under edge cases before coding.
- **Enforcement**: Before writing code for a new feature, explicitly document 2 ways the architecture will crash or fail under edge-case conditions, and write tests to catch those specific failures.

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

### Rule: Golden UI Tests for Design Verification
- **Rule**: All UI additions or modifications must include Golden UI tests to prevent manual verification of components and layout.
- **Enforcement**: Run `flutter test --update-goldens` during the implementation phase to check rendering before concluding.

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
- **Gotcha: Card-Count Layout Assertions in Widget Tests**
  - **Fix:** When refactoring components that are expected to render as Card widgets by standard unit tests (specifically verified via `find.byType(Card)` assertions), make sure the outer widget is a `Card` widget rather than a `Container` with rounded borders to satisfy the test assertions and layout contracts.
- **Gotcha: Widget-Type Assertions in Create Wizard Tests (BubblyButton vs ElevatedButton)**
  - **Fix:** When refactoring interactive buttons in forms/wizards that are verified in existing unit or widget tests using precise class searches (specifically casting to `ElevatedButton`), make sure to render an `ElevatedButton` wrapped or styled rather than using a custom non-Material button like `BubblyButton` to prevent type cast exception failures.
- **Gotcha: Admin Duolingo Reskin Aesthetic**
  - **Fix:** All administrative pages (Dashboard, User, Store, Audit, Risk, and Logs) must utilize the custom `StrokeCard` and `PillChip` design primitives rather than raw standard cards or custom styled containers to ensure aesthetic consistency and visual excellence across the platform.
- **Gotcha: TextFormField length-limiting validation testing**
  - **Fix:** In Flutter widget testing, when a `TextFormField` has `maxLength` specified, `tester.enterText()` will be constrained by the input formatter and cannot enter text longer than `maxLength`. To test validation logic asserting text exceeds this maximum limit, you must set the text value directly on the `TextEditingController` (e.g. `field.controller!.text = 'a' * 201`), then call `tester.pump()` to trigger the validation check on submission.
- **Gotcha: Asynchronous Timer pending in widget tests**
  - **Fix:** Stateful widgets that instantiate delayed futures or Timers for staggered entrance animations (such as BouncyListWrapper or StaggeredListItem) must store references to their underlying timers/controllers and explicitly call `.cancel()` inside `dispose()`. This guarantees that all active timers are discarded when the widget tree is torn down at the end of a test run, preventing the framework from throwing a "A Timer is still pending even after the widget tree was disposed" exception.
- **Gotcha: Public State Naming for Animation Testing**
  - **Fix:** When implementing custom animated widgets whose internal controller states or animation status needs to be verified during widget testing (e.g. `isAnimating`), name the `State` class publicly (e.g. `class ChecklyEmptyStateState extends State<ChecklyEmptyState>` instead of using a private `_` prefix). This allows the widget testing framework to access it directly via `tester.state<ChecklyEmptyStateState>(find.byType(ChecklyEmptyState))`.
- **Gotcha: Reduced Motion Compliance**
  - **Fix:** All highly active micro-animations (such as bouncy button squashes, list cascades, empty state jiggles, and elastic checkbox pops) must explicitly verify and respect reduced motion settings via `MediaQuery.disableAnimationsOf(context)`. If active, transitions must immediately snap to target boundaries without delay, curve interpolation, or ticker activity, to avoid triggering motion sensitivity issues for accessibility users.
- **Gotcha: Shared Database Testing & Analytics Pollution**
  - **Fix:** Integration tests running against a shared database must never assume the database is empty or calculate absolute aggregates against mutable seeded tables. Always isolate test calculations using unique query anchors (e.g., unique tags, isolated IDs, or far-past/far-future dates) to prevent other tests' persistent records from corrupting mathematical assertions.
- **Gotcha: Card Title Flex Overflow in Headless Tests**
  - **Fix:** In narrow headless testing environments or mobile layouts, horizontal `Row` components containing `Icon` and `Text` (like card header layouts) will throw layout overflow exceptions. Always wrap the header `Text` widget in an `Expanded` or `Flexible` widget to allow elegant text wrapping and guarantee test robustness.
- **Gotcha: Pre-computed Snapshot Polling**
  - **Fix:** When triggering on-demand calculations, the API returns immediately while calculations complete in the background. The Flutter frontend must poll the GET endpoint every 5 seconds (with a 60s timeout fallback) until the retrieved `computedAt` timestamp increases, showing a loading shimmer in the meantime to ensure real-time visual accuracy without instant page snaps.
- **Gotcha: OLAP Background Aggregations (Advisory Locking)**
  - **Fix:** To prevent database performance degradation under heavy aggregate queries, calculate boardroom analytics in a nightly background job and cache the rollups as `jsonb` documents in a snapshot table. Protect worker concurrency using PostgreSQL-native transaction-level advisory locks to eliminate race conditions and thundering herds.
- **Gotcha: BOD Section Scores Key Mismatch**
  - **Fix:** Do not assume `SubmissionSectionScores` JSON uses raw names or simple keys. The Flutter frontend `_buildSectionScoresJson()` serializes group details under distinct keys (the group UUIDs) with nested `title`, `score`, and `maxScore`/`maxPoints` properties. The backend `SectionScoreExploder.cs` extracts the human-readable section title from this nested `"title"` property to match UI category queries, falling back to the property name key for older or simpler payloads.
- **Gotcha: PostgreSQL Null Inequality Translation Bug**
  - **Fix:** In EF Core queries targeting PostgreSQL, any inequality comparison like `s.ReviewStatus != "rejected"` will silently exclude all records where the column value is `NULL`. This happens because Postgres evaluates `NULL != 'rejected'` as `NULL` (falsy in WHERE clauses). To correctly query all records that are not rejected (including both null/unreviewed and non-rejected records), you must always write `(s.ReviewStatus == null || s.ReviewStatus != "rejected")`.
- **Gotcha: Flutter SQLite Array Serialization (categoryTags)**
  - **Fix:** SQLite does not natively support array types. `TemplateDao` serializes `List<String>? categoryTags` into a comma-separated String when saving to SQLite. When reading, it splits by comma and sanitizes the result using `.where((t) => t.isNotEmpty).toList()` to prevent empty strings from polluting the output. Ensure any test models or frontend widgets handle empty/whitespace strings gracefully and never assume index-based access on un-sanitized comma values.
- **Gotcha: Golden UI Asset Path Mapping**
  - **Fix:** Golden test images must be saved under the `test/goldens/` directory. Do not check in full device screenshots; only assert against the target widget or isolated component viewports to keep reference images small, lightweight, and clean.
- **Gotcha: Widget-Type Switch Finder Collisions**
  - **Fix:** In Flutter widget testing, when using `find.byType(Switch).first` to retrieve the first question's toggle, ensure that other simulation switches (e.g., Global Risk Override switches) are placed at the bottom of the list or use unique widgets/keys so they do not collide with the question's toggle selection.
- **Gotcha: Default pass_fail minusImpact**
  - **Fix:** For scoring engine simulators, a failed `pass_fail` criterion with no explicit `minusImpact` set should fall back to `1.0` to match expected test deductions (e.g. dropping score from `100.00%` to `90.00%` under a standard `10` points weight).
- **Gotcha: Linter Rule Drift & HTTP 422 Mapping**
  - **Fix:** The frontend linter and backend linter might drift. When mapping HTTP 422 response bodies to the frontend, ensure that `LintResult` parsing is resilient to missing fields and can display server-side linter errors gracefully in the linter panel.
- **Gotcha: Nesting Depth Constraints**
  - **Fix:** Scoring calculation engines (`VerifyPenalty` in C# and `ScoringInputMapper` in Dart) only support up to 2 levels of group hierarchy (Sections and Subsections). Nesting beyond this depth results in incorrect calculations because intermediate groups are bypassed or ignored.
- **Gotcha: Progressive Repeat Decimal Overflow Safeguards**
  - **Fix:** Always cast progressive repeat fault counts to `decimal` *before* multiplication (`(decimal)repeatedFaults * (decimal)repeatedFaults`) to prevent 32-bit integer overflow exceptions on high fault counts (above 46,340 faults).
- **Gotcha: PowerShell UTF-8 ANSI Double-Encoding (Vietnamese/Unicode Corruption)**
  - **Fix:** Windows PowerShell 5.1 loads files in ANSI by default if they lack a BOM, which corrupts multi-byte UTF-8 sequences (like Vietnamese `Đ` and `á`) during seeder generation. To prevent string corruption, NEVER use raw non-ASCII unicode literal strings in script templates or heredocs. Always express non-ASCII characters inside string literals using their safe C# escape sequence representation (e.g., `\u0110\u00e1nh gi\u00e1` for `Đánh giá`).
- **Gotcha: Viewport Off-Screen Test Failure**
  - **Fix:** If a newly added list/grid item pushes other elements off-screen in widget tests, the lazy-loading widgets (like GridView/ListView) will not build them, causing finders to fail. Always set `tester.view.physicalSize` to a larger size (e.g. `const Size(800, 1200)`) and restore it inside `addTearDown` to ensure all elements fit in the test viewport.
- **Gotcha: Bimodal Geofence Proximity validation flow**
  - **Fix:** Geofence checks must run synchronously before GPS is resolved for final audit outbox pinning, preventing race conditions or premature submissions before geofence warning/blocking dialogs are rendered.
- **Gotcha: TemplateDto and TemplateTreeDto optional params**
  - **Fix:** When extending DTO parameters, make new parameters optional in default constructors with safe fallbacks rather than strictly `required` to prevent breaking existing test cases, seeder models, and mock builders.
- **Gotcha: Geofence Count Semantics**
  - **Fix:** Geofence warning alerts trigger in the frontend only when `geofenceBypassCount > 0`. The card renders next to `Total Auditors` in Row 4 of `BodKpiGrid`.







## 4. Environment Rules
- **Folders:** Never run commands from the project root. Use `server/` or `lib/`.
- **No Interactive CLI:** Do not run `dotnet run`, `dotnet watch`, or `flutter run`.
- **Zero Bloat:** Do not install packages without permission.
- **RTK Wrapper:** Always prepend `rtk` to terminal commands (e.g., `rtk dotnet build`).
- **Historical Tracking (Logs & Scratchpads):** NEVER leave test logs (`.log`), scratch queries (`.sql`), or text outputs in the project root, `server/`, or `lib/`. For historical tracking: Route all test outputs/logs to `.agents/logs/`. Route all scratch database scripts to `dbquery/`. Compiler dumps (`.xml`) must be deleted, not saved.
