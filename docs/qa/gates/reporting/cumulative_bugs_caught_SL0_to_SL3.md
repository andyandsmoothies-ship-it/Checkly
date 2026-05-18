# Cumulative Test Quality & Bugs Caught (Slice 0 - Slice 3)

This document aggregates all bugs, edge cases, and test quality issues caught during the verification (`/verify`) phase across the entire Analytics & Reporting epic (Slice 0 through Slice 3).

## Slice 0 (AnalyticsManager API Rewire)
- **Bug Caught (Warning)**: Code used a deprecated `withOpacity` method in Flutter.
  - **Resolution**: Fixed to ensure `flutter analyze` passed with 0 warnings.
  - **Reference**: `verification_20260517_160000_SL0_analytics_rewire.md`

## Slice 1 (Area Benchmark Worker)
- **Test Quality**: The logic was split into a separate stateless `AreaBenchmarkCalculator` and a background `AreaBenchmarkWorker`, heavily increasing testability without triggering long-running integrations.
- **Reference**: `verification_20260517_165700_VRF_benchmark_B1_B2.md`

## Slice 2 (Insight Generator Service)
- **Critical Logic Regression (Sparsity Guard)**: The implementation plan specified a sparsity guard to prevent generating insights for a store if it had fewer than 3 audits in the last 30 days (`totalAudits30d < 3`). The Builder incorrectly passed `snapshot.TotalAuditCount` (which is the **Area's** total audit count) to the `InsightGeneratorService.Generate()` method instead of the store's audit count.
  - **Why tests missed it initially**: The integration test `GetAnalytics_SparseStore` was flawed. It seeded the database where the Area's total count was *also* below 3, causing the sparsity guard to fire, masking the bug.
  - **Resolution**: Fixed `GetAnalytics.cs` to pass the local `totalAudits` variable, and updated the integration test to properly isolate store count from area count.
  - **Reference**: `verification_20260518_063029_SL2_insight_generator.md`

## Slice 3 (Flutter Insight UI)
- **Missing Implementation**: The Builder implemented the UI code properly but completely skipped writing the widget tests and the manager parsing tests (FL-01 to FL-10) specified in the implementation plan.
  - **Resolution**: The Sentinel (Verify phase) implemented the missing tests (`insight_card_test.dart`, `insights_radar_chart_test.dart`, `analytics_page_test.dart`, `analytics_manager_test.dart`).
- **Framework Crash (`fl_chart` Constraint)**: The `fl_chart` `RadarChartData` component asserts that at least 3 categories must be provided. The test mock originally provided 2, causing an unhandled flutter framework exception.
  - **Resolution**: Updated mock data in tests to provide 3 categories (`'A'`, `'B'`, `'C'`).
- **Lazy Loading Test Failure (`FL-09`)**: `AnalyticsPage` utilizes a lazy-loaded `ListView`. The test failed because the `_StaleBanner` was off-screen and not rendered by the widget tree.
  - **Resolution**: Added `tester.drag(find.byType(ListView), const Offset(0, -1000))` to force the ListView to render the Insights section.
- **Hidden Element Test Failure (`FL-10`)**: The test failed because the scroll from `FL-09` was duplicated. The offline banner is at the top of the screen; scrolling down pushed it completely off-screen.
  - **Resolution**: Removed the scroll command for the offline banner test.
- **Data Model Compilation Error**: Missing `id` parameter in `ActionableInsight` mock models causing initialization failures in unit tests, since the model strictly maps `id` from JSON.
  - **Resolution**: Added dummy `id` values to tests.
  - **Reference**: `verification_20260518_071000_SL3_flutter_insight_ui.md`
