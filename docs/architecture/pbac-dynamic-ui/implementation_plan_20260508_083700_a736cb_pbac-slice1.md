<latent_space_scratchpad>
Edge cases to consider:

1. `template_list_page.dart` passes `isAdmin` to `TemplateCard`. The `TemplateCard.isAdmin` prop controls Edit/Duplicate/Delete menu visibility inside the card itself. The right capability to use there is NOT `submissionsReview` — it should be `templatesCreate` (which the epic confirmed covers template mutation actions). The builder must change BOTH the source in `template_list_page.dart` AND the semantics in `TemplateCard` — but `TemplateCard.isAdmin` is a bool prop, not a PBAC call. The builder should rename it or keep the API and just change the caller in `template_list_page.dart`. Simplest fix: keep `TemplateCard.isAdmin` as a bool, change the caller to pass `pm.can(AppCapabilities.templatesCreate)`. Zero API break.

2. `history_list_view.dart` uses the role check as the *value* of `onVoidAudit` parameter (a function vs null). The pattern is: `onVoidAudit: role == 'admin' ? (submission) async { ... } : null`. The replacement must compute the capability BEFORE the `StoreGroup` call: `final canVoid = _di<PolicyManager>().can(AppCapabilities.submissionsReview); ... onVoidAudit: canVoid ? (submission) async { ... } : null`. Import `PolicyManager` and `AppCapabilities`.

3. `submission_row.dart` has `isAdmin` computed inside `itemBuilder: (_) { ... }` of `PopupMenuButton`. The import for `PolicyManager` is not present. Must add import + replace inline role check.

4. `online_capability_grid.dart:114` — `role == 'admin'` is comparing the ROLE BEING EDITED (passed as widget param) against the string 'admin'. This is an admin self-lock guard on the Role Management screen, NOT a current-user auth check. It must NOT be touched. Confirmed in assessment.

5. `PolicyManager` import path: `'../../../../_shared/services/policy_manager.dart'` (relative from `submission_row.dart` which is in `lib/features/dashboard/pages/widgets/`). For `history_list_view.dart` in `lib/features/audit/pages/widgets/`: `'../../../../_shared/services/policy_manager.dart'`.
</latent_space_scratchpad>

# Implementation Plan: PBAC Slice 1 — Auth/Visibility Role String Sweep

**Plan ID:** `implementation_plan_20260508_083700_a736cb_pbac-slice1`
**Date:** 2026-05-08
**Workflow:** /analyze-feature → /implement
**Status:** READY FOR BUILDER

---

## Input Lineage

- **Epic Plan:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\analysis_epic_20260507_212618_a736cb_pbac-dynamic-ui.md`
- **ADR:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\decision_record_20260507_211849_a736cb_pbac-synthesize.md`

---

## Executive Summary & Out of Scope

**What this plan builds:**
Replace 3 hardcoded `role == 'admin'` auth/visibility checks in feature widgets with `PolicyManager.can(AppCapabilities.xyz)` calls. This closes the GEMINI.md compliance gap for Slice 1 of the PBAC migration.

**Files to modify (3):**
1. `lib/features/templates/pages/template_list_page.dart` — line 162
2. `lib/features/dashboard/pages/widgets/submission_row.dart` — line 253–254
3. `lib/features/audit/pages/widgets/history_list_view.dart` — line 92

**What is OUT OF SCOPE:**
- `online_capability_grid.dart:114` — assessed and confirmed: `role == 'admin'` compares the *role being edited* (widget parameter), not the current user. This is a data comparison on the Role Management screen. **Leave untouched.**
- `profile_page.dart`, `dashboard_manager.dart`, `manager_dashboard_variant.dart`, `dashboard_page.dart` — Slice 2 (structural/layout). Not this plan.
- Any backend file. No backend changes required.
- Any DAO file (`store_dao.dart`, `profile_dao.dart`) — ownership scoping. Not auth. Leave.
- `user_create_sheet.dart`, `user_edit_sheet.dart`, `schedule_audit_form_logic.dart`, `admin_audit_manager.dart` — business data filters. Leave.

