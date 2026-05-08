<latent_space_scratchpad>
## Edge Cases & Internal Decisions

**1. Greeting widget: role param is dead code**
`dashboard_page.dart:104` passes `role` to `Greeting(role: role)`.
`Greeting.build()` never uses `role` — it only computes a time-based greeting ("Good Morning/Afternoon/Evening") and the user's name from `AuthManager.currentUser`. The `role` parameter does nothing. This is dead code on the widget API.
Decision: Remove the `role` param from `Greeting` entirely. Zero functional change. Eliminates the last reason to read `role` string in `dashboard_page.dart`.

**2. ManagerDashboardVariant: role → persona API change**
`ManagerDashboardVariant(state: s, role: role)` is the only call site (dashboard_page.dart:118-122).
Inside `manager_dashboard_variant.dart:32`: `final isArea = role == 'area_manager'`
Decision: Replace `String role` prop with `UserPersona persona`. Derive `isArea = persona == UserPersona.manager && persona.isArea` — but wait, `UserPersona.manager` covers BOTH store_manager and area_manager. We need finer grain here.

**Critical Design Decision for UserPersona enum:**
The `DashboardManager` switches on role to load different DashboardState variants:
- `'auditor'` → `AuditorDashboardState`
- `'store_manager'` OR `'area_manager'` → `ManagerDashboardState`
- default → `AdminDashboardState`

But `ManagerDashboardVariant` needs to distinguish `store_manager` vs `area_manager` for labels ("Area Action Plans" vs "Store Action Plans", "Area Avg Score" vs "Store Avg Score").

Option A: 3-value enum: `auditor`, `manager`, `admin` — but `isArea` is lost. We'd need to read currentUser.role inside the widget again.
Option B: 4-value enum: `auditor`, `storeManager`, `areaManager`, `admin` — preserves all distinction, perfect compiler safety.
Option C: 3-value enum + `isAreaManager` getter computed from currentUser role inside widget — messy, re-introduces the problem.

**Winner: Option B (4-value enum)**
- `UserPersona.admin` — DashboardManager: loads AdminDashboardState
- `UserPersona.auditor` — DashboardManager: loads AuditorDashboardState
- `UserPersona.storeManager` — DashboardManager: loads ManagerDashboardState with `isArea = false`
- `UserPersona.areaManager` — DashboardManager: loads ManagerDashboardState with `isArea = true`

In `DashboardManager.loadStats()`:
```dart
switch (persona) {
  case UserPersona.auditor: _state = await _loadAuditorState(queries);
  case UserPersona.storeManager: _state = await _loadManagerState(queries, isArea: false);
  case UserPersona.areaManager: _state = await _loadManagerState(queries, isArea: true);
  case UserPersona.admin: _state = await _loadAdminState(queries);
}
```
`_loadManagerState` drops the `role` string param — replaces with `bool isArea`.

In `ManagerDashboardVariant`:
Replace `String role` prop with `UserPersona persona`.
Replace `final isArea = role == 'area_manager'` with `final isArea = persona == UserPersona.areaManager`.

In `dashboard_page.dart`:
- Remove `final role = _di<AuthManager>().currentUser?.role ?? 'admin';`
- Add `final persona = UserPersona.fromRole(_di<AuthManager>().currentUser?.role);`
- Pass `persona: persona` to `ManagerDashboardVariant`.
- Remove `role: role` from `Greeting(role: role)` (after removing param from Greeting).

**3. profile_page.dart: role → persona OR capability?**
`_managementItems()` branches on role to add nav links:
- `admin` → "Admin Dashboard"
- `area_manager` → "My Region"
- `store_manager` → "My Store"

This is a LAYOUT/NAVIGATION structural branch — exactly what UserPersona enum is designed for. Use `UserPersona.fromRole(user?.role)` and switch on it.
But this could also be replaced by PBAC capabilities:
- "Admin Dashboard" → pm.can(AppCapabilities.adminAccess)
- "My Region" → pm.can(AppCapabilities.analyticsArea) [area managers have this]
- "My Store" → ??? no specific "store view" capability exists

Since there's no `store:view` capability defined, and store managers have `submissions:list` only, we cannot replace "My Store" with a capability check without adding a new capability. This would require a backend change.

**Decision: Use UserPersona enum for profile_page.dart** (not capabilities). The profile menu is structural layout, not action authorization. It decides which NAVIGATION link to show — which is persona-driven, not permission-driven. This avoids introducing a new `store:view` backend capability just for a nav link.

