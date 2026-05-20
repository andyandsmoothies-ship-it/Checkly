# UX Heuristic Evaluation: Dashboard Roles

## Scope
- **Target Screens**: Home Page Dashboard (Role Variants)
- **User Groups**: System Admin, Auditor, Store Manager, Area Manager
- **Device Type**: Mobile
- **Methodology**: Visual Review (Screenshots) + Code Review (`dashboard_page.dart`)

## Executive Summary
The core issue across the role-based dashboards is a **hardcoded outer shell** that forces inappropriate titles onto different personas. The global `dashboard_page.dart` forces the title "Store Overview" for every user, which fundamentally breaks the semantic context for Area Managers (who view regions) and Admins (who view the platform). This also causes a double-header aesthetic violation on the Admin view.

## Scorecard
| Heuristic | Status | Notes |
|---|---|---|
| H1: Visibility of System Status | ⚠️ | Ambiguous "just now" deadline status. |
| H2: Match between system and real world | ❌ | "Store Overview" applies incorrectly to AMs and Admins. |
| H3: User Control & Freedom | ✅ | Navigation is clear. |
| H4: Consistency and standards | ❌ | Admin view has conflicting headers. |
| H5: Error prevention | ✅ | Not heavily applicable on this read-only view. |
| H6: Recognition rather than recall | ✅ | KPIs are clearly labeled. |
| H7: Flexibility and efficiency of use | ✅ | Floating Action Button appears correctly for authorized roles. |
| H8: Aesthetic and minimalist design | ❌ | Double titles on Admin view waste vertical space. |
| H9: Help users recognize, diagnose, and recover from errors | N/A | Evaluated in previous slice. |
| H10: Help and documentation | ✅ | Simple enough to not require docs. |

---

## Sorted Findings

### H2: Semantic Mismatch of Global Dashboard Title
- **Severity**: 3
- **Location**: `DashboardPage` > `Greeting` Widget (All variants)
- **Issue**: The text "Store Overview" is hardcoded in the `Greeting` widget. When an Area Manager logs in, they are viewing aggregated area data ("Area Action Plans", "Area Avg Score"), but the page claims it is a "Store Overview". This is factually incorrect and confusing.
- **Recommendation**: Make the title dynamic based on the user's role. For example: "Store Overview" for SM/Auditor, "Area Overview" for Area Manager, and "Platform Overview" for Admin.

### H8: Double Header Clutter on Admin Dashboard
- **Severity**: 3
- **Location**: `AdminDashboardVariant`
- **Issue**: Because the global `dashboard_page.dart` shell forces "Store Overview", the `AdminDashboardVariant` adds its own title ("Mission Control / PLATFORM OVERVIEW") directly underneath it. This results in two massive headers stacked together, wasting vertical space and confusing the visual hierarchy.
- **Recommendation**: Remove the hardcoded "Store Overview" from the shell and let each variant provide its own title, or pass the title dynamically into the `Greeting` widget so `AdminDashboardVariant` doesn't need to render its own duplicate headers.

### H1: Ambiguous Time Status in Action Plan Banners
- **Severity**: 2
- **Location**: Auditor and Area Manager Variants
- **Issue**: The banner states "Next Action Plan Deadline: just now". "Just now" is an ambiguous relative time string that doesn't tell the user if the deadline is in the past (overdue) or exactly at this minute.
- **Recommendation**: Use absolute formats for deadlines (e.g., "Today at 5:00 PM" or "Overdue since 2:00 PM") instead of imprecise relative time ago/until formats for critical action items.

---

## Top Fix Priorities
1. **Fix the Hardcoded Title**: Refactor the `Greeting` widget to accept a `title` parameter or compute it based on the `UserPersona` role.
2. **Remove Admin Double Header**: Delete the "Mission Control" headers from `AdminDashboardVariant` once the global title is dynamic.
3. **Clarify Deadline Strings**: Update the relative time formatter used for "Next Action Plan Deadline" to be exact for deadlines that are imminent or overdue.

**Routing**: Route fixes through `Feature Analysis -> Implementation` using this exact path: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\dashboard\ux_heuristic_eval_dashboard_roles.md`
