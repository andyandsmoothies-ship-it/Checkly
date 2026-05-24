# Requirements: Insight-Driven Analytics Dashboard

## Input Lineage
- ADR: `docs/architecture/decision_record_20260517_120515_SYN1_reporting.md`

## [ORIGIN_IDEA]
Transform static reports into a narrative-driven, actionable insight engine.

## 1. Functional Context (Use Case)

**Goal:** Understand store performance and identify immediate areas for operational improvement via insights.
**Primary Actor:** Store Manager, Area Manager
**System of Interest:** Flutter App (Analytics Tab) and .NET Backend (`GetAnalytics.cs`)

**1. Conditions**
- Pre-conditions: User is authenticated and has at least `submissions:read` capability.
- Post-conditions (Success): User views regional comparisons, insights, and trend data.
- Post-conditions (Failure): System displays offline mode warning or error state.

**2. Basic Scenario (Happy Path)**
1. The Primary Actor navigates to the Analytics Tab.
2. The System requests Analytics Data from the backend, passing the current user context.
3. The System (Backend) retrieves the live Store score.
4. The System (Backend) retrieves the cached Regional Benchmark and computed Actionable Insights.
5. The System (Frontend) renders the Executive Summary cards, KPI Sparklines, and Radar Chart.
*(Goal is achieved)*

**3. Extensions**
**2a. Device is Offline**
1. The System detects no network connectivity.
2. The System loads locally cached Drift analytics (Basic KPIs).
3. The System hides the Executive Summary and Radar Chart, showing a banner: "Insights require internet connection."
*(Ends: Use Case ends with degraded experience)*

**4a. Data Sparsity (Not enough audits)**
1. The System (Backend) detects the Store has < 3 total audits.
2. The System suppresses comparative insights to avoid mathematical variance noise.
3. The System returns a default insight: "Complete 3 audits to unlock regional benchmarks."
*(Ends: Returns to step 5)*

**4. Supporting Information**
- Test Variables: New Store (<3 audits), Offline Mode, Area Manager vs Store Manager view.
- Non-Functional Requirements: Regional Average must be calculated asynchronously (15-30m cache) to prevent N+1.

## 2. Visual Context (UI Flow & Screens)

```text
+------------------------------------------------+
|  Analytics Dashboard                           |
+------------------------------------------------+
|  [Executive Summary]                           |
|  [⚠️ Safety dropped 12% vs Regional Avg]       |
|  [💡 Store is Top 10% in Inventory accuracy]   |
+------------------------------------------------+
|  [KPI Metrics]                                 |
|  Score: 85% (⬆️2%) | Audits: 14 (⬇️1)          |
+------------------------------------------------+
|  [Category Performance - Radar Chart]          |
|         * Safety                               |
|     *       * (Store Line vs Region Polygon)   |
|   *           *                                |
|        * *                                     |
+------------------------------------------------+
|  [Historical Trend - Line Chart]               |
|  ~~~~~~~~~~~~~~~~~~~~~~~ (Over 6 months)       |
+------------------------------------------------+
```

## 3. Data Context (Schema)

```json
{
  "storeId": "123",
  "liveScore": 85.5,
  "insights": [
    {
      "id": "ins_1",
      "type": "warning",
      "text": "Safety scores dropped 2 Standard Deviations below your 30-day moving average.",
      "chartType": "radar_chart",
      "actionRoute": "/reports?category=safety"
    },
    {
      "id": "ins_2",
      "type": "anomaly",
      "text": "Your region's average is fine, but this store is an extreme statistical outlier.",
      "chartType": "boxplot_chart",
      "actionRoute": "/reports?view=outliers"
    }
  ],
  "radarData": {
    "categories": ["Safety", "Inventory", "Cleanliness"],
    "storeValues": [70, 95, 80],
    "regionalValues": [82, 80, 85]
  },
  "trendData": [
    { "month": "Jan", "score": 80 },
    { "month": "Feb", "score": 85 }
  ]
}
```

## 4. Shaping & Fit Check

**Shape A: The "Dumb" Shape (Procedural)**
- Mechanism: Backend calculates everything on the fly. Flutter renders standard text widgets.
- Stress Test: Fails Scale (N+1 database crash for 500-1000 stores).

