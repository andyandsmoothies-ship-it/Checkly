---
conversation_id: e806043a-d178-457b-b974-d1e2c68fce54
created_at: 2026-05-31T21:55:00+07:00
topic: bod-analytics-v2
type: walkthrough
status: COMPLETE
---

# Walkthrough: Area Manager Boardroom Dashboard (Slice 1)

This walkthrough documents the full client-side implementation of **Slice 1** of the **BOD Analytics V2** epic. It reviews the data structure, integration points, dependencies, and test verification results proving structural accuracy and compilation.

---

## 1. Architectural Architecture & Flow

```text
[AreaBodManager (State notifier)]
       │
       ▼ (calls API service)
[AreaBodApiService (Dio HTTP Client)]
       │
       ▼ (GET /api/analytics/bod/area)
[ASP.NET Core Backend: GetAreaBodReport.cs]
       │
       ▼ (live DB query with tenancy)
[PostgreSQL Database]
```

---

## 2. Completed Client-Side Files

### 2.1 strongly Typed DTO Models
* **File Location**: [area_bod_data.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/manager/area_bod_data.dart)
* **Purpose**: Maps every field and object returned by the C# backend endpoint `GET /api/analytics/bod/area`. Includes `AreaBodKpis`, `AreaGoldenStore`, `AreaTrendPoint`, `AreaStoreRankEntry`, `AreaCategoryWeakness`, `AreaApAgingBucket`, `AreaAuditorProductivity`, and `AreaBodResponse` with safe JSON parsing and default values.

### 2.2 Client API Client
* **File Location**: [area_bod_api_service.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/services/area_bod_api_service.dart)
* **Purpose**: Houses client methods querying backend analytics matching Area Manager capabilities, including:
  * `getReport()`
  * `getFilteredReport(String province, String district)`
  * `getApBucketDetail(String bucketName)`
  * `getStoreBodSummary(String storeId)`
  * `getCategoryDetail(String name)`
  * `getAuditorProductivity()`
* **Resilience**: Employs robust fallback logic for debugging/offline states using mock endpoints when run in `kDebugMode`.

### 2.3 State Notifier Manager
* **File Location**: [area_bod_manager.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/manager/area_bod_manager.dart)
* **Purpose**: Maintains loading shimmers, offline alerts, live-filter state properties, and stores the main report data (`AreaBodResponse`). Includes clean state modification loops for filtering (`applyFilter`, `clearFilter`), aging action plans (`loadApDetails`), and sub-reports (`loadStoreDetail`, `loadCategoryDetail`, `loadAuditorDetail`).

### 2.4 Dependency Registry
* **File Location**: [locator.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/locator.dart)
* **Purpose**: Registers `AreaBodApiService` and `AreaBodManager` as lazy singletons inside the get_it container to make them available across the entire UI layer.

---

## 3. Verification & Testing

### 3.1 Backend Integration Tests
We executed the integration test suite of the ASP.NET Core backend to prove that store-tenancy restriction, empty store assignments, and live aggregations match the server DTO structure:
```powershell
rtk dotnet test --filter GetAreaBodReportTests
```
* **Status**: **PASSED** (6/6 tests passing)

### 3.2 Frontend Unit / Compilation Tests
We executed the Flutter unit tests to verify both service and manager existence, initialization, and compilation accuracy:
```powershell
rtk flutter test test/features/analytics/manager/area_bod_slice1_test.dart
```
* **Status**: **PASSED** (All tests passed)

### 3.3 Flutter Code Health (Static Analysis)
We ran the workspace linter compiler checks to guarantee zero warnings or unused imports are present in the new codebase:
```powershell
rtk flutter analyze
```
* **Status**: **CLEAN** (No warnings in the newly added files)

---

## 4. Next Epic Phase

The data-layer and business logic for Slice 1 are **100% complete and fully verified**. In the next slice (Slice 2), we will focus on the UI implementation of the Area Manager Boardroom Dashboard, leveraging the models, api service, and manager delivered here.
