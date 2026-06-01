# Walkthrough: UX Heuristics Remediation

## Objective
Implement UX heuristic recommendations systematically for the Checkly dashboards across Auditor, Manager, and Admin personas to resolve specific visibility, navigation, and discoverability issues.

## Slices Implemented
### Slice 1: Auditor & Manager Dashboards
1.  **Background Sync Indicator:**
    -   Exposed `isSyncing` getter in `DashboardManager` (`lib/features/dashboard/manager/dashboard_manager.dart`).
    -   Passed `isSyncing` to the global `Greeting` widget within `DashboardPage`.
    -   Updated `Greeting` to display a non-blocking `SYNCING` chip in the overline whenever background synchronization occurs, satisfying **H1: Visibility of System Status**.
2.  **Start New Audit CTA (Auditor):**
    -   Updated `AuditorDashboardVariant` (`lib/features/dashboard/pages/widgets/auditor_dashboard_variant.dart`) to act dynamically based on `draftCount`.
    -   If `draftCount == 0`, a secondary-colored `HeroCard` appears prompting the user to "Start New Audit" leading to `/templates`. This resolves **H3: User Control & Freedom**, eliminating the empty-state dead-end.
3.  **Manager Analytics Routing:**
    -   Modified `ManagerDashboardVariant` (`lib/features/dashboard/pages/widgets/manager_dashboard_variant.dart`).
    -   Changed the "Store Avg Score" tile logic. Instead of blindly routing to `/analytics`, it detects if the user is a direct store manager (`!isArea` & `state.storeId != null`) and routes them directly to their specific store dashboard (`/stores/${state.storeId}/dashboard`), fixing **H8: Aesthetic and Minimalist Design (Efficiency of Use)**.

### Slice 2: System Admin Dashboard & Profile Unification
1.  **Terminology De-collision:**
    -   Modified `ProfileWorkspaceSection` (`lib/features/profile/widgets/profile_workspace_section.dart`).
    -   Renamed the "Admin Dashboard" card entry to "System Management" to prevent confusion with the app's default "Home" tab (which represents the true Admin Dashboard), fulfilling **H4: Consistency and Standards**.
2.  **Home Tab Aesthetic Unification:**
    -   Upgraded `AdminDashboardVariant` (`lib/features/dashboard/pages/widgets/admin_dashboard_variant.dart`) from a generic `CompactStatusPanel` to the premium `_KpiCard` 2x2 grid originally restricted to `AdminDashboardPage`.
    -   Ensured the "Home" tab acts identically to the premium admin view, preserving routing across different operational hubs (Action Plans, Audits, Analytics).
3.  **Manual Refresh Control:**
    -   Added a `RefreshIndicator` wrapper inside the `AdminDashboardPage` (`lib/features/admin/pages/admin_dashboard_page.dart`) over the main `ListView`.
    -   Configured it to call `loadStats(showLoading: false)` and `loadCounts()` from the underlying managers, granting Admins direct caching control (**H3: User Control and Freedom**).

## QA & Visuals
-   Verified no `flutter analyze` linter drift occurred.
-   Executed `flutter test` confirming successful preservation of `DashboardManager` and dashboard UI logic, specifically applying isolated `MockDashboardManager.isSyncing` states for testing resiliency.
