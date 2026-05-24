<latent_space_scratchpad>
## Latent Space Scratchpad: Slice 3 — Flutter UI Edge Cases & Mechanics

### Boundary Conditions & Edge Cases
1. **Network Disconnection (Offline State)**:
   - Since BOD Analytics is pre-calculated nightly by the backend, it CANNOT use the offline Drift DB fallback.
   - If the API request fails due to `DioException` (no connection, network error), the manager must set `isOffline = true`.
   - The UI must render a highly polished `ChecklyEmptyState` or a custom offline block rather than showing zeroed charts.
2. **Polling on Successful On-Demand Refresh**:
   - The user triggers a refresh via `POST /api/analytics/bod/refresh`.
   - The API will start the worker execution asynchronously. The frontend will receive a `200 OK` or `202 Accepted` response with the `computedAt` of the previous snapshot.
   - To reflect the newly computed data, the page must show a loading skeleton and **poll** `GET /api/analytics/bod` every 5 seconds (up to 12 times, i.e., 60 seconds) until `ComputedAt` is newer than the previous `ComputedAt`.
   - If the poll succeeds with new data, the skeleton disappears and the view is updated with new metrics.
   - If the poll times out (60 seconds elapsed), the view reverts to the previous data and shows a warning toast: "Data computation is taking longer than expected. Please check back shortly."
3. **Yellow Partial Failure Warning Banner**:
   - If `SnapshotStatus` in the response is `"PartiallyFailed"`, it means some sub-queries failed on the backend.
   - The UI must display a prominent, high-taste warning banner: "⚠ Some board metrics could not be fully calculated due to temporary database timeouts. Leaderboard scores may be incomplete."
4. **AppCapabilities.analyticsBod Gating**:
   - The route `/analytics/bod` must use a redirect guard: `di<PolicyManager>().can(AppCapabilities.analyticsBod)`.
   - If not allowed, GoRouter redirect drops the user back to `/home`.
