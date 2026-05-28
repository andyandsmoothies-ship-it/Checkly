# Test Contracts: Golden Metrics MVP Slice 2 Flutter KPI Card Promotion ATDD

This document serves as the formal ATDD contract for Slice 2 of the Golden Metrics MVP, establishing the Average Time to Resolve (Avg TTR Days) KPI card layout, state thresholds, zero guards, and automated widget tests.

## Input Lineage

- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\implementation_plan_20260528_200757_golden-metrics-slice2_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`

## Architecture Flow

```
   [Chain KPIs Payload] 
             │
             ├─► avgTtrDays == 0.0 or < 0.0  ──► [Displays "N/A", no PillChip]
             ├─► avgTtrDays <= 7.0           ──► [Displays "${value} days", Green PillChip]
             ├─► avgTtrDays <= 14.0          ──► [Displays "${value} days", Yellow PillChip]
             └─► avgTtrDays > 14.0           ──► [Displays "${value} days", Red PillChip]
```

## Test Scenario Catalog

| ID | Name | Objective | Target Widget / Component | Expected Outcome |
|:---|:---|:---|:---|:---|
| **TC-S2-01** | Standard Resolution Day Display | Verify KPI Card displays "Avg TTR Days" label and "4.2 days" value when `avgTtrDays: 4.2`. | `BodKpiGrid` | Renders "4.2 days" |
| **TC-S2-02** | Zero State Guard | Verify KPI Card displays "N/A" rather than "0.0 days" when `avgTtrDays: 0.0`. | `BodKpiGrid` | Renders "N/A" |
| **TC-S2-03** | Speedometer Pill Thresholds | Verify KPI Card renders correct green (≤7d), yellow (≤14d), and red (>14d) `PillChip` indicators. | `BodKpiGrid` / `PillChip` | Correct PillChip color |
| **TC-S2-04** | Grid Regression Check | Verify existing KPI cards (Completion Rate, Open APs, Active Stores, Total Auditors) remain intact. | `BodKpiGrid` | All cards visible |
| **TC-S2-05** | Viewport Layout Safety | Verify grid does not overflow or clip when rendering in standard narrow viewports. | `BodKpiGrid` | No layout overflow |
| **TC-S2-06** | Negative Guard | Verify negative `avgTtrDays` values are caught, defaulting to `0.0` (rendering `"N/A"`). | `BodKpiGrid` | Renders "N/A" |
| **TC-S2-07** | Extreme Value Scalability | Verify extremely large values (e.g., `999.9`) scale gracefully without layout clipping. | `BodKpiGrid` | Scales cleanly |

## Automated Test Implementations (RED Suite)

The automated tests asserting this contract have been authored and verified to be **RED** (failing) for the correct semantic reasons (i.e., widget doesn't yet render the `Avg TTR Days` card).

- **File**: [bod_drilldown_sheets_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/widgets/bod_drilldown_sheets_test.dart)
- **Tests Added**:
  - `TC-S2-01: BodKpiGrid displays Avg TTR Days and a non-zero value format`
  - `TC-S2-02: BodKpiGrid displays N/A when avgTtrDays is exactly 0.0`
  - `TC-S2-03: BodKpiGrid displays correct colored PillChips for different TTR limits`
  - `TC-S2-06: BodKpiGrid treats negative avgTtrDays value as 0.0 and shows N/A`
  - `TC-S2-07: BodKpiGrid with extremely large value handles layouts cleanly at 400px width`

## Verification Run Status

The test runs were executed and failed specifically on the newly introduced tests due to the absence of the `Avg TTR Days` KPI card:

```
Test Failure:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Avg TTR Days": []>
   Which: means none were found but one was expected
```

These failures guarantee that the tests are **RED for the correct reasons** and are ready to be satisfied by the incoming Builder agent.

## Forensic Evidence

- **[COMMAND]** `cmd /c rtk flutter test test/features/analytics/widgets/bod_drilldown_sheets_test.dart`
- **[FILE_UPDATE]** `test/features/analytics/widgets/bod_drilldown_sheets_test.dart`