> [!IMPORTANT]
> **ADR Correction Confirmed:** The ADR's "Backend BLOCKER" (add IMemoryCache) is a false requirement. `CapabilityAuthorizationHandler` reads `PbacDictionaryCache` — an in-memory singleton. Zero DB hits per request. No backend work needed.

---

## System Context

- **Offline/Online:** Offline-first. `PolicyManager.can()` reads `AuthManager.capabilities` (in-memory `ValueNotifier<Set<String>>` loaded from SQLite at login).
- **APIs:** No API calls. All checks are synchronous.
- **RBAC/PBAC:** `submissionsReview` capability controls Void Audit action. `templatesCreate` controls template mutation actions (Edit, Duplicate, Delete, FAB).
- **DI:** `PolicyManager` is registered as `LazySingleton` in `locator.dart`. Already imported in `template_list_page.dart` (via `PermissionGuard`). Must add import to `submission_row.dart` and `history_list_view.dart`.

---

## Lifecycle Context (4-State Matrix)

| State | Behavior After This Change |
|---|---|
| **Loading** (caps not yet loaded) | `PolicyManager.can()` returns `false` → admin buttons hidden. Fail-safe deny. ✅ |
| **Success** (caps loaded) | `pm.can(AppCapabilities.submissionsReview)` / `templatesCreate` returns correct value from in-memory Set. ✅ |
| **Error** (auth failure) | `AuthManager` clears capabilities. All guarded widgets hidden. ✅ |
| **Empty** (user has no capabilities) | Same as Loading. All hidden. ✅ |

---

## Test Contracts

| ID | Scenario | Input State | Expected Output | Why it fails RED first |
|---|---|---|---|---|
| TC-01 | Auditor without `templates:create` opens Template list | JWT without `templates:create` | FAB hidden. No Edit/Duplicate/Delete in card menu. | `isAdmin = role == 'admin'` would have shown nothing for auditor anyway — but now it's capability-driven, not role-driven. |
| TC-02 | Admin with `templates:create` opens Template list | JWT with `templates:create` | FAB visible. Edit/Duplicate/Delete in card menu visible. | If `pm.can()` broken, FAB hidden. |
| TC-03 | Area Manager with `templates:create` opens Template list | JWT with `templates:create` but role `area_manager` | FAB visible. Edit/Duplicate/Delete visible. | Old code: `role == 'admin'` → `false` for area_manager. New code: `pm.can()` → `true`. **This is a behavioral improvement.** |
| TC-04 | Auditor without `submissions:review` views Submission feed | JWT without `submissions:review` | Void Audit hidden in `submission_row.dart` popup menu. | Old code: `role == 'admin'` → false for auditor. Same result but now capability-driven. |
| TC-05 | Admin with `submissions:review` views Submission feed | JWT with `submissions:review` | Void Audit visible in popup menu. | Same behavior, now PBAC-gated. |
| TC-06 | Auditor without `submissions:review` views History | JWT without `submissions:review` | `onVoidAudit` is null in `history_list_view.dart`. Void UI not shown. | Old: `role == 'admin'` → null. New: `pm.can()` → null. Same but PBAC-driven. |
| TC-07 | Admin with `submissions:review` views History | JWT with `submissions:review` | Void Audit dialog available from history list. | `pm.can()` must return `true`. |
| TC-08 | `online_capability_grid.dart` role management screen | Admin editing 'admin' role | `isSelfLock = true`. Admin:access checkbox disabled. | **No change to this file.** Verifier must confirm `role == 'admin'` on line 114 is untouched. |
| TC-09 | `pm.can()` called before capabilities loaded | Empty `AuthManager.capabilities.value` | Returns `false` for all checks. Buttons hidden. | Fail-safe deny behavior must hold. |

---

## Test Fixture & Payloads

**No API contracts.** This is a pure UI visibility test using the local PBAC state.

