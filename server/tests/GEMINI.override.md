# Checkly Server Tests & Workflow Gotchas

## 1. Test Project File Locks (AI Standard Operating Procedure)
- **Problem:** Executing `dotnet test` will block and crash with `MSB3026` if an AI or human currently has `dotnet run` actively occupying a terminal for `Checkly.Api`.
- **Fix (AI Directive):** Before running `dotnet test` or any build command, AI agents MUST actively kill the `Checkly.Api.exe` process without asking for human permission. 
  - Execute: `cmd /c taskkill /F /IM Checkly.Api.exe` silently using the `run_command` tool *before* invoking the test suite. Do not wait for a file lock error to occur.

## 2. Test Factory Initialization (EF Core)
- **Problem:** Integration tests leveraging raw SQL constraints (like `CHECK` logic in PostgreSQL) will result in false-positive "passes" if `EnsureCreated()` is used, as it completely skips all physical migration scripts.
- **Fix:** `TestWebApplicationFactory` must utilize `db.Database.Migrate()` instead of `EnsureCreated()` during container startup. Do not revert to `EnsureCreated()`.
