# Task: Province Benchmark Test Pollution
Workflow: /diagnose | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\area_deprecation\walkthrough_20260519_120900_impl_b1_sl2_province_benchmark.md`

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260519_135000_e63e501c_area_deprecation.md | Report |

## Diagnostic Reasoning

### Falsifiable Hypotheses
1. **Hypothesis A (Test Isolation via Unique Strings)**: If the test failure is purely due to database state contamination, then replacing static strings like `"Hồ Chí Minh"` and `"Hà Nội"` with GUID-suffixed unique province strings (e.g., `$"HCM_{Guid.NewGuid():N}"`) in both `SeedTestDataAsync` and the assertions will isolate the test execution and allow the tests to pass successfully without touching the production calculation code.
2. **Hypothesis B (Database Truncation)**: If the test failure is due to global side effects (e.g. other tests querying overall database state or matching null check assertions), then executing an explicit `RemoveRange` truncation for all dependent tables at the beginning of `SeedTestDataAsync` will clear out all dirty data and make the tests pass.
3. **Hypothesis C (Calculator Implementation Bug)**: If the test failure is due to a bug in the production `ProvinceBenchmarkCalculator` itself (e.g., aggregating values incorrectly or failing to filter correctly), then even with unique province strings and a truncated database, the tests will continue to fail with mathematically incorrect averages or standard deviations.

### Initial Hypothesis
Tests in `ProvinceBenchmarkCalculatorTests.cs` fail because the underlying local PostgreSQL database `checkly_test` is dirty/contaminated with pre-existing store, submission, and benchmark records. When `ProvinceBenchmarkCalculator` runs, it queries all stores across all provinces, resulting in inflated aggregate counts (e.g. HCM audits = 110 instead of 5) and unexpected benchmark creation for Hà Nội (where 2 audits were expected, but more were found).

### Evidence Gathered
- Run `rtk dotnet test` resulted in:
  - `ProvinceBenchmarkCalculator_ProvinceWithMinAudits_ComputesAndUpsertsBenchmark`: Expected `5`, got `110`.
  - `ProvinceBenchmarkCalculator_ProvinceUnderMinAudits_SkipsBenchmark`: Expected `null`, but a snapshot for "Hà Nội" was created with an average score.
- The `checkly_test` database persists data between test suite runs and does not wipe tables by default.
- `ProvinceBenchmarkCalculator.RunForAllProvincesAsync` queries `db.Stores` globally without scoped filtering to our test run, bringing in all records seeded by previous migrations or other tests.

### Root Cause Identified
Lack of test database isolation. `ProvinceBenchmarkCalculatorTests` does not truncate the relevant database tables before seeding, nor does it use isolated, unique, randomized province strings (e.g. HCM_random, HN_random) to separate its calculations from pre-existing or parallel test execution data.

### Fix Strategy
Modify the test code in `ProvinceBenchmarkCalculatorTests.cs` to use isolated, unique, randomized province strings (e.g. `$"HCM_{Guid.NewGuid():N}"` and `$"HN_{Guid.NewGuid():N}"`) instead of static string values like `"Hồ Chí Minh"` and `"Hà Nội"`. This guarantees that even on a dirty, persistent, or concurrently modified database, the calculator only aggregates the specific stores and submissions created within this test execution.