**4. Greeting widget `role` param — confirm it's truly unused**
Line 144-181: Greeting.build() doesn't reference `this.role` anywhere in the widget body. Confirmed dead param.

**5. DashboardManager._loadManagerState signature change**
Currently: `_loadManagerState(DashboardQueries queries, String role)`
Inside it: `role` is NEVER used — it only loads stores from DB, no branching on role string.
The `isArea` distinction is only in the VARIANT widget (labels), not the data queries.
Decision: Remove the `role` parameter from `_loadManagerState` entirely. It was only passed to match the switch case and has no effect on the data loaded. The store queries are identical for both store_manager and area_manager.

Summary of changes:
- New: `lib/_shared/constants/user_persona.dart`
- Mod: `lib/features/dashboard/manager/dashboard_manager.dart` (switch + _loadManagerState)
- Mod: `lib/features/dashboard/pages/dashboard_page.dart` (remove role string, add persona, fix Greeting call)
- Mod: `lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart` (role → persona)
- Mod: `lib/features/profile/pages/profile_page.dart` (_managementItems: role → persona)

Total: 1 new file + 4 modified files. 5 total. Moderate blast radius, all within 250 lines each.
</latent_space_scratchpad>

# Implementation Plan: PBAC Slice 2 — UserPersona Structural Layout Sweep

**Plan ID:** `implementation_plan_20260508_112559_a736cb_pbac-slice2`
**Date:** 2026-05-08
**Workflow:** /analyze-feature → /implement
**Status:** READY FOR BUILDER

---

## Input Lineage

- **Epic Plan:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\analysis_epic_20260507_212618_a736cb_pbac-dynamic-ui.md`
- **Slice 1 Plan:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\implementation_plan_20260508_083700_a736cb_pbac-slice1.md`

---

## Executive Summary & Out of Scope

**What this plan builds:**
Create a `UserPersona` enum that acts as a typed, compiler-enforced wrapper for role-based layout branching. Replace all `switch (role)` and `if (role == '...')` structural checks with a proper Dart enum, so that adding a new role generates a compile-time exhaustiveness warning instead of a silent visual bug.

**Files to create/modify (5):**
| Status | File | Change |
|---|---|---|
| [NEW] | `lib/_shared/constants/user_persona.dart` | 4-value enum with `fromRole()` factory |
| [MOD] | `lib/features/dashboard/manager/dashboard_manager.dart` | Replace `switch (role)` with `switch (persona)`. Remove `role` param from `_loadManagerState`. |
| [MOD] | `lib/features/dashboard/pages/dashboard_page.dart` | Replace `role` string with `persona`. Remove dead `role` param from `Greeting`. |
| [MOD] | `lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart` | Replace `String role` prop with `UserPersona persona`. |
| [MOD] | `lib/features/profile/pages/profile_page.dart` | Replace `role` string in `_managementItems()` with `UserPersona`. |

**What is OUT OF SCOPE:**
- Any Slice 1 file (`template_list_page.dart`, `submission_row.dart`, `history_list_view.dart`).
- Any DAO file — ownership scoping is intentionally role-string based.
- Any backend file.
- `admin_audit_manager.dart` — business data scoping.
- `user_create_sheet.dart`, `user_edit_sheet.dart` — role strings are the DATA being edited.

> [!IMPORTANT]
> **Builder Decision Pre-Approved (No Approval Gate Needed):**
> - `UserPersona` will be a **4-value enum** (`auditor`, `storeManager`, `areaManager`, `admin`) — NOT 3-value. This preserves the `isArea` label distinction in `ManagerDashboardVariant` without re-reading the role string inside a widget.
> - The `Greeting` widget's `role` constructor parameter is **dead code** (never read in `build()`). It will be removed entirely. Zero functional change.
> - `_loadManagerState` in `DashboardManager` will have its unused `String role` parameter removed. The data queries are identical for both manager sub-types.

---

## System Context

- **Offline/Online:** Offline-first. `UserPersona.fromRole()` reads `currentUser?.role` — loaded from SQLite at login. Synchronous. Zero network calls.
- **APIs:** No API calls in this slice.
- **RBAC:** No capability checks. This slice is structural layout only, not permission authorization.
- **DI:** `AuthManager` already registered. No new DI registrations needed.

---

## Lifecycle Context (4-State Matrix)