5. **No Visual Clipping / Responsive Grid**:
   - In portrait mode (phones), the 6 dashboard components should stack vertically inside a `ListView`.
   - In landscape/tablet mode, a two-column responsive grid layout should be used to prevent excessive scrolling.
   - Each card must be wrapped in `StrokeCard` to ensure exact aesthetic match with other administrative views.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\analysis_epic_20260524_142100_bod_analytics.md`

## Executive Summary & Out of Scope
This implementation plan describes the frontend delivery for **Slice 3 — Flutter UI** of the BOD Analytics Executive Dashboard. This slice builds the customer-facing (Admin-only) visual presentation layer that connects to the `GET /api/analytics/bod` and `POST /api/analytics/bod/refresh` endpoints delivered in Slices 1 & 2. 

### In Scope
1. Adding the `AppCapabilities.analyticsBod` capability constant and registering it within the `adminDomainCapabilities` list.
2. Adding a capability-guarded route `/analytics/bod` in `app_router.dart` and an entry button on the Admin Dashboard.
3. Implementing `BodAnalyticsApiService` for API calls using `Dio`.
4. Implementing `BodAnalyticsManager` utilizing ChangeNotifier for loading, offline state, refresh handling, and polling.
5. Implementing `BodAnalyticsPage` with the following aesthetic modules:
   - "Data as of [localized timestamp]" header.
   - Dynamic floating refresh button with rate-limiting support (handling HTTP 429 gracefully with a high-visibility snackbar).
   - "Partially Failed" status warning banner.
   - 6 Premium Metric/Chart cards wrapped in `StrokeCard`:
     - **KPI Grid**: 6 key metrics with delta indicators (▲ and ▼).
     - **Score Trend**: Area / line trend chart.
     - **Store Leaderboard**: Horizontal bar charts displaying Top 10 vs Bottom 10 stores.
     - **Category Weakness**: Sorted horizontal bar chart.
     - **AP Aging**: Horizontal stacked breakdown (0-7d, 8-30d, 31-90d, 90d+).
     - **Auditor Productivity**: Volume vs Score Scatter/Quadrant Chart.
6. Reduced motion compliance for all loading/scroll micro-animations.

### Out of Scope (YAGNI)
- Offline database syncing/caching (Drift fallback is disabled as this is pre-computed nightly server-side data).
- Drill-down actions for category/store/auditor metrics when offline.

---

## Risk Assessment
- **Blast Radius**: Low. The page is gated behind `AppCapabilities.analyticsBod`, meaning it is completely isolated and invisible to normal users.
- **Architectural Cost**: Low. Standard Dart/ChangeNotifier implementation that integrates cleanly into existing app routing.
- **Aesthetic Alignment**: Matches the Duolingo Admin Reskin, maintaining visual harmony.

---

## System Context
- **Offline-Only Behavior**: If the app fails to fetch data due to socket exceptions or timeouts, it transitions to `isOffline = true` and displays `ChecklyEmptyState` with a standard retry button. No stale local data will be shown to ensure executives never see corrupted metrics.
- **RBAC / PBAC**: The screen is gated by the dynamic policy check `di<PolicyManager>().can(AppCapabilities.analyticsBod)`. If the role lacks this permission, the router redirects the user to `/home`.
- **API Endpoints Utilized**:
  - `GET /api/analytics/bod`
  - `POST /api/analytics/bod/refresh`
- **Logging**: The manager and UI will emit descriptive logs for lifecycle events (loading, refreshed, polling, rate-limited).

---

## Lifecycle Context
### 4-State Matrix

| State | Visual Representation | Target Triggers / Controls |
|---|---|---|
| **Loading** | Shimmer loading skeleton overlays on all 6 chart panels. A circular progress indicator replaces the Refresh button icon. | Triggered automatically on page load or after a successful refresh initiation while polling. |
| **Empty** | `ChecklyEmptyState` widget showing an inbox icon, title "Boardroom Dashboard Empty", and description "No pre-computed report is available yet. The background worker runs nightly at 02:00 AM." with a "Trigger Recomputation" action button (if admin). | Triggered when `GET /api/analytics/bod` returns `404 Not Found`. |
| **Error / Offline** | `ChecklyEmptyState` with a warning/refresh icon, title "Connection Required", and description "BOD Analytics requires an active internet connection to retrieve executive snapshots." with a prominent "Try Again" action button. | Triggered when API call throws a `DioException` or socket error. |
| **Success** | Detailed responsive grid displaying the 6 `StrokeCard` charts, "Data as of: [Timestamp]" label, and a fully enabled Refresh button. If `snapshotStatus` is `"PartiallyFailed"`, a yellow warning banner is pinned at the top. | Triggered when the API successfully returns `200 OK` with JSON payload. |

---

## Constraint Traceability

| ID | Constraint | Description | Test Contract ID |
|---|---|---|---|
| **C-BOD-01** | PBAC Gate | Route `/analytics/bod` must redirect non-authorized roles (e.g. Area Manager) back to `/home`. | `TC-BOD-ROUTING-01` |
| **C-BOD-02** | Timezone Info | Localize the exact `computedAt` timestamp returned by the API using local timezone format. | `TC-BOD-UI-01` |
| **C-BOD-03** | Partial Failure | Show a warning banner if `snapshotStatus == "PartiallyFailed"`. | `TC-BOD-UI-02` |
| **C-BOD-04** | Offline State | Render an offline error state screen instead of showing zeros when network is down. | `TC-BOD-OFFLINE-01` |
| **C-BOD-05** | Refresh Limit | Handle `429 Too Many Requests` gracefully by showing a snackbar and disabling refresh for 15 min. | `TC-BOD-REFRESH-02` |
| **C-BOD-06** | Visual System | All cards must strictly use `StrokeCard` primitives for Duolingo reskin consistency. | `TC-BOD-UI-03` |

---

## Test Contracts

| ID | Exact Assertion / Intent | State Matrix | Why it fails first |
|---|---|---|---|
| **TC-BOD-ROUTING-01** | Navigating to `/analytics/bod` redirects unauthorized users to `/home`. | Auth Guard | Accessing the path will render the page directly instead of redirecting. |
| **TC-BOD-UI-01** | UI displays the correctly formatted, localized `ComputedAt` timestamp. | Success | The UI either omits the timestamp or displays raw ISO-8601 UTC. |
| **TC-BOD-UI-02** | PartiallyFailed status renders a yellow alert banner containing the incomplete warning. | Success (Partial) | Alert banner is missing and user is unaware of missing sub-metrics. |
| **TC-BOD-OFFLINE-01** | API connection error displays the `ChecklyEmptyState` offline view with a "Try Again" button. | Error / Offline | Screen displays zeroed charts or throws a NullReference/TypeCast exception. |
| **TC-BOD-REFRESH-01** | Successful refresh starts polling and renders shimmer skeleton until `computedAt` increases. | Loading / Polling | Page snaps instantly without showing active background processing. |
| **TC-BOD-REFRESH-02** | Triggering refresh when rate-limited (HTTP 429) displays a custom warning snackbar. | Success (Limit) | API fails silently or crashes the page without visual notification. |
| **TC-BOD-UI-03** | Verify all 6 chart panels are instances of `StrokeCard` with proper Swan border decoration. | Success | Standard `Card` or `Container` widgets are used, breaking design guidelines. |

---

## Test Fixture & Payloads

### GET /api/analytics/bod — Success (Complete) Response Payload
```json
{
  "chainKpis": {
    "totalAudits": 450,
    "avgScore": 84.5,
    "avgScoreDelta": 2.3,
    "completionRate": 92.1,
    "completionRateDelta": -1.4,
    "openAPs": 18,
    "overdueAPs": 5,
    "activeStores": 42,
    "totalAuditors": 12
  },
  "trend": [
    { "month": "Jan 2026", "avgScore": 81.0, "count": 35 },
    { "month": "Feb 2026", "avgScore": 82.5, "count": 40 },
    { "month": "Mar 2026", "avgScore": 83.2, "count": 42 },
    { "month": "Apr 2026", "avgScore": 84.5, "count": 45 }
  ],
  "topStores": [
    { "storeId": "s-01", "storeName": "Central Market", "avgScore": 96.5, "completedCount": 12 },
    { "storeId": "s-02", "storeName": "Siam Square", "avgScore": 94.2, "completedCount": 15 }
  ],
  "bottomStores": [
    { "storeId": "s-09", "storeName": "Outpost West", "avgScore": 62.1, "completedCount": 8 },
    { "storeId": "s-10", "storeName": "Airport Express", "avgScore": 58.4, "completedCount": 5 }
  ],
  "categoryBreakdown": [
    { "categoryName": "Food Safety", "avgScore": 72.4, "failedCount": 18 },
    { "categoryName": "Customer Service", "avgScore": 88.1, "failedCount": 2 }
  ],
  "apAging": {
    "days0to30": 10,
    "days31to60": 5,
    "days61to90": 2,
    "days90Plus": 1
  },
  "auditorProductivity": [
    { "auditorId": "a-01", "auditorName": "John Doe", "auditsCompleted": 24, "avgScore": 86.2 },
    { "auditorId": "a-02", "auditorName": "Jane Smith", "auditsCompleted": 18, "avgScore": 89.4 }
  ],
  "computedAt": "2026-05-24T02:15:00Z",
  "snapshotStatus": "Complete",
  "allowedActions": ["refresh"]
}
```

---

## Tools & Commands
- **Required Skills**: `flutter-architecture`, `flutter-api`, `enterprise-authorization`, `tdd`.
- **Test Commands**:
  - `rtk flutter test test/features/analytics/pages/bod_analytics_page_test.dart`
  - `rtk flutter test test/features/analytics/manager/bod_analytics_manager_test.dart`

---

## Proposed Changes

| Path | Mode | Description |
|---|---|---|
| `lib/_shared/constants/app_capabilities.dart` | `[MOD]` | Add `analyticsBod` constant and register in `adminDomainCapabilities`. |
| `lib/_shared/router/app_router.dart` | `[MOD]` | Add `/analytics/bod` capability-guarded detail route. |
| `lib/features/admin/pages/admin_dashboard_page.dart` | `[MOD]` | Add BOD Analytics navigation menu item to the dashboard (Operations section). |
| `lib/locator.dart` | `[MOD]` | Register `BodAnalyticsApiService` and `BodAnalyticsManager` singletons. |
| `lib/features/analytics/services/bod_analytics_api_service.dart` | `[NEW]` | API service mapping GET `/api/analytics/bod` and POST `/api/analytics/bod/refresh`. |
| `lib/features/analytics/manager/bod_analytics_data.dart` | `[NEW]` | Data transfer models and sub-structures mapping the backend JSON schema. |
| `lib/features/analytics/manager/bod_analytics_manager.dart` | `[NEW]` | Business logic state class with fetching, manual triggers, and polling logic. |
| `lib/features/analytics/pages/bod_analytics_page.dart` | `[NEW]` | Premium dashboard screen (under 300 lines) displaying all aggregated metrics. |
| `lib/features/analytics/widgets/bod_kpi_grid.dart` | `[NEW]` | Multi-metric KPI cards grid using `StrokeCard` and delta indicators. |
| `lib/features/analytics/widgets/bod_store_leaderboard.dart` | `[NEW]` | Bar charts for Top 10 and Bottom 10 stores. |
| `lib/features/analytics/widgets/bod_ap_aging_funnel.dart` | `[NEW]` | Action Plan aging horizontal stacked metrics card. |
| `lib/features/analytics/widgets/bod_auditor_scatter.dart` | `[NEW]` | Volume vs Score scatter chart representing auditor productivity. |

### Component Overflow Table

| Component | Truncation Limit | Overflow Action | Required New Route |
|---|---|---|---|
| KPI Grid | 6 cards max | Fixed grid, wraps cleanly in responsive layout. | None |
| Store Leaderboard | Top 10 / Bottom 10 | Displays scrollable horizontal layout. | `/analytics?storeId=X` |
| Category Weakness | Top 15 categories | Render inside a scrollable column. | `/analytics?category=X` |
| Auditor Scatter | 50 points | Render cleanly using `fl_chart` ScatterChart. | `/activity?auditorId=X` |

---

## Concept Diagram

```
                [Admin Dashboard]
                        │  (Taps Menu Item)
                        ▼
                [app_router.dart]
           Checks capability 'analytics:bod'
            /           \
        (Allowed)     (Denied)
          /               \
         ▼                 ▼
