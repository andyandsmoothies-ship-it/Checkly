# UX Heuristic Evaluation: Chunk 3 - System Admin

## Scope
- `lib/features/dashboard/pages/widgets/admin_dashboard_variant.dart` (Home Tab)
- `lib/features/admin/pages/admin_dashboard_page.dart` (System Dashboard)
- `lib/features/profile/pages/profile_page.dart` (Admin Workspace)

## 1. H4: Consistency and Standards (Severity: Critical)
**Observation:** The application presents two distinctly different "dashboards" for the System Admin role, leading to severe cognitive dissonance:
1.  **Home Tab (`/home`)**: Renders `AdminDashboardVariant`. Displays operational metrics (Action Plans, Audits, Overdue) using the legacy, flat `CompactStatusPanel` UI.
2.  **Profile > Admin Dashboard (`/admin/dashboard`)**: Renders `AdminDashboardPage`. Displays system metrics (Users, Stores, Templates) using the newly implemented premium "Duolingo-style" 2x2 grid.

**Impact:** Admins face a fragmented experience. The nomenclature "Admin Dashboard" is overloaded. Furthermore, the aesthetic disconnect makes the app feel like two different applications stitched together.

**Remediation Plan:**
*   **Rename & Repurpose:** Rename the Profile route from "Admin Dashboard" to "System Management" or "Platform Settings" to clarify its purpose.
*   **Unify Aesthetics:** Upgrade `AdminDashboardVariant` to utilize the premium 2x2 `StrokeCard` and `PillChip` aesthetic to match `AdminDashboardPage`, ensuring the Home tab feels state-of-the-art.

## 2. H3: User Control and Freedom (Severity: High)
**Observation:** The newly redesigned `AdminDashboardPage` (`/admin/dashboard`) lacks a pull-to-refresh mechanism (`RefreshIndicator`). It only fetches data (`loadCounts()`) during `initState`.

**Impact:** If an Admin is actively managing the system (e.g., adding a new user or store from a different tab/device, or returning from a sub-page), the KPI counts will be stale. The only way to refresh the data is to hard-navigate away and back to force a widget rebuild.

**Remediation Plan:**
*   Wrap the primary `ListView` in `AdminDashboardPage` with a `RefreshIndicator` connected to `_countsManager.loadCounts()` and `_manager.loadStats()`.

## 3. H1: Visibility of System Status (Severity: Medium)
**Observation:** In `AdminDashboardPage`, if an error occurs while loading the counts, the error state is only surfaced via a transient `Snackbar` (`ErrorDisplayService`). The KPI cards simply fall back to displaying `—`.

**Impact:** If the admin misses the transient snackbar, they are left looking at empty `—` cards with no persistent indication that a network failure occurred or a way to retry the specific failed request.

**Remediation Plan:**
*   Introduce persistent error states or a retry button within the `_KpiCard` or at the top of the grid when `_countsManager.error` is non-null.

## 4. H8: Aesthetic and Minimalist Design (Severity: Medium)
**Observation:** `AdminDashboardVariant` (the first screen an Admin sees upon logging in) uses the legacy flat design, missing out on the high-contrast, card-based visual hierarchy requested for the platform's modernization.

**Remediation Plan:**
*   Port the `_KpiCard` layout from `AdminDashboardPage` into a shared widget, and apply the 2x2 grid layout to `AdminDashboardVariant`.

## Next Steps
With all 3 chunks completed, we must consolidate the findings and transition to the **Implementation** phase using the Builder Agent (`/implement`) to systematically apply these UX/UI remediations across the Dashboard flows for Auditors, Managers, and Admins.