| State | Behavior |
|---|---|
| **Loading** (role not yet loaded) | `UserPersona.fromRole(null)` → returns `UserPersona.admin` (fallback). Dashboard shows admin view until auth completes. Same as current `role ?? 'admin'`. |
| **Success** (role loaded) | Correct `UserPersona` variant returned. Dashboard/Profile shows persona-matched layout. |
| **Error** (auth failure) | `AuthManager.currentUser` is null. `fromRole(null)` → `UserPersona.admin` fallback. Router redirects to `/login` before dashboard renders. |
| **Unknown role** (future role added) | `fromRole('new_role')` → `UserPersona.admin` fallback. Dashboard shows admin-style view. No crash. Dart `switch` on enum gives exhaustiveness warning to devs. |

---

## Test Contracts

| ID | Scenario | Input State | Expected Output | Why it fails RED first |
|---|---|---|---|---|
| TC-01 | `UserPersona.fromRole('auditor')` | `role = 'auditor'` | Returns `UserPersona.auditor` | Enum doesn't exist yet. |
| TC-02 | `UserPersona.fromRole('store_manager')` | `role = 'store_manager'` | Returns `UserPersona.storeManager` | Enum doesn't exist yet. |
| TC-03 | `UserPersona.fromRole('area_manager')` | `role = 'area_manager'` | Returns `UserPersona.areaManager` | Enum doesn't exist yet. |
| TC-04 | `UserPersona.fromRole('admin')` | `role = 'admin'` | Returns `UserPersona.admin` | Enum doesn't exist yet. |
| TC-05 | `UserPersona.fromRole(null)` | `role = null` | Returns `UserPersona.admin` | Null fallback must be safe. |
| TC-06 | `UserPersona.fromRole('unknown_future_role')` | unknown string | Returns `UserPersona.admin` | Unknown roles must not crash. |
| TC-07 | Auditor logs in → opens Dashboard | `persona = UserPersona.auditor` | `AuditorDashboardState` loaded | `switch (persona)` must route correctly. |
| TC-08 | Store Manager logs in → opens Dashboard | `persona = UserPersona.storeManager` | `ManagerDashboardState` loaded; `isArea = false` | Labels: "Store Action Plans", "Store Avg Score". |
| TC-09 | Area Manager logs in → opens Dashboard | `persona = UserPersona.areaManager` | `ManagerDashboardState` loaded; `isArea = true` | Labels: "Area Action Plans", "Area Avg Score". |
| TC-10 | Admin logs in → opens Dashboard | `persona = UserPersona.admin` | `AdminDashboardState` loaded | Correct widget variant rendered. |
| TC-11 | Admin opens Profile → Management section | `persona = UserPersona.admin` | "Admin Dashboard" link appears | `if (persona == UserPersona.admin)` branch fires. |
| TC-12 | Area Manager opens Profile → Management | `persona = UserPersona.areaManager` | "My Region" link appears, NOT "Admin Dashboard" | Correct persona branch. |
| TC-13 | Store Manager opens Profile → Management | `persona = UserPersona.storeManager` | "My Store" link appears | Correct persona branch. |
| TC-14 | `grep_search` for `role == '` in 4 modified files | Post-build | Zero results | All string checks replaced. |

---

## Test Fixture & Payloads

**No API contracts.** Pure local state.

**Required manual test fixture state:**
- Flutter app running locally.
- Login with **auditor** JWT → verify dashboard shows auditor variant.
- Login with **store_manager** JWT → verify "Store Action Plans" / "Store Avg Score" labels.
- Login with **area_manager** JWT → verify "Area Action Plans" / "Area Avg Score" labels.
- Login with **admin** JWT → verify admin dashboard variant.
- For profile: check that correct management section link appears per role.

---

## Tools & Commands

**Skills the Builder needs:**
- `flutter-api` — enum patterns, widget prop changes.

**Test commands (run after each step):**
```
cmd /c rtk flutter analyze lib/_shared/constants/user_persona.dart
cmd /c rtk flutter analyze lib/features/dashboard/manager/dashboard_manager.dart
cmd /c rtk flutter analyze lib/features/dashboard/pages/dashboard_page.dart
cmd /c rtk flutter analyze lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart
cmd /c rtk flutter analyze lib/features/profile/pages/profile_page.dart
```
**Full sweep after all changes:**
```
cmd /c rtk flutter analyze lib/
```

---

## Concept Diagram

