# Walkthrough: B3 — Flutter Layer (SL-1 Store Structured Address)

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_221700_sl1_store_address.md`
- **ATDD Test Contracts**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260518_223644_atdd_sl1_store_address.md`
- **B2 Walkthrough**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\area_deprecation\walkthrough_20260519_071700_impl_b2_sl1_store_address.md`

## System Context Diagram

```
Store Form Sheet (Flutter)
  on mount → fetchProvinces() → GET /api/reference/locations → _provinces = [...63]
  Province DropdownButtonFormField  ← replaces Area dropdown
  District / Ward / Street TextFields (free text)
  
  on save → updateStore(province, district, ward, street) → PUT /api/stores/{id}
          → createStore(province, district, ward, street) → POST /api/stores

StoreDto (Flutter)
  +addressProvince?, +addressDistrict?, +addressWard?, +addressStreet?
  fromJson maps camelCase keys from server response

StoreApiService
  createStore() / updateStore() → body includes province/district/ward/street when non-null
  fetchProvinces() → GET /reference/locations → List<String>

CachedStores (Drift)
  +addressProvince TEXT, +addressDistrict TEXT, +addressWard TEXT, +addressStreet TEXT
  Schema v28 → v29 migration: addColumn x4

store_location_map_widget.dart (NEW)
  Extracted from store_form_sheet.dart to keep it under 400 lines
  Receives: markerPos, mapController, onTap, isSaving
```

## Decision Log

| Decision | Proposed in Plan | Implemented | Reason |
|---|---|---|---|
| Remove `areas:` param from `showStoreFormSheet` | "Pass `areas: []` or remove the parameter" | Removed entirely | Area dropdown is gone — the param had no purpose. Callers in `store_management_page.dart` updated to match. `StoreFilterBar` still uses `_manager.areas` separately |
| Province list loading | Load from API on mount | `_loadProvinces()` in `initState()` — non-fatal; dropdown stays empty on error | Matches server ref endpoint pattern; graceful degradation on offline |
| Province dropdown pre-population on Edit | Set `initialValue` from `store.addressProvince` | `_provinces.contains(_selectedProvince)` guard prevents invalid initial value | Protects against province not in list during dropdown reset |
| `DropdownButtonFormField.value` | Used `value:` | Changed to `initialValue:` | Deprecated since Flutter v3.33 — `flutter analyze` caught it |
| Map widget extraction | Plan: `store_location_map_widget.dart` | Extracted to `lib/features/stores/widgets/` | Kept `store_form_sheet.dart` at 301 lines (vs 378 before). Stays under 400-line hard cap |
| Drift schema version | Bump to 29 | `schemaVersion => 29` + `if (from < 29)` migration | Follows existing `from < N` incremental pattern. 4 nullable `addColumn` calls — safe for existing devices |
| `build_runner` codegen | Needed after `tables.dart` change | `dart run build_runner build --delete-conflicting-outputs` | Drift regenerates `app_database.g.dart` with new `CachedStoresData` columns. Without it, `m.addColumn(cachedStores, cachedStores.addressProvince)` fails type check |

## Files Changed

| Action | File |
|---|---|
| [NEW] | `lib/features/stores/widgets/store_location_map_widget.dart` |
| [MOD] | `lib/features/stores/model/store_dto.dart` (+4 nullable address fields) |
| [MOD] | `lib/features/stores/services/store_api_service.dart` (+4 address params, +fetchProvinces) |
| [MOD] | `lib/_shared/database/tables.dart` (+4 nullable TextColumns in CachedStores) |
| [MOD] | `lib/_shared/database/app_database.dart` (v29 schema bump, migration block) |
| [REGEN] | `lib/_shared/database/app_database.g.dart` (Drift code generation) |
| [MOD] | `lib/features/admin/pages/widgets/store_form_sheet.dart` (Province UI, 301 lines) |
| [MOD] | `lib/features/admin/pages/store_management_page.dart` (remove areas: param) |

## Verification Handoff

Manual QA steps after running the Flutter app:
1. Navigate to Admin → Store Management
2. Tap `+` to create a new store
3. Confirm Province dropdown loads 63 provinces (requires running server with B2 live)
4. Select a province (e.g. "Hồ Chí Minh"), fill District/Ward/Street → tap Create Store
5. Edit that store → confirm Province/District/Ward/Street pre-populate correctly
6. Confirm Area dropdown is gone from the form (StoreFilterBar at top still works separately)
7. On device with existing DB (v28): confirm app starts without crash (v29 migration runs)

> [!IMPORTANT]
> The server must be running with B1's EF migration applied (triggered on server restart).
> Province dropdown calls `GET /api/reference/locations` — requires auth token.

## Gotcha Protocol

Propose adding to `lib/GEMINI.md`:

```markdown
> **Gotcha 26: Drift Schema + build_runner (addColumn pre-codegen errors)**
> After adding new columns to a `Table` class in `tables.dart`, `flutter analyze` will report
> `TextColumn` type errors in `app_database.dart` migration calls (e.g., `m.addColumn(cachedStores, cachedStores.addressProvince)`).
> These errors are false positives — they disappear after running:
>   `dart run build_runner build --delete-conflicting-outputs`
> from the `lib/` directory. ALWAYS run codegen after any schema change.
```

```markdown
> **Gotcha 27: DropdownButtonFormField.value Deprecation**
> `DropdownButtonFormField.value:` was deprecated in Flutter v3.33. Use `initialValue:` instead.
> `flutter analyze` catches this as a `deprecated_member_use` info. Fix it to keep the project warning-free.
```

<test_trace>
Full flutter analyze run — 2026-05-19 07:33 UTC+7

First run (pre-codegen):
  5 issues found — 4 TextColumn type errors (pre-codegen false positives) + 1 deprecated_member_use

After build_runner + fix:
  rtk flutter analyze lib/ → No issues found! (ran in 26.7s)

Server tests unchanged: 526 passed, 0 failed (B2 verification — B3 is Flutter-only, no server test impact)
</test_trace>

<forensic_evidence>
Build runner:
  cmd /c "rtk dart run build_runner build --delete-conflicting-outputs" → exit 0

Flutter analyze (post-codegen):
  rtk flutter analyze lib/ → No issues found! (ran in 26.7s)

showStoreFormSheet call site search:
  grep_search "showStoreFormSheet" → 3 results: store_management_page.dart:106, 180, store_form_sheet.dart:14
  Both caller sites at 106 and 180 no longer pass areas: parameter.

areas: param residual check in store_management_page.dart:
  grep_search "areas: _manager.areas" → StoreFilterBar usage at line 120 (correct — not showStoreFormSheet)

new StoreDto call sites in Flutter:
  (none — StoreDto is only constructed via StoreDto.fromJson in Flutter)

File line count:
  store_form_sheet.dart → 301 lines (below 400 hard cap)
  store_location_map_widget.dart → 78 lines
</forensic_evidence>
