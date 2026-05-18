<latent_space_scratchpad>
## Constraints from Epic (Slice 3)

C1 — AnalyticsPage shows Insight Cards below the KPI grid.
C2 — InsightCard: icon + text + optional "Go" button (from actionRoute). Color by type: warning=AppTheme.warning, info=AppTheme.info, positive=AppTheme.success.
C3 — InsightCard max 3 shown (backend enforces, UI just renders the list).
C4 — InsightsStale banner: when insightsStale=true, show a soft "⚠ Insights last updated over 2 hours ago" note above the insight cards.
C5 — RadarChart: shows "Store vs Region" polygon chart when radarData is not null and has ≥ 3 categories.
C6 — Offline: No insight cards shown when offline (data comes only from API). The existing "Insights require an internet connection" banner covers this.
C7 — Empty/sparse: if insights = [{type:"info"}] (sparsity card), still render it normally using InsightCard (the info style).
C8 — Section header "INSIGHTS" above cards, "PERFORMANCE RADAR" above radar chart.

## File Size Issues (CRITICAL)
- analytics_page.dart = 361 lines → MUST split before adding code
- analytics_manager.dart = 404 lines → MUST split model classes out

## How to Split

### analytics_manager.dart split
Move these pure data classes to a new file:
- AnalyticsData → `analytics_data.dart`
- ActionableInsight → `analytics_data.dart`
- RadarData → `analytics_data.dart`

Manager stays in `analytics_manager.dart` (~220 lines after split)

### analytics_page.dart split
Extract the filter chip row into `analytics_filter_bar.dart` (inline StatelessWidget → takes manager ref).
Page stays at ~280 lines after extraction.

## Manager Fix (Line 192-193)
Current code hardcodes `insights: const [], radarData: null`.
Must parse from JSON:

```dart
// parse insights
final insightsList = (json['insights'] as List<dynamic>?) ?? [];
final insights = insightsList.map((e) => ActionableInsight(
  id: e['id'] as String,
  type: e['type'] as String,
  text: e['text'] as String,
  actionRoute: e['actionRoute'] as String?,
)).toList();

// parse radarData
RadarData? radarData;
final radarJson = json['radarData'];
if (radarJson != null) {
  final storeMap = (radarJson['storeAverages'] as Map<String, dynamic>? ?? {});
  final areaMap = (radarJson['areaAverages'] as Map<String, dynamic>? ?? {});
  final cats = storeMap.keys.toList();
  if (cats.length >= 3) {
    radarData = RadarData(
      categories: cats,
      storeValues: cats.map((k) => (storeMap[k] as num).toDouble()).toList(),
      regionalValues: cats.map((k) => (areaMap[k] as num? ?? 0).toDouble()).toList(),
    );
  }
}
```

## InsightCard Widget
Simple `Card` with:
- Left accent border (3px) colored by type
- Icon: warning_amber / info_outlined / check_circle — colored by type
- Text (bodyMedium)
- Optional InkWell if actionRoute != null → context.go(actionRoute!)

## InsightsRadarChart Widget
- `SizedBox(height: 220)` containing `RadarChart`
- 2 datasets: Store (primary color), Region (grey dashed)
- Legend: two colored dots + labels
- Empty state if radarData == null or < 3 categories

## RadarChart (fl_chart v1) API
RadarChart takes:
  - RadarChartData
    - dataSets: List<RadarDataSet>
    - radarBorderData: BorderSide
    - ticksTextStyle: TextStyle
    - tickCount: 5 (0,20,40,60,80,100)
    - titleTextStyle: TextStyle
    - getTitle: (idx) → RadarChartTitle

RadarDataSet:
  - dataEntries: [RadarEntry(value: double), ...]
  - fillColor: Color
  - borderColor: Color
  - borderWidth: double

## Test Contracts
FL-01: InsightCard renders warning type with amber color
FL-02: InsightCard renders positive type with success color  
FL-03: InsightCard renders info type with info color
FL-04: InsightCard renders action button when actionRoute != null
FL-05: InsightsRadarChart renders "No regional data" when radarData is null
FL-06: InsightsRadarChart renders two polygons when radarData has 3+ categories
FL-07: AnalyticsManager.load() parses insights from API JSON (mocked Dio)
FL-08: AnalyticsManager.load() parses radarData from API JSON (mocked Dio)
FL-09: InsightsStale banner visible when insightsStale=true
FL-10: No insights section shown when offline (isOffline=true)

