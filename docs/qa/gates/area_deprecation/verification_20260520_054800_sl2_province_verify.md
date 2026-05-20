# Verification Gate: Province Benchmark Migration (SL2)

## Phase 1: Context & Accountability Audit
- **Code path traced line-by-line:** Yes. Examined `analytics_manager.dart`, `analytics_drift_loader.dart`, `GetAnalytics.cs`, and `GetAreaLeaderboard.cs`.
- **All ACs verified against real code:** Yes. TC-SL2-01 through TC-SL2-10 are implemented. The API successfully transitions to aggregating benchmarks dynamically over `addressProvince` instead of `AreaId`.

## Phase 1.5: Adversarial Interrogation (Red Team)
1. **Concurrency Extreme:** Protected by `db.TryExecuteInLockAsync("Checkly.ProvinceBenchmarkWorker", ...)` within `AreaBenchmarkWorker` avoiding thundering herd.
2. **Volume Extreme:** Flutter `analytics_drift_loader.dart` bounds memory with `.limit(1000)` checks.
3. **Dependency Extreme:** Offline fallback works correctly if the network crashes during API refresh.
4. **Trust Assumption Audit:** Access strictly adheres to PBAC; area managers bypass standard IDOR checks correctly through explicit policy mapping `analytics:area`.

## Phase 2: Continuous Integration
| Phase | Status | Details |
|-------|--------|---------|
| 1. Build | **PASS** | `dotnet build` compiled without error. |
| 2. Diagnostics | **PASS** | `flutter analyze` 0 warnings. `dotnet format analyzers server/` 0 warnings. |
| 3. Anti-patterns | **PASS** | 0 anti-patterns detected. CancellationTokens propagated. |
| 4. Tests | **PASS** | All .NET (`dotnet test`) and Flutter (`flutter test`) tests run and passed successfully. GUID isolation fix for `ProvinceBenchmarkCalculatorTests` eliminated state contamination. |
| 5. Security | **PASS** | No secrets detected. |
| 6. Format | **PASS** | `dart format .` and `dotnet format server/` executed. |
| 7. Diff Review | **PASS** | Obsolete tests pruned. |

## Phase 3: Deliverable & Handoff

### Blast Radius
The changes effectively pivot Checkly analytics away from Area structure, allowing deprecation of Area (SL-5) to proceed safely.
- **Affected:** `AnalyticsApiService`, `GetAnalytics`, and offline drift caches.
- **Risk:** Low. Tested with high coverage and deterministic data isolation.

### Manual Test Plan
1. **Critical Path**: Navigate to the Analytics tab. Expand filters. Verify "Provinces" has replaced "Areas". Select a province to ensure the charts reload correctly.
2. **Offline Fallback**: Disable internet and change province filter. Ensure UI updates via Drift offline load.

**Final Verdict:** PASS
