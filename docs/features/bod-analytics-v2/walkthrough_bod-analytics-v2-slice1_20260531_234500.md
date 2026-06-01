---
conversation_id: e806043a-d178-457b-b974-d1e2c68fce54
created_at: 2026-05-31T23:45:00+07:00
topic: bod-analytics-v2
type: walkthrough
status: COMPLETED
---

# Walkthrough: Area Manager BOD Dashboard | Slice 1

This walkthrough chronicles the implementation of Slice 1 for the **Area Manager BOD Analytics Dashboard** in the Checkly Flutter frontend.

## 1. Architectural Design

The routing and page assembly follow the **Pragmatic Flutter Architecture (PFA)** and Strict PBAC (Policy-Based Access Control) guidelines:

```
[Router: appRouter]
       │ (Gated with capability check 'analytics:area' & 'analytics:view')
       ▼
[Page: AreaBodAnalyticsPage]
       │
       ├─► [State Management: WatchIt / AreaBodAnalyticsManager]
       │
       ▼
[Body: AreaBodDashboardBody]
       ├─► [KPI Premium Summary Grid] (totalAudits, avgScore, completionRate, etc.)
       ├─├─► [Trend Premium Line Chart] (Historical score progression)
       ├─├─► [Golden Store Spotlights] (Highest performer highlights)
       ├─├─► [Critical Focus Weaknesses] (Low-scoring section details)
       ├─├─► [Action Plan Aging Buckets] (Overdue & Open aging distributions)
       └─└─► [Auditor Leaderboard] (Productivity rank & metrics)
```

## 2. Completed Components

### A. Routing Configuration (`lib/router/app_router.dart`)
- **Route Name**: `/analytics/area`
- **Guards**: Enforces that the active profile possesses both `'analytics:area'` and `'analytics:view'` capabilities. Unauthorized access redirects to `/home`.

### B. View Assembly (`lib/features/analytics/pages/area_bod_analytics_page.dart`)
- Listens to `AreaBodAnalyticsManager` states: `Loading`, `Offline`, `Empty`, `SystemError`, and `Success`.
- Integrates `ChecklyEmptyState` to handle offline, empty, and system error states gracefully:
  - **Offline**: Connection Required ChecklyEmptyState with a "Try Again" trigger.
  - **Empty**: Area Dashboard Empty ChecklyEmptyState with a "Trigger Recomputation" trigger.
  - **System Error**: System Error ChecklyEmptyState with a "Retry" trigger.

### C. Dashboard Body (`lib/features/analytics/widgets/area_bod_dashboard_body.dart`)
- Formats and displays 6 distinct premium components:
  1. **KPI Header & Summary Cards**: Displays absolute aggregates (Total Audits, Average Score, Completion Rate, Open Action Plans, etc.) styled with premium brand-colored borders.
  2. **Trend Chart Panel**: Integrates a responsive `TrendChart` built on `fl_chart`.
  3. **Golden Store & Spotlights**: Lists high-scoring stores utilizing the custom `StrokeCard` and `PillChip` primitives.
  4. **Critical Focus & Weaknesses**: Showcases low-performing sections to call out direct operational actions.
  5. **Action Plan Aging Distribution**: Visualizes open tasks using horizontal bar distributions.
  6. **Auditor Leaderboard**: Ranks auditor productivity with standard pill tags.

## 3. Visual Verification

The user-facing screens render responsive panels that strictly scale down safely to small/headless viewports. All text elements are wrapped inside `Flexible`/`Expanded` widgets to prevent flexible overflow issues.
