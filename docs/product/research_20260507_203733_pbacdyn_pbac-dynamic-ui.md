# Research: Migrating UI to Dynamic PBAC Capability Checks

`[ORIGIN_IDEA]`: The user requested an investigation into whether the completed PBAC system can be used to remove hardcoded role checks in the Flutter app to make the system as dynamic and less hardcoded as possible, acknowledging that structural layouts may still need some role/persona awareness.

<latent_space_scratchpad>
- We found strings like `role == 'admin'`, `role == 'area_manager'` across `profile_page.dart`, `dashboard_manager.dart`, `history_list_view.dart`, etc.
- `PolicyManager` and `PermissionGuard` are already implemented and seeded with `AppCapabilities`.
- We need to replace conditional widget trees with `PermissionGuard` and replace conditional logic in Managers with `_di<PolicyManager>().can()`.
- The user is correct: data visibility and action execution (buttons, routing) should be 100% dynamic via PBAC.
- However, structural layouts (like which dashboard variant to show) might still rely on a "persona" enum rather than capabilities, because capabilities denote *what you can do*, not *what layout looks best for you*.
- We must adhere to the GEMINI.md rule: "Do not hardcode role string checks in the frontend".
</latent_space_scratchpad>

## E2E Workflow Map

**Upstream Triggers (Backend):**
1. Server seeds capabilities via `RoleCapabilities` DB.
2. `AppCapabilities` maps to strings like `templates:create`.
3. Client logs in, triggering `GET /api/system/capabilities`.

**App State Handoff (Frontend):**
1. `PolicyApiService` fetches payload.
2. `PolicyDao.upsertCapabilities()` stores to SQLite for offline access.
3. `AuthManager.capabilities` reflects memory state.
4. `PolicyManager.can(AppCapabilities.xyz)` provides synchronous checks.

**Status Quo Friction:**
Currently, UI components bypass this pipeline. Widgets explicitly read `currentUser.role == 'admin'` instead of using `PermissionGuard(capability: AppCapabilities.adminAccess)`. This breaks PBAC.

## Comparative Decision Matrix

### Option A: Strict Native Fit (Recommended)
Replace all data/action role checks with `PolicyManager.can()`. Introduce a `UserPersona` enum for purely structural layout choices (like Dashboard scaffolding) to remove string literals, but guard all actual widgets within that dashboard with capabilities.
- **Hypothesis**: Solves the rule conflict while keeping UI structure readable.
- **Architectural Implication**: Needs a sweep of all `role ==` instances.

### Option B: Pragmatic Balance
Only replace mutation/admin checks (like "Void Audit" or "Create Template") with PBAC. Leave dashboard routing alone.
- **Hypothesis**: Faster, but leaves string literals in code.
- **Architectural Implication**: Violates GEMINI.md mandate to remove magic strings.

### Option C: Enterprise Overhaul (Server-Driven UI)
Backend sends JSON detailing exactly which widgets to render based on roles.
- **Hypothesis**: 100% dynamic.
- **Architectural Implication**: Massive rewrite of Flutter architecture. Rejected due to over-engineering.

## Forensic Evidence
<forensic_evidence>
Executed `grep_search` across `lib/` for `role ==`. Found instances in:
- `lib/features/profile/pages/profile_page.dart` (`role == 'admin'`)
- `lib/features/dashboard/manager/dashboard_manager.dart`
- `lib/features/audit/pages/widgets/history_list_view.dart`
</forensic_evidence>

## Blind Spots & Non-Functional Requirements
1. **Offline Capability Drift**: If admin changes a user's role on the server, the offline client won't know until the next sync or active login, potentially allowing unauthorized offline actions (mitigated by server-side 403s on sync).
2. **Synchronous Race Conditions**: `PolicyManager` must be fully loaded before `DashboardManager` tries to evaluate capabilities for its layout.
3. **UX Layout vs Authorization**: A capability is an authorization unit, not a UI component specifier. "Area Manager Layout" is a UX concept, so entirely replacing it with capabilities might lead to weird, fragmented UI states if an Auditor is temporarily granted "Admin" capabilities.

## Conflicts with Rules
1. **Conflict**: Global `GEMINI.md` strictly forbids hardcoded role string checks (`u['role'] == 'auditor'`). The current codebase is in direct violation.
2. **Conflict**: Code uses Magic Strings (`'admin'`) instead of strongly typed Enums or Static Constants.

## Handoff Block

- **Verdict**: Viable. Proceed with Option A. We will migrate all access/action checks to PBAC capabilities using `PermissionGuard` and `PolicyManager`. We will also migrate the remaining structural role checks to a typed `UserPersona` enum.
- **Sizing**: Track C (Epic). This requires sweeping multiple features (Dashboard, Admin, Profile, Router).
- **AI Agent Mission Brief**: The Builder agent needs to sweep the Flutter codebase to replace hardcoded `role == 'x'` strings. Mutation/visibility checks must become `PolicyManager.can()` / `PermissionGuard` using `AppCapabilities`. Structural layout branches must use a new strongly-typed enum.
- **Next Command**: Please pass this directly to the feature analysis workflow by running: `/analyze-epic {c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260507_203733_pbacdyn_pbac-dynamic-ui.md}`
