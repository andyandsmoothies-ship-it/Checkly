<latent_space_scratchpad>
## Key Constraints Extracted from Epic

1. BLOCKING: `AnalyticsManager` currently NEVER calls `AnalyticsApiService`. It reads 100% from Drift.
2. `AnalyticsApiService` IS registered in `locator.dart` (line 273-274) — DI is wired, just not consumed.
3. `AnalyticsManager` is registered as a LazySingleton (line from locator search). Constructor only takes `AppDatabase?` — NO `AnalyticsApiService` injection. Must add it.
4. Offline fallback: The project has `AppError.fromDioException()` and `DioException` patterns. `AppError` has `isOfflineExpected` flag. On `DioException` → fall back to Drift path. Keep ALL the Drift query code — do not delete it.
5. New state field `isOffline` added to `AnalyticsManager` — the UI reads this to hide/show the insight banner.
6. `AnalyticsData` model must be extended with `List<ActionableInsight> insights` and `RadarData? radarData` and `bool insightsStale` — BUT the API response for these new fields doesn't exist yet (backend Slice 1+2 are not done).
   - **CRITICAL DECISION**: We must NOT hard-code the new DTO fields from a non-existent API. For Slice 0, the API returns the OLD shape. We just do the rewire for basic data. We add the new fields to the `AnalyticsData` model as nullable/empty lists so Slice 3 just fills them in. This prevents a breaking re-write later.
7. `AnalyticsPage` is 331 lines — ABOVE the 250 line soft limit but BELOW the 400 hard limit. No mandatory split required. But the File Size Rule says >250 lines requires a split STEP before adding features. However, Slice 0 touches the MANAGER, not the PAGE. The page only needs a minimal `isOffline` banner widget added. We can defer the page split to Slice 3.
8. The test file `analytics_manager_test.dart` constructs `AnalyticsManager(db: db)`. Adding `AnalyticsApiService` to the constructor means we MUST update the test fixture to provide a mock service. Rules say: do NOT change tests and main code in the same step. So: implementation plan must route to `/implement` first (add new fields), then separately tell the builder to update tests.
   - Actually re-reading the rule: "Never change a test and the main code in the exact same step." — the Builder can write the updated code; the test update is a SEPARATE step/TDD run.
   - Route decision: Slice 0 rewires the API call — this touches network layer. That means Route 3 (ATDD) should apply. BUT the Epic says Slice 0 route is `/analyze-feature → /implement` (Track A). The Epic is the authority. We follow it. The builder must ensure the existing Drift tests still pass; that is the regression proof.
9. `AnalyticsApiService.getAnalytics()` currently returns `Map<String, dynamic>`. We need to parse this into `AnalyticsData`. For Slice 0, only the existing fields (totalAudits, avgScore, etc.) need mapping. New insight fields will be empty lists/null.
10. The backend current `AnalyticsResponse` shape must be cross-checked. The Epic says it already returns `AnalyticsResponse` from `GetAnalytics.cs`. But the NEW fields (Insights, RadarData) are NOT there yet. So for Slice 0, the API response will have the OLD shape. We must parse defensively.
</latent_space_scratchpad>

# Implementation Plan: Slice 0 — AnalyticsManager API Rewire

