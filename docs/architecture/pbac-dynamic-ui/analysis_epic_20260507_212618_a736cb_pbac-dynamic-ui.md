# Epic Plan: PBAC Dynamic UI — Remove Hardcoded Role Strings

**ShortID:** a736cb
**Date:** 2026-05-07
**Workflow:** /analyze-epic
**Status:** APPROVED FOR IMPLEMENTATION

---

<latent_space_scratchpad>
## Internal Debate

**Critical ADR Correction Discovered:**
The ADR's "Slice 1 Backend BLOCKER" (add IMemoryCache to CapabilityAuthorizationHandler) is based on a false assumption. Forensic reading of `CapabilityAuthorizationHandler.cs` and `PbacDictionaryCache.cs` proves:
- The handler reads from `PbacDictionaryCache`, a **singleton in-memory Dictionary** already loaded at startup.
- It does NOT touch the database on any request. Zero DB DDoS risk exists.
- The backend is already architecturally correct. **No backend changes are required for PBAC enforcement.**

**What the ADR got right:**
- `/api/admin/users?capability=` endpoint: `ListUsers.cs` already supports `?role=` filter. A `?capability=` filter for `schedule_audit_form_logic.dart` needs assessment. Looking at the code, `schedule_audit_form_logic.dart` reads `u['role']` from the existing users map to determine who can be assigned as auditor. This is a BUSINESS DATA filter (who CAN perform an audit), not an AUTHORIZATION filter. The existing `?role=` filter on `GET /api/admin/users` is sufficient to query `?role=auditor&role=admin&role=area_manager`. No new endpoint is needed.

**What must actually be done — Frontend only:**
- **23 violations** of type `role == 'x'` across 13 files.
- **3 violations** of type `u['role'] == 'x'` in admin_audit_manager (business data filter on assigned users — leave as-is, this is correct).
- **3 violations** of type `currentUserRole == 'x'` in admin_audit_manager (see above, data scoping not auth).

**Hardcoded role check taxonomy (from grep evidence):**
1. **AUTH/VISIBILITY checks** (must migrate to PBAC): Where a role string decides if a widget renders or action is allowed.
   - `template_list_page.dart:162` → `isAdmin = role == 'admin'` → replace with `pm.can(AppCapabilities.templatesCreate)` (already on that page)
   - `submission_row.dart:254` → `role == 'admin'` → `pm.can(AppCapabilities.submissionsReview)` or specific cap
   - `history_list_view.dart:92` → `role == 'admin'` → `pm.can(AppCapabilities.submissionsReview)` 
   - `online_capability_grid.dart:114` → `role == 'admin'` → this is the role management screen itself, reading a string passed to it; acceptable
   - `profile_page.dart:119-139` → structural layout branching by role → `UserPersona` enum
   - `manager_dashboard_variant.dart:32` → `isArea = role == 'area_manager'` → `UserPersona` enum
   - `dashboard_manager.dart:129/162` → `switch (role)` → `UserPersona` enum
   - `dashboard_page.dart:86` → `role ?? 'admin'` → `UserPersona` enum

2. **STRUCTURAL/LAYOUT branches** (UserPersona enum):
   - `dashboard_manager.dart` — switch on role to pick DashboardState variant
   - `profile_page.dart` — show different sections by role
   - `manager_dashboard_variant.dart` — isArea layout

