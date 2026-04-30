# Checkly Global Agent Rules

## 1. Governance Rules

### Rule: Read Before You Write
- **Rule**: Research the code before editing. Never change code you haven't read.
- **Enforcement**: Use `grep_search` and `view_file`. Always check `GEMINI.md` in subfolders for local rules before editing files there.

### Rule: Do Not Fix Unrelated Code
- **Rule**: Only touch what you have to. Do not clean up unrelated code or "improve" adjacent logic.
- **Enforcement**: Match surrounding style perfectly. Preserve quote marks, spacing, and dead code exactly as they are.

### Rule: Keep It Simple
- **Rule**: Write the simplest code that solves the problem. Don't make bad abstractions.
- **Enforcement**: Duplication is cheaper than the wrong abstraction (WET). Do not extract shared helpers unless used in 3+ places.

### Rule: Use Existing Tools
- **Rule**: Prove you are using the project's existing tools before building your own custom logic.
- **Enforcement**: Search `server/Common/` or `lib/_shared/` before building utilities, routing logic, or UI components.

### Rule: Trust Shared Tools
- **Rule**: When using a shared utility, delete any surrounding guard clauses or boilerplate it already handles internally. Don't write manual checks around it.

### Rule: Tests Must Come First
- **Rule**: If a test fails, fix the code, not the test.
- **Enforcement**: Never write tests and main code in the exact same prompt cycle.

### Rule: Keep Files Small
- **Rule**: Files must NEVER exceed 400 lines. Split them to prevent AI confusion.
- **Enforcement**: Reduce size by pulling logic into new files, not by deleting comments or whitespace.

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
- **Gotcha: The 6 Sync Steps**
  - **Fix:** Update in order: (1) Entity, (2) DbContext, (3) Server DTO, (4) Endpoint projections, (5) Sync endpoint, (6) Flutter DTO.

## 4. Environment Rules
- **Folders:** Never run commands from the project root. Use `server/` or `lib/`.
- **No Interactive CLI:** Do not run `dotnet run`, `dotnet watch`, or `flutter run`.
- **Zero Bloat:** Do not install packages without permission.
- **RTK Wrapper:** Always prepend `rtk` to terminal commands (e.g., `rtk dotnet build`).