**Required Test Fixture State (manual testing):**
- Flutter app running locally.
- Login with **auditor JWT** (role: `auditor`, capabilities: `submissions:create`, `submissions:list` only).
- Login with **admin JWT** (role: `admin`, capabilities include `templates:create`, `submissions:review`).
- Login with **area_manager JWT** with `templates:create` assigned in PBAC DB.

---

## Tools & Commands

**Skills the Builder needs:**
- `flutter-api` — Widget tree changes.

**Test commands (run after each file change):**
```
cmd /c rtk flutter analyze lib/features/templates/pages/template_list_page.dart
cmd /c rtk flutter analyze lib/features/dashboard/pages/widgets/submission_row.dart
cmd /c rtk flutter analyze lib/features/audit/pages/widgets/history_list_view.dart
```
**Full analysis after all changes:**
```
cmd /c rtk flutter analyze lib/
```

---

## Proposed Changes

| Status | File | Change |
|---|---|---|
| [MOD] | `lib/features/templates/pages/template_list_page.dart` | Line 162: Replace `role == 'admin'` with `_di<PolicyManager>().can(AppCapabilities.templatesCreate)`. Remove unused `AuthManager` import if no other usage. |
| [MOD] | `lib/features/dashboard/pages/widgets/submission_row.dart` | Line 253–254: Replace inline `role == 'admin'` with `_di<PolicyManager>().can(AppCapabilities.submissionsReview)`. Add import for `PolicyManager` and `AppCapabilities`. |
| [MOD] | `lib/features/audit/pages/widgets/history_list_view.dart` | Line 92: Extract capability check to local variable `canVoid`. Replace ternary condition with `canVoid`. Add imports for `PolicyManager` and `AppCapabilities`. |
| [NO CHANGE] | `lib/features/admin/widgets/online_capability_grid.dart` | Line 114 uses `role == 'admin'` as a DATA comparison (role being edited), not auth. Leave untouched. |

---

## Concept Diagram

```
Before:
[Widget] --> [AuthManager.currentUser?.role == 'admin'] --> show/hide button
                 ↑ Magic string. Not PBAC.

After:
[Widget] --> [PolicyManager.can(AppCapabilities.submissionsReview)] --> show/hide button
                 ↑ Reads from AuthManager.capabilities (in-memory Set<String>)
                 ↑ Loaded from SQLite at login (offline-safe)
```

---

## Execution Phase: Auth/Visibility Sweep (3 files)

**Complexity: Low** — Three isolated line-level swaps. No new widgets. No new state. No new API.

**Plain English Summary:**
Three widgets in the app still ask "is the user an admin?" by checking the raw role string. We replace each check with a PBAC question: "does the user have the right capability?". No visual change for users who have the expected capabilities — but now the check is capability-driven, which means a future role (e.g., `supervisor`) can get `submissions:review` without changing any widget code.

**Why this step now?**
This is the lowest-risk change. It's widget-level only. No structural changes. No new files. The PBAC infrastructure (`PolicyManager`, `AppCapabilities`) is already built and registered in DI.

**Scenario Focus:** Basic Scenario — auth/visibility access control.

**Value Delivered:**
When this phase is done: zero `role == 'admin'` strings remain in feature widget auth checks. Any role with the correct capability sees the correct buttons.

**Entry State Required:**
- `PolicyManager` registered in `locator.dart` ✅ (confirmed)
- `AppCapabilities.templatesCreate` and `AppCapabilities.submissionsReview` defined ✅ (confirmed)
- No current Flutter analyzer errors in these 3 files.

**Exit State Guaranteed:**
- `flutter analyze lib/` produces zero new errors or warnings for these 3 files.
- `grep_search` for `role == 'admin'` in `template_list_page.dart`, `submission_row.dart`, and `history_list_view.dart` returns zero results.
- `online_capability_grid.dart:114` is untouched (verify with grep).

**Architectural Scope:** Flutter only. 3 modified files. 0 new files. 0 backend files.

