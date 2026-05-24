# Implementation Plan: BOD Analytics — 5 Interactive Boardroom Use Cases
**Date**: 2026-05-24T19:53:13+07:00 | **ShortID**: 1eb2d30e | **Workflow**: /analyze-feature

<!--
<latent_space_scratchpad>
KEY CONSTRAINTS EXTRACTED:
C1. GetBodReport.cs (62 lines) passes raw jsonb — no filter params. Must ADD province/district query params.
C2. BodReportDtos.cs (32 lines) BodStoreRankEntry has NO LastSyncedAt. Must add DateTime? LastSyncedAt.
C3. Store.cs (30 lines) has NO LastSyncedAt column. Must add nullable DateTimeOffset? LastSyncedAt.
C4. StoreConfiguration.cs (41 lines) must map the new column.
C5. BodAnalyticsManager.dart (110 lines) has single _report state, NO filter state. Must add _activeProvince, _activeDistrict, _isLiveMode.
C6. BodReportResponse.dart uses Map<String,dynamic> — WEAKLY TYPED. Must refactor to typed models before wiring interactivity.
C7. bod_analytics_page.dart is 265 lines (>250 limit). MUST split before adding filter bar.
C8. BodApAgingFunnel reads from Map<String,dynamic> apAging — must add onTap callbacks.
C9. BodStoreLeaderboard _buildStoreRow() has no onTap. Must add onTap + sync dot.
C10. AnalyticsEndpoints.cs has only /bod and /bod/refresh. Must add 3 new routes.
C11. Action Plan entity already has StoreId, StoreManagerName, CriteriaLabel, CreatedAt — AP drill-down is native.
C12. Province/District already exists in Store.Address2 — regional filter is native.
C13. AppCapabilities.AnalyticsBod = "analytics:bod" — reuse for all new BOD endpoints.

OUT OF SCOPE:
- No BodReportCalculator.cs changes (418-line monolith, untouched)
- No per-province nightly snapshot generation
- No new DI registrations (BodAnalyticsManager already registered)
- No router/navigation changes
- No new DB tables (only column addition to existing stores table)
- No changes to existing /bod/refresh endpoint
- No tests touching existing working endpoints

RISKS:
- bod_analytics_page.dart at 265 lines > 250 limit. Split FIRST.
- BodReportResponse uses Map<String,dynamic> everywhere. Typed model refactor must happen before interactivity to avoid runtime cast errors.
- Regional filter returns live data; main dashboard shows nightly snapshot. UI MUST show badge to prevent confusion.
- apAging in snapshot is a Map, not a List. New AP drill-down endpoint returns a List. Keep both shapes separate.
</latent_space_scratchpad>
-->

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\product\bod-analytics\research_20260524_193500_1eb2d30e_bod_analytics_boardroom_1eb2d30e.md`

---

## Executive Summary & Out of Scope

**Goal**: Transform 6 static BOD cards into interactive drill-down panels. Add 3 new thin server endpoints + `Store.LastSyncedAt` column + typed Dart models + filter state in manager.

**Architecture Pattern**: `Snapshot OLAP + On-Demand Query Overlay`

**Out of Scope** (YAGNI):
- No changes to `BodReportCalculator.cs` (418-line monolith)
- No per-province nightly snapshots
- No new DB tables (only 1 column added to `stores`)
- No router/navigation changes
- No new DI registrations
- No changes to `/bod/refresh` endpoint

---

## System Context

| Property | Value |
|---|---|
| Connectivity | Online-only. Analytics requires live server connection. |
| Auth/RBAC | All new BOD endpoints use existing `AppCapabilities.AnalyticsBod = "analytics:bod"` |
| Polling | Manager already polls every 5s during refresh. Gate all drill-down commands with `if (_isLoading) return;` |
| Cache | `IMemoryCache` (TTL=60s) on server for regional filter endpoint, keyed by `province+district` |
| Data Modes | Nightly Snapshot (unfiltered) vs Live Dynamic Data (filtered). UI badge must reflect mode. |

---

## Lifecycle Context (4-State Matrix)

| State | When | UI Behaviour |
|---|---|---|
| **Loading** | `_isLoading == true` | Shimmer overlay on all 6 cards |
| **Error** | `_error != null` | Toast via `InteractionManager.showWarningToast()` |
| **Empty** | `_isEmpty == true` | `ChecklyEmptyState` with "Trigger Recomputation" button |
| **Success** | `_report != null` | All 6 cards interactive with drill-down modals |

---

## Concept Diagram

```
[Flutter UI — BodAnalyticsPage]
    │
    ├─ [BodRegionFilterBar] ──► manager.applyFilter(province, district)
    │       └── Status badge: [Nightly Snapshot] ↔ [Live Dynamic Data]
    │
    ├─ [BodKpiGrid]        ──► MoM delta PillChip (client-side from trend[])
    ├─ [BodScoreTrend]     ──► Localized 12-month trend (returned in filter response)
    ├─ [BodStoreLeaderboard] → onTap row ──► sync detail bottom sheet (lastSyncedAt from DTO)
    ├─ [BodApAgingFunnel]  ──► onTap bucket ──► AP detail bottom sheet
    │
    └─ [BodAnalyticsManager]
            ├── loadReport()        → GET /api/analytics/bod         [EXISTING]
            ├── applyFilter()       → GET /api/analytics/bod?province=&district= [NEW]
            ├── loadApBucketDetail()→ GET /api/analytics/bod/ap/{bucket} [NEW]
            └── loadAuditorFilter() → GET /api/analytics/auditors/productivity [NEW]

