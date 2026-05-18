# Walkthrough: AnalyticsManager API Rewire (Slice 0)

## Overview
This walkthrough summarizes the completion of the "Slice 0" task for the Analytics Rewire initiative. The primary objective was to transition the `AnalyticsManager` from a local-only Drift SQLite implementation to an API-first approach, ensuring the existing Drift database logic serves as a robust offline fallback.

## Implementation Details

### 1. `AnalyticsManager` Updates
*   **Dependency Injection:** Injected `AnalyticsApiService` into the constructor.
*   **`load()` Strategy:** Rewritten to orchestrate the "API-first, Drift-fallback" flow. It attempts to fetch data via the API and, upon encountering a `DioException` (connection error), falls back to querying the local Drift SQLite database.
*   **State Management:** Introduced an `isOffline` boolean state flag to notify the UI when the application is operating in fallback mode.

### 2. `AnalyticsData` Model Expansion
*   Updated the model to support upcoming backend enhancements (e.g., Insights, Radar Charts).
*   Added defensive parsing for new nullable/empty fields (`insights`, `radarData`, `insightsStale`) to prevent breaking current UI implementations that consume partial API responses.
*   Created local stubs for `ActionableInsight` and `RadarData`.

### 3. UI Integration
*   Updated `analytics_page.dart` to conditionally display a warning banner ("⚠️ Insights require an internet connection.") above the filter chip bar when `_manager.isOffline` is true.
*   Replaced deprecated `withOpacity()` calls with `withValues(alpha: ...)` to clear flutter analyze warnings.

### 4. Dependency Injection (`locator.dart`)
*   Modified the `di.registerLazySingleton<AnalyticsManager>` registration to properly inject the `AnalyticsApiService` dependency.

### 5. Testing Enhancements
*   Created `MockAnalyticsApiService` for dependency injection during tests.
*   Configured the mock in the `setUp` block to throw a connection error by default. This ensures that all existing Drift-based test cases continue to pass and correctly exercise the offline fallback path.
*   Added two new specific test cases:
    *   **AR-01**: Verifies the online path successfully parses the API response and maps data to the `AnalyticsData` model.
    *   **AR-02**: Confirms the offline path gracefully catches `DioException` and falls back to Drift data.

## Verification
*   Executed `flutter analyze`: Passed with 0 issues after fixing deprecation warnings.
*   Executed `flutter test`: All tests in `analytics_manager_test.dart` passed successfully.

## Next Steps
The application is now prepared for Slice 1, where the API endpoint will be updated to serve the advanced metrics (Insights, Radar Chart) expected by the enhanced `AnalyticsData` model.