```
Before:
[AuthManager.currentUser.role] (String) 
  → switch ('auditor'/'store_manager'/'area_manager'/'admin')
  → load DashboardState variant
  → passed to ManagerDashboardVariant(role: 'area_manager')
  → final isArea = role == 'area_manager'   ← magic string

After:
[AuthManager.currentUser?.role] (String?)
  → UserPersona.fromRole(role)              ← single conversion point
  → UserPersona enum value                 ← typed, compiler-checked
  → switch (persona)                       ← exhaustiveness warning if new case added
  → load DashboardState variant
  → passed to ManagerDashboardVariant(persona: UserPersona.areaManager)
  → final isArea = persona == UserPersona.areaManager  ← no magic strings
```

---

## Execution Phase: UserPersona Structural Sweep

**Complexity: Low-Medium** — 1 new file + 4 prop changes. No new state, no new API. Main risk is changing the `ManagerDashboardVariant` widget API.

**Plain English Summary:**
We will create a 4-value Dart enum that converts the server's role string into a named, typed concept: `auditor`, `storeManager`, `areaManager`, or `admin`. We then replace every place in the dashboard and profile code that reads the raw role string with this enum. The compiler will now catch any missing case if a future role is added.

**Value Delivered:**
Zero `role ==` string checks in structural/layout code. Adding a new role in the future generates a compiler warning — it cannot be silently ignored. Dashboard and Profile pages are type-safe.

**Entry State Required:**
- Slice 1 complete (3 widget auth-check files already cleaned).
- `UserPersona` enum does NOT yet exist (confirmed: no results from grep).
- `flutter analyze lib/` passes cleanly.

**Exit State Guaranteed:**
- `UserPersona` enum exists in `lib/_shared/constants/user_persona.dart`.
- `grep_search` for `role == '` in all 4 modified files returns zero results.
- `flutter analyze lib/` produces zero new errors or warnings.

**Anti-Attention Collapse — ONE FILE PER STEP:**

---

**Step 1 — Create `user_persona.dart` (new file)**

Create `lib/_shared/constants/user_persona.dart` with:
```dart
/// Strongly-typed user persona enum.
/// Replaces raw role string switches throughout structural layout code.
///
/// Mapping:
///   'auditor'        → UserPersona.auditor
///   'store_manager'  → UserPersona.storeManager
///   'area_manager'   → UserPersona.areaManager
///   'admin' / null / unknown → UserPersona.admin (safe fallback)
enum UserPersona {
  auditor,
  storeManager,
  areaManager,
  admin;

  /// Convert a raw server role string to a typed [UserPersona].
  /// Defaults to [UserPersona.admin] for null or unknown roles — same
  /// fail-safe as the previous `role ?? 'admin'` fallback.
  static UserPersona fromRole(String? role) => switch (role) {
    'auditor' => UserPersona.auditor,
    'store_manager' => UserPersona.storeManager,
    'area_manager' => UserPersona.areaManager,
    _ => UserPersona.admin,
  };
}
```
Run: `rtk flutter analyze lib/_shared/constants/user_persona.dart`

---

**Step 2 — `dashboard_manager.dart`**

*Change:*
- Line 129: `final role = _auth.currentUser?.role ?? 'admin';`
  Replace with: `final persona = UserPersona.fromRole(_auth.currentUser?.role);`
- Add import: `import '../../../_shared/constants/user_persona.dart';`
- Lines 161-170: Replace `switch (role)` with `switch (persona)`:
  ```dart
  switch (persona) {
    case UserPersona.auditor:
      _state = await _loadAuditorState(queries);
    case UserPersona.storeManager:
    case UserPersona.areaManager:
      _state = await _loadManagerState(queries);
    case UserPersona.admin:
      _state = await _loadAdminState(queries);
  }
  ```
- Line 203: `_loadManagerState(DashboardQueries queries, String role)` → remove `String role` param (it was never used in the method body — confirmed by reading the file).
- Line 166: `_loadManagerState(queries, role)` call → `_loadManagerState(queries)`.

Run: `rtk flutter analyze lib/features/dashboard/manager/dashboard_manager.dart`

---

**Step 3 — `manager_dashboard_variant.dart`**

*Change:*
- Add import: `import '../../../../_shared/constants/user_persona.dart';`
- Line 20: `final String role;` → `final UserPersona persona;`
- Line 25: `required this.role,` → `required this.persona,`
- Line 32: `final isArea = role == 'area_manager';` → `final isArea = persona == UserPersona.areaManager;`
- Remove now-unused `role` references.

Run: `rtk flutter analyze lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart`

---

**Step 4 — `dashboard_page.dart`**

*Change:*
- Add import: `import '../../../_shared/constants/user_persona.dart';`
- Line 86: `final role = _di<AuthManager>().currentUser?.role ?? 'admin';`
  Replace with: `final persona = UserPersona.fromRole(_di<AuthManager>().currentUser?.role);`
