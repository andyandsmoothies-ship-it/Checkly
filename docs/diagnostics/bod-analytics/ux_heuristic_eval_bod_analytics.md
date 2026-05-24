# Heuristic UX Evaluation: Boardroom Executive Analytics Dashboard

> **Scope**: Boardroom Analytics Screen (`lib/features/analytics/pages/bod_analytics_page.dart`)
> **Target Audience**: Executive Board of Directors (BOD) & C-Suite Administrators
> **Device Profile**: Tablet & Mobile Responsive Layout

---

## 1. Executive Summary

This report evaluates the **Boardroom Executive Analytics Dashboard** against Jakob Nielsen’s **10 Usability Heuristics**. The dashboard is visually premium, uses responsive grid layouts, and models all 4 state extremes (Loading, Offline, Empty, and Error) successfully. 

However, for a retail chain operating **hundreds of stores**, the interface contains severe scalability bottlenecks and missing historical context. It forces executive readers to perform manual calculations to understand progress, violating the fundamental principle of **Recognition rather than Recall**.

### Heuristic Scorecard

| Heuristic | Rating | Status | Summary |
|---|---|---|---|
| **H1: Visibility of System Status** | 🟢 ✅ | **Excellent** | Polling state and "PartiallyFailed" data timeout warnings are highly explicit. |
| **H2: Match System & Real World** | 🟡 ⚠️ | **Minor Issue** | Uses corporate terms, but lacks regional/district grouping for large-scale operations. |
| **H3: User Control & Freedom** | 🟢 ✅ | **Excellent** | Standard back navigation and pull-to-refresh pull exits are native and present. |
| **H4: Consistency & Standards** | 🟢 ✅ | **Excellent** | Follows the established "StrokeCard" and material layout standards perfectly. |
| **H5: Error Prevention** | 🟢 ✅ | **Excellent** | Blocks parallel recalculation requests and checks active connection state. |
| **H6: Recognition Rather than Recall** | 🔴 ❌ | **Major Issue** | Forces users to manually compare month-over-month delta bars to find improvement. |
| **H7: Flexibility & Efficiency of Use** | 🔴 ❌ | **Major Issue** | No ability to filter by Region, District, or Campaign. 100+ stores list is unusable. |
| **H8: Aesthetic & Minimalist Design** | 🟢 ✅ | **Excellent** | High-taste color selection (macaw, wolf, eel) with clean, spacious layouts. |
| **H9: Help Users Recover from Errors** | 🟢 ✅ | **Excellent** | Blame-free error states with retry buttons. |
| **H10: Help and Documentation** | 🟡 ⚠️ | **Minor Issue** | Lacks standard definitions of KPI metrics (e.g., how "Completion Rate" is calculated). |

---

## 2. Detailed Findings

### H6: Missing Month-over-Month (MoM) Delta Indicators
- **Severity**: 3 (Major)
- **Location**: `Historical Score Trend` Panel (Card 2)
- **Issue**: The chart displays the raw monthly averages (e.g. *Jan: 81.0%, Feb: 83.2%*). To find out if we improved or got worse since last month, the director is forced to manually calculate the subtraction in their head (e.g. *83.2% - 81.0% = +2.2%*). It lacks visual indicators (like red/green delta pill-chips `+2.2%` or `-0.5%`) showing exact progress since the previous month.
- **Recommendation**: Add a secondary trend line or a dynamic MoM comparison pill-chip above the chart indicating the current month's percentage change compared to the previous month.

### H7: Scalability Bottleneck for Hundreds of Stores
- **Severity**: 3 (Major)
- **Location**: `Store Performance Leaderboard` Panel (Card 3)
- **Issue**: The leaderboard renders a static flat list of "Top 5" and "Bottom 5" stores. For a chain with 100+ stores, this means 90% of stores are invisible, and there is no ability to group or filter by **Region, District, or Store Format**. The BOD cannot drill down to see why a particular region is failing.
- **Recommendation**: Introduce a filter row (dropdowns) at the top of the dashboard allowing the user to filter all cards by **Region** (e.g., North, South, East) and **Format** (e.g., Airport, High Street, Outlet).

### H2: Raw Auditor List is Unactionable for Executives
- **Severity**: 2 (Minor)
- **Location**: `Auditor Productivity` Scatter/List Panel (Card 6)
- **Issue**: The panel renders individual auditors listed by name. At a scale of hundreds of stores, the C-Suite does not know individual auditors; they manage **District Operations Managers**. Displaying a raw list of hundreds of individual auditors is information overload.
- **Recommendation**: Allow toggling this panel's view between "Individual Auditor" and "District/Manager Teams" so executives can review team-level performance.

### H10: Missing Metric Tooltips / Definitions
- **Severity**: 1 (Cosmetic)
- **Location**: `Chain Performance KPIs` Grid (Card 1)
- **Issue**: Standard terms like "Completion Rate" or "Overdue/Open APs" can be interpreted differently by different directors. There is no helper indicator (like a small info icon) to clarify the formula.
- **Recommendation**: Place a small `info_outline` icon next to each card title that displays a brief popup definition when tapped (e.g., *"Completion Rate = Completed Audits / Scheduled Audits"*).

---

## 3. Top 3 Fix Priorities

1. **MoM Delta Badges**: Add green/red pill badges to the monthly trend chart showing positive/negative variance from the previous month.
2. **Regional Filter Dropdowns**: Add a sticky filter bar at the top of the body allowing directors to slice the 100+ stores into regional segments.
3. **Escalation Indicator on AP Aging**: Color-code the "90+ Days" Action Plan card to an energetic warning color (AppColors.fox) to instantly draw C-suite attention to stale high-risk issues.

---

## 4. Design Tradeoffs & Justifications
- **Tradeoff: Pull-to-Refresh on Desktop layouts**: Pull-to-refresh is primarily a mobile gesture. However, keeping it on desktop tablets ensures absolute interaction consistency across all target device formats.
