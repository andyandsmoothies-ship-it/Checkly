<latent_space_scratchpad>
## Client Bridge & Caching Guard
- Mapping display names (e.g., "0-30 Days") to standardized query parameters (e.g., "0-30d") is the biggest failure point for developers.
- Mitigation: Add case-insensitive string parsing in `loadApDetails` to ensure "0-30 days", "0-30 Days", "0-30d" all cleanly map to "0-30d".
- Implement robust `.fromJson` parsing in Flutter data models to ensure data models support both C# field names (`ageInDays`) and potential legacy names (`overdueDays`).
- Use mocktail to mock `BodAnalyticsApiService` to guarantee clean isolation in unit tests.
</latent_space_scratchpad>

# Implementation Plan: BOD Analytics - Slice 2 Client Bridge Fix

**Workflow:** /analyze-feature | **ShortID:** 453a8146 | **ConversationID:** 453a8146-beae-4db5-80db-588a20479470
**Date:** 2026-05-25T11:45:00+07:00

---

## Input Lineage

**Source Requirements:** `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\analysis_epic_20260525_105400_453a8146_bod_drilldown_453a8146-beae-4db5-80db-588a20479470.md` (specifically referencing Slice 2 details).

---

## Executive Summary & Out of Scope

Slice 2 establishes the Client Bridge by removing the mock action plan details and integrating real network communication in the Flutter client. It also builds three new API methods and manager commands required by the upcoming drill-down sheets.

### Out of Scope:
- UI layout or rendering of sheets (Slice 3).
- Gestures and navigation wiring to open sheets (Slice 4).
- Server-side modifications (Slice 1).

---

## System Context

- **Dio APIs Integrated**:
  - `GET /api/analytics/bod/ap/{bucket}`
  - `GET /api/analytics/stores/{storeId}/bod-summary`
  - `GET /api/analytics/bod/category/{name}`
- **Models Built**:
  - `ApDetailEntry`
  - `StoreBodSummary`
  - `RecentAuditEntry`
  - `CategoryScoreEntry`
  - `CategoryStoreEntry`
- **Dependency Injection**: Leverages existing GetIt registrations for `BodAnalyticsApiService` and `BodAnalyticsManager`.

---

## Lifecycle Context

Presentation states managed in `BodAnalyticsManager` for the new details:
- **Success**: Data fetched, loading = `false`, target detail model is populated, and `notifyListeners()` is called.
- **Loading**: Set loading = `true` and trigger `notifyListeners()` before the API request commences.
- **Error**: Fetch fails, loading = `false`, error string is set, model is reset to default (`[]` or `null`), and `notifyListeners()` is called.
- **Empty**: If the backend returns empty arrays, models will contain empty lists with status code `200 OK`.

---

## Constraint Traceability

| Source Constraint | Target Test ID | Verification Method |
|---|---|---|
| AP bucket display name "0-30 Days" maps to API "0-30d" | C2-TEST-01 | Call `loadApDetails("0-30 Days")` -> verify Dio requests `/bod/ap/0-30d` |
| AP bucket display name "90+ Days" maps to API "90d+" | C2-TEST-02 | Call `loadApDetails("90+ Days")` -> verify Dio requests `/bod/ap/90d+` |
| AP details populated successfully into list | C2-TEST-03 | Mock API response -> verify `apDetails` list matches |
| AP details loading failure resets list & sets error | C2-TEST-04 | Mock API throws -> verify `apDetails` is empty and error set |
| Store detail loaded and parsed correctly | C2-TEST-05 | Mock API response -> verify `storeDetail` fields match DTO |
| Store detail error resets data and sets error | C2-TEST-06 | Mock API throws -> verify `storeDetail` is null and error set |
| Category detail worst stores loaded and parsed | C2-TEST-07 | Mock API response -> verify `categoryDetail` matches DTO |
| Auditor productivity detail filtered client-side | C2-TEST-08 | Mock API returns list -> verify filter by `auditorId` works |

---

## Test Contracts

### C2-TEST-01: AP Bucket Normalization Flow
- **Description**: Verifies that any variant of display names is normalized to server standard.
- **Assertion**:
  - `loadApDetails("0-30 Days")` -> Expect service call to `getApBucketDetail("0-30d")`.
  - `loadApDetails("31-60 Days")` -> Expect service call to `getApBucketDetail("31-60d")`.
  - `loadApDetails("61-90 Days")` -> Expect service call to `getApBucketDetail("61-90d")`.
  - `loadApDetails("90+ Days")` -> Expect service call to `getApBucketDetail("90d+")`.

### C2-TEST-02: AP Details List Population
- **Description**: Verifies success path for AP bucket detail lookup.
- **Assertion**: Mock API response returns `List<ApDetailEntry>`. Expect manager `apDetails` matches mock data, `isApDetailLoading` is false, and listeners notified.

### C2-TEST-03: AP Details Error Path
- **Description**: Verifies error handling inside manager for AP lookup.
- **Assertion**: Mock API throws `DioException`. Expect manager `apDetails` is empty list, `isApDetailLoading` is false, and error message is populated.

### C2-TEST-04: Store BOD Summary Loading
- **Description**: Verifies store summary fetch and mapping.
- **Assertion**: Call `loadStoreDetail("id")`. Expect `isStoreDetailLoading` is true during call, then false, and `storeDetail` contains correct name and lists.

### C2-TEST-05: Category Detail Loading
- **Description**: Verifies worst stores category fetch.
- **Assertion**: Call `loadCategoryDetail("name")`. Expect `isCategoryDetailLoading` is false, and `categoryDetail` matches mocked store performance entries.

