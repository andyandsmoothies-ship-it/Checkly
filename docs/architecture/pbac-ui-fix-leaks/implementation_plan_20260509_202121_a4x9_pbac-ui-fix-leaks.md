<latent_space_scratchpad>
- `analytics:view`: Easy fix, just add a guard in `authRedirect` for `/analytics`.
- `submissions:list`: Hide the Activity tab in `main_shell.dart`. Could also add a route guard for `/activity` in `authRedirect`.
- `programs` routes: Add segment-based checking in `authRedirect` (`/programs` -> list, `/programs/new` -> create, `/programs/review` -> review, `/programs/:id` -> execute).
- Admin pages: Update cards to accept nullable callbacks and hide the action UI (e.g. `PopupMenuButton` in `StoreCard`) when callbacks are null. Hide FABs in the list pages based on the specific capability (`stores:write`, `areas:write`, `global_risks:manage`).
</latent_space_scratchpad>

# Task: PBAC UI Leaks Fix
Workflow: /analyze-feature | Track: A

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\493220d8-99f2-4839-9729-5c0dc0748efe\pbac_roles_and_options_report_FINAL.md.resolved`

## Executive Summary & Out of Scope
**Goal:** Address UI leaks and partial guards identified in the PBAC compliance check. Ensure routes and UI elements properly enforce `analytics:view`, `submissions:list`, `programs:*`, and granular admin capabilities (`stores:write`, `areas:write`, `global_risks:manage`).
**Out of Scope:** We will not change the backend enforcement logic or add new capabilities to the `AppCapabilities` list.

## System Context
- **Capabilities Checked**: `analytics:view`, `submissions:list`, `programs:list`, `programs:create`, `programs:review`, `programs:execute`, `stores:write`, `areas:write`, `global_risks:manage`.
- **Enforcement Layer**: Router (`app_router.dart`), Shell (`main_shell.dart`), and Admin UI Pages/Cards.

## Lifecycle Context
- **Empty/Read-Only State**: Users without write access to Admin pages will see a read-only list. FABs and 3-dot menus/InkWells will be hidden/disabled.

## Test Contracts
| ID | Exact Text | State Matrix |
|---|---|---|
| TC-01 | Router blocks `/analytics` if missing `analytics:view` | Route redirects to `/home`. |
| TC-02 | Router blocks `/programs` routes based on segments | `/programs` -> list, `/programs/new` -> create, etc. Redirects to `/home` if denied. |
| TC-03 | Activity Tab is hidden without `submissions:list` | Tab is absent from BottomNavigationBar. |
| TC-04 | Admin pages become read-only | FABs omitted; `StoreCard`, `AreaCard`, `RiskCard` disable taps/menus. |

## Tools & Commands
- **Testing**: `flutter test`
- **Linting**: `flutter analyze`

## Risk Assessment
**Risk Level: Low**.
The changes are isolated to frontend routing and UI rendering conditionals. No backend API contracts or core state management logic are affected.
**Tradeoffs:** Enforcing granular capability checks inside `app_router.dart` for the `/programs` module slightly increases the routing complexity but prevents deep-link leaks. Passing null to `onEdit`/`onTap` simplifies the components without requiring entirely new Read-Only component variants.

## Verification Plan
1. **Automated tests:** Run the global Flutter test suite to ensure router updates don't break existing navigation tests.
2. **Visual/Manual:** Log in as a user with partial capabilities and verify `/analytics` and `/programs` gracefully redirect to `/home`.

## Proposed Changes
- `[MOD] lib/_shared/router/app_router.dart`: Add route guards for analytics, activity, and programs.
- `[MOD] lib/_shared/router/main_shell.dart`: Hide ACTIVITY tab if no `submissions:list`.
- `[MOD] lib/features/admin/pages/store_management_page.dart`: Pass `null` to edit callbacks and hide FAB if no `stores:write`.
- `[MOD] lib/features/admin/pages/widgets/store_card.dart`: Support null callbacks.
- `[MOD] lib/features/admin/pages/area_management_page.dart`: Hide FAB, pass null if no `areas:write`.
- `[MOD] lib/features/admin/widgets/area_card.dart`: Support null `onTap`.
- `[MOD] lib/features/admin/pages/global_risk_management_page.dart`: Hide FAB, pass null if no `global_risks:manage`.
- `[MOD] lib/features/admin/pages/widgets/risk_card.dart`: Support null `onTap`.

## Concept Diagram
```text
[Router] -> Intercepts /analytics -> Requires analytics:view -> Allow/Redirect
[Router] -> Intercepts /programs/* -> Checks path segments -> Requires specific programs:* capability
[Admin UI] -> Evaluates capability -> Renders Read-Only Card OR Editable Card + FAB
```

## Execution Slices

### Phase A: Router & Shell Guards
**Plain English Summary:** Enforce PBAC on the application's root navigation routes and the bottom shell.
**Value Delivered:** Prevents unauthorized deep-linking to Analytics, Activity, and Programs modules.
**Entry/Exit State:** Entry: Unprotected routes. Exit: All primary routes verify `PolicyManager`.
**Scope:** `app_router.dart`, `main_shell.dart`.
**Acceptance Criteria:** `authRedirect` handles `/analytics`, `/activity`, and `/programs/*`. `main_shell.dart` conditionally renders the `ACTIVITY` tab.
**Complexity:** Low. Standard boolean checks and route segment parsing.

### Phase B: Admin Sub-Page Granular Gating
**Plain English Summary:** Apply strict read-only states to Admin management pages when the user lacks explicit write capabilities.
**Value Delivered:** Prevents the "Group Policy Trap" where gaining `admin:access` inadvertently grants write access to all admin domains.
**Entry/Exit State:** Entry: Admin pages assume full edit power. Exit: Admin pages gracefully fallback to read-only.
**Scope:** Store, Area, and Global Risk management pages and their respective Card widgets.
**Acceptance Criteria:** FABs are hidden and card tap/edit actions are disabled if the user lacks the specific `*:write` or `*:manage` capability.
**Complexity:** Low. Simple widget prop propagation and conditional rendering.

## Handoff Block
Run the phases using `@[/implement]`:

**Route 2: Visuals/Simple (Direct Build)**
@[/implement] Execute build for Phase A: file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/implementation_plan_20260509_202121_a4x9_pbac-ui-fix-leaks.md

@[/implement] Execute build for Phase B: file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/implementation_plan_20260509_202121_a4x9_pbac-ui-fix-leaks.md
