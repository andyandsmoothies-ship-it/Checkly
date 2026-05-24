# TDD Hand-off: SL-2 Province Benchmark (Red Phase)

## Test Contracts Implemented
| ID | Test File | Test Method | Target Component |
|---|---|---|---|
| TC-SL2-01 | ProvinceBenchmarkCalculatorTests.cs | ProvinceBenchmarkCalculator_ProvinceWithMinAudits_ComputesAndUpsertsBenchmark | ProvinceBenchmarkCalculator |
| TC-SL2-02 | ProvinceBenchmarkCalculatorTests.cs | ProvinceBenchmarkCalculator_NullProvince_SkipsBenchmark | ProvinceBenchmarkCalculator |
| TC-SL2-03 | ProvinceBenchmarkCalculatorTests.cs | ProvinceBenchmarkCalculator_ProvinceUnderMinAudits_SkipsBenchmark | ProvinceBenchmarkCalculator |
| TC-SL2-04 | ProvinceLeaderboardEndpointTests.cs | GetAreaLeaderboard_WithProvinceParam_ForAreaManager_Returns200 | GET /api/analytics/area-leaderboard |
| TC-SL2-05 | ProvinceLeaderboardEndpointTests.cs | GetAreaLeaderboard_WithProvinceParam_FiltersStoresCorrectly | GET /api/analytics/area-leaderboard |
| TC-SL2-06 | ProvinceLeaderboardEndpointTests.cs | GetAnalytics_ByStoreId_ReturnsInsights_FromProvinceBenchmark | GET /api/analytics |

## Failure Analysis (RED for the right reason)
1. **Compilation Errors (TC-SL2-01 to 03)**:
   - `error CS0234: The type or namespace name 'ProvinceBenchmarkCalculator' does not exist`
   - `error CS1061: 'AppDbContext' does not contain a definition for 'ProvinceBenchmarkSnapshots'`
   - *Why it's good:* Proves the class and EF entity have not been created yet by the Builder.
2. **Compilation Errors / Route Missing (TC-SL2-04 to 06)**:
   - Fails because `ProvinceBenchmarkSnapshot` EF entity does not exist so DB setup in `TC-SL2-06` fails to compile.
   - For `TC-SL2-04`, the route requires PBAC configuration which will be introduced in B1.
   
## Instructions for Builder
1. Implement Phase B1:
   - Create `ProvinceBenchmarkSnapshot.cs` entity and EF Config.
   - Run EF Migration to seed `analytics:area` capability.
   - Implement `ProvinceBenchmarkCalculator`.
2. Implement Phase B2:
   - Refactor `GetAnalytics` and extract insights generation to a separate file (e.g. `GetAnalyticsInsightsResolver.cs`).
   - Refactor `GetAreaLeaderboard` to filter by province string instead of AreaId.
3. Keep running `dotnet test` until all 6 ATDD tests pass.