## Proposed Changes (5 files)
- [NEW] lib/features/analytics/manager/analytics_data.dart — pure data classes
- [MOD] lib/features/analytics/manager/analytics_manager.dart — extract classes, fix lines 192-193
- [NEW] lib/features/analytics/widgets/insight_card.dart — new widget
- [NEW] lib/features/analytics/widgets/insights_radar_chart.dart — new widget
- [MOD] lib/features/analytics/pages/analytics_page.dart — add 2 sections, wire widgets
  * Also extract filter chip bar inline (avoids splitting to new file since it has manager dependency)

Actually, I need to check if splitting analytics_page.dart is possible without adding a 6th file (would exceed max 5 for single phase). I'll split the model classes (new file = analytics_data.dart) and then edit the page to add the new sections. The filter bar extraction can be an inline _buildFilterBar() private method — no new file needed, just refactoring.

## Slice Strategy
This is pure UI — Track A (Direct Build, /implement). No business logic. No tests beyond widget tests (optional).
The manager parse fix is simple (replaces 2 lines). No TDD needed.

## Line Count After Changes
- analytics_data.dart (new): ~45 lines — fine
- analytics_manager.dart (after extracting data classes): ~365 lines (still over 250!)
  → Need to also extract _loadFromDrift() to analytics_drift_loader.dart
  → analytics_manager.dart after: ~220 lines ✅

## Phases
Phase A (Data Layer): Extract analytics_data.dart + analytics_drift_loader.dart + fix manager insights parse (4 files, no UI)
Phase B (Widget Layer): Build InsightCard + InsightsRadarChart + wire into AnalyticsPage (3 files, UI only)

Split into 2 phases because Phase A has no visual output and Phase B is the visible outcome.
</latent_space_scratchpad>

# Implementation Plan: Slice 3 — Flutter Insight Cards & Radar Chart

## Input Lineage
- **Epic**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md`
- **Slice 2 Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_060602_SL2_insight_generator.md`

---

## ⚠️ Pre-Flight Blocker

> [!CAUTION]
> **Slice 2 has an open bug.** `verification_20260518_063029_SL2_insight_generator.md` shows the sparsity guard passes `snapshot.TotalAuditCount` (area total) instead of the store's own audit count. This bug must be fixed before this slice is tested end-to-end. The Flutter work can proceed independently of this fix, but E2E validation requires the backend to be corrected first.

---

## Executive Summary & Out of Scope

**Goal:** Complete the user-facing analytics UI by (1) fixing the hardcoded `insights: const []` in `AnalyticsManager.load()`, (2) building two new widgets — `InsightCard` and `InsightsRadarChart`, and (3) wiring them into `AnalyticsPage` below the KPI grid.

**Also delivers (mandatory before new code):** Split two oversized files:
- `analytics_manager.dart` (404 lines) → extract model classes + offline loader
- `analytics_page.dart` (361 lines) → stays; new code is additive to a smaller base

**Out of Scope (YAGNI):**
- Navigation to a deep-link route from `insight.actionRoute` — currently a no-op `context.go()` call
- Any backend changes — Slice 2 work only
- `GetAreaLeaderboard` UI — separate slice
- Dark mode RadarChart color tuning — use `withValues(alpha: 0.15)` defaults

---

## System Context

| Dimension | Details |
|---|---|
| **Online / Offline** | Insights rendered **online only**. Offline path (`_loadFromDrift()`) returns `insights: const []` — existing offline banner covers this. |
| **RBAC / PBAC** | No new guards. All roles with `analytics:view` see insights. The backend controls what's in the list. |
| **API Contract** | `GET /api/analytics` now returns `insights[]`, `radarData`, `insightsStale`. Manager parses these (hardcoded empty → parsed). |
| **Dependency** | `fl_chart: ^1.0.0` already in pubspec — no new packages needed. |
| **File Size Rule** | `analytics_manager.dart` (404L) and `analytics_page.dart` (361L) exceed the 250L limit. Splits are **mandatory** before adding new code. |

---

## Lifecycle Context (4-State Matrix)

| State | Insight Cards | Radar Chart |
|---|---|---|
| **Loading** | Hidden (whole page shows spinner) | Hidden |
| **Offline** | Hidden + "Insights require internet" banner (already exists) | Hidden |
| **Success — sparse (< 3 audits)** | 1 "info" card: "Complete 3 audits to unlock insights" | Hidden (`radarData=null`) |
| **Success — stale** | Normal cards + "⚠ Insights last updated over 2 hours ago" note | Normal radar |
| **Success — fresh** | 1–3 insight cards | Store vs Region radar polygon |
| **Success — no area context** | `insights=[]` → section hidden | Hidden |
| **Error** | Hidden (manager sets `error` string, page shows error message) | Hidden |

---

## Constraint Traceability