### C2-TEST-06: Client-Side Auditor Filtering
- **Description**: Verifies auditor lookup.
- **Assertion**: Call `loadAuditorDetail("Jane Smith")`. Expect API returns multiple records. Manager filters list to isolate "Jane Smith" and populates `auditorDetail`.

---

## Test Fixture & Payloads

### mock `ApDetailEntry` response payload:
```json
[
  {
    "id": "11111111-2222-3333-4444-555555555555",
    "criteriaLabel": "Temperature Logs",
    "storeName": "Central Market",
    "managerName": "Andy Manager",
    "ageInDays": 12
  }
]
```

---

## Tools & Commands

- **Skills**: `flutter-architecture`, `testing-strategy`
- **Verification Commands**:
  - Run all Flutter analytical unit tests:
    `cmd /c rtk flutter test test/features/analytics/manager/bod_analytics_manager_test.dart`

---

## Proposed Changes

### 1. `lib/features/analytics/manager/bod_analytics_data.dart` [MOD]
- Add new C# matching model classes:
  - `ApDetailEntry` (with legacy fallback for `overdueDays` mapping to `ageInDays`)
  - `StoreBodSummary`
  - `RecentAuditEntry`
  - `CategoryScoreEntry`
  - `CategoryStoreEntry`

### 2. `lib/features/analytics/services/bod_analytics_api_service.dart` [MOD]
- Add API methods:
```dart
  Future<List<ApDetailEntry>> getApBucketDetail(String bucketName) async {
    final response = await _dio.get('/analytics/bod/ap/$bucketName');
    final data = response.data as List<dynamic>;
    return data.map((e) => ApDetailEntry.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<StoreBodSummary> getStoreBodSummary(String storeId) async {
    final response = await _dio.get('/analytics/stores/$storeId/bod-summary');
    return StoreBodSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CategoryStoreEntry>> getCategoryDetail(String name) async {
    final response = await _dio.get('/analytics/bod/category/$name');
    final data = response.data as List<dynamic>;
    return data.map((e) => CategoryStoreEntry.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<dynamic>> getAuditorProductivity() async {
    final report = await getReport();
    return report.auditorProductivity;
  }
```

### 3. `lib/features/analytics/manager/bod_analytics_manager.dart` [MOD]
- Add loading state fields, getters, and getters for:
  - `_isApDetailLoading`, `_apDetails`
  - `_isStoreDetailLoading`, `_storeDetail`
  - `_isCategoryDetailLoading`, `_categoryDetail`
  - `_isAuditorDetailLoading`, `_auditorDetail`
- Remove the hardcoded mock database lookup from `loadApDetails` and rewrite it to call `_api.getApBucketDetail()` using normalized bucket names.
- Implement `loadStoreDetail()`, `loadCategoryDetail()`, and `loadAuditorDetail()`.

### 4. `test/features/analytics/manager/bod_analytics_manager_test.dart` [MOD]
- Add new test cases mapping `C2-TEST-01` through `C2-TEST-06` using `mocktail` and `fakeAsync`.

---

## Concept Diagram

```
[BodAnalyticsManager] ──► calls ──► [BodAnalyticsApiService] ──► calls ──► [Dio HTTP REST Client]
        │                                                                         │
        ├─► loadApDetails() ───────► api.getApBucketDetail(normalizedBucket) ─────┼─► /api/analytics/bod/ap/{bucket}
        ├─► loadStoreDetail() ─────► api.getStoreBodSummary(storeId) ─────────────┼─► /api/analytics/stores/{id}/bod-summary
        ├─► loadCategoryDetail() ──► api.getCategoryDetail(categoryName) ─────────┼─► /api/analytics/bod/category/{name}
        └─► loadAuditorDetail() ───► api.getAuditorProductivity() ────────────────┼─► /api/analytics/bod (Filters client-side)
```

---

## Execution Slices

### Slice 1: Models & API Client Expansion
- **Summary**: Implement all new Flutter classes inside `bod_analytics_data.dart` and add Dio network methods to `bod_analytics_api_service.dart`.
- **Value**: Builds foundational data models and standard HTTP client interface mapping backend DTO schemas.
- **Entry State**: Flutter app builds cleanly.
- **Exit State**: Both files build with zero compilation errors.
- **Scope**: `bod_analytics_data.dart`, `bod_analytics_api_service.dart` (2 files).

### Slice 2: Manager Wiring & Unit Test Suite
- **Summary**: Replace the synchronous mock logic inside `bod_analytics_manager.dart` with new real network calls, normalizations, and load methods. Expand `bod_analytics_manager_test.dart` to verify all test contracts under mock API conditions.
- **Value**: Completes business logic wiring and guarantees correctness against all normalization bounds.
- **Entry State**: Slice 1 builds cleanly.
- **Exit State**: Entire Dart unit test suite passes successfully.
- **Scope**: `bod_analytics_manager.dart`, `bod_analytics_manager_test.dart` (2 files).

---

## Handoff Block

- **Implementation Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_453a8146_slice2_453a8146-beae-4db5-80db-588a20479470.md`

### Action Sequence:
- **Slice 1**: Plan -> Write Unit Tests -> Build
  - Target: Execute Route 2 (Unit Tests First). Add the unit tests in `bod_analytics_manager_test.dart` first, verify compilation, then implement the C# endpoints/models.

**Please execute slices ONE AT A TIME.** Do not combine slices.
