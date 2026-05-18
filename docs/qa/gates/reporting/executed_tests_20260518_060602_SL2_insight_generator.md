# Executed Tests: InsightGeneratorService (Slice 2 — RED Phase)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_060602_SL2_insight_generator.md`

## Test Files Written
1. `server/tests/Checkly.Api.Tests/Features/Analytics/InsightGeneratorTests.cs` — Unit tests (IG-02, IG-03, IG-08 + sparsity unit + RadarData suppression unit)
2. `server/tests/Checkly.Api.Tests/Features/Analytics/InsightsIntegrationTests.cs` — Integration tests (IG-01, IG-04, IG-05, IG-06, IG-07)

## RED State Confirmation

### Unit Tests (`InsightGeneratorTests.cs`)
```
rtk dotnet test --filter InsightGenerator

error CS0103: The name 'InsightGeneratorService' does not exist in the current context
  → InsightGeneratorTests.cs(25,22)
  → InsightGeneratorTests.cs(47,22)
  → InsightGeneratorTests.cs(76,22)
  → InsightGeneratorTests.cs(108,22)
  → InsightGeneratorTests.cs(127,22)

fail dotnet test: 0 passed, 1 failed, 0 skipped, 0 warnings in 1 projects (unknown)
Exit code: 1
```

### Integration Tests (`InsightsIntegrationTests.cs`)
```
rtk dotnet test --filter InsightsIntegration

Same build errors — shared project cannot compile.
Additional runtime failures would be:
  - insights, radarData, insightsStale properties missing from AnalyticsResponse DTO
  - InsightGeneratorService.Generate() static method missing

fail dotnet test: 0 passed, 1 failed, 0 skipped in 1 projects
Exit code: 1
```

## Failure Classification

| Test | Failure Type | Failure Reason |
|---|---|---|
| `Generate_StoreScoreWellAboveAreaAvg_ReturnsPositiveInsight` | ✅ Good RED | `InsightGeneratorService` class does not exist |
| `Generate_StoreScoreWellBelowAreaAvg_ReturnsWarningInsight` | ✅ Good RED | `InsightGeneratorService` class does not exist |
| `Generate_AllFiveRulesFire_ReturnsMaxThreeInsights` | ✅ Good RED | `InsightGeneratorService` class does not exist |
| `Generate_LessThanThreeCategories_ReturnsNullRadarData` | ✅ Good RED | `InsightGeneratorService` class does not exist |
| `Generate_TotalAuditsBelow3_ReturnsSingleInfoInsight` | ✅ Good RED | `InsightGeneratorService` class does not exist |
| `GetAnalytics_SparseStore_ReturnsSingleInfoInsightAndNullRadarData` | ✅ Good RED | `insights` property missing on `AnalyticsResponse` |
| `GetAnalytics_StaleBenchmark_ReturnsInsightsStaleTrue` | ✅ Good RED | `insightsStale` property missing on `AnalyticsResponse` |
| `GetAnalytics_NoBenchmarkRow_ReturnsEmptyInsightsAndNullRadarData` | ✅ Good RED | `insights` property missing on `AnalyticsResponse` |
| `GetAnalytics_FullBenchmarkExists_ReturnsPopulatedRadarData` | ✅ Good RED | `radarData` property missing on `AnalyticsResponse` |
| `GetAnalytics_AfterSlice2Extension_StillReturnsKpisTrendSectionBreakdown` | ✅ Good RED | `insights` property missing on `AnalyticsResponse` |

## What the Builder Must Implement

1. **`Dtos.cs`** — Add `ActionableInsight`, `RadarData`, `InsightResult` records; extend `AnalyticsResponse` with 3 new fields
2. **`InsightGeneratorService.cs`** — New static class with `Generate(...)` method implementing 5 heuristic rules + `.Take(3)` cap
3. **`GetAnalytics.cs`** — Read `AreaBenchmarkSnapshot`, call `InsightGeneratorService.Generate()`, return enriched `AnalyticsResponse`

## Commands to Run
```bash
# Unit tests (no DB, fast)
rtk dotnet test --filter InsightGenerator server/tests/Checkly.Api.Tests

# Integration tests (DB required)
rtk dotnet test --filter InsightsIntegration server/tests/Checkly.Api.Tests
```