- Line 104: `Greeting(role: role)` → `Greeting()` (after removing the dead `role` param from the Greeting widget class at line 141–142 in the same file).
  - Remove `final String role;` field from `Greeting`.
  - Remove `required this.role,` from `Greeting` constructor.
- Line 120: `role: role,` inside `ManagerDashboardVariant(...)` → `persona: persona,`
- Check: `AuthManager` import — still used? Line 147 `GetIt.instance<AuthManager>().currentUser` inside `Greeting.build()`. Keep import. Also line 86 now uses `_di<AuthManager>()`. Keep import.

Run: `rtk flutter analyze lib/features/dashboard/pages/dashboard_page.dart`

---

**Step 5 — `profile_page.dart`**

*Change:*
- Add import: `import '../../../_shared/constants/user_persona.dart';`
- Line 22: `final role = user?.role ?? 'auditor';` → `final persona = UserPersona.fromRole(user?.role);`
- Line 35: `_managementItems(context, role)` → `_managementItems(context, persona)`
- Line 31: `ProfileHeader(..., role: role)` — `role` is a display string on the header badge. **Keep this line unchanged.** The header shows the raw role label (e.g., "store_manager") as a badge — this is display data, not branching logic. Use `role` from `user?.role ?? 'auditor'` which stays as a separate local variable for display only.
- Line 117: `List<MenuItemData> _managementItems(BuildContext context, String role)` → `List<MenuItemData> _managementItems(BuildContext context, UserPersona persona)`
- Lines 119, 129, 139: Replace `if (role == 'admin')`, `if (role == 'area_manager')`, `if (role == 'store_manager')` with `if (persona == UserPersona.admin)`, `if (persona == UserPersona.areaManager)`, `if (persona == UserPersona.storeManager)`.

> [!NOTE]
> **Two separate local variables in `profile_page.dart`:**
> - `final role = user?.role ?? 'auditor';` — kept for `ProfileHeader(role: role)` display badge. This is **display data**, not a role check.
> - `final persona = UserPersona.fromRole(user?.role);` — used for `_managementItems()` structural branch.
> This is intentional and correct. The `role` string here is the data being displayed to the user, not a security gate.

Run: `rtk flutter analyze lib/features/profile/pages/profile_page.dart`

---

**Step 6 — Final Verification**

```
rtk flutter analyze lib/
grep_search lib/features/dashboard/manager/dashboard_manager.dart "role == '"
grep_search lib/features/dashboard/pages/dashboard_page.dart "role == '"
grep_search lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart "role == '"
grep_search lib/features/profile/pages/profile_page.dart "role == '"
```
All 4 grep searches must return **zero results**.

---

<command_logs>
- `view_file dashboard_page.dart` (1–183) — full file. Line 86: `role = ... ?? 'admin'`. Line 104: `Greeting(role: role)`. Line 120: `role: role` to ManagerDashboardVariant. Greeting.build() never uses `this.role` — confirmed dead param.
- `view_file profile_page.dart` (1–152) — full file. Lines 119, 129, 139: three `if (role ==)` branches. Line 31: `ProfileHeader(role: role)` — display string, must keep.
- `view_file manager_dashboard_variant.dart` (1–121) — full file. Line 20: `String role` prop. Line 32: `isArea = role == 'area_manager'`. 1 call site in dashboard_page.dart.
- `view_file dashboard_manager.dart` (1–345) — full file. Line 129: `role` local var. Lines 161-169: `switch (role)` with 3 cases. Line 203: `_loadManagerState(queries, role)` — `role` param never used in method body (confirmed reading lines 203–267).
- `grep_search lib/ "UserPersona"` — No results. Enum does not exist yet.
- `grep_search lib/ "ManagerDashboardVariant"` — 3 results: definition + 1 call site in dashboard_page.dart. Blast radius confirmed as 1 call site.
- `grep_search lib/ "Greeting(role:"` — 1 result: dashboard_page.dart:104.
- `list_dir lib/_shared/constants/` — 2 files: `app_capabilities.dart`, `review_status.dart`. No `user_persona.dart` exists.
- `view_file app_capabilities.dart` — Confirmed 16 capability constants. No `store:view` capability exists (confirming profile_page must use UserPersona, not capabilities).
</command_logs>

---

## Proposed Changes