[Server]
    ├── GET /api/analytics/bod            [EXISTING - jsonb pass-through]
    ├── GET /api/analytics/bod?province=&district= [NEW - live query + localized trend]
    ├── GET /api/analytics/bod/ap/{bucket}         [NEW - AP drill-down]
    └── GET /api/analytics/auditors/productivity   [NEW - DM grouped]

[DB]
    stores table ──► + last_synced_at column (nullable DateTimeOffset)
```

---

## Constraint Traceability

| Constraint | Source | Test Contract ID |
|---|---|---|
| C1: No filter params on `/bod` | `GetBodReport.cs` L14 | TC-01 |
| C2: `BodStoreRankEntry` has no `LastSyncedAt` | `BodReportDtos.cs` L24 | TC-02 |
| C3: `Store` entity has no `LastSyncedAt` | `Store.cs` L1-30 | TC-02 |
| C4: Regional filter returns live data; badge required | Research doc §Stateful Data Indicator | TC-03 |
| C5: `BodReportResponse` is weakly typed `Map<String,dynamic>` | `bod_analytics_data.dart` L2 | TC-04 |
| C6: `bod_analytics_page.dart` is 265 lines > 250 limit | File limit rule | TC-05 |
| C7: `BodApAgingFunnel._buildAgingBox()` has no GestureDetector | `bod_ap_aging_funnel.dart` L88 | TC-06 |
| C8: `BodStoreLeaderboard._buildStoreRow()` has no onTap | `bod_store_leaderboard.dart` L78 | TC-07 |
| C9: Advisory lock / IMemoryCache for regional filter | Research §Rules Conflicts | TC-08 |
| C10: AP entity has `CreatedAt` for age calculation | Research §AP Drill-Down | TC-06 |

---

## Test Contracts

### TC-01: Regional Filter Endpoint — Happy Path
- **Route**: Route 3 (Acceptance Test First — hits DB)
- **Request**: `GET /api/analytics/bod?province=Hanoi`
- **Expected Response** (200 OK):
```json
{
  "kpis": { "totalAudits": 42, "avgScore": 78.5 },
  "trend": [{ "month": "2026-05", "avgScore": 78.5 }, "...11 more months"],
  "topStores": [{ "storeId": "...", "storeName": "Hoan Kiem", "avgScore": 91.2, "auditCount": 5, "lastSyncedAt": "2026-05-24T10:00:00Z" }],
  "bottomStores": [...],
  "isLiveData": true
}
```
- **Fail if**: Response returns nightly snapshot data instead of live filtered query.

### TC-02: Store.LastSyncedAt Written on Sync
- **Route**: Route 3
- **Setup**: Store exists, `last_synced_at` IS NULL.
- **Action**: POST `/api/sync/submissions` with `storeId`.
- **Expected**: `Store.LastSyncedAt` updated to NOW(). Leaderboard DTO includes `lastSyncedAt`.
- **Fail if**: Column is NULL after sync completes.

### TC-03: UI Badge Transitions (Live Mode)
- **Route**: Route 1 (UI only — badge driven by manager state)
- **Given**: `manager.isLiveMode == false` → badge reads "Nightly Snapshot".
- **When**: `manager.applyFilter("Hanoi", null)` called.
- **Then**: `manager.isLiveMode == true` → badge reads "Live Dynamic Data".
- **Fail if**: Badge stays "Nightly Snapshot" while filtered data is shown.

### TC-04: Dart Typed Model Parity
- **Route**: Route 2 (unit test — data parsing)
- **Given**: Raw JSON from server (TC-01 response above).
- **When**: `BodReportResponse.fromJson(json)` called.
- **Then**: All typed fields non-null; `topStores[0].lastSyncedAt` is a `DateTime?`.
- **Fail if**: Any field falls back to `dynamic` or throws a cast error.

### TC-05: Page Split — bod_analytics_page.dart < 250 lines after extraction
- **Route**: Route 1
- **Given**: `bod_analytics_page.dart` is 265 lines.
- **When**: `_BodDashboardBody` extracted to `bod_dashboard_body.dart`.
- **Then**: Both files are < 250 lines. No functional change.
- **Fail if**: `flutter test` fails after extraction.

### TC-06: AP Bucket Drill-Down Endpoint
- **Route**: Route 3
- **Request**: `GET /api/analytics/bod/ap/90d+`
- **Expected Response** (200 OK):
```json
[
  { "id": "...", "criteriaLabel": "Fire Safety", "storeName": "Airport", "managerName": "Nguyen A", "ageInDays": 112 }
]
```
- **Fail if**: Returns empty list when `ActionPlans` with `Status=Open` AND age>90 days exist.

### TC-07: Store Leaderboard onTap Shows Sync Sheet
- **Route**: Route 1
- **Given**: `topStores[0].lastSyncedAt = "2026-05-24T10:00:00Z"`.
- **When**: User taps first store row.
- **Then**: `showModalBottomSheet` opens showing "Last synced: X mins ago".
- **Fail if**: Tap does nothing.

### TC-08: Regional Filter Caching (60s TTL)
- **Route**: Route 3
- **Given**: Two identical requests for `?province=Hanoi` within 60 seconds.
- **Then**: Second request does NOT trigger a new DB query (served from `IMemoryCache`).
- **Fail if**: DB is queried twice for identical requests within the TTL window.

---

## Test Fixture & Payloads

```
Required Seeded State:
- Admin user with capability "analytics:bod"
- At least 2 Stores in Province "Hanoi" with Address2.Province = "Hanoi"
- At least 1 ActionPlan with Status = "Open", CreatedAt > 90 days ago
- At least 1 Submission in last 30 days for a Hanoi store
- BOD snapshot exists (run RefreshBodReport first in test setup)
```

---

## Tools & Commands

| Tool | Purpose |
|---|---|
| `dotnet-scaffolding` skill | Scaffold new endpoint handlers |
| `ef-core` skill | Add `LastSyncedAt` migration |
| `testing-strategy` skill | Integration test pattern (WebApplicationFactory) |
| `flutter-architecture` skill | Manager commands, typed model patterns |

```bash
# Backend
rtk dotnet build server/

