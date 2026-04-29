# GEMINI.md — Admin Feature

## Gotcha: EF Migration Discovery Requires Designer.cs

**Problem:** Manually writing a `{Timestamp}_{Name}.cs` migration file without a companion `{Timestamp}_{Name}.Designer.cs` causes EF to silently ignore the migration. `db.Database.Migrate()` will not apply it, and `dotnet ef migrations list` will not show it.

**Symptom:** `dotnet ef migrations list` shows the previous migration as the latest. `db.Database.Migrate()` runs successfully but doesn't apply the new file.

**Fix:** Always generate migrations via `dotnet ef migrations add {Name}`. Then inject custom SQL into the generated `Up()` / `Down()` methods.

**Promoted from:** HYPOTHESIS after 1 empirical failure. Confirmed cause and fix.

---

## Gotcha: TestWebApplicationFactory Stale PbacDictionaryCache

**Problem:** `EnsureDatabaseCreated()` calls `EnsureDeleted() + Migrate()`, wiping and re-seeding the test DB. The app's `PbacDictionaryCache` singleton is initialized during startup (before the factory wipe), so the cache becomes stale after the DB is rebuilt.

**Symptom:** All `RequireCapability(...)` endpoints return 403 even for authenticated admin users.

**Fix:** After `db.SaveChanges()` in `EnsureDatabaseCreated()`, resolve `PbacDictionaryCache` from the service scope and call `InitializeAsync(scope.ServiceProvider).GetAwaiter().GetResult()`.

**Status:** Implemented in `TestWebApplicationFactory.cs`. Tag as architectural constraint — any new capability-gated endpoint tests require this fix to remain in place.