| ID | Constraint (from Epic) | Test Contract |
|---|---|---|
| C1 | Insight Cards shown below KPI grid | FL-07, FL-09 |
| C2 | Card color by type: warning/info/positive | FL-01, FL-02, FL-03 |
| C3 | Max 3 cards (enforced by backend, UI renders list) | — (structural) |
| C4 | `insightsStale=true` → stale banner above cards | FL-09 |
| C5 | RadarChart: store vs region polygon, ≥ 3 categories | FL-06 |
| C6 | Offline → no cards (existing offline banner covers) | FL-10 |
| C7 | Sparse info card renders with info style | FL-03 |
| C8 | Section headers: "INSIGHTS", "PERFORMANCE RADAR" | — (visual) |

---

## Test Contracts

| ID | Scenario | Required State | Why RED First |
|---|---|---|---|
| **FL-01** | `InsightCard` renders with amber left border for `type='warning'` | Widget test, type='warning' | Widget doesn't exist |
| **FL-02** | `InsightCard` renders with success green for `type='positive'` | Widget test, type='positive' | Widget doesn't exist |
| **FL-03** | `InsightCard` renders with info color for `type='info'` | Widget test, type='info' | Widget doesn't exist |
| **FL-04** | `InsightCard` shows arrow button when `actionRoute != null` | Widget test, actionRoute='/plans' | Widget doesn't exist |
| **FL-05** | `InsightsRadarChart` shows "No regional data" when `radarData=null` | Widget test, radarData=null | Widget doesn't exist |
| **FL-06** | `InsightsRadarChart` renders 2 RadarDataSets when data has 3 categories | Widget test, radarData seeded | Widget doesn't exist |
| **FL-07** | `AnalyticsManager.load()` parses `insights` from API JSON | Unit test, mocked Dio | Line 192 hardcodes `const []` |
| **FL-08** | `AnalyticsManager.load()` parses `radarData` from API JSON | Unit test, mocked Dio | Line 193 hardcodes `null` |
| **FL-09** | Stale banner visible when `insightsStale=true` in page | Widget test, AnalyticsData with stale=true | Banner widget not in page |
| **FL-10** | No insight section rendered when `isOffline=true` | Widget test, isOffline=true | Section not guarded |

---

## Test Fixture & Payloads

### Mocked API JSON (for FL-07, FL-08)
```json
{
  "totalAudits": 5,
  "avgScore": 78.5,
  "openAPs": 2,
  "overdueAPs": 1,
  "completionRate": 90.0,
  "trend": [],
  "categoryScores": [],
  "sectionBreakdown": [],
  "insightsStale": false,
  "insights": [
    { "id": "ins_score_drop", "type": "warning", "text": "Your score is below the regional average.", "actionRoute": "/plans" }
  ],
  "radarData": {
    "storeAverages": { "Safety": 72.0, "Operations": 65.0, "Cleanliness": 81.0 },
    "areaAverages": { "Safety": 80.0, "Operations": 78.0, "Cleanliness": 85.0 }
  }
}
```

### Widget Test Fixture (InsightCard)
```dart
InsightCard(
  insight: ActionableInsight(
    id: 'ins_test',
    type: 'warning',
    text: 'Test warning message',
    actionRoute: null,
  ),
)
```

### Widget Test Fixture (InsightsRadarChart)
```dart
InsightsRadarChart(
  radarData: RadarData(
    categories: ['Safety', 'Operations', 'Cleanliness'],
    storeValues: [72.0, 65.0, 81.0],
    regionalValues: [80.0, 78.0, 85.0],
  ),
)
```

---

## Tools & Commands

| Tool | Command |
|---|---|
| Flutter widget tests | `rtk flutter test lib/features/analytics/` |
| Full Flutter tests | `rtk flutter test` |
| Analyze (no warnings) | `rtk flutter analyze lib/features/analytics/` |

**Skills needed:** `flutter-api` (for `RadarChart` API reference), `flutter-architecture` (PFA Manager pattern), `interaction-design` (card micro-animation).

---

## Proposed Changes

| Action | File | Reason |
|---|---|---|
| **[NEW]** | `lib/features/analytics/manager/analytics_data.dart` | Extract `AnalyticsData`, `ActionableInsight`, `RadarData` classes from manager |
| **[MOD]** | `lib/features/analytics/manager/analytics_manager.dart` | Remove model classes, fix line 192–193 to parse API JSON, extract `_loadFromDrift()` |
| **[NEW]** | `lib/features/analytics/manager/analytics_drift_loader.dart` | Extract `_loadFromDrift()` as a standalone function |
| **[NEW]** | `lib/features/analytics/widgets/insight_card.dart` | New widget for a single insight card |
| **[NEW]** | `lib/features/analytics/widgets/insights_radar_chart.dart` | New widget for the store vs region radar chart |
| **[MOD]** | `lib/features/analytics/pages/analytics_page.dart` | Add "INSIGHTS" + "PERFORMANCE RADAR" sections; import new widgets |