## Input Lineage
- **Epic Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md`
- **Requirements**: `c:\Users\HP\Documents\GitHub\Checkly\docs\product\requirements_20260517_125659_REQ1_reporting.md`

---

## Executive Summary & Out of Scope

**Goal**: Rewire `AnalyticsManager.load()` to call `AnalyticsApiService` as the primary data source (online path), while keeping the full Drift SQLite path as an offline fallback. This is the prerequisite that makes Slices 1–3 possible.

**Why now?**: Without this rewire, adding `ActionableInsight` and `RadarData` to the backend DTO has no effect — the app never reads from the API.

### Out of Scope for this Slice
| What | Why |
|------|-----|
| `ActionableInsight`, `RadarData` DTO fields (populated) | Backend Slice 1 & 2 don't exist yet. Add as empty stubs only. |
| `AreaBenchmarkSnapshot` entity | Backend work — Slice 1 |
| `InsightGeneratorService` | Backend work — Slice 2 |
| Insight Cards UI, Radar Chart widget | Flutter UI — Slice 3 |
| Splitting `AnalyticsPage` (331 lines) | Deferred to Slice 3 (only manager is touched here) |

---

## System Context

| Dimension | Details |
|---|---|
| **Offline / Online** | Try API first. On `DioException` → fall back to Drift. Set `isOffline = true`. |
| **RBAC / PBAC** | `AnalyticsApiService` uses the shared `Dio` instance which already carries the JWT token from the auth interceptor. No PBAC changes in this slice. |
| **DI** | `AnalyticsApiService` is already registered as `LazySingleton` in `locator.dart`. `AnalyticsManager` registered as `LazySingleton` — needs `AnalyticsApiService` injected. |
| **API Shape (current)** | `GET /api/analytics` returns existing `AnalyticsResponse` fields. New insight fields don't exist yet. Must parse defensively (missing fields → null / empty list). |
| **Test Boundary** | Existing `analytics_manager_test.dart` seeds Drift and calls `load()`. After rewire, tests must inject a `MockAnalyticsApiService` that throws `DioException` to force the offline path, so all Drift assertions still pass. |

---

## Lifecycle Context

| State | UI Behaviour (after this slice) |
|---|---|
| **Loading** | `CircularProgressIndicator` (unchanged) |
| **Success (Online)** | Data shows. `isOffline = false`. Insight section hidden (backend not ready yet — stubs are empty). |
| **Offline (DioException)** | Falls back to Drift. `isOffline = true`. Page shows "⚠️ Insights require internet connection." banner. KPIs from local Drift. |
| **Error (non-network)** | `error` string set. Page shows `ChecklyEmptyState` with retry (unchanged). |
| **Empty** | `totalAudits == 0`. Empty state widget (unchanged). |

---

## Constraint Traceability

| # | Epic Constraint | Test Contract ID |
|---|---|---|
| C1 | API is primary source; Drift is offline fallback | AR-01 |
| C2 | `isOffline = true` when `DioException` caught | AR-02 |
| C3 | All existing filter logic preserved in offline path | AR-03 |
| C4 | No new package dependencies | AR-04 (architecture review only) |
| C5 | `AnalyticsData` extended with stub fields for future insights | AR-05 |
| C6 | `AnalyticsManager` DI receives `AnalyticsApiService` | AR-06 |
| C7 | Existing Drift tests still pass via mock API throwing offline | AR-07 |
| C8 | `insightsStale` flag from API response parsed defensively | AR-08 |

---

## Test Contracts

| ID | Scenario | Entry State | Expected Exit | Why It Fails First |
|---|---|---|---|---|
| AR-01 | `load()` online — calls API, maps response to `AnalyticsData` | Mock API returns valid JSON | `isOffline == false`, `data` not null | `AnalyticsManager` currently never calls API |
| AR-02 | `load()` offline — `DioException` from API triggers Drift fallback | Mock API throws `DioException(type: connectionError)` | `isOffline == true`, `data` populated from Drift | `isOffline` field doesn't exist yet |
| AR-03 | Filters applied after offline fallback still filter Drift data correctly | API throws, `selectedArea = 'North'` set | `data.totalAudits` reflects only North area submissions | Filters run on Drift path |
| AR-04 | No import of new packages added | `pubspec.yaml` | `pubspec.yaml` unchanged | Architectural guard |
| AR-05 | `AnalyticsData.insights` and `AnalyticsData.radarData` exist as empty stubs | Any `load()` call | `data.insights == []`, `data.radarData == null` | Fields don't exist yet |
| AR-06 | `AnalyticsManager` constructor accepts `AnalyticsApiService` | `locator.dart` and tests | DI wired; test passes mock | Constructor doesn't accept service yet |
| AR-07 | Existing Drift-seeded tests pass unchanged | Drift DB seeded with submissions | All KPI assertions pass | Tests construct `AnalyticsManager(db: db)` — will break when constructor changes |
| AR-08 | API response missing `insightsStale` field → defaults to `false` | API returns JSON without `insightsStale` key | `data.insightsStale == false` | Defensive parse not written yet |

---

## Test Fixture & Payloads

### API Response (Current Shape — used for AR-01)
```json
{
  "totalAudits": 14,
  "avgScore": 85.5,
  "openAPs": 3,
  "overdueAPs": 1,
  "completionRate": 92.5,
  "trend": [
    { "month": "2026-01", "avgScore": 82.0, "count": 4 },
    { "month": "2026-02", "avgScore": 85.5, "count": 5 }
  ],
  "categoryScores": [
    { "name": "Safety", "avgScore": 78.0, "auditCount": 6 }
  ]
}
```
*(Note: `insights`, `radarData`, `insightsStale` fields are absent — parse defensively as empty/null/false.)*

### Mock Service Fixtures
```dart
// AR-01: Happy path — online
class MockAnalyticsApiService extends Mock implements AnalyticsApiService {}

