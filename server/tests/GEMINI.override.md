# Server Tests Gotchas

> [!IMPORTANT]
> **MSB3026 File Lock (AI Auto-Kill)**
> **Problem:** `dotnet test` blocks with MSB3026 if `dotnet run` is active.
> **Fix:** Run `cmd /c taskkill /F /IM Checkly.Api.exe` *before* `dotnet test`. Do not ask for human permission.

> [!WARNING]
> **EF Core `EnsureCreated()` Banned in Tests**
> **Problem:** `EnsureCreated()` skips raw SQL `CHECK` constraints, causing false positives.
> **Fix:** `TestWebApplicationFactory` MUST use `db.Database.Migrate()`. Never use `EnsureCreated()`.

> [!WARNING]
> **WAF Parallel Initialization DB Race Condition**
> **Problem:** xUnit parallel tests interleave `EnsureDeleted()` + `Migrate()`, yielding false `3D000` or `42P07` Postgres/EF errors.
> **Fix:** These are infrastructure flakes. Test isolated fixes via `--filter`. Trust the combined sequential `dotnet test` result as the source of truth. Do NOT rewrite application logic to fix a 3D000 DB initialization error.