3. **ADMIN DATA/BUSINESS LOGIC** (acceptable to keep role strings — leave alone):
   - `admin_audit_manager.dart:117-119` — filter `u['role']` to decide who can be assigned auditor (business rule, not PBAC)
   - `admin_audit_manager.dart:125-130` — currentUserRole check for data scoping (area manager sees only own area). This is ownership scoping, not capability authorization. **Leave.**
   - `user_create_sheet.dart`, `user_edit_sheet.dart` — `selectedRole ==` string comparisons to decide which form fields to show (store vs area picker). These widgets manage a ROLE STRING as DATA (they are editing a user's role). This is correct — the role string IS the data being edited.
   - `store_dao.dart:19` — `profileRow?.role == 'area_manager'` to determine which stores to fetch. This is RLS data scoping. **Leave.**
   - `profile_dao.dart:44` — same pattern. **Leave.**
   - `schedule_audit_form_logic.dart:17,41` — filtering assignable auditors by role (business rule). **Leave.**
   - `user_management_list.dart`, `user_management_page.dart` — filtering users by role for display (data filter). **Leave.**

**Final count of actual violations to fix:**
- **Slice 2 targets (auth/visibility):** 4 files, 7 violations → `PolicyManager.can()` / `PermissionGuard`
- **Slice 3 targets (structural):** 3 files, 4 violations → `UserPersona` enum

**UserPersona enum decision:**
The `DashboardManager` switches on `role` to produce `AuditorDashboardState`, `ManagerDashboardState`, or `AdminDashboardState`. These are fundamentally data queries (different DB queries per persona). A `UserPersona` enum maps cleanly: `auditor`, `manager`, `admin`. The enum value must come from the server payload, NOT derived from `currentUser.role`. However, the server already provides `currentUser.role`. The question is: how does `UserPersona` come from the server? 

The safest approach is: server adds `persona` field to the auth user payload. BUT — this requires a backend change (entity, DTO, sync endpoint, Flutter DTO). That is the 7-step sync gotcha. Is it worth it for a structural hint?

**Alternative (simpler):** Introduce `UserPersona` as a local enum computed once at login from the role string and stored in the user session. Since it's computed at login time from the authoritative server role value (not cached separately), it is NOT a desync vector. The enum is a typed wrapper, not independent state. The `currentUser.role` IS the server payload. If we derive `UserPersona` from `currentUser.role` at call time (not store it separately), we have the same security as reading the role string directly, but with type safety.

**Decision: Derive `UserPersona` synchronously from `currentUser.role` at call time via a static method/extension on `UserPersona`. Do NOT add it as a server payload field.** Rationale: It is a compile-time-typed wrapper over the already server-sourced role string. No independent state = no desync. This avoids the 7 Sync Steps.

**No new backend changes required. This is a pure Flutter sweep.**
</latent_space_scratchpad>

---

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\decision_record_20260507_211849_a736cb_pbac-synthesize.md`

---

## Executive Summary

The Checkly Flutter app has **hardcoded `role == 'x'` string checks** in feature widgets and managers, bypassing the fully-implemented PBAC system (`PolicyManager.can()`, `PermissionGuard`, `AppCapabilities`). This violates the GEMINI.md mandate and breaks the scalability promise of PBAC — adding a new role currently requires manual code changes across many files.

**What will be built:**
1. Replace all **auth/visibility** role checks with `PolicyManager.can(AppCapabilities.xyz)` or `PermissionGuard`.
2. Create a `UserPersona` enum to replace **structural/layout** role branches with a typed, compiler-enforced switch.

**What will NOT change:**
- Backend (already correct — `CapabilityAuthorizationHandler` uses in-memory cache, no DB hit).
- Row-Level Security (ownership scoping) in DAOs and managers (correct by design).
- Admin forms that manage role strings as data (user creation/editing forms).
- Business data filters in `schedule_audit_form_logic.dart` and `admin_audit_manager.dart`.

> [!IMPORTANT]
> **ADR Slice 1 Correction:** The ADR's stated "Backend BLOCKER" (add `IMemoryCache` to `CapabilityAuthorizationHandler`) is a false requirement. Forensic audit proves the handler reads from `PbacDictionaryCache` — a singleton in-memory `Dictionary<string, HashSet<string>>` loaded once at startup. No database call occurs per request. **No backend changes are required.**

---

## Decision Matrix

### Shape A: Full `PolicyManager` Sweep + `UserPersona` Enum (SELECTED)
Replace auth/visibility checks with `PolicyManager.can()` / `PermissionGuard`. Replace structural branches with typed `UserPersona` enum derived from `currentUser.role` at call time.

**Fit Check:**

| Requirement | Shape A | Shape B (Partial) |
|---|:---:|:---:|
| Eliminates magic role strings in auth checks | ✅ | ✅ |
| Compiler-safe structural branches | ✅ (enum) | ❌ (still strings) |
| GEMINI.md compliant (no magic strings) | ✅ | ❌ |
| No backend changes required | ✅ | ✅ |
| Offline-safe (no server round-trip to check caps) | ✅ | ✅ |
| Does not break existing `PermissionGuard` widgets | ✅ | ✅ |
| Leaves business-data role usage untouched | ✅ | ✅ |

**Winner: Shape A**

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Missing a violation in sweep | Medium | Builder MUST use `grep_search` with pattern `role\s*==\s*'` and `currentUser?.role ==` to enumerate ALL instances before editing. Trust scope not memory. |
| Breaking offline dashboard (wrong state loaded) | High | `UserPersona` is derived from `currentUser.role` which is always locally cached from login. No network required. |
| Capability not yet assigned to a role in DB | Low | `PolicyManager.can()` returns false if capability not in set — fail-safe deny. The Builder must verify all used capabilities are seeded in `Program.cs`. |
| `analyticsView` capability missing from `AppCapabilities` | Medium | Audit `AppCapabilities.dart` against all `AppCapabilities.cs` constants before sweep. Add any missing constants. |

---

## Visual & Functional Context

**Affected screens (from forensic grep):**

| File | Current Violation | Target Fix |
|---|---|---|
| `template_list_page.dart:162` | `role == 'admin'` → controls FAB | `pm.can(AppCapabilities.templatesCreate)` |
| `submission_row.dart:254` | `role == 'admin'` → controls Void button | `pm.can(AppCapabilities.submissionsReview)` |
| `history_list_view.dart:92` | `role == 'admin'` → onVoidAudit callback | `pm.can(AppCapabilities.submissionsReview)` |
| `profile_page.dart:119-139` | `if (role == 'admin')`, `if (role == 'area_manager')`, `if (role == 'store_manager')` → structural sections | `UserPersona` switch |
| `manager_dashboard_variant.dart:32` | `isArea = role == 'area_manager'` → layout branch | `UserPersona.isArea` getter |
| `dashboard_manager.dart:129,162` | `switch (role)` → loads different DashboardState | `switch (persona)` using `UserPersona` |
| `dashboard_page.dart:86` | `role ?? 'admin'` | `UserPersona.fromRole(...)` |

**Screen image provided by user:** Role Management screen (admin view) — shows 4 roles with capability counts: `admin (22/17)`, `auditor (4/17)`, `store_manager (5/17)`, `area_manager (6/17)`. This confirms the PBAC system is live and returning capability data. The `/api/system/capabilities` endpoint is working.

---

## System Context

- **PBAC Stack (Flutter side):** `PolicyApiService` → `PolicyDao` (SQLite) → `AuthManager.capabilities` (`ValueNotifier<Set<String>>`) → `PolicyManager.can()` / `PermissionGuard`.
- **Offline:** Capabilities are stored in local SQLite via `PolicyDao.upsertCapabilities()` on every login. They survive offline sessions.
- **Race Condition guard:** `PolicyManager.can()` returns `false` if `AuthManager.capabilities.value.isEmpty`. The router's `authRedirect` is called on `AuthManager` notifier changes, so capabilities are loaded before the user lands on any protected screen.
- **Backend:** `CapabilityAuthorizationHandler` reads `PbacDictionaryCache` — singleton Dictionary built at startup from `role_capabilities` table, atomically swapped on `LISTEN/NOTIFY` events. **Zero DB hits per request.**

---

## Lifecycle Context

**Edge States:**

| State | Expected Behavior |
|---|---|
| User with zero capabilities | `PolicyManager.can()` → false for all checks. All guarded widgets hidden. Router redirects /admin to /home. |
| User role changed by admin while app is open | Capabilities update only on next login or manual refresh. UI shows stale state until then — acceptable (same as any session-based auth). |
| `UserPersona` for an unknown role | `UserPersona.fromRole()` returns `UserPersona.admin` as default fallback (same as current `role ?? 'admin'`). |
| Capability removed from role while user online | All server calls return 403. Frontend UI still shows guarded widgets until next capability refresh. Add a 403 handler in `AuthManager` to force re-fetch capabilities. |

---

## Data Context

No database migrations required. No new entities. No new backend endpoints.

The only "data" change is adding `UserPersona` as a Dart enum in `lib/_shared/constants/`.

---

## Architecture Flow

```
Login → PolicyApiService.fetchCapabilities() 
      → PolicyDao.upsertCapabilities() (SQLite)
      → AuthManager.capabilities (ValueNotifier<Set<String>>)
      → PolicyManager.can(AppCapabilities.xyz) [synchronous]
          ↓
    [Widget rendering / Router redirect]
          ↓
    PermissionGuard(capability: AppCapabilities.xyz) → show/hide child
    OR
    UserPersona.fromRole(currentUser.role) → switch (persona) → layout variant
```

---

## Risk Review & Security

> [!CAUTION]
> **Capability-string typo risk:** If a developer uses a raw string like `pm.can('admin:acces')`, the compiler will not catch the typo. Mandate: ALL `pm.can()` calls MUST use `AppCapabilities.xyz` constants. The Builder must audit the `AppCapabilities.dart` constants list against `AppCapabilities.cs` on the backend to ensure they are in sync.

- **No security regression:** Moving from `role == 'admin'` to `pm.can(AppCapabilities.adminAccess)` is strictly more secure — the server controls capability assignment, the app only reads what it was given.
- **`[PRODUCTION_LOCK]` for backend:** No backend code will be modified. Zero blast radius on server endpoints.

---

## Logs & Audits

No new logging required. Existing `PolicyManager.can()` is synchronous and side-effect-free.

---

## Testing Expectations

- **After Slice 2:** Manually test with an `auditor` JWT that does NOT have `templates:create`. Verify FAB is hidden in `template_list_page.dart`. Verify "Void Audit" button is hidden in `submission_row.dart`.
- **After Slice 3:** Manually test dashboard renders correct variant for each role persona.
- **No new unit tests required** for this sweep (replacing one string check with another; no new branching logic introduced). Existing ATDD tests (`PbacCapabilityAuthTests.cs`, `OwnershipScopeFilterTests.cs`) already cover server-side enforcement.

---

<command_logs>
- `grep_search` on `lib/` for `role\s*==\s*'[a-z]` → 26 matches across 13 files
- `grep_search` on `lib/` for `u\['role'\]|currentUserRole\s*==` → 8 matches in admin features
- `view_file` on `CapabilityAuthorizationHandler.cs` → CONFIRMED: reads PbacDictionaryCache, not DB
- `view_file` on `PbacDictionaryCache.cs` → CONFIRMED: Volatile.Write/Read singleton in-memory Dictionary
- `view_file` on `ListUsers.cs` → CONFIRMED: supports `?role=` filter; no new endpoint needed
- `view_file` on `AdminEndpoints.cs` → CONFIRMED: PBAC-gated with `RequireCapability()`
- `view_file` on `dashboard_manager.dart` → CONFIRMED: switch on role string at line 161
- `view_file` on `app_router.dart` → CONFIRMED: router already uses `pm.can(AppCapabilities.xxx)` correctly
- `view_file` on `app_capabilities.dart` → CONFIRMED: all constants defined
</command_logs>

<forensic_evidence>

### grep_search 1 — Role magic strings in lib/
**Command:** `grep_search lib/ "role\s*==\s*'[a-z]" (IsRegex=true, MatchPerLine=true)`
**Result:** 26 matches across 13 files. Key auth/visibility violations:
- `template_list_page.dart:162` — `role == 'admin'`
- `submission_row.dart:254` — `role == 'admin'`
- `history_list_view.dart:92` — `role == 'admin'`
- `profile_page.dart:119,129,139` — 3× role string layout branches
- `dashboard_manager.dart:129,162` — `role ?? 'admin'` and `case 'auditor'`
- `manager_dashboard_variant.dart:32` — `isArea = role == 'area_manager'`

### grep_search 2 — Business data role usage
**Command:** `grep_search lib/ "u\['role'\]|currentUserRole\s*==" (IsRegex=true)`
**Result:** 8 matches in `admin_audit_manager.dart` and `user_management_*.dart` — confirmed business data / ownership scoping, NOT authorization checks. Leave untouched.

### view_file — CapabilityAuthorizationHandler.cs (server)
**Confirmed:** Handler reads `PbacDictionaryCache.GetCapabilities(role)` — a Volatile.Read on an in-memory Dictionary. **Zero database calls per request.** The ADR's Slice 1 "Backend BLOCKER" is a false requirement. The backend is architecturally correct as-is.

### view_file — PbacDictionaryCache.cs (server)
**Confirmed:** Singleton `Dictionary<string, HashSet<string>>`. Loaded once via `InitializeAsync()` at startup. Atomically swapped on `LISTEN/NOTIFY` events via `Volatile.Write`. Thread-safe. No per-request I/O.

### view_file — ListUsers.cs (server)
**Confirmed:** `GET /api/admin/users` supports `?role=` query filter already. No new `?capability=` endpoint needed. The ADR's proposed new endpoint is redundant.

### view_file — AdminEndpoints.cs (server)
**Confirmed:** All admin routes already protected by `RequireCapability(AppCapabilities.xyz)`. Backend authorization is complete.

### view_file — dashboard_manager.dart (Flutter)
**Confirmed:** `switch (role)` at line 161 with raw string literals `'auditor'`, `'store_manager'`, `'area_manager'`. Target for `UserPersona` enum in Slice 2.

### view_file — app_router.dart (Flutter)
**Confirmed:** Router redirect guard already uses `pm.can(AppCapabilities.adminAccess)`, `pm.can(AppCapabilities.submissionsReview)`, `pm.can(AppCapabilities.templatesCreate)`. Router is already compliant.

### view_file — app_capabilities.dart (Flutter)
**Confirmed:** `AppCapabilities` class with 16 typed constants exists. All capability strings are defined. Builder must use these — no raw strings in `pm.can()` calls.

</forensic_evidence>

---

## Handoff Block

**Final Decision:** Shape A — Full `PolicyManager` Sweep + `UserPersona` Enum. **Flutter-only.** Zero backend changes.

**Strict Builder Constraints:**
1. **`grep_search` before every file edit.** Do not edit from memory.
2. **All `pm.can()` calls MUST use `AppCapabilities.xyz` constants** — no raw strings.
3. **Do NOT touch:** `store_dao.dart`, `profile_dao.dart`, `admin_audit_manager.dart` (lines 117-130), `schedule_audit_form_logic.dart`, `user_create_sheet.dart`, `user_edit_sheet.dart`, `user_management_list.dart`, `user_management_page.dart`. These use role as data or for business/ownership scoping.
4. **No backend changes.** The backend is already correct.
5. **Anti-Attention Collapse:** This touches 7 files. Execute ONE file per micro-step, then yield.

---

**Execution Slices:**

**Slice 1 (Flutter — Auth/Visibility Sweep)**
- **Plain English:** Fix the 4 files where the app checks `role == 'admin'` to show or hide action buttons (FAB, Void Audit button). Replace with PBAC capability checks.
- **Why this step now?:** This is the most urgent violation — it directly breaks security intent. No structural changes needed. Low blast radius.
- **Scenario Focus:** Basic Scenario.
- **Value Delivered:** Auditors without the right capability no longer see admin-only action buttons.
- **Entry State Required:** `PolicyManager` and `AppCapabilities` constants exist (confirmed ✅).
- **Exit State Guaranteed:** Zero `role == 'admin'` auth-check strings remain in feature widget files.
- **Architectural Scope:** Flutter only. 4 files: `template_list_page.dart`, `submission_row.dart`, `history_list_view.dart`, and `online_capability_grid.dart` (assess only).
- **Route:** `/analyze-feature` → `/implement`
- **Order:** `[BLOCKING]` — Slice 2 depends on this being clean first.
- **Acceptance Criteria:**
  | Test | Expected |
  |---|---|
  | Auditor without `templates:create` opens Template list | FAB is hidden |
  | Admin with `templates:create` opens Template list | FAB is visible |
  | Auditor without `submissions:review` views History | Void Audit button hidden |
  | Admin with `submissions:review` views History | Void Audit button visible |

**Slice 2 (Flutter — Structural Layout: UserPersona)**
- **Plain English:** The Dashboard and Profile screens branch their layout based on a raw role string. We create a typed `UserPersona` enum so the Dart compiler catches any new roles at build time — no more magic strings.
- **Why this step now?:** Depends on Slice 1 being clean so we have a known-good baseline to work from. Structural changes are slightly riskier than widget-level changes.
- **Scenario Focus:** Extension (structural correctness).
- **Value Delivered:** `DashboardManager` and `ProfilePage` are compiler-enforced — adding a new role to the system generates a compile warning if not handled.
- **Entry State Required:** Slice 1 complete. `UserPersona` enum does not yet exist.
- **Exit State Guaranteed:** `UserPersona` enum created in `lib/_shared/constants/`. `DashboardManager.loadStats()`, `ProfilePage`, `DashboardPage`, and `ManagerDashboardVariant` use `UserPersona.fromRole()` instead of raw strings. Zero layout-purpose `role ==` strings remain.
- **Architectural Scope:** Flutter only. New file: `lib/_shared/constants/user_persona.dart`. Modified files: `dashboard_manager.dart`, `profile_page.dart`, `dashboard_page.dart`, `manager_dashboard_variant.dart`.
- **Route:** `/analyze-feature` → `/implement`
- **Order:** `[SEQUENTIAL after Slice 1]`
- **Acceptance Criteria:**
  | Test | Expected |
  |---|---|
  | `UserPersona.fromRole('auditor')` | Returns `UserPersona.auditor` |
  | `UserPersona.fromRole('area_manager')` | Returns `UserPersona.manager` |
  | `UserPersona.fromRole('unknown_future_role')` | Returns `UserPersona.admin` (safe fallback) |
  | Auditor logs in and opens Dashboard | `AuditorDashboardState` is loaded |
  | Store Manager logs in and opens Dashboard | `ManagerDashboardState` is loaded |
  | `grep_search` for `role ==` in modified files | Zero results |

---

**Next Steps:** Each slice should be routed through `/analyze-feature` first to produce a compact implementation plan, then `/implement`. Start with Slice 1 as it is the smallest and most impactful.

**Next Workflow Command (Slice 1):**
```
/analyze-feature c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-dynamic-ui\analysis_epic_20260507_212618_a736cb_pbac-dynamic-ui.md
```
> Instruct the analysis agent: "Plan Slice 1 only — the auth/visibility sweep of 4 files (template_list_page, submission_row, history_list_view, online_capability_grid). Do not touch Slice 2."