[BodAnalyticsPage]      [Home / Dashboard]
  Loads State Manager
         │
         ▼
[BodAnalyticsManager] ──(API Call)──► [GET /api/analytics/bod]
  ├── isOffline = true  ──► Render checkly offline error
  ├── isLoaded  = false ──► Render shimmer loading skeletons
  └── isLoaded  = true  ──► Render StrokeCard Executive Dashboard
                              ├── "Data as of [ComputedAt]"
                              ├── If PartiallyFailed ──► Show yellow banner
                              └── Tapping [🔄 Refresh]
                                     │
                                     ▼
                              [POST /analytics/bod/refresh]
                               ├── HTTP 429 ──► Warning Snackbar
                               └── HTTP 200 ──► Polling starts (loading skeleton)
```

---

## Execution Slices

### Slice 3A — Scaffold & Core Routing (Happy Path Foundations)
- **Summary**: Implement capabilities, wire up dependency injection, define data models, write API integration services, and establish GoRouter navigation gates.
- **Why this step now?**: This creates the logical plumbing. The manager, data models, and API client must be registered in the service locator before any visual page can be wired or tested.
- **Value**: A fully mockable state manager and service routing interface with complete unit tests.
- **Entry State**: Flutter project running normally, router has standard detail routes.
- **Exit State**: `AppCapabilities.analyticsBod` registered. GoRouter `/analytics/bod` gates requests correctly. DI singletons registered. `BodAnalyticsApiService` returns successful models on correct responses.
- **Complexity**: Low (Standard boilerplate wiring).
- **Acceptance Criteria**:
  - `[AC-3A-01]` `AppCapabilities.analyticsBod` is defined as `'analytics:bod'` and added to `adminDomainCapabilities`.
  - `[AC-3A-02]` `BodAnalyticsApiService.getReport()` returns deserialized `BodReportResponse` successfully.
  - `[AC-3A-03]` Router config blocks `/analytics/bod` and redirects to `/home` when client lacks the required capability.
  - `[AC-3A-04]` DI resolves `BodAnalyticsManager` lazy singleton smoothly.

---

### Slice 3B — Manager Lifecycle & States (Logic Gates)
- **Summary**: Implement state coordination within `BodAnalyticsManager` for handling loading, success, empty (404), offline, and refresh polling.
- **Why this step now?**: We must establish robust state transitions (e.g. how polling is triggered, how error outcomes are captured) before writing the visual widgets to consume them.
- **Value**: The frontend manager is fully resilient to rate limits, timeouts, and network failures.
- **Entry State**: Slice 3A complete.
- **Exit State**: State manager correctly handles API failures, rate limiting, and triggers a timed loop to poll for snapshot completion.
- **Complexity**: Medium (Refining async polling loop and rate limit interceptors).
- **Acceptance Criteria**:
  - `[AC-3B-01]` Manager sets `isOffline = true` and `error` when network is disabled.
  - `[AC-3B-02]` Manager sets `isEmpty = true` when API returns HTTP 404 (first load empty report).
  - `[AC-3B-03]` Manager handles HTTP 429 gracefully, updates a status stream, and notifies the UI to show a snackbar.
  - `[AC-3B-04]` Initiating refresh starts a 60-second polling cycle, fetching every 5 seconds until a newer `computedAt` timestamp is retrieved.

---

### Slice 3C — Visually Premium Executive Dashboard (Widget assembly)
- **Summary**: Build `BodAnalyticsPage` and assemble the 6 custom widgets using `StrokeCard`, custom graphs, status grids, and warning headers.
- **Why this step now?**: Wires up the user interface with the proven logic from Slice 3B, achieving the visual "wow" factor required for the Board of Directors presentations.
- **Value**: Fully dynamic, responsive executive board screen complete with localized timestamps and error triggers.
- **Complexity**: Medium (Ensuring `fl_chart` widgets wrap correctly and look outstanding).
- **Acceptance Criteria**:
  - `[AC-3C-01]` Main layout displays a localized "Data as of [DateTime]" header matching system timezone.
  - `[AC-3C-02]` All 6 panels (KPI Grid, Trend Chart, Store Leaderboard, Category Weakness, AP Aging, Auditor Scatter) are rendered using `StrokeCard`.
  - `[AC-3C-03]` PartiallyFailed snapshots display a high-taste warning banner pinned at the top.
  - `[AC-3C-04]` Offline view is rendered cleanly via the standard error block with a fully functioning retry tap target.

---

## Verification Plan

### Automated Test Cases

#### Manager Unit Tests
`test/features/analytics/manager/bod_analytics_manager_test.dart`
- Verify successful state mapping (success, loading, offline).
- Verify polling behavior (stops when updated timestamp is found, stops at 60s timeout).
- Verify HTTP 429 rate limit propagation.

#### Widget & Pages Tests
`test/features/analytics/pages/bod_analytics_page_test.dart`
- Verify routing protection (PBAC).
- Verify "Data as of" localization.
- Verify warning banner is visible only on partially failed responses.
- Verify retry button behaves correctly in the offline state.
- Verify all cards use `StrokeCard` primitives.

---

## Handoff Block
- **Next Phase**: **Write Acceptance / Widget Tests**, then **Build Phase** for **Slice 3A**.
- **Execution Path**: Execute slices sequentially one at a time.
  - **Slice 3A**: Write Unit / Router Tests -> Build Scaffolding.
  - **Slice 3B**: Write Manager Lifecycle Tests -> Build Logic.
  - **Slice 3C**: Write Widget & Interaction Tests -> Assemble Premium Dashboard.
- **Implementation Spec Path**: `docs/architecture/bod-analytics/implementation_plan_20260524_163000_s3_bod_analytics.md`
