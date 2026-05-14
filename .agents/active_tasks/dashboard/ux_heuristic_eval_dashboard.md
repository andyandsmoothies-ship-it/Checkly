# UX Heuristic Evaluation: Store Manager Dashboard

**Target Scope**: Store Manager Dashboard (Store Overview)
**User Persona**: Store Manager / Area Manager
**Device Type**: Mobile

## Summary
The Store Overview provides a comprehensive view of the manager's tasks, but suffers from severe visual hierarchy issues and a missing error state. The overuse of "Hero" style banners causes visual clutter, and network/database errors are swallowed and hidden behind a perpetual loading spinner.

## Scorecard
- ✅ H1: Visibility of system status (Partial)
- ✅ H2: Match between system and the real world
- ✅ H3: User control and freedom
- ⚠️ H4: Consistency and standards
- ✅ H5: Error prevention
- ✅ H6: Recognition rather than recall
- ✅ H7: Flexibility and efficiency of use
- ❌ H8: Aesthetic and minimalist design
- ❌ H9: Diagnose and recover from errors
- ✅ H10: Help and documentation

## Sorted Findings

### H9: Perpetual Loading on Error (No Error Recovery)
- **Severity**: 3
- **Location**: `DashboardManager.loadStats()` in `dashboard_manager.dart`
- **Issue**: If an exception occurs during data fetching, the `catch` block intentionally falls back to `_state = DashboardLoading();`. This violates H1 and H9, as the user is presented with a permanent loading spinner, hiding the error and offering no way to recover or retry.
- **Recommendation**: Create a `DashboardErrorState` and render an explicit error message with a "Retry" button.

### H8: Aesthetic and Minimalist Design (Banner Clutter)
- **Severity**: 3
- **Location**: `manager_dashboard_variant.dart`
- **Issue**: Stacking multiple massive `HeroCard` widgets (both amber "Action Required" and green "All Clear") creates extreme visual weight and violates progressive disclosure. The "All Clear" card is also highly redundant, as the metric directly below it already states "Store Action Plans: 0".
- **Recommendation**: Demote the "All Clear" state to either disappear entirely when `overdueActionPlans == 0` or become a small status pill. Convert the Program Assignment banners into a compact, scrollable list.

### H4: Consistency and Standards (Semantic Color Misuse)
- **Severity**: 2
- **Location**: `ActionRequiredWidget` vs `HeroCard` (All Clear)
- **Issue**: The system uses the exact same visual component (`HeroCard`) to represent both an urgent warning (Amber, Action Required) and a quiet success state (Green, No Overdue Plans). This trains users to ignore large blocks of color.
- **Recommendation**: Reserve the `HeroCard` layout exclusively for urgent, singular interventions (e.g., Overdue tasks). Use standard list tiles for routine pending tasks.

## Top 3 Fix Priorities
1. **Implement Error State**: Fix the `catch` block in `DashboardManager` to prevent the infinite loading spinner trap.
2. **Remove Redundant "All Clear" Hero**: Delete the green `HeroCard` in the dashboard variant when action plans are zero to reduce visual noise.
3. **Consolidate Campaign Banners**: Redesign the Program Assignments to use standard, compact `ListTile`s rather than full-bleed HeroCards.

## Tradeoffs Documented
- The dashboard collapses personal metrics (Auditor state) into the Manager view when the store data is syncing. This is a deliberate "Resilient Manager View" tradeoff to show *something* rather than blocking the UI, which is a justified exception to strict data purity.
