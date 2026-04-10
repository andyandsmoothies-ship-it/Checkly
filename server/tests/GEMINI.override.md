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

> [!IMPORTANT]
> **Register Endpoint Role Allowlist Blocks Test-Role Injection**
> **Problem:** `POST /api/auth/register` validates `role` against a server-side allowlist (`admin, auditor, store_manager, area_manager`). Using `RegisterUserAsync("phantom")` to inject an unmapped role for capability boundary tests returns **400 Bad Request** before a JWT is issued.
> **Fix:** Forge a JWT directly via `TokenService.GenerateToken(userId, email, "phantom")` resolved from `_factory.Services`. This bypasses registration entirely and still produces a valid signed token that the PBAC handler will evaluate against the capability cache.
> ```csharp
> using var scope = _factory.Services.CreateScope();
> var ts = scope.ServiceProvider.GetRequiredService<TokenService>();
> var token = ts.GenerateToken(Guid.NewGuid(), "fake@test.test", "phantom");
> var client = _factory.CreateAuthenticatedClient(token);
> ```

> [!WARNING]
> **PBAC LISTEN/NOTIFY Cross-Test Contamination**
> **Problem:** xUnit parallel execution causes test classes to run simultaneously against the shared `checkly_test` database. If Test A mutates `role_capabilities` (e.g. testing `GrantCapability`), Postgres fires `NOTIFY`. Test B's `PbacCacheListenerService` instantly catches this signal, dynamically reloading its PBAC cache with the dirty state mid-test, leading to impossible "403 Expected but got 201" failures.
> **Fix:** Checkly integration tests must be strictly sequential. Use `[assembly: CollectionBehavior(DisableTestParallelization = true)]` in `GlobalUsings.cs` to prevent cross-contamination.

> [!CAUTION]
> **Gotcha 18: CCP Weight Normalization — C# vs Flutter Divergence**
> **Problem:** When a CCP section is triggered in penalty mode, Flutter's `ScoringEngine._calculatePenalty()` excludes the CCP section from `participatingWeight`. The ORIGINAL C# `ScoringVerifier.VerifyPenalty()` divided by `totalWeight` (all sections), producing systematically lower scores. Concrete example: 2 sections [60, 40], CCP on section-1 triggered. Flutter gives 100% (section-2 all-pass, normalized to 40). Old C# gave 40% (divided by 100). This caused **400 Bad Request** on every `PUT /submissions/{id}/finalize` that involved a triggered CCP.
> **Fix:** `VerifyPenalty()` now collects only participating (non-CCP) sections into a list, then sums `participatingWeight` as the denominator. Regression test: `Ccp_TriggeredSection_ExcludedFromWeightDenominator_MatchesFlutter` in `ScoringVerifierTests.cs`.
> **Rule:** Never port scoring logic between Dart and C# without a cross-engine parity test covering at least: no-CCP, CCP-triggered-with-one-section, CCP-triggered-with-multiple-sections.