| Status | File | Change |
|---|---|---|
| [NEW] | `lib/_shared/constants/user_persona.dart` | 4-value enum: `auditor`, `storeManager`, `areaManager`, `admin`. Static `fromRole(String?)` factory with safe null/unknown fallback. |
| [MOD] | `lib/features/dashboard/manager/dashboard_manager.dart` | Replace `switch (role)` with `switch (persona: UserPersona)`. Remove unused `String role` param from `_loadManagerState`. Add import. |
| [MOD] | `lib/features/dashboard/pages/dashboard_page.dart` | Replace `role` String local var with `persona: UserPersona`. Remove dead `role` param from `Greeting` widget. Pass `persona` to `ManagerDashboardVariant`. |
| [MOD] | `lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart` | Replace `String role` prop with `UserPersona persona`. Replace `role == 'area_manager'` with `persona == UserPersona.areaManager`. |
| [MOD] | `lib/features/profile/pages/profile_page.dart` | Add `UserPersona persona` local var. Replace 3× `if (role == '...')` in `_managementItems()` with `if (persona == UserPersona.xxx)`. Keep `role` string for `ProfileHeader` display. |

---

## Verification Plan

**After Step 1 (user_persona.dart created):**
1. `rtk flutter analyze lib/_shared/constants/user_persona.dart` — zero errors.

**After Step 2 (dashboard_manager.dart):**
2. `rtk flutter analyze lib/features/dashboard/manager/dashboard_manager.dart` — zero errors.
3. `grep_search dashboard_manager.dart "role == '"` — zero results.

**After Step 3 (manager_dashboard_variant.dart):**
4. `rtk flutter analyze lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart` — zero errors.
5. `grep_search manager_dashboard_variant.dart "role == '"` — zero results.

**After Step 4 (dashboard_page.dart):**
6. `rtk flutter analyze lib/features/dashboard/pages/dashboard_page.dart` — zero errors.
7. `grep_search dashboard_page.dart "role == '"` — zero results.

**After Step 5 (profile_page.dart):**
8. `rtk flutter analyze lib/features/profile/pages/profile_page.dart` — zero errors.
9. `grep_search profile_page.dart "role == '"` — zero results.

**Final sweep (Step 6):**
10. `rtk flutter analyze lib/` — zero new errors or warnings.
11. All 4 grep searches from steps 3, 5, 7, 9 must each return zero results.
12. Manual login with each role (auditor, store_manager, area_manager, admin) — verify correct dashboard variant and profile menu items render.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `ManagerDashboardVariant` API change breaks a call site | Low | Only 1 call site confirmed (dashboard_page.dart:120). Builder must update it in Step 4. |
| `Greeting` dead `role` param causes confusion | Low | Remove the param entirely — zero impact since Greeting never reads it. |
| `_loadManagerState` removes `String role` but it was used somewhere | Low | Read lines 203-267 confirmed it is never used inside the method. Remove safely. |
| `ProfileHeader` loses its display role string | Medium | `role = user?.role ?? 'auditor'` stays as a separate variable specifically for the display badge. Do NOT replace this with `persona`. |
| Adding `UserPersona` without exhaustive switch → silent fallback | Low | `fromRole()` uses a Dart `switch` with `_` wildcard — all unknowns go to `admin`. This is identical to the current `?? 'admin'` fallback. |

---

## Handoff Block

**Summary for Builder:** Create the `UserPersona` enum first (Step 1). Then modify each file one-by-one in order (Steps 2–5). Run `flutter analyze` after every single step. The biggest gotcha is that `profile_page.dart` keeps TWO separate local variables: `role` (for display) and `persona` (for branching logic).

**Strict Builder Constraints:**
1. Read each file with `view_file` before editing.
2. Execute **ONE step at a time**. Run `flutter analyze` after each. Do not batch.
3. Do NOT remove `role = user?.role` from `profile_page.dart` — it feeds `ProfileHeader` display badge.
4. `UserPersona.fromRole(null)` MUST return `UserPersona.admin`. Test with `grep_search` after.
5. After Step 6, all 4 grep searches must return zero results before declaring done.

**Routing Command:**
```
@[/implement] Execute build for Execution Phase (Step 1 — user_persona.dart):
c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\implementation_plan_20260508_112559_a736cb_pbac-slice2.md
```
Then sequentially: Step 2 (dashboard_manager.dart) → Step 3 (manager_dashboard_variant.dart) → Step 4 (dashboard_page.dart) → Step 5 (profile_page.dart) → Step 6 (verification).

**Concurrency:** All steps are SEQUENTIAL. Step N must pass `flutter analyze` before Step N+1 begins.
