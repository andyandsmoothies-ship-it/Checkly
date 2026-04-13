# GEMINI.override.md — Checkly.Api.Tests

## Gotcha: FK_submissions_templates_template_id (CONFIRMED)

**Problem:** Seeding a `Submission` with `TemplateId = Guid.NewGuid()` (a random, non-existent GUID) causes a `DbUpdateException` at `SaveChangesAsync` time because PostgreSQL enforces `submissions.template_id → templates.id` as a hard FK constraint at INSERT, even though EF Core's `OnDelete(SetNull)` only governs DELETE cascade behaviour.

**Symptom:** The exception was previously masked because `dotnet test` ran a stale pre-compiled binary (before the relevant code changes were compiled in). The test appeared to fail with a `403 Forbidden` rather than exposing the real `DbUpdateException`.

**Fix:** Always set `TemplateId = null` in test Submission seeds unless a real Template is required by the test scenario. `Submission.TemplateTitle` is a denormalized snapshot field and can be set freely without a live FK.

```csharp
// WRONG — FK violation at PostgreSQL level:
seedDb.Submissions.Add(new Submission { TemplateId = Guid.NewGuid(), ... });

// CORRECT — null bypasses FK enforcement:
seedDb.Submissions.Add(new Submission { TemplateId = null, TemplateTitle = "Test Template", ... });
```

---

## Gotcha: Stale Binary Masking Real Errors (CONFIRMED)

**Problem:** When the MSBuild `CoreGenerateAssemblyInfo` / `StaticWebAssets` target fails with a false-positive error (cache file locked), `dotnet test --no-build` runs the OLD pre-compiled binary. Code changes made after the last successful build are invisible to the test run.

**Symptom:** Test failures appear to be a different error than the actual code problem (e.g., `403 Forbidden` instead of FK `DbUpdateException`).

**Fix:** When seeing confusing test failures after a code change, always force a full rebuild by deleting the `obj` directory or running `dotnet test` (without `--no-build`) to ensure the latest code is compiled.

---

## Gotcha: PBAC Cache Fail-Closed on Cold Start (CONFIRMED)

**Problem:** The `PbacDictionaryCache` starts with `IsReady = false`. When `PbacCacheListenerService` tries to initialize in the background before `EnsureDatabaseCreated()` completes, it hits the not-yet-migrated DB and fails with `SqlState: 42P01` (table does not exist). All subsequent requests get `403 Forbidden` because `CapabilityAuthorizationHandler` denies all requests when `IsReady = false`.

**Fix:** Always run tests that require PBAC as part of the full `SubmissionActionPlanTests` class (using `IClassFixture<TestWebApplicationFactory>`), NOT in isolation. The class constructor calls `EnsureDatabaseCreated()` which migrates the DB AND initializes the PBAC cache synchronously before any test runs. Running a single test in isolation skips this setup.
