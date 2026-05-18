# Walkthrough: Flutter Insight UI — Phase A (Data Layer Split & Manager Fix)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_064918_SL3_flutter_insight_ui.md`

## Decision Log

| Decision | Proposed | Implemented | Reason |
|---|---|---|---|
| `fromJson` placement | Option A (inline in manager) or B (factory on model class) | **Option B** — factory constructors on `ActionableInsight` and `RadarData` | Clean, independently testable. FL-07/FL-08 can unit-test the parse without loading the manager. |
| Drift loader extraction | Private method `_loadFromDrift()` | Standalone top-level function `loadFromDrift({...})` in `analytics_drift_loader.dart` | Top-level function avoids needing a class instance; all filter state is passed as explicit named parameters — clearer blast radius. |
| Manager import updates | Import `analytics_data.dart` in all 3 consumers | No update needed for `analytics_page.dart` / `analytics_filter_sheet.dart` / `locator.dart` | They only reference `AnalyticsManager` by type, not `AnalyticsData`/`ActionableInsight`/`RadarData` directly. The manager barrel-exposes them transitively via return types. |
| Category count guard | Inline in `fromJson` or in manager | Guard **in manager** — `RadarData.fromJson()` creates the object; manager checks `candidate.categories.length >= 3` before assigning | Keeps `fromJson` pure (no business rules), while the sparsity check lives at the consumer. |

## Verification Handoff

QA steps for Phase A:
1. Open `analytics_manager.dart` — confirm it is ~193 lines (not 404).
2. Open `analytics_data.dart` — confirm `ActionableInsight.fromJson()` and `RadarData.fromJson()` exist.
3. Open `analytics_drift_loader.dart` — confirm `loadFromDrift(...)` is a top-level function taking all filter params.
4. Run `rtk flutter analyze lib/features/analytics/manager/` — must show **"No issues found"**.
5. Run `rtk flutter test test/features/analytics/` — must show **7 passed, 0 failed**.

## Phase A Acceptance Criteria Check
- [x] Manager calls `ActionableInsight.fromJson(e)` — NOT hardcoded `const []` (line 129)
- [x] `radarData` parses only when ≥ 3 categories (manager guards with `candidate.categories.length >= 3`)
- [x] `flutter analyze lib/features/analytics/manager/` → 0 warnings (**No issues found**)
- [x] All existing `flutter test lib/features/analytics/` tests still pass (**7 passed**)

## File Size Check (Anti-Collapse Gate)
| File | Lines | Status |
|---|---|---|
| `analytics_manager.dart` | ~193 | ✅ (<250) |
| `analytics_data.dart` | ~95 | ✅ (<250) |
| `analytics_drift_loader.dart` | ~168 | ✅ (<250) |

<test_trace>
Loading test/features/analytics/manager/analytics_manager_test.dart
+0: AnalyticsApiService — getAnalytics maps query parameters correctly and returns data
+1: AnalyticsManager computes basic KPIs from empty DB
+2: AnalyticsManager computes basic KPIs from empty DB
+3: AnalyticsManager computes KPIs accurately from populated DB
+4: AnalyticsManager applies filters correctly
+5: AR-01: AnalyticsManager online path - calls API and maps response
+6: AR-02: AnalyticsManager offline path - DioException triggers Drift fallback
+7: All tests passed!
</test_trace>

<forensic_evidence>
rtk flutter analyze lib/features/analytics/manager/
→ "No issues found! (ran in 55.1s)"

rtk flutter test test/features/analytics/
→ 7 passed, 0 failed, 0 skipped
</forensic_evidence>

## Gotcha Protocol
No new gotchas found. Existing Gotcha #14 (bounded `.limit(1000)`) is preserved in `analytics_drift_loader.dart`.
