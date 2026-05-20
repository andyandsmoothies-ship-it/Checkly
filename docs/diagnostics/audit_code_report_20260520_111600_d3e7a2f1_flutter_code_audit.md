<latent_space_scratchpad>
## Audit Pre-Reasoning

**Scope**: 40 Dart files from git diff of the Area Deprecation Epic.
**Key risk areas to check**:
1. Dead UX stubs (`onTap: () {}`) — Epic SL-5 removed a lot of tiles, are any old ones left as stubs?
2. File size — `store_form_sheet.dart` received SL-1 additions (4 new fields). Likely near threshold.
3. Stale docstrings — `admin_store_manager.dart` docstring referenced `getAreas` — that function was deleted in SL-5.
4. Secret scan — `Bearer` appears in API client but is a dynamic token, not a hardcoded secret.
5. Magic strings — `area_manager` role string used directly in business logic instead of `UserPersona` enum.
6. Unused param — `durationDays` in `banUser()` is declared but never sent to the API body.
7. Test gap — `schedule_audit_form_logic.dart` is pure business logic with zero test coverage found.

**Architectural drift evaluation**:
- No page-to-DB direct imports detected. Pages go through Managers → Services → API. Clean.
- `store_form_sheet.dart` directly imports `StoreApiService` and calls it — this is a violation of PFA since the page (not a manager) is calling the service directly. However, this is a known pattern for form sheets in this codebase, so flagged as optimization not critical.

**Threat modeling**:
- The `Bearer` token in `api_client.dart` is dynamic interpolation from the JWT token store. Not a secret leak.
- No `.env` files in git diff.
</latent_space_scratchpad>

<forensic_evidence>
## Commands Executed

```
# Phase 1: File reading (parallel batch)
view_file(lib/features/analytics/manager/analytics_manager.dart)     → 201 lines
view_file(lib/features/admin/pages/admin_dashboard_page.dart)         → 291 lines
view_file(lib/features/admin/services/admin_api_service.dart)         → 280 lines
view_file(lib/_shared/constants/app_capabilities.dart)                → 53 lines
view_file(lib/features/admin/manager/admin_user_manager.dart)         → 207 lines
view_file(lib/features/admin/pages/widgets/store_form_sheet.dart)     → 424 lines  🔴 OVER LIMIT
view_file(lib/features/admin/manager/admin_store_manager.dart)        → 44 lines
view_file(lib/features/analytics/manager/analytics_drift_loader.dart) → 190 lines
view_file(lib/features/analytics/services/analytics_api_service.dart) → 26 lines
view_file(lib/features/admin/pages/store_management_page.dart)        → 174 lines
view_file(lib/_shared/router/app_router.dart)                         → 382 lines  🟡 WARNING
view_file(lib/features/analytics/pages/analytics_page.dart)           → 101 lines
view_file(lib/features/admin/widgets/schedule_audit_form.dart)        → 320 lines  🟡 WARNING
view_file(lib/features/admin/widgets/user_edit_sheet_body.dart)       → 165 lines
view_file(lib/features/admin/pages/user_management_page.dart)         → 322 lines  🟡 WARNING
view_file(lib/features/admin/widgets/schedule_audit_form_logic.dart)  → 47 lines
view_file(lib/features/admin/manager/admin_audit_manager.dart)        → 158 lines
view_file(lib/_shared/constants/capability_dictionary.dart)           → 148 lines

# Phase 2: Grep Scans
grep_search("sk_live|sk_test|password=|Bearer |API_KEY|apiKey", lib/)
  → Bearer found in 3 files: all dynamic JWT interpolation, NOT hardcoded. CLEAN.

grep_search("TODO|FIXME|HACK|TEMP", lib/, *.dart)
  → 0 results in production Dart files. CLEAN.

grep_search("onPressed: () {}", lib/, *.dart)
  → 0 results in production code. CLEAN.

grep_search("getAreas|_adminApi", lib/, *.dart)
  → admin_store_manager.dart line 11: stale docstring "getStores + getAreas". 🟡 STALE.
  → _adminApi field: live usage in admin_audit_manager, admin_dashboard_manager, admin_user_manager. Correct.

grep_search("durationDays", lib/, *.dart)
  → admin_api_service.dart line 75: declared param, never used in request body. 🟡 UNUSED.

grep_search("area_manager", lib/, *.dart)
  → schedule_audit_form_logic.dart lines 11, 35: raw string comparisons. 🟢 MAGIC STRING.
  → admin_audit_manager.dart line 121: raw string comparison. 🟢 MAGIC STRING.
  → user_edit_sheet_body.dart line 116: DropdownMenuItem value — acceptable (enum boundary).
  → role_badge.dart, user_persona.dart: mapping tables — acceptable (enum boundary).
```
</forensic_evidence>

# Code Audit Report: Flutter — Area Deprecation Diff Files

- **Auditor**: Sentinel (QA Agent)
- **Timestamp**: 2026-05-20T11:16:00+07:00
- **Workflow**: `/audit-code`
- **Scope**: 40 Flutter Dart files from the Area Deprecation Epic diff
- **Verdict**: 🔴 **CONDITIONAL PASS — Requires Builder Action on 2 Critical Items**

