# Failure Report: Province Benchmark Test Pollution
Workflow: /diagnose | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\area_deprecation\walkthrough_20260519_120900_impl_b1_sl2_province_benchmark.md`

## Root Cause
The integration test suite in `Checkly.Api.Tests` shares a persistent PostgreSQL database instance (`checkly_test`). 
In `ProvinceBenchmarkCalculatorTests.cs`, the test cases seed static province strings (`"Hồ Chí Minh"` and `"Hà Nội"`) without clearing or truncating pre-existing data in the database. Because `ProvinceBenchmarkCalculator.RunForAllProvincesAsync` queries distinct provinces and aggregates stores globally (`db.Stores`), it also processes store and submission records seeded by other test suites or previous test runs.
This leaks state between tests, resulting in:
1. `HCM` aggregate audit counts returning `110` instead of the expected `5`.
2. `Hà Nội` (which only has 2 seeded audits in the test method) inheriting pre-existing audits, passing the threshold of 3, and generating an unexpected snapshot (causing `Assert.Null()` to fail).

## Explicit Code Trace
### Premises
1. **Database Persistence**: `TestWebApplicationFactory.EnsureDatabaseCreated()` (line 20 of `ProvinceBenchmarkCalculatorTests.cs`) migrates and keeps the database persistent. It is not wiped or recreated per test class or method.
2. **Global Queries**: In `ProvinceBenchmarkCalculator.cs`, the calculator retrieves distinct provinces globally from the database:
   ```csharp
   var provinces = await db.Stores
       .Where(s => s.Address2 != null && s.Address2.Province != null)
       .Select(s => s.Address2!.Province!)
       .Distinct()
       .ToListAsync(ct);
   ```
3. **Aggregations**: The calculator aggregates audits for each province globally using:
   ```csharp
   var storeIds = await db.Stores
       .Where(s => s.Address2 != null && s.Address2.Province == province)
       .Select(s => s.Id)
       .ToListAsync(ct);
   ```
   This pulls in ALL stores matching that province name, regardless of which test seeded them.

### Proof
- When `ProvinceBenchmarkCalculator_ProvinceWithMinAudits_ComputesAndUpsertsBenchmark` runs, `SeedTestDataAsync` is called.
- `SeedTestDataAsync` adds 3 new stores for `"Hồ Chí Minh"`.
- However, since previous tests (or runs) already have stores with `"Hồ Chí Minh"`, the database contains a total of `110` submissions linked to HCM stores.
- The calculator processes all of them, yielding `snapshot.TotalAuditCount == 110`.
- The assertion `Assert.Equal(5, snapshot.TotalAuditCount)` fails.

## Proposed Scope-Limited Fix

We present two alternative solutions to resolve the state pollution:

### Option A: Test Isolation via Unique randomized province strings (Recommended)
Replace the static strings `"Hồ Chí Minh"` and `"Hà Nội"` with GUID-suffixed unique province strings.
```csharp
private static readonly string _provinceHcm = $"HCM_{Guid.NewGuid():N}";
private static readonly string _provinceHn = $"HN_{Guid.NewGuid():N}";
```
Update all usages in `SeedTestDataAsync` and the assertions to reference these static unique fields.

#### Pros:
- **Perfect Isolation**: Guarantees absolute safety from parallel/sequential execution pollution. No two test runs will ever clash.
- **Ultra Safe**: Zero impact on other tests or database operations. No risk of race conditions with concurrently executing tests.
- **Minimal Code Change**: Localized entirely within the test file.

#### Cons:
- Accumulates dead test data in the `checkly_test` database, though not a performance bottleneck for development testing.

---

### Option B: Database Table Truncation
Add an explicit deletion sweep at the start of `SeedTestDataAsync` to truncate the tables before seeding.
```csharp
db.ProvinceBenchmarkSnapshots.RemoveRange(db.ProvinceBenchmarkSnapshots);
db.StoreAnalyticsSnapshots.RemoveRange(db.StoreAnalyticsSnapshots);
db.SubmissionSectionScores.RemoveRange(db.SubmissionSectionScores);
db.Submissions.RemoveRange(db.Submissions);
db.Stores.RemoveRange(db.Stores);
await db.SaveChangesAsync();
```

#### Pros:
- **Clean DB State**: Keeps the `checkly_test` database clean and lightweight.

#### Cons:
- **Parallelism Risk**: If parallel test collections are enabled or run in the future, truncating tables globally will instantly break other concurrently running tests.
- **Complexity**: Cascade deletes might trigger EF Core exception errors or foreign key constraint violations if not truncated in precise reverse-dependency order.

---

## Forensic Evidence
<forensic_evidence>
Command executed:
`cmd /c "rtk dotnet test server/tests/Checkly.Api.Tests/ --filter FullyQualifiedName~ProvinceBenchmarkCalculatorTests"`

Output failure:
```
  Failed Checkly.Api.Tests.Features.Analytics.ProvinceBenchmarkCalculatorTests.ProvinceBenchmarkCalculator_ProvinceWithMinAudits_ComputesAndUpsertsBenchmark [7 s]
  Error Message:
   Assert.Equal() Failure: Values differ
Expected: 5
Actual:   110

  Failed Checkly.Api.Tests.Features.Analytics.ProvinceBenchmarkCalculatorTests.ProvinceBenchmarkCalculator_ProvinceUnderMinAudits_SkipsBenchmark [3 s]
  Error Message:
   Assert.Null() Failure: Value is not null
Expected: null
Actual:   ProvinceBenchmarkSnapshot { ... Province = "Hà Nội" }
```
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict**: State pollution in the shared `checkly_test` database. Path: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260519_135000_e63e501c_area_deprecation.md`
2. **Required Fix**: Apply Option A (Unique randomized province strings) to [ProvinceBenchmarkCalculatorTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/ProvinceBenchmarkCalculatorTests.cs). Blast radius: 100% localized to `ProvinceBenchmarkCalculatorTests.cs`.
3. **AI Agent Mission Brief**: Replace static province strings in `ProvinceBenchmarkCalculatorTests.cs` with GUID-isolated variables to prevent database pollution from leaking other test runs' store and submission records.
4. **Execution Queue**:
   - [x] Execute Build/Fix Phase: `docs/diagnostics/failure_report_20260519_135000_e63e501c_area_deprecation.md`