---

## Concept Diagram

```text
AnalyticsManager.load() [FIXED]
  │
  ├── Call _api.getAnalytics(...)  ← already done
  │
  ├── [FIXED] Parse json['insights'] → List<ActionableInsight>
  ├── [FIXED] Parse json['radarData'] → RadarData?
  │
  └── AnalyticsData(
        ..existing fields..,
        insights: insights,     ← was const []
        radarData: radarData,   ← was null
        insightsStale: json['insightsStale'] ?? false
      )

AnalyticsPage (ListView)
  ├── Offline Banner (existing)
  ├── Filter Chip Bar (existing)
  ├── Empty State / KPI Grid (existing)
  ├── 6-Month Trend (existing)
  ├── Category Performance (existing)
  │
  ├── [NEW] if (!isOffline && insights.isNotEmpty):
  │     ├── SectionHeader('INSIGHTS')
  │     ├── if (insightsStale): StaleDataBanner
  │     └── for each insight: InsightCard(insight)
  │
  └── [NEW] if (!isOffline && radarData != null):
        ├── SectionHeader('PERFORMANCE RADAR')
        └── InsightsRadarChart(radarData)

InsightCard
  Card with left accent border (3px, color by type)
    Row:
      ├── Icon (warning_amber / info_outline / check_circle)
      ├── Expanded Text (insight.text)
      └── [if actionRoute != null] IconButton(→) → context.go(route)

InsightsRadarChart
  Card
    ├── [if radarData == null] Center("No regional data yet")
    └── RadarChart(
          RadarChartData(
            dataSets: [
              RadarDataSet(store, primary color, 15% alpha fill),
              RadarDataSet(region, grey, 10% alpha fill),
            ],
            tickCount: 5,
            getTitle: (idx) → categories[idx]
          )
        )
    └── Legend Row: [● Store] [● Region]
```

---

## Execution Slices

### Phase A — Data Layer Split & Manager Fix
**Plain English:** Before touching the UI, split the oversized `analytics_manager.dart` into 3 focused files. Extract the pure data classes to `analytics_data.dart` and extract the offline Drift loader to `analytics_drift_loader.dart`. Then fix lines 192–193 to parse `insights` and `radarData` from the API JSON.

**Value Delivered:** `AnalyticsManager.load()` now populates `insights` and `radarData` from the real API. The file size limit is met. Tests FL-07 and FL-08 pass.

**Entry State Required:** Slice 2 backend is deployed OR mocked in tests.

**Exit State Guaranteed:**
- `analytics_manager.dart` < 250 lines, 0 analyzer warnings
- `analytics_data.dart` contains all 3 model classes
- `analytics_drift_loader.dart` contains the offline loader function
- `flutter analyze` clean on all 3 files
- FL-07 + FL-08 manager unit tests pass

**Scope:**
```
lib/features/analytics/manager/analytics_data.dart       [NEW]
lib/features/analytics/manager/analytics_drift_loader.dart [NEW]
lib/features/analytics/manager/analytics_manager.dart    [MOD] — extract + fix lines 192-193
```

**Acceptance Criteria:**
1. Manager calls `ActionableInsight.fromJson(e)` (or inline parse) — NOT hardcoded `const []`
2. `radarData` parses only when ≥ 3 categories in both store and area maps
3. `flutter analyze lib/features/analytics/manager/` — 0 warnings
4. All existing `flutter test lib/features/analytics/` tests still pass

**Complexity:** Low — mechanical extract + 15-line parse block.

**Key Design Decision — where to put `fromJson`:**

| Option | Pros | Cons |
|---|---|---|
| **A: Inline parse in manager** | No new methods on data classes | Manager still has parse logic mixed in |
| **B: `fromJson` factory on model classes** | Clean, testable | Adds 2 methods to data classes |

**Decision: Option B** — `ActionableInsight.fromJson()` and `RadarData.fromJson()` factory constructors in `analytics_data.dart`. This makes FL-07/FL-08 unit tests independent of the manager.

---

### Phase B — Widget Build & Page Wire-Up
**Plain English:** Build the two new widgets and add two new sections to `AnalyticsPage`. No new routes, no DI changes.

**Value Delivered:** Users see Insight Cards and the Radar Chart below the category heatmap when online with sufficient audit data.

