# Test Contracts: Golden Metrics MVP Slice 1 Backend Archetype Filter Gate

This document serves as the formal ATDD contract for Slice 1 of the Golden Metrics MVP, establishing the template archetype filter gate behavior and its corresponding automated verification suite.

## Architecture Flow

```
   [Submission Payload] 
            │
            ├─► Template.Type == "QC"       ──► [INCLUDED in Leaderboard]
            ├─► Template.Type == "General"  ──► [EXCLUDED from Leaderboard]
            └─► Template.Type == null       ──► [INCLUDED in Leaderboard (Defensive Fallback)]
```

## Test Scenario Catalog

| ID | Name | Objective | Target Path | Expected Outcome |
|:---|:---|:---|:---|:---|
| **TC-S1-01** | QC Store Nightly | Verify stores with QC template submissions are included in nightly calculation. | `BodReportCalculator` / Nightly Job | Included |
| **TC-S1-02** | QC Store Live | Verify stores with QC template submissions appear in the dynamic live leaderboards. | `GetBodReport` Live Path | Included |
| **TC-S1-03** | General Store Calculator | Verify stores with General template submissions are excluded from nightly calculations. | `BodReportCalculator` / Nightly Job | Excluded |
| **TC-S1-04** | General Store Endpoint | Verify stores with General template submissions are excluded from the live regional leaderboards. | `GetBodReport` Live Path | Excluded |
| **TC-S1-05** | Null Template Fallback | Verify submissions with null TemplateId/Type are treated as QC (ScoredAudit) defensively. | `BodReportCalculator` / Nightly Job | Included |
| **TC-S1-06** | Province Live Filter | Verify dynamic regional leaderboards properly filter out General stores by province. | `GetBodReport` Live Path | Excluded |

## Automated Test Implementations (RED Suite)

The automated tests asserting this contract have been physically authored and verified to be **RED** (failing) for the correct semantic reasons (i.e. currently including "General" template types).

### 1. Daily Nightly Snapshot Test Suite
- **File**: [BodReportCalculatorArchetypeTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/BodReportCalculatorArchetypeTests.cs)
- **Tests**:
  - `ComputeDailyReport_QCStore_IncludedInTopBottomCalculation` (Asserts `TC-S1-01`/`TC-S1-03`)
  - `ComputeDailyReport_GeneralStore_ExcludedFromTopBottomCalculation` (Asserts `TC-S1-04`)
  - `ComputeDailyReport_NullTemplateId_TreatedAsQCFallback` (Asserts `TC-S1-05`)

### 2. Live Dynamic Province Endpoint Suite
- **File**: [BodAnalyticsFilteredEndpointTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsFilteredEndpointTests.cs)
- **Tests**:
  - `GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot` (Asserts end-to-end integration via nightly worker trigger)
  - `GetBodReport_WithProvinceFilter_ExcludesGeneralTemplateStoresFromLeaderboard` (Asserts `TC-S1-02`/`TC-S1-06` on dynamic live regional paths)

## Verification Run Status

The test suite runs were executed and captured via `rtk dotnet test` and resulted in expected failures on the exclusion checks:

1. `BodReportCalculatorArchetypeTests.ComputeDailyReport_GeneralStore_ExcludedFromTopBottomCalculation`
   - **Reason for Failure**: The General template store was incorrectly included in nightly leaderboards.
2. `BodAnalyticsFilteredEndpointTests.GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot`
   - **Reason for Failure**: The General template store was incorrectly included in the nightly snapshot payload.
3. `BodAnalyticsFilteredEndpointTests.GetBodReport_WithProvinceFilter_ExcludesGeneralTemplateStoresFromLeaderboard`
   - **Reason for Failure**: The General template store was incorrectly included in the live province leaderboard.

These failures guarantee that the tests are **RED for the correct reasons** and are ready to be satisfied by the incoming Builder agent.

<test_trace>
  Failed Checkly.Api.Tests.Features.Analytics.BodReportCalculatorArchetypeTests.ComputeDailyReport_GeneralStore_ExcludedFromTopBottomCalculation [114 ms]
  Error Message:
   Expected General template store to be excluded from nightly leaderboard calculations.
  Stack Trace:
     at Checkly.Api.Tests.Features.Analytics.BodReportCalculatorArchetypeTests.ComputeDailyReport_GeneralStore_ExcludedFromTopBottomCalculation() in C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Analytics\BodReportCalculatorArchetypeTests.cs:line 184

  Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsFilteredEndpointTests.GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot [1 s]
  Error Message:
   Expected the General template store to be excluded from topStores.
  Stack Trace:
     at Checkly.Api.Tests.Features.Analytics.BodAnalyticsFilteredEndpointTests.GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot() in C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Analytics\BodAnalyticsFilteredEndpointTests.cs:line 544

  Failed Checkly.Api.Tests.Features.Analytics.BodAnalyticsFilteredEndpointTests.GetBodReport_WithProvinceFilter_ExcludesGeneralTemplateStoresFromLeaderboard [6 s]
  Error Message:
   Expected the General template store to be excluded from live topStores.
  Stack Trace:
     at Checkly.Api.Tests.Features.Analytics.BodAnalyticsFilteredEndpointTests.GetBodReport_WithProvinceFilter_ExcludesGeneralTemplateStoresFromLeaderboard() in C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Analytics\BodAnalyticsFilteredEndpointTests.cs:line 672
</test_trace>

<forensic_evidence>
[COMMAND] cmd /c "rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter FullyQualifiedName~Archetype"
[COMMAND] cmd /c "rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter FullyQualifiedName~ExcludesGeneral"
[FILE_WRITE] BodReportCalculatorArchetypeTests.cs
[FILE_UPDATE] BodAnalyticsFilteredEndpointTests.cs
</forensic_evidence>