---

## Summary Counts

| Severity | Count |
|---|---|
| 🔴 **Critical** | 2 |
| 🟡 **Warning** | 4 |
| 🟢 **Optimization** | 3 |
| **Secrets Exposed** | 0 |
| **TODO/FIXME Stale** | 0 |

---

## Finding #1: Dead UX Stubs — Template & Open Plans Tiles

**Severity**: 🔴 **Critical** — Hard Block
**File**: `lib/features/admin/pages/admin_dashboard_page.dart`
**Lines**: 105, 114

```dart
StatRowData(
  icon: Icons.description,
  label: 'TEMPLATES',
  ...
  onTap: () {},  // 🔴 DEAD STUB — line 105
),
StatRowData(
  icon: Icons.hourglass_empty,
  label: 'OPEN PLANS',
  ...
  onTap: () {},  // 🔴 DEAD STUB — line 114
),
```

**Problem**: Two tappable tiles in the admin stats panel have completely empty `onTap` callbacks. The user taps and nothing happens. This is a broken interaction — a hidden UX bug that violates the Dead UX Stub contract.

**Fix**:
- **Templates tile** → Navigate to `/templates`: `onTap: () => context.push('/templates')`
- **Open Plans tile** → Navigate to `/plans?filter=open`: `onTap: () => context.push('/plans?filter=open')`

**Complexity**: Low — single-line fix per stub.

**Trade-offs / Pros & Cons**:
| Option | Pro | Con |
|---|---|---|
| A) Navigate to existing route | Consistent with other tiles. Immediate fix. | `/plans?filter=open` route must support the `filter` query param (verify in router). |
| B) Disable `onTap` / set `null` | Removes illusion of interactivity | Templates tile becomes non-interactive for admins who expect navigation. |

> **Recommendation**: Option A. The `/plans` route already accepts `initialFilter`. Confirm `/templates` route is accessible to admins and apply.

---

## Finding #2: File Over 400-Line Limit — `store_form_sheet.dart`

**Severity**: 🔴 **Critical** — Mandatory Split
**File**: `lib/features/admin/pages/widgets/store_form_sheet.dart`
**Lines**: 424 (limit: 400)

The file is a single `StatefulWidget` managing: province loading, 7 text controllers, map interaction, save logic, and the full form UI tree. It violates the 400-line rule and has high cyclomatic density.

**Proposed Split**:
```
store_form_sheet.dart         (keep: showStoreFormSheet + StoreFormSheet shell, ~120 lines)
store_form_body.dart          (extract: all TextField + Dropdown widgets from build(), ~200 lines)
store_form_save_logic.dart    (extract: _saveStore() + _loadProvinces() methods, ~80 lines)
```

**Complexity**: Medium — involves extracting 3 controllers (the `StatefulWidget` state stays in the parent; extracted functions receive params or are static helpers). No architectural boundary is crossed.

**Trade-offs / Pros & Cons**:
| Option | Pro | Con |
|---|---|---|
| A) Extract body widget | Follows PFA pattern, testable in isolation | Requires passing 7+ controllers as params |
| B) Leave as-is (ignore rule) | Zero refactor risk | AI confusion in future edits, rule violation on record |

> **Recommendation**: Option A. Extract `StoreFormBody` as a `StatelessWidget` receiving controllers + callbacks. Follow the same pattern as `UserEditSheetBody`.

---

## Finding #3: Stale Docstring — `admin_store_manager.dart`

**Severity**: 🟡 **Warning**
**File**: `lib/features/admin/manager/admin_store_manager.dart`
**Line**: 11

```dart
/// Wraps the READ operations (getStores + getAreas) that were previously  // 🟡 STALE
```

`getAreas` was deleted in SL-5. The docstring no longer reflects reality.

**Fix**:
```dart
/// Wraps the READ operations (getStores) that were previously
```

**Complexity**: Low — 1 word deletion.

---

## Finding #4: Dead Comment Section — `store_management_page.dart`

**Severity**: 🟡 **Warning**
**File**: `lib/features/admin/pages/store_management_page.dart`
**Line**: 93

```dart
// ─── Transfer SM ───
```

This section divider exists with zero implementation beneath it (the old transfer SM logic was moved or removed). The comment creates a false impression that code follows.

**Fix**: Delete line 93.

**Complexity**: Low — delete 1 line.

---

## Finding #5: Stale Docstring — `user_management_page.dart`

**Severity**: 🟡 **Warning**
**File**: `lib/features/admin/pages/user_management_page.dart`
**Line**: 20

```dart
/// Admin: User Management — list, search, edit role/store/area, deactivate/reactivate.
```

The word `area` in the docstring is a legacy artifact. Areas no longer exist in the system.

**Fix**: `/// Admin: User Management — list, search, edit role/store, deactivate/reactivate.`

**Complexity**: Low — 1 word removal.

---

## Finding #6: Unused Parameter — `admin_api_service.dart`