**Entry State Required:** Phase A complete (manager correctly populates `insights` and `radarData`).

**Exit State Guaranteed:**
- `InsightCard` renders correctly for all 3 types
- `InsightsRadarChart` renders 2 polygons or an empty state
- `analytics_page.dart` < 400 lines
- Stale banner visible when `insightsStale=true`
- Online guard: insight sections only render when `!isOffline`
- FL-01 → FL-06, FL-09, FL-10 widget tests pass
- `flutter analyze lib/features/analytics/` — 0 warnings

**Scope:**
```
lib/features/analytics/widgets/insight_card.dart           [NEW]
lib/features/analytics/widgets/insights_radar_chart.dart   [NEW]
lib/features/analytics/pages/analytics_page.dart           [MOD]
```

**Acceptance Criteria:**
1. `InsightCard` — left border color: `warning=AppTheme.warning`, `positive=AppTheme.success`, `info=AppTheme.info`
2. `InsightCard` — `actionRoute != null` → tap navigates via `context.go(route)`
3. `InsightsRadarChart` — `null` data → shows "No regional data yet" placeholder
4. `InsightsRadarChart` — valid data → renders `RadarChart` with 2 `RadarDataSet`s
5. `AnalyticsPage` — stale banner: yellow chip "⚠ Insights last updated over 2 hours ago" above cards
6. `AnalyticsPage` — sections hidden when `isOffline=true`
7. `AnalyticsPage` — sections hidden when `insights.isEmpty` (no area context case)

**Complexity:** Medium — `fl_chart RadarChart` API requires careful category alignment between `dataSets` indices and `getTitle` callback index.

> [!TIP]
> **fl_chart RadarChart gotcha:** `getTitle` callback receives an index (0-based) into the `dataSets[0].dataEntries` list. Ensure `categories`, `storeValues`, and `regionalValues` are always the same length. If they mismatch, RadarChart silently renders wrong labels.

---

<command_logs>
- list_dir: `lib/features/analytics/` — 4 subdirs (manager, pages, services, widgets)
- list_dir: `lib/features/analytics/pages/` — analytics_page.dart (14451 bytes)
- list_dir: `lib/features/analytics/manager/` — analytics_manager.dart (12652 bytes)
- list_dir: `lib/features/analytics/widgets/` — 4 existing widgets
- list_dir: `lib/features/analytics/services/` — analytics_api_service.dart (792 bytes)
- view_file: `analytics_page.dart` (361 lines) — full read: confirmed 361 lines, KPI+trend+heatmap sections exist
- view_file: `analytics_manager.dart` (404 lines) — confirmed: lines 192-193 hardcode `insights: const [], radarData: null`. AnalyticsData, ActionableInsight, RadarData classes at lines 15-403.
- view_file: `analytics_api_service.dart` (26 lines) — Dio GET wrapper confirmed.
- view_file: `trend_chart.dart` (203 lines) — fl_chart LineChart pattern confirmed (RadarChart API similar).
- view_file: `app_theme.dart` (167 lines) — AppTheme.warning, .success, .info confirmed.
- view_file: `section_header.dart` (40 lines) — SectionHeader widget pattern confirmed.
- view_file: `verification_20260518_063029_SL2_insight_generator.md` — SL2 bug confirmed (open action item).
- grep_search: `fl_chart` in lib/ — found in `trend_chart.dart` line 1. ✅ No `RadarChart` usage yet.
- grep_search: `fl_chart` in pubspec.yaml — `fl_chart: ^1.0.0` confirmed.
</command_logs>

---

## Handoff Block

> **Route: Track A — Direct Build (`/implement`)**
>
> This is pure UI with a mechanical manager fix. No business logic math. No database. No ATDD required.

Execute **ONE AT A TIME** in this order:

**Step 1 — Phase A: Data Layer Split & Manager Fix**
```
/implement c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_064918_SL3_flutter_insight_ui.md
```
*(Instruction for AI: Focus on Phase A — extract analytics_data.dart, analytics_drift_loader.dart, and fix analytics_manager.dart lines 192-193 only. DO NOT touch the page or build new widgets yet.)*

**Step 2 — Phase B: Widget Build & Page Wire-Up**
```
/implement c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_064918_SL3_flutter_insight_ui.md
```
*(Instruction for AI: Focus on Phase B — build insight_card.dart, insights_radar_chart.dart, and wire into analytics_page.dart.)*

**Concurrency:** This slice is blocked until **Slice 2 backend bug is fixed** (`GetAnalytics.cs` line 223 must pass store audit count, not `snapshot.TotalAuditCount`). The widget build (Phase B) can proceed independently, but end-to-end testing requires the backend fix.
