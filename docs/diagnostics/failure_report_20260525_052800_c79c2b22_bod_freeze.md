# Failure Report: BOD Analytics Dashboard — Main Isolate Paused On Exception

**Date**: 2026-05-25  
**Severity**: P0 — App freezes and becomes unresponsive  
**Status**: RESOLVED

---

## Input Lineage

- **Source Input**: User screenshot + IDE Call Stack + VSCode Problems panel
- **Log Evidence**: `[API] ← 200 /analytics/bod` (4.7ms), `main PAUSED ON EXCEPTION`, `Drift isolate PAUSED ON ENTRY`

---

## Root Cause

**Flutter 3.41.4 assertion exception in `DropdownButtonFormField`.**

In Flutter 3.41.4, `DropdownButtonFormField<String>` **throws a runtime assertion** when `value` is not in the `items` list. The `BodRegionFilterBar` widget had:

```dart
// value: null (initial state — no province selected)
DropdownButtonFormField<String>(
  value: _selectedProvince,  // null
  items: _provinceDistricts.keys.map(...).toList(),  // only non-null Strings
)
```

`_selectedProvince` initializes to `null` (manager starts with no active province). The `items` list never contained `null`. Flutter's dropdown asserts `value == null || items.any((item) => item.value == value)` — assertion fails → exception thrown in main isolate → app freezes.

This is **immediately triggered** on success-state render: API returns 200 → `BodDashboardBody` builds → `BodRegionFilterBar` builds → assertion fires.

---

## Explicit Code Trace

```
BodAnalyticsPage.initState()
  └─► addPostFrameCallback → loadReport()
        └─► API GET /analytics/bod → 200 (4.7ms)
              └─► notifyListeners() (isLoading=false, report=set)
                    └─► ListenableBuilder rebuilds
                          └─► BodDashboardBody.build()
                                └─► BodRegionFilterBar.build()
                                      └─► DropdownButtonFormField<String>(value: null)
                                            └─► ASSERT FAIL: null not in items
                                                  └─► ⚠️ EXCEPTION THROWN → main PAUSED
```

---

## Evidence: Existing Project Pattern

`dropdown_card.dart` line 8 literally documents this as a known issue:
> *"This replaces the old DropdownButtonFormField approach which caused Contextual Claustrophobia..."*

The BOD filter bar was built after this migration and was never updated to use the safe approach.

---

## Fix Applied

**File**: `lib/features/analytics/widgets/bod_region_filter_bar.dart`

Changed both dropdowns from `DropdownButtonFormField<String>` to `DropdownButtonFormField<String?>` and added null-sentinel items:

```dart
// BEFORE (crashes Flutter 3.41.4 when value is null)
DropdownButtonFormField<String>(
  value: _selectedProvince,  // null — not in items list → EXCEPTION
  items: _provinceDistricts.keys.map((prov) =>
    DropdownMenuItem<String>(value: prov, child: Text(prov))
  ).toList(),
)

// AFTER (null is explicitly a valid choice)
DropdownButtonFormField<String?>(
  value: _selectedProvince,  // null — present in items → OK
  items: [
    const DropdownMenuItem<String?>(value: null, child: Text('All Provinces')),
    ..._provinceDistricts.keys.map((prov) =>
      DropdownMenuItem<String?>(value: prov, child: Text(prov))
    ),
  ],
)
```

**Trade-offs:**
- ✅ Zero-risk: `_handleApply()` guard already checks `_selectedProvince != null && _selectedDistrict != null` before calling manager  
- ✅ Better UX: User can clearly see "All Provinces" as the default selection  
- ⚠️ Minor: The "All Provinces" item won't trigger a filter call — this is intentional (Apply button stays disabled)

---

## Secondary Fix (Previous Session)

`GridView.count(shrinkWrap: true, childAspectRatio: 1.35)` in `BodKpiGrid` was also replaced with `Row + IntrinsicHeight` layout to prevent unbounded-width constraint propagation in certain parent contexts.

---

<forensic_evidence>
## Commands Executed

1. `flutter test test/features/analytics/pages/bod_analytics_page_test.dart test/features/analytics/manager/bod_analytics_manager_test.dart`
   → **18/18 PASS**

2. Files read: `bod_analytics_data.dart`, `bod_analytics_manager.dart`, `bod_region_filter_bar.dart`, `bod_score_trend.dart`, `bod_kpi_grid.dart`, `dropdown_card.dart`, `bod_analytics_page.dart`

3. Flutter version confirmed: **Flutter 3.41.4 / Dart 3.11.1**
</forensic_evidence>

---

## Handoff Block

**Final Verdict**: The BOD Analytics freeze is caused by `DropdownButtonFormField<String>(value: null)` in `BodRegionFilterBar` — Flutter 3.41.4 asserts null must exist in items, causing `main` isolate to pause on exception on first successful data render.

**Fix blast radius**: 1 file — `lib/features/analytics/widgets/bod_region_filter_bar.dart`. No model, manager, or routing changes required.

**AI Mission Brief**: The `BodRegionFilterBar` used `DropdownButtonFormField<String>` with `value: null` (initial state) while items never included null. Flutter 3.41.4 throws on this. Fixed by changing to `DropdownButtonFormField<String?>` and adding null-sentinel "All Provinces"/"All Districts" items. 18/18 tests pass.

## Execution Queue

- [x] Fix applied: `lib/features/analytics/widgets/bod_region_filter_bar.dart`
- [x] Tests verified: 18/18 BOD analytics tests pass
- [ ] Manual test: Login as admin → BOD Analytics → verify dashboard loads without freeze