// In test setUp:
when(() => mockApi.getAnalytics(...)).thenAnswer((_) async => {
  'totalAudits': 14, 'avgScore': 85.5, 'openAPs': 3, ... // full shape above
});

// AR-02: Offline path
when(() => mockApi.getAnalytics(...)).thenThrow(
  DioException(type: DioExceptionType.connectionError, requestOptions: RequestOptions(path: ''))
);
```

---

## Tools & Commands

- **Skills needed**: `flutter-architecture` (PFA Manager pattern)
- **Test command**: `cmd /c rtk flutter test test/features/analytics/manager/analytics_manager_test.dart --reporter=expanded`
- **Full suite**: `cmd /c rtk flutter test --reporter=expanded`

---

## Proposed Changes

| Status | File | Change |
|--------|------|--------|
| `[MOD]` | `lib/features/analytics/manager/analytics_manager.dart` | Add `AnalyticsApiService` param; add `isOffline` state; add API call in `load()` with Drift fallback |
| `[MOD]` | `lib/locator.dart` | Pass `AnalyticsApiService` to `AnalyticsManager()` constructor |
| `[MOD]` | `lib/features/analytics/pages/analytics_page.dart` | Add offline banner widget (`isOffline` check) |
| `[MOD]` | `test/features/analytics/manager/analytics_manager_test.dart` | Inject `MockAnalyticsApiService`; add 2 new tests (AR-01, AR-02) |

### UI Routing Table (Minimal — AnalyticsPage change is additive only)

| Widget | Change | Overflow/Truncation | Route |
|--------|--------|---------------------|-------|
| Offline Banner | NEW — shown when `isOffline == true` | Single line, no overflow | No route (display only) |
| Existing KPI cards | Unchanged | Unchanged | Unchanged |

---

## Concept Diagram

```text
[AnalyticsPage.initState()]
  → _manager.load()
       │
       ├─── [TRY] AnalyticsApiService.getAnalytics(storeId, areaId, dateRange)
       │         │
       │         ├─ SUCCESS → parse JSON → AnalyticsData(insights:[], radarData:null)
       │         │            isOffline = false
       │         │
       │         └─ DioException (network/timeout/connectionError)
       │                    │
       │                    └─── FALLBACK: Run all Drift queries (existing logic)
       │                         isOffline = true
       │
       └─── [ALWAYS] notifyListeners()

[AnalyticsPage.build()]
  → if _manager.isOffline → show "⚠️ Insights require internet connection." banner
  → else → show existing KPI grid (unchanged)
  → (Insight Cards & Radar Chart shown in Slice 3)
```

---

## Execution Phase

**Complexity**: Medium  
**Reason**: The data flow pivot (Drift → API) is the hardest part. However, the Drift queries are preserved 1:1 as the fallback. The primary risk is the constructor change breaking the existing test fixture (mitigated by updating the test in the same phase).

### Entry State Required
- `AnalyticsManager` exists and works from Drift
- `AnalyticsApiService` is registered in DI (confirmed ✅)
- Backend `/api/analytics` endpoint returns the existing `AnalyticsResponse` shape (no new fields yet)

### Exit State Guaranteed
- `load()` calls `AnalyticsApiService` first (online) OR falls back to Drift (offline)
- `isOffline` flag is set correctly
- `AnalyticsData` has stub fields `insights: []`, `radarData: null`, `insightsStale: false`
- `AnalyticsPage` shows offline banner when `isOffline == true`
- All 3 existing tests pass + 2 new tests pass (AR-01, AR-02)

### Step-by-Step Instructions for Builder

**Step 1: Extend `AnalyticsData` model**

Add these fields to the `AnalyticsData` class (with defaults for backward compatibility with existing test constructors):
- `List<ActionableInsight> insights` (default `const []`)
- `RadarData? radarData` (default `null`)
- `bool insightsStale` (default `false`)

Also add the two stub data classes `ActionableInsight` and `RadarData` at the bottom of `analytics_manager.dart`. Keep them simple — they are placeholder structs until Slice 2 fills them:

```
class ActionableInsight {
  final String id;
  final String type;       // 'warning' | 'info' | 'positive'
  final String text;
  final String? actionRoute;
  const ActionableInsight({required this.id, required this.type, required this.text, this.actionRoute});
}