**Shape B: Event-Driven Cache + Adaptive Rules Engine (The Selected Shape)**
- Mechanism: A Background Worker calculates the **30-day Moving Average and Standard Deviation** for regions every 15-30 mins, saving to `RegionalBenchmarks`. The Rules Engine fires using **Adaptive Thresholds** (e.g., Score < 2 StdDev) instead of static percentages. Backend generates the insight string AND specifies the optimal dynamic chart (`chartType`). Flutter renders the text and dynamically displays the requested chart (Radar, Boxplot, etc.).
- Scale: O(1) read for the dashboard.
- Role Isolation: Domain layer agnostic of PBAC. Endpoint controls access.
- Empty State: Displays "Complete 3 audits to unlock..." if sparse data.
- Offline: Graceful fallback to Drift local KPIs without insights.

| Requirement | Shape A (Procedural) | Shape B (Event-Driven Cache) |
|-------------|:-------:|:-------:|
| R1: Live Store Score | ✅ | ✅ |
| R2: Actionable Narrative Cards | ✅ | ✅ |
| R3: Prevent N+1 Database Crashing | ❌ | ✅ |
| R4: Hide False Alarms (Sparsity) | ❌ | ✅ |
| R5: Offline Graceful Degradation | ❌ | ✅ |

## 5. Use-Case Slices (Micro-Specs)

**Slice 1: Backend Adaptive Insight Engine & Cache Foundation**
- **Plain English Summary**: Sets up the background worker to calculate the 30-day moving averages and standard deviations for regions every 15-30 minutes, saving them to a fast cache table.
- **Why this step now?**: We need the performance foundation (the cache) before the API can serve data safely.
- **Scenario Focus**: Basic Scenario (Backend Data Prep).
- **Value Delivered**: Backend is ready to serve complex benchmark statistical data without crashing.
- **Entry State Required**: Raw audit submissions exist in DB.
- **Exit State Guaranteed**: `RegionalBenchmarks` cache table is populated and fresh.
- **Architectural Scope**: .NET Backend (Hangfire/Worker), EF Core (new Cache Entity).
- **Acceptance Criteria**:
  - Background job runs and writes to `RegionalBenchmarks`.
  - Database queries do not exceed O(1) per region upon user dashboard load.

**Slice 2: The Insight API Endpoint**
- **Plain English Summary**: Upgrades the existing `GetAnalytics` endpoint to pull from the new cache, compute variances using Adaptive Thresholds (e.g., triggering alarms if a store drops > 2 Standard Deviations), and return formatted English sentences to the frontend.
- **Why this step now?**: The data is ready in the cache, now we need to run the heuristic rules engine to format it and ship it to the mobile app.
- **Scenario Focus**: Basic Scenario (Data Delivery) + Sparsity Extension.
- **Value Delivered**: Mobile app can request data and get `ActionableInsight` strings along with dynamic chart routing instructions.
- **Entry State Required**: Cache is populated.
- **Exit State Guaranteed**: JSON payload matches the Data Context schema.
- **Architectural Scope**: .NET Backend (API Endpoint, DTOs).
- **Acceptance Criteria**:
  - Store with >3 audits gets regional variance insights based on Standard Deviation.
  - Store with <3 audits gets "Complete 3 audits..." message.
  - Live Store Score is accurate up to the second (not from the 15m cache).

**Slice 3: Flutter Dashboard Redesign**
- **Plain English Summary**: Replaces the old static profile page with a new layout featuring warning cards and a radar chart.
- **Why this step now?**: The API is now returning the exact JSON needed to draw this UI.
- **Scenario Focus**: Basic Scenario (Rendering) + Offline Extension.
- **Value Delivered**: Users see the new actionable dashboard.
- **Entry State Required**: Valid API response available.
- **Exit State Guaranteed**: UI accurately reflects JSON data; degrades gracefully offline.
- **Architectural Scope**: Flutter (`AnalyticsPage`, `fl_chart`).
- **Acceptance Criteria**:
  - Insights are rendered as cards at the top.
  - Radar chart plots store vs regional data using `fl_chart`.
  - In Airplane mode, insights hide and local Drift data is shown.

---
## Handoff Block
- **Mission Brief**: Build the Insight-Driven Analytics dashboard according to the 3 Slices defined here. Start with Slice 1 to ensure the background caching mechanism protects the DB.
- **Next Command**: `@[/implement] docs/product/requirements_20260517_125659_REQ1_reporting.md`