# Backend tests
rtk dotnet test server/

# Flutter
rtk flutter test lib/
```

---

## Proposed Changes (Build Order: Schema → Logic → API → UI)

| # | File | Type | Slice |
|---|---|---|---|
| 1 | `server/Common/Persistence/Entities/Store.cs` | [MOD] | S1 |
| 2 | `server/Common/Persistence/Configurations/StoreConfiguration.cs` | [MOD] | S1 |
| 3 | `server/Common/Persistence/Migrations/AddStoreLastSyncedAt.cs` | [NEW] | S1 |
| 4 | `server/Features/Analytics/BodReportDtos.cs` | [MOD] | S1 |
| 5 | `server/Features/Analytics/GetBodReportFiltered.cs` | [NEW] | S1 |
| 6 | `server/Features/Analytics/GetApBucketDetail.cs` | [NEW] | S2 |
| 7 | `server/Features/Analytics/GetAuditorProductivity.cs` | [NEW] | S2 |
| 8 | `server/Features/Analytics/AnalyticsEndpoints.cs` | [MOD] | S2 |
| 9 | `lib/features/analytics/manager/bod_analytics_data.dart` | [MOD] | S3 |
| 10 | `lib/features/analytics/manager/bod_analytics_manager.dart` | [MOD] | S3 |
| 11 | `lib/features/analytics/services/bod_analytics_api_service.dart` | [MOD] | S3 |
| 12 | `lib/features/analytics/pages/bod_dashboard_body.dart` | [NEW — SPLIT] | S4 |
| 13 | `lib/features/analytics/pages/bod_analytics_page.dart` | [MOD — SPLIT] | S4 |
| 14 | `lib/features/analytics/widgets/bod_region_filter_bar.dart` | [NEW] | S4 |
| 15 | `lib/features/analytics/widgets/bod_mom_delta_chip.dart` | [NEW] | S5 |
| 16 | `lib/features/analytics/widgets/bod_kpi_grid.dart` | [MOD] | S5 |
| 17 | `lib/features/analytics/widgets/bod_store_leaderboard.dart` | [MOD] | S5 |
| 18 | `lib/features/analytics/widgets/bod_store_sync_modal.dart` | [NEW] | S5 |
| 19 | `lib/features/analytics/widgets/bod_ap_aging_funnel.dart` | [MOD] | S6 |
| 20 | `lib/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart` | [NEW] | S6 |

**UI Component Overflow Table**:

| Component | Truncation Limit | Overflow Action |
|---|---|---|
| `BodRegionFilterBar` | Province: 20 chars | `TextOverflow.ellipsis` |
| `BodStoreSyncModal` | Store name: 1 line | `maxLines: 1, overflow: ellipsis` |
| `BodApBucketDetailSheet` | Max 50 rows | `ListView` with scroll |
| `BodMomDeltaChip` | Delta: 1 decimal place (`+2.4%`) | Truncate beyond 1dp |

---

## Execution Slices

---

### Slice 1 — Server Foundation: LastSyncedAt Column + Filtered BOD Endpoint
**Summary**: Add `LastSyncedAt` to `Store` entity and create the regional filter endpoint.
**Value**: Unblocks all regional drill-down and sync telemetry UI.
**Entry State**: `Store.cs` has no `LastSyncedAt`. No filtered BOD endpoint exists.
**Exit State**: DB has `last_synced_at` column on `stores`. `GET /api/analytics/bod?province=Hanoi` returns 200 with typed response + `lastSyncedAt` in store rows.
**Files** (4 max): `Store.cs`, `StoreConfiguration.cs`, `BodReportDtos.cs`, `GetBodReportFiltered.cs`.
**Migration**: Run `rtk dotnet ef migrations add AddStoreLastSyncedAt -p server/` separately after files are saved.
**Acceptance Criteria**:
- [ ] `Store.LastSyncedAt` is `DateTimeOffset?` — nullable, no default.
- [ ] Column mapped as `last_synced_at` in `StoreConfiguration`.
- [ ] `GetBodReportFiltered` accepts `[AsParameters] FilterParams(string? Province, string? District)`.
- [ ] When province/district are null, same as `GetBodReport` (returns snapshot). When filtered, runs live EF query grouped by month for trend.
- [ ] Response includes `isLiveData: true` flag when filter is active.
- [ ] `BodStoreRankEntry` record gains `DateTime? LastSyncedAt` field.
- [ ] `IMemoryCache` TTL=60s on filtered response, keyed by `$"{province}:{district}"`.
- [ ] `dotnet build` passes with 0 errors.
**Complexity**: Medium

---

### Slice 2 — Server: AP Drill-Down + Auditor Productivity Endpoints
**Summary**: Add `GetApBucketDetail` and `GetAuditorProductivity` endpoints. Wire all 3 new routes in `AnalyticsEndpoints`.
**Value**: Completes server-side for Case 4 (AP Aging) and Case 5 (Auditor Scatter).
**Entry State**: Slice 1 complete. `AnalyticsEndpoints` still only has `/bod` and `/bod/refresh`.
**Exit State**: `GET /api/analytics/bod/ap/{bucket}` and `GET /api/analytics/auditors/productivity` return correct typed responses. All 3 new routes wired.
**Files** (4 max): `GetApBucketDetail.cs`, `GetAuditorProductivity.cs`, `AnalyticsEndpoints.cs`, `BodReportDtos.cs`.
**Acceptance Criteria**:
- [ ] `bucket` param maps to age range: `0-30d` → `CreatedAt > NOW()-30d`, `31-60d`, `61-90d`, `90d+`.
- [ ] AP endpoint returns `List<ApDetailEntry>` with `{ Id, CriteriaLabel, StoreName, ManagerName, AgeInDays }`.
- [ ] Auditor endpoint accepts `?from=&to=&search=` and returns `List<DmProductivityDto>` grouped by DistrictManager.
- [ ] `AnalyticsEndpoints` registers: `/bod` (filter params), `/bod/ap/{bucket}`, `/auditors/productivity` — all gated with `RequireCapability(AppCapabilities.AnalyticsBod)`.
- [ ] `dotnet build` + `dotnet test` pass with 0 errors.
**Complexity**: Medium

---

### Slice 3 — Flutter: Typed Models + Manager Filter State
**Summary**: Replace `Map<String,dynamic>` in `BodReportResponse` with typed Dart classes. Add `isLiveMode`, `_activeProvince`, `_activeDistrict` to manager. Add `applyFilter()`, `clearFilter()`, `loadApBucketDetail()`.
**Value**: Enables type-safe widget wiring in Slices 4-6. Prevents runtime cast errors.
**Entry State**: `BodReportResponse` is weakly typed. Manager has no filter state.
**Exit State**: `BodReportResponse` fully typed. Manager exposes `isLiveMode`, `applyFilter()`, `clearFilter()`. `BodAnalyticsApiService` has `getFilteredReport()`, `getApBucketDetail()`.
**Files** (4 max): `bod_analytics_data.dart`, `bod_analytics_manager.dart`, `bod_analytics_api_service.dart`.
**Acceptance Criteria**:
- [ ] `BodStoreEntry` has `DateTime? lastSyncedAt` field parsed from ISO string.
- [ ] `MomDeltaEntry` computed client-side: `deltaPercent = (thisMonth - prevMonth) / prevMonth * 100`.
- [ ] `applyFilter(province, district)` sets `_isLiveMode = true` and calls filtered API endpoint.
- [ ] `clearFilter()` sets `_isLiveMode = false` and calls `loadReport()` (unfiltered snapshot).
- [ ] `if (_isLoading) return;` guard on all drill-down commands.
- [ ] `flutter test lib/` passes with 0 errors.
**Complexity**: Medium

---

### Slice 4 — Flutter: Page Split + Region Filter Bar
**Summary**: Extract `_BodDashboardBody` to `bod_dashboard_body.dart` to bring page < 250 lines. Add `BodRegionFilterBar` sticky widget.
**Value**: Fixes the 265-line file limit violation. Adds Province → District cascading filter UI.
**Entry State**: `bod_analytics_page.dart` is 265 lines. No filter bar exists.
**Exit State**: `bod_analytics_page.dart` < 150 lines. `bod_dashboard_body.dart` < 200 lines. `BodRegionFilterBar` shows status badge: `[ Nightly Snapshot ]` or `[ Live Dynamic Data ]`.
**Files** (4 max): `bod_analytics_page.dart`, `bod_dashboard_body.dart`, `bod_region_filter_bar.dart`.
**Acceptance Criteria**:
- [ ] `bod_analytics_page.dart` contains only: Scaffold, AppBar, `ListenableBuilder` routing to 4 states. < 150 lines.
- [ ] `bod_dashboard_body.dart` contains the success-state card layout. < 200 lines.
- [ ] `BodRegionFilterBar` shows Province dropdown → District dropdown (district disabled until province selected).
- [ ] Badge text: `"Nightly Snapshot"` when `!manager.isLiveMode`, `"Live Dynamic Data"` when `manager.isLiveMode`.
- [ ] `flutter test lib/` passes with 0 errors.
**Complexity**: Low-Medium

---

### Slice 5 — Flutter: KPI Delta Chip + Sync Leaderboard
**Summary**: Add `BodMomDeltaChip` to `BodKpiGrid`. Add sync dot + onTap to `BodStoreLeaderboard`. Create `BodStoreSyncModal`.
**Value**: Answers Case 1 (MoM variance) and Case 3 (sync status) without any new API calls.
**Entry State**: Slice 3 complete (typed models available). KPI cards show no delta. Store rows have no tap.
**Exit State**: Each KPI card shows `+2.4% ↑` or `-1.1% ↓` delta chip. Tapping a store row shows sync sheet.
**Files** (4 max): `bod_mom_delta_chip.dart`, `bod_kpi_grid.dart`, `bod_store_leaderboard.dart`, `bod_store_sync_modal.dart`.
**Acceptance Criteria**:
- [ ] `BodMomDeltaChip` shows green `↑` for positive delta, red `↓` for negative, grey `—` for no previous month.
- [ ] `BodKpiGrid` passes `MomDeltaEntry` to each KPI card to render delta chip.
- [ ] `_buildStoreRow()` shows a coloured sync dot: green if `lastSyncedAt` < 2h ago, amber if < 24h, red if older/null.
- [ ] Tapping a store row calls `showModalBottomSheet` with `BodStoreSyncModal(store)`.
- [ ] `BodStoreSyncModal` displays: store name, "Last synced: X mins/hours ago", coloured status text.
- [ ] `flutter test lib/` passes with 0 errors.
**Complexity**: Low

---

### Slice 6 — Flutter: AP Aging Drill-Down Sheet
**Summary**: Add `GestureDetector` to `BodApAgingFunnel` boxes. Create `BodApBucketDetailSheet`. Wire manager command.
**Value**: Answers Case 4 (AP aging). Executives can tap a bucket and see the list of overdue action plans.
**Entry State**: Slice 2 (server AP endpoint) and Slice 3 (manager) complete.
**Exit State**: Tapping any aging box triggers `manager.loadApBucketDetail(bucket)` and shows a scrollable list sheet.
**Files** (4 max): `bod_ap_aging_funnel.dart`, `bod_ap_bucket_detail_sheet.dart`.
**Acceptance Criteria**:
- [ ] `_buildAgingBox()` wrapped in `GestureDetector.onTap`.
- [ ] Tap triggers `showModalBottomSheet` with `BodApBucketDetailSheet(bucket: '90d+')`.
- [ ] Sheet shows a `ListView` of AP items: `CriteriaLabel — Store — Manager — X days`.
- [ ] Sheet shows loading shimmer while `manager.isApDetailLoading` is true.
- [ ] Sheet shows "No overdue action plans" empty state if list is empty.
- [ ] Max 50 rows in the list (apply `.Take(50)` on server).
- [ ] `flutter test lib/` passes with 0 errors.
**Complexity**: Low-Medium

---

<command_logs>
grep_search: server/Features/Analytics — class|record|endpoint|MapGet|MapPost
grep_search: lib/features/analytics — class|Command|Manager|Service|Widget
view_file: server/Features/Analytics/GetBodReport.cs (62 lines)
view_file: server/Features/Analytics/BodReportDtos.cs (32 lines)
view_file: server/Features/Analytics/AnalyticsEndpoints.cs (34 lines)
view_file: lib/features/analytics/services/bod_analytics_api_service.dart (19 lines)
view_file: lib/features/analytics/manager/bod_analytics_manager.dart (110 lines)
view_file: lib/features/analytics/manager/bod_analytics_data.dart (41 lines)
view_file: server/Common/Persistence/Entities/Store.cs (30 lines)
view_file: server/Common/Persistence/Configurations/StoreConfiguration.cs (41 lines)
view_file: lib/features/analytics/pages/bod_analytics_page.dart (265 lines) ← FILE LIMIT TRIGGERED
view_file: lib/features/analytics/widgets/bod_ap_aging_funnel.dart (127 lines)
view_file: lib/features/analytics/widgets/bod_store_leaderboard.dart (128 lines)
grep_search: AppCapabilities.AnalyticsBod → "analytics:bod" (server/Common/Auth/AppCapabilities.cs L38)
grep_search: LastSyncedAt → NO RESULTS (confirmed absent)
</command_logs>

---

## Handoff Block

**Plan Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_20260524_195313_1eb2d30e_bod_analytics_1eb2d30e-2365-48bd-af96-fc489f276027.md`

Execute slices **ONE AT A TIME** in this order. Do not skip ahead.

| Slice | Action Sequence | Route |
|---|---|---|
| **Slice 1** | Write Acceptance Tests (TC-01, TC-02) → Build | Route 3 |
| **Slice 2** | Write Acceptance Tests (TC-06, TC-08) → Build | Route 3 |
| **Slice 3** | Write Unit Tests (TC-04) → Build | Route 2 |
| **Slice 4** | Build directly (TC-05 verified by file line count) | Route 1 |
| **Slice 5** | Build directly (TC-03, TC-07 are UI interactions) | Route 1 |
| **Slice 6** | Build directly (TC-06 already covered in Slice 2) | Route 1 |

**Dependency Chain**:
```
Slice 1 (DB + Filtered Endpoint)
    → Slice 2 (AP + Auditor Endpoints)  [parallel with Slice 3]
    → Slice 3 (Dart Models + Manager)
        → Slice 4 (Page Split + Filter Bar)
            → Slice 5 (KPI Chips + Sync Leaderboard)
                → Slice 6 (AP Drill-Down Sheet)
```

> [!IMPORTANT]
> Start with **Slice 1**. Command: `/atdd` → input this plan → "Write acceptance tests for Slice 1 (TC-01, TC-02)"
