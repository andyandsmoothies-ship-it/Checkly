# Walkthrough: SL-2 Phase B3 (Flutter Layer)

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260519_075200_sl2_province_benchmark.md`

## Decision Log
- **Province Dropdown Filter (Proposed & Implemented)**: Swapped "Area" filter option for "Province" string filter dropdown in `AnalyticsFilterSheet`. Dropdown values load directly from unique, sorted values of the `CachedStores.addressProvince` SQLite column.
- **Offline Drift Fallback Integration (Proposed & Implemented)**: Implemented offline `loadFromDrift` handling in `analytics_drift_loader.dart` to filter submissions by the store's `addressProvince` matching the chosen selectedProvince.
- **Parametric API Mapping (Proposed & Implemented)**: Replaced `areaId` Guid parameter with `province` string parameter in the typed `AnalyticsApiService.getAnalytics()` call to align with the backend's new route query parameter.

## Verification Handoff
1. The Flutter UI compiles cleanly without any legacy code references (`areaId`/`selectedArea`/`areaNames`).
2. Selecting a province on the filter drawer correctly applies the `selectedProvince` constraint on both API queries (online mode) and Drift SQLite sub-select matches (offline mode).
3. The horizontal scrollable chip bar renders a `Province: {name}` chip for active filter visibility.

<test_trace>
01:03 +543: All tests passed!
Exit code: 0
</test_trace>

<forensic_evidence>
Executed `rtk flutter test`
Executed `rtk flutter analyze`
</forensic_evidence>

## Gotcha Protocol
- **Gotcha Proposed**: In `lib/GEMINI.md` -> Dropdown and Filter Naming consistency. When filtering dashboard KPIs or analytical reports by geographical groupings, ensure that frontend widgets map exactly to `addressProvince` rather than `areaId` or `areaName` constants. This guarantees proper coordination with backend-seeded province snapshots.
