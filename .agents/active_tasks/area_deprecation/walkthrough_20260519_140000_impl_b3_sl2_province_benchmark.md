# Walkthrough: Phase B3 - Flutter Layer (Province Analytics)

## Changes Made
Phase B3 of the `sl2_province_benchmark` implementation plan successfully transitioned the Flutter analytics frontend from Area-based resolution to Province-based resolution.

*   **`analytics_api_service.dart`**:
    *   Updated the `getAnalytics()` method to accept `province` as a `String?` parameter instead of `areaId`.
*   **`analytics_data.dart`**:
    *   Renamed `areaNames` to `provinceNames` (type `List<String>`).
*   **`analytics_manager.dart`**:
    *   Refactored all references from `selectedArea` to `selectedProvince`.
    *   Switched the analytics load API call to map `selectedProvince` into the `province` query parameter.
*   **`analytics_drift_loader.dart`**:
    *   Modified the offline query filtering to inspect `addressProvince` instead of `areaName` when fetching stored audits for the active province.
*   **`analytics_filter_sheet.dart`** & **`analytics_filter_chips.dart`**:
    *   Updated the UI text and variable bindings to show "Province" instead of "Area".
*   **Tests (`test/features/analytics/...`)**:
    *   Updated the mock configurations in `analytics_manager_test.dart`, `analytics_page_test.dart`, and `analytics_api_service_test.dart` to match the new `province` and `provinceNames` properties.
    *   Updated `analytics_drift_loader_test.dart` to rely on `addressProvince` for local test seeding instead of `areaName`.

## Testing & Verification
### 1. Flutter Build
```
rtk flutter build apk --debug
```
- **Result:** Success. 0 compile errors after the property renaming across widgets and managers.

### 2. Flutter Unit Tests
```
rtk flutter test test/features/analytics
```
- **Result:** All 22 tests within the analytics feature passed successfully, confirming both online and offline resolution paths are solid with the new province logic.

### 3. Backend Test Suite Verification
```
rtk dotnet test
```
- **Result:** Executed backend suite to ensure API layer changes hadn't drifted out of sync. Tests remain completely Green.

## Validation Results
The analytics domain is now fully executing against the `address_province` column introduced in SL-1. The frontend no longer requests `areaId`, and properly populates its dropdowns using `addressProvince` caching logic from Drift, ensuring full compatibility with the new `province_benchmark_snapshots` backend strategy. Phase B3 is fully verified and complete.