**Step-by-Step Builder Instructions (Anti-Attention Collapse):**
> **One file per step. Run `flutter analyze` after each. Do not batch.**

**Step 1 — `template_list_page.dart`**

*Change:*
- Line 162: `final isAdmin = _di<AuthManager>().currentUser?.role == 'admin';`
- Replace with: `final isAdmin = _di<PolicyManager>().can(AppCapabilities.templatesCreate);`
- Add import: `import '../../../_shared/services/policy_manager.dart';`
- Check: does `AuthManager` have any other usage in this file? If not, remove the `AuthManager` import. (The file already imports `AppCapabilities` and `PermissionGuard`.)
- Run: `flutter analyze lib/features/templates/pages/template_list_page.dart`

**Step 2 — `submission_row.dart`**

*Change:*
- Line 253–254 inside `itemBuilder`:
  ```
  final isAdmin =
      _di<AuthManager>().currentUser?.role == 'admin';
  ```
  Replace with:
  ```
  final canVoid =
      _di<PolicyManager>().can(AppCapabilities.submissionsReview);
  ```
- Rename `isAdmin` to `canVoid` in the `if (isAdmin)` guard on the `PopupMenuItem` below (line 276).
- Add imports:
  ```dart
  import '../../../../_shared/services/policy_manager.dart';
  import '../../../../_shared/constants/app_capabilities.dart';
  ```
- Check: `AuthManager` is still used on line 39 (`currentUser?.userId`). Keep that import.
- Run: `flutter analyze lib/features/dashboard/pages/widgets/submission_row.dart`

**Step 3 — `history_list_view.dart`**

*Change:*
- Line 92: The `onVoidAudit` ternary uses `_di<AuthManager>().currentUser?.role == 'admin'` as its condition.
- Extract to local variable before the `StoreGroup` call:
  ```dart
  final canVoid = _di<PolicyManager>().can(AppCapabilities.submissionsReview);
  ```
- Replace the ternary condition on line 92 with `canVoid`.
- Add imports:
  ```dart
  import '../../../../_shared/services/policy_manager.dart';
  import '../../../../_shared/constants/app_capabilities.dart';
  ```
- Check: `AuthManager` import on line 5 — no other usage in this file after the change. Remove it.
- Run: `flutter analyze lib/features/audit/pages/widgets/history_list_view.dart`

**Step 4 — Verify Scope is Clean**

```
flutter analyze lib/
grep_search lib/ "role == 'admin'" (MatchPerLine=true)
```
Expected: `online_capability_grid.dart:114` remains. The 3 modified files must not appear.

**Pros & Cons of this approach:**