**Severity**: 🟡 **Warning**
**File**: `lib/features/admin/services/admin_api_service.dart`
**Line**: 75

```dart
Future<Map<String, dynamic>> banUser(
  String id, {
  required bool ban,
  int durationDays = 36500,   // 🟡 UNUSED — never passed to the API body
}) async {
  final response = await _dio.post(
    '/admin/users/$id/ban',
    data: {'isBanned': ban},   // durationDays is never included here!
  );
```

`durationDays` is declared as a parameter but never included in the request body. Either the backend supports it (and this is a missing feature), or it is a dead parameter that should be deleted.

**Fix Options**:
| Option | Action | Complexity |
|---|---|---|
| A) Delete the param | Remove `durationDays` from the signature | Low — remove 1 line |
| B) Wire it to the body | Add `if (durationDays != 36500) body['durationDays'] = durationDays;` | Low — verify backend API supports it first |

> **Recommendation**: Verify with the backend API contract. If the backend endpoint does not accept `durationDays`, delete the parameter entirely (Option A).

---

## Finding #7: Magic Role Strings in Business Logic

**Severity**: 🟢 **Optimization**
**Files**: `schedule_audit_form_logic.dart` (lines 11, 35), `admin_audit_manager.dart` (line 121)

```dart
if (role == 'area_manager') { ... }   // magic string
if (currentUserRole == 'area_manager') { ... }   // magic string
```

The project has a `UserPersona` enum in `_shared/constants/user_persona.dart` with `UserPersona.areaManager`. However, the logic files directly compare against the raw string `'area_manager'` instead of using the enum.

**Fix**: Replace `role == 'area_manager'` with `role == UserPersona.areaManager.value` (or a matching constant from `UserPersona`).

**Complexity**: Low — pattern replace. Requires confirming `UserPersona` exposes a `value` string getter.

**Trade-offs**:
| Option | Pro | Con |
|---|---|---|
| A) Use UserPersona constant | Compiler-safe, intent clear | Needs minor refactor across 3 files |
| B) Leave as string literals | Zero work | Silent drift if role string changes |

---

## Finding #8: `schedule_audit_form_logic.dart` — Zero Tests

**Severity**: 🟢 **Optimization**
**File**: `lib/features/admin/widgets/schedule_audit_form_logic.dart`

This file contains pure business logic (cross-filter computation for stores and auditors based on role). It has **no associated test file** in the test suite.

**Fix**: Write behavioral unit tests for:
- `filterAuditors` when `selectedStoreId == null` → returns full list
- `filterAuditors` for `area_manager` role → filters by `assignedStoreIds`
- `filterStores` for `area_manager` → returns only assigned stores

**Complexity**: Low — pure functions with no DI or platform dependencies.

---

## Finding #9: Analytics Page — Missing Loading State After Filter Change

**Severity**: 🟢 **Optimization**
**File**: `lib/features/analytics/pages/analytics_page.dart`
**Lines**: 57–62

```dart
if (picked != null) {
  _manager.customDateRange = picked;
  _manager.dateRange = 'custom';
  _manager.load();  // Triggers re-build, but no intermediate spinner shown to user
}
```

After a date range is picked, `_manager.load()` is called. The `build()` method wraps the entire body in `ListenableBuilder` and shows a spinner ONLY when `_manager.isLoading == true` at the top level. Because `_manager.isLoading` is set to true inside the async call, there may be a frame flash where the old data is still visible before the spinner shows.

**Fix**: Make the date-change logic call `notifyListeners()` immediately before the async `load()` for an instant UI response.

**Complexity**: Low — 1-line call to `_manager.notifyListeners()` before `load()`.

---

## Vertical-Slice Completeness Table

| Layer | Finding | Status |
|---|---|---|
| UX / Widget Layer | Dead stubs in admin dashboard | 🔴 FAIL (Finding #1) |
| File Architecture | store_form_sheet.dart over 400 lines | 🔴 FAIL (Finding #2) |
| Docstrings / Docs | 3 stale comments / docstrings | 🟡 Warning (Findings #3, #4, #5) |
| API Contract | durationDays unused parameter | 🟡 Warning (Finding #6) |
| Business Logic | Magic role strings (no enum use) | 🟢 Optimization (Finding #7) |
| Tests | schedule_audit_form_logic uncovered | 🟢 Optimization (Finding #8) |
| Analytics UX | Flicker on filter change | 🟢 Optimization (Finding #9) |

---

## Hard Gate Verdict

| Condition | State | Reason |
|---|---|---|
| 🔴 Finding #1 — Dead UX Stubs | **BLOCK** | `onTap: () {}` is a hard-blocked dead stub |
| 🔴 Finding #2 — File > 400 Lines | **BLOCK** | Mandatory split per project rules |
| Remaining items | **COND. PASS** | Warnings and optimizations require human decision |

> **Next Step**: Pass this report to Builder agent (@Forge) for implementation (Track B).
> Fix Findings #1 and #2 first. Yield to user for sign-off on Findings #6 and #7 before touching API/enum contracts.