class RadarData {
  final List<String> categories;
  final List<double> storeValues;
  final List<double> regionalValues;
  const RadarData({required this.categories, required this.storeValues, required this.regionalValues});
}
```

**Step 2: Update `AnalyticsManager` constructor**

- Add `AnalyticsApiService? apiService` parameter.
- Resolve it from DI if null: `_api = apiService ?? _di<AnalyticsApiService>()`.
- Add `bool isOffline = false;` to the state fields.

**Step 3: Rewrite `load()` with API-first + Drift fallback**

The new `load()` flow:
1. Try `_api.getAnalytics(...)` with the active filter params mapped to the API signature.
2. On success: parse the JSON map into `AnalyticsData`. For missing new fields (`insights`, `radarData`, `insightsStale`), use safe defaults.
3. On `DioException`: catch it, set `isOffline = true`, run the full existing Drift query block (move it verbatim into the catch path — do NOT delete it).
4. All other exceptions: set `error = 'Failed to load analytics'` as before.

**Step 4: Update `locator.dart`**

Change the `AnalyticsManager` registration to inject `AnalyticsApiService`:
```dart
di.registerLazySingleton<AnalyticsManager>(
  () => AnalyticsManager(apiService: di<AnalyticsApiService>()),
);
```

**Step 5: Add offline banner to `AnalyticsPage`**

In the `ListView` children, BEFORE the filter chip bar, add:
```dart
if (_manager.isOffline)
  Container(
    // warning amber banner, one line, icon + text
    // "⚠️ Insights require an internet connection."
  ),
```

**Step 6: Update test file**

- Add `MockAnalyticsApiService extends Mock implements AnalyticsApiService`.
- Update `setUp` to create the mock and pass it to the constructor: `manager = AnalyticsManager(db: db, apiService: mockApiService)`.
- Configure the mock to throw `DioException(type: DioExceptionType.connectionError)` so ALL existing Drift tests still exercise the offline fallback path.
- Add 2 new tests: AR-01 (mock returns valid map → `isOffline == false`) and AR-02 (mock throws → `isOffline == true`, Drift data still populated).

### Pros & Cons of This Approach

| | Pros | Cons |
|---|---|---|
| **Drift as fallback (chosen)** | Zero risk of breaking offline-first. Existing tests prove it works. | Drift code duplicates API mapping logic temporarily. |
| **Delete Drift path, force online-only** | Simpler code | Violates offline-first architecture. Breaks all existing tests. NOT acceptable. |

---

<command_logs>
- findstr: `AnalyticsApiService` in `lib/` → confirmed: registered in `locator.dart` (lines 273-274), defined in `analytics_api_service.dart`, NOT imported in `analytics_manager.dart`
- findstr: `AnalyticsManager` in `lib/` → confirmed: `locator.dart` line registers as `LazySingleton(() => AnalyticsManager())` — NO service injection
- view_file: `analytics_manager.dart` (265 lines) — confirmed 100% Drift-based, no API call
- view_file: `analytics_api_service.dart` (26 lines) — confirmed wraps `GET /analytics` with query params
- view_file: `analytics_manager_test.dart` (229 lines) — confirmed constructs `AnalyticsManager(db: db)`, 3 tests all Drift-based
- view_file: `analytics_page.dart` (331 lines) — no offline banner exists
- view_file: `app_error.dart` — confirmed `AppError.fromDioException()` exists, `isOfflineExpected` flag exists
- grep: `isOffline` in `lib/` → found in `app_error.dart` and `error_display_service.dart` — NO existing `isOffline` in `AnalyticsManager` (new field needed)
- grep: `DioException` in features — existing pattern via `AppError` class
</command_logs>

---

## Handoff Block

### Summary for Builder
Rewire `AnalyticsManager.load()` so it calls `AnalyticsApiService` first and falls back to the existing Drift path when offline. Add `isOffline` state flag and stub data model fields (`insights`, `radarData`). Update DI and the test file.

### Execution Order

| Step | Target Phase | File | Route |
|------|-------------|------|-------|
| 1 | **Implementation Phase** | `analytics_manager.dart` + `locator.dart` + `analytics_page.dart` | `/implement` |
| 2 | **Implementation Phase (Test Update)** | `analytics_manager_test.dart` | `/implement` (test update, not TDD — rewire, not new logic) |

> Execute Step 1 and Step 2 **in that order**. Do not start Step 2 before Step 1 passes `flutter analyze`.

### Next Command
```
/implement c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260517_160000_SL0_analytics_rewire.md
```