| Aspect | Pro | Con |
|---|---|---|
| Keep `TemplateCard.isAdmin: bool` API | Zero breaking change to `TemplateCard` | `isAdmin` variable name is now semantically misleading (it's actually `canManageTemplates`) |
| Rename `isAdmin` → `canManageTemplates` in `template_list_page.dart` only | More readable | Adds one line of rename work |

> **Builder Decision:** Keep `TemplateCard.isAdmin` prop name unchanged (it's a local API, not public). The parent now passes `pm.can(AppCapabilities.templatesCreate)` to it. No rename needed in `TemplateCard`. This is the lowest blast radius option.

---

<command_logs>
- `grep_search lib/ "role\\s*==\\s*'[a-z]"` — 17 results, confirmed 3 Slice 1 targets
- `grep_search lib/ "PolicyManager|pm\\.can\\(|AppCapabilities\\."` — confirmed DI registration, existing usage pattern
- `view_file template_list_page.dart` (1–292) — full file. Line 162 violation confirmed. FAB already wrapped in `PermissionGuard`.
- `view_file history_list_view.dart` (1–251) — full file. Line 92 violation confirmed. Pattern: function-vs-null ternary.
- `view_file submission_row.dart` (1–341) — full file. Line 253–254 violation confirmed. Pattern: `isAdmin` inside `itemBuilder`.
- `view_file online_capability_grid.dart` (1–166) — full file. Line 114 confirmed as data comparison on edited role. No change.
- `view_file app_capabilities.dart` — confirmed `submissionsReview` and `templatesCreate` constants exist.
- `view_file policy_manager.dart` — confirmed synchronous `can()` method.
- `view_file template_card.dart` — confirmed `isAdmin: bool` prop flows into Edit/Duplicate/Delete guards. Source is the only change needed.
</command_logs>

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `pm.can()` returns wrong value if `AuthManager.capabilities` not yet loaded | Low | `PolicyManager.can()` returns `false` (fail-safe deny). Buttons hidden. Acceptable. |
| Capability string typo in `pm.can('...')` call | Medium | MANDATORY: use `AppCapabilities.xyz` constant. Compiler does not catch raw string typos. |
| `online_capability_grid.dart:114` incorrectly modified | Medium | Builder MUST verify with grep after work: `role == 'admin'` at that line must remain. |
| Forgetting to remove unused `AuthManager` import | Low | `flutter analyze` will flag unused import as a warning. Fix before declaring done. |

---

## Verification Plan

**Manual testing steps after all 3 file changes:**

1. Run `flutter analyze lib/` — must produce zero errors or new warnings.
2. Run `grep_search lib/features/templates/pages/template_list_page.dart "role == 'admin'"` — must return zero results.
3. Run `grep_search lib/features/dashboard/pages/widgets/submission_row.dart "role == 'admin'"` — must return zero results.
4. Run `grep_search lib/features/audit/pages/widgets/history_list_view.dart "role == 'admin'"` — must return zero results.
5. Run `grep_search lib/features/admin/widgets/online_capability_grid.dart "role == 'admin'"` — must return 1 result (line 114, untouched).
6. **Login with auditor JWT** and navigate to Templates → FAB must be hidden.
7. **Login with admin JWT** and navigate to Templates → FAB must be visible, and Edit/Duplicate/Delete appear in the card context menu.
8. **Login with auditor JWT** and open Dashboard submission feed → "Void Audit" option must NOT appear in the popup menu.
9. **Login with admin JWT** and open Dashboard submission feed → "Void Audit" option must appear in the popup menu.
10. **Login with auditor JWT** and open History page → void audit dialog must not be triggerable.

---



**Summary for Builder Agent:**
Replace 3 hardcoded `role == 'admin'` auth checks with `PolicyManager.can()` calls. Flutter only. 3 files. One step per file. Run `flutter analyze` after each step. Do NOT touch `online_capability_grid.dart`.

**Strict Builder Constraints:**
1. Read each file with `view_file` before editing. Do not edit from memory.
2. All `pm.can()` calls MUST use `AppCapabilities.xyz` constants — no raw strings.
3. One file per micro-step. Yield after each step for compile check.
4. Do NOT touch: `online_capability_grid.dart`, any DAO, any backend file.
5. After Step 3, run `grep_search` to prove the 3 files are clean.

**Routing Commands (run ONE AT A TIME):**

```
@[/implement] Execute build for Execution Phase (Step 1 — template_list_page.dart):
c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\implementation_plan_20260508_083700_a736cb_pbac-slice1.md
```
Then, after Step 1 passes:
```
@[/implement] Execute build for Execution Phase (Step 2 — submission_row.dart):
c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\implementation_plan_20260508_083700_a736cb_pbac-slice1.md
```
Then, after Step 2 passes:
```
@[/implement] Execute build for Execution Phase (Step 3 — history_list_view.dart):
c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\implementation_plan_20260508_083700_a736cb_pbac-slice1.md
```

**Concurrency:** Steps 1, 2, 3 are SEQUENTIAL. Each step must pass `flutter analyze` before the next begins.

**After all 3 steps complete → run Slice 2:**
```
@[/analyze-feature] c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\analysis_epic_20260507_212618_a736cb_pbac-dynamic-ui.md
```
Instruct: "Plan Slice 2 only — the UserPersona structural layout sweep."
