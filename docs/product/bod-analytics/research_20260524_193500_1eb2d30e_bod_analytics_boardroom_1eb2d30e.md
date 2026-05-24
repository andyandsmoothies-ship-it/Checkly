# Research: BOD Analytics — 5 Interactive Boardroom Use Cases
**Date**: 2026-05-24 | **ShortID**: 1eb2d30e | **Session**: 1eb2d30e-2365-48bd-af96-fc489f276027
**Workflow**: /research → next: /implement

---

## [ORIGIN_IDEA]
The Checkly Boardroom Analytics Dashboard currently shows a **static, non-interactive snapshot** of the current month. During live boardroom sessions, Admin executives cannot answer critical operational questions because they cannot drill into regions, compare months, or investigate system vs. manager failures. The mission is to design a cohesive, interactive strategy for 5 use cases: (1) MoM variance comparison, (2) regional cascading drill-down, (3) sync telemetry per-store, (4) AP aging funnel drill-to-detail, and (5) auditor productivity filters.

---

## System Design Pattern
**Primary**: `Snapshot OLAP + On-Demand Query Overlay`

The existing architecture uses a nightly-computed `jsonb` blob (`BodReportSnapshot.Payload`) which is static. Interactive use cases require a hybrid approach: the snapshot feeds the **main dashboard** by default, while **new thin, optimized query endpoints** serve live filtered data and drill-down sub-data on demand. This avoids rebuilding the 418-line calculator while unlocking interactive boardroom analysis.

### Stateful Data Mode & Filtering Logic
To ensure complete data consistency and eliminate any "why doesn't the sum of parts match the whole" confusion:
* **Stateful Data Indicator**: The UI displays a clear `[ Nightly Snapshot (2:00 AM) ]` badge in unfiltered view, which transforms dynamically into `[ Live Dynamic Data ]` whenever a regional filter is active. An Admin toggle is provided to switch manually between static cached views and active live views.
* **Cascading Localized Trend Array**: The regional filtered endpoint (`GetBodReportFiltered.cs`) dynamically groups submissions by month for the filtered region to return a localized trend array, preserving cascading regional Month-over-Month (MoM) calculations.
* **O(1) Sync Telemetry**: Instead of a transaction log table, a single `LastSyncedAt` column is added directly to the existing `Store` entity. Sync logs are updated in-place, enabling instant O(1) checks.
* **District Manager Grouping**: The scatter plot groups auditor productivity by District Manager Teams by default to prevent overplotting ("ink-blob overload"), with a search filter to highlight individual auditors.

```
[Flutter UI]
    |
    ├── BodAnalyticsManager (ChangeNotifier)
    │       ├── loadReport()    → GET /api/analytics/bod                       [EXISTING - jsonb blob]
    │       ├── applyFilter()   → re-calls filtered endpoint with ?province=&district= [NEW params, returns localized trend]
    │       ├── loadRegions()   → GET /api/analytics/bod/regions               [NEW]
    │       ├── loadApDetail()  → GET /api/analytics/bod/ap/bucket/{bucket}    [NEW]
    │       └── loadAuditorFilter() → GET /api/analytics/auditors/productivity [NEW, groups by District Manager]
    |
[Server]
    ├── GET /api/analytics/bod?province=&district=  [MODIFY GetBodReportFiltered - live query returning filtered snapshot + trend]
    ├── GET /api/analytics/bod/regions             [NEW endpoint for cascading dropdown keys]
    ├── GET /api/analytics/bod/ap/bucket/{bucket}  [NEW endpoint for Action Plan aging detail]
    └── GET /api/analytics/auditors/productivity   [NEW endpoint - grouped by District Manager by default]
```

---

## Status Quo Audit — Current Codebase Reality

| Area | Finding | Implication |
|---|---|---|
| `GetBodReport.cs` | Returns raw `jsonb` blob, no query params accepted | Must add `province?` + `district?` query params |
| `BodReportCalculator.cs` | 418-line monolith, no filter arguments | Cannot filter at compute time; need separate live query for filtered views |
| `BodReportDtos.cs` | `BodStoreRankEntry(StoreId, StoreName, AvgScore, AuditCount)` — no sync fields | AP detail needs `StoreManagerName` (already in `ActionPlan.StoreManagerName`) |
| `BodReportSnapshot` entity | `{ Id, Date, ComputedAt, Status, Payload }` — no per-region snapshots | Filtering must be live-query, not snapshot-based |
| `Store.Address2` | `{ Province, District, Ward, Street }` — **Province/District ALREADY EXISTS** | Cascading filter is native — no schema changes needed |
| `ActionPlan` entity | Has `StoreId`, `StoreManagerName`, `CriteriaLabel`, `Deadline`, `CreatedAt` | AP drill-down is native — new endpoint only |
| Store.LastSyncedAt column | **DOES NOT EXIST** anywhere in the codebase | Sync Telemetry (Case 3) requires adding a nullable `LastSyncedAt` column to the `Store` entity. Super easy EF Core migration, keeps writes at O(1). |
| BodReportResponse (Dart) | `Map<String, dynamic>` — weakly typed | Refactor to typed models is needed before interactivity |
| `BodAnalyticsManager` | 110 lines, single `_report` state, no filter state | Must add `_activeProvince`, `_activeDistrict`, `_momData` state fields |
| `BodApAgingFunnel` widget | Static `_buildAgingBox()`, no `GestureDetector` | Must wrap boxes in `GestureDetector` for drill-down |
| `BodStoreLeaderboard` widget | Static `_buildStoreRow()`, no `onTap` | Must add `onTap` callback and sync indicator |

---

<latent_space_scratchpad>
**Tradeoff Debate:**

Option A (Native Fit): Keep jsonb blob architecture. Add filter params to the EXISTING calculator — recalculate live per request. Risk: The calculator runs 6 expensive DB queries. Running it live per filter will cause N+1 and timeout issues at boardroom scale (hundreds of stores).

Option B (Pragmatic): Keep snapshot for the main dashboard KPIs (fast). Add 4-5 thin NEW endpoints that do targeted, indexed queries live for drill-down only. Filter applies to new endpoints. This is the sweet spot — no calculator rewrite, no over-engineering.

Option C (Enterprise): Add per-province/district snapshot rows to `BodReportSnapshot`. Nightly worker generates N×M snapshots. Fast read-time but massive storage explosion and delayed data. Overkill for current scale.

**Winner: Option B (Pragmatic)**. Main KPIs stay fast (pre-computed). Drill-down data is live-queried via thin, indexed endpoints. This matches the existing PFA pattern perfectly.

**Sync Telemetry Design (Keep it O(1)):**
Instead of introducing a transaction-heavy `DeviceSyncLog` table, we will add a single nullable `LastSyncedAt` datetime column directly to the `Store` entity. When a sync occurs, we execute a simple in-place update on the store row. This keeps data reads and writes at O(1) complexity, completely eliminates table bloat, and provides the exact sync timestamp required.

**The "Live vs. Nightly" Math Conflict (Stateful Mode Indicator):**
Nightly reports are pre-calculated at 2:00 AM. When the Admin applies a regional filter (e.g., Hanoi), the server runs a live query on active submissions. Hanoi's live score might drop to 78% due to today's submissions. When the filter is cleared, the dashboard snaps back to the static snapshot showing 85%.
To resolve this:
* We add a stateful badge that displays `[ Nightly Snapshot ]` (when unfiltered) versus `[ Live Dynamic Data ]` (when filtered).
* We provide a header toggle for "Static Snapshot" vs "Live Mode".

**Cascading Regional MoM Trend:**
When the Admin filters by Region (Case 2), the new filtered endpoint GET /api/analytics/bod?province=Hanoi will load Hanoi's data. To prevent the trend chart from disappearing or displaying the national trend, the filtered endpoint groups submissions by month for the filtered region to return a localized trend array.

**Scatter Plot auditor scalability (Ink-Blob Overload):**
For a chain with hundreds of stores, showing individual auditor dots on a scatter plot will look like a crowded, unreadable ink blob.
By default, the scatter plot groups points by **District Manager Teams** rather than individual auditors. We provide an interactive search bar at the top of the card so the Admin can highlight or search for a specific auditor's name.

**AP Drill-Down:**
The `ActionPlan` entity has `StoreId`, `StoreManagerName`, `CriteriaLabel`, `Deadline`, `CreatedAt`. The bucket boundaries (0-7d, 8-30d, 31-90d, 90d+) are computed from `CreatedAt`. A new thin endpoint `GET /ap/bucket/{bucket}` queries `ActionPlans` WHERE `Status = 'open'` AND age falls in bucket range. Returns list of `{ id, criteriaLabel, storeName, managerName, ageInDays }`. This is straightforward.
</latent_space_scratchpad>

---

## E2E Workflow Maps

### Case 1: MoM Variance (Client-Side Delta)
```
[trend[] in existing snapshot] — already has 12 months of data
    |
    v
[BodAnalyticsManager.computeMomDeltas()]
    reads trend[n].avgScore vs trend[n-1].avgScore
    emits: List<MomDeltaEntry> { month, score, deltaPercent, isPositive }
    |
    v
[BodKpiGrid widget] + [BodScoreTrend widget]
    adds delta pill chips: "+2.4% ↑" / "-1.1% ↓" next to each KPI card
    NO NEW API CALL NEEDED
```

### Case 2: Regional Filter Drill-Down
```
[User taps Province dropdown]
    |
    v
[BodAnalyticsManager._activeProvince = 'Hanoi']
    - State changes to Live Mode!
    - UI updates top header status badge: [ Nightly Snapshot ] ──► [ Live Dynamic Data ]
    - UI shows loading shimmer on all 6 cards
    |
    v
[GET /api/analytics/bod?province=Hanoi&district=null]
    - Server: re-runs 6 sub-queries with .Where(s => s.Store.Address2.Province == province)
    - Dynamically computes 12-month localized trend array for Hanoi
    - Returns filtered BodReportResponse containing localized KPIs + trend array
    |
    v
[BodAnalyticsManager._filteredReport = result]
    notifyListeners() → all 6 cards re-render with Hanoi's live metrics + trend line
    |
    v
[User taps District dropdown (cascading)]
    GET /api/analytics/bod?province=Hanoi&district=HoanKiem
    Same flow ──► deeper filter
```

### Case 3: Sync Telemetry (O(1) In-Place Column)
```
[Flutter sync engine calls POST /api/sync/submissions]
    |
    v
[Server: UPDATE Stores SET LastSyncedAt = NOW() WHERE Id = storeId]
    (Fast in-place write, no transaction-heavy logs, O(1) complexity)
    |
    v
[GetBodReportFiltered endpoint executes]
    - Joins Store table and projects LastSyncedAt directly into Leaderboard DTO rows
    - No secondary network request required!
    |
    v
[User taps store row in BodStoreLeaderboard]
    - BodStoreLeaderboard reads lastSyncedAt directly from the local list item DTO
    - Instantly launches detail sheet
    |
    v
[showModalBottomSheet]
    Displays: "Last synced: 10 mins ago. Status: Healthy"
```

### Case 4: AP Aging Drill-Down
```
[User taps '90d+' aging box in BodApAgingFunnel]
    |
    v
[GestureDetector.onTap → BodAnalyticsManager.loadApBucketDetail('90d+')]
    GET /api/analytics/bod/ap/bucket/90d+
    Query: ActionPlans WHERE status='open'
           AND (NOW() - created_at) > 90 days
    Returns: List<ApDetailEntry> { id, criteriaLabel, storeName, managerName, ageInDays }
    |
    v
[showModalBottomSheet with ListView]
    Shows scrollable list: "Store A — Manager B — Criteria X — 112 days overdue"
```

### Case 5: Auditor Productivity Filter (DM Teams Grouping)
```
[User taps date range picker / search bar in BodAuditorScatter]
    |
    v
[BodAnalyticsManager.loadAuditorProductivity(from, to, searchPhrase)]
    GET /api/analytics/auditors/productivity?from=2026-04-01&to=2026-05-24&search=John
    Live query: Submissions grouped by District Manager (DM) Teams by default
    - Highlighting search target points if searchPhrase is supplied
    |
    v
[BodAuditorScatter widget re-renders with DM points]
    Prevents "ink-blob overload" on massive lists while retaining searchable detail
```

---

## Comparative Decision Matrix

| Use Case | Option A: Snapshot Extend | Option B: Hybrid Live Query ✅ | Option C: Multi-Snapshot |
|---|---|---|---|
| MoM Variance | Recompute each snapshot | **Client-side from existing trend[]** | Add prev-month snapshot field |
| Regional Filter | Add N×M snapshots (storage explosion) | **New filtered GET endpoint (dynamic trend)** | Pre-generate per-province snapshots |
| Sync Telemetry | N/A — no existing data | **Store.LastSyncedAt column + updated DTOs** | N/A |
| AP Drill-Down | Embed AP lists in snapshot (size explosion) | **New thin AP endpoint** | N/A |
| Auditor Filter | Recompute at save time | **New live DM Grouped endpoint + search filter** | N/A |
| **Effort** | HIGH (rewrite calculator) | **MEDIUM (thin endpoints + EF column)** | HIGH (worker explosion) |
| **Risk** | Timeout under boardroom load | **Low — O(1) telemetry, grouped scatter** | Stale data risk |
| **VERDICT** | REJECT | **APPROVED** | REJECT |

---

## UI Component Routing Table

| Widget | Current State | New Interaction | Overflow / Route |
|---|---|---|---|
| `BodKpiGrid` | Static KPI tiles | Add MoM delta `PillChip` per KPI | Overflow: truncate delta to 1 decimal |
| `BodScoreTrend` | Static line chart | Highlight current vs prev month bar | No overflow risk |
| `BodStoreLeaderboard` | Static list rows | `onTap(storeId)` → sync detail modal | Modal: `showModalBottomSheet` |
| `BodApAgingFunnel` | Static boxes | `GestureDetector.onTap(bucket)` → AP detail modal | Modal list: max 50 rows, add scroll |
| `BodAuditorScatter` | Static scatter plot | Date range picker + active toggle | Picker: `showDateRangePicker` Material |
| `BodAnalyticsPage` | No filter bar | Add sticky `_RegionFilterBar` widget at top | Filter bar: Province → District → (All) |
| **NEW** `_StoreSyncModal` | N/A | Shows sync status per store | `showDialog` — no navigation |
| **NEW** `_ApBucketDetailSheet` | N/A | Shows AP list per aging bucket | `showModalBottomSheet` — scrollable |

---

## Strategy Assessment

### Blind Spots (3 Mandatory)

1. **Payload Size on Regional Filter**: Live-querying all 6 sub-queries for a filtered view may return large result sets when province = all stores in a major city. The new endpoint must apply `.Take(50)` limits on store lists and implement DB indexes on `address_province` and `address_district` columns (check migration first).

2. **Snapshot vs. Live Data Clock Skew**: Case 2 (regional filter) returns live data while the main dashboard shows the nightly snapshot. A store may appear in the top 5 on the snapshot but rank lower in the live view if scores changed today. The UI must transition a status badge from `[ Nightly Snapshot ]` to `[ Live Dynamic Data ]` to make this context clear and prevent executive confusion.

3. **LastSyncedAt Database Write Simplification**: Instead of a heavy `DeviceSyncLog` write-heavy telemetry table (generating high insert loads and query timeouts), Case 3 uses an in-place column `LastSyncedAt` on the `Store` table, updated during the sync process. This eliminates high-write table bloat and converts the leaderboard lookup into a standard, index-backed O(1) query, completely removing any risk of transactional lockups.

### Rules Conflicts (from GEMINI.md)

1. **GOTCHA: Pre-computed Snapshot Polling** — `BodAnalyticsManager.refreshReport()` already polls every 5 seconds for up to 60s. Adding new manager methods that make live API calls (Cases 2-5) will cause concurrent polling collisions if the user rapidly changes filters during a refresh cycle. **Fix**: Gate all drill-down commands with `if (_isLoading) return;` and cancel in-flight drill-down requests when a regional filter changes (use `CancelToken` on Dio).

2. **GOTCHA: OLAP Background Aggregations (Advisory Locking)** — The regional filter endpoint (Case 2) triggers 6 concurrent DB sub-queries per request. Multiple board members hitting the same endpoint simultaneously could cause query storms. **Fix**: Add a short-circuit cache (`IMemoryCache`, TTL=60s) keyed by `province+district` on the server side. The first request computes, subsequent requests hit cache.

---

## File Change Plan

### [MOD] Entities & Migration
| File | Change Type | Reason |
|---|---|---|
| `server/Common/Persistence/Entities/Store.cs` | **[MOD]** | Add `DateTime? LastSyncedAt` field for O(1) sync tracking |
| `server/Common/Persistence/Configurations/StoreConfiguration.cs` | **[MOD]** | Map `LastSyncedAt` column |
| `server/Common/Persistence/Migrations/AddStoreLastSyncedAt.cs` | **[NEW]** | DB migration adding `LastSyncedAt` column to stores table |

### [NEW] Server Endpoints
| File | Change Type | Reason |
|---|---|---|
| `server/Features/Analytics/GetBodReportFiltered.cs` | **[NEW]** | Case 2: Regional filter live query + localized trend + store lastSyncedAt |
| `server/Features/Analytics/GetApBucketDetail.cs` | **[NEW]** | Case 4: AP drill-down |
| `server/Features/Analytics/GetAuditorProductivity.cs` | **[NEW]** | Case 5: DM Grouped Auditor filter with search phrase & date range |
| `server/Features/Analytics/AnalyticsEndpoints.cs` | **[MOD]** | Wire 3 new GET routes (Store Sync is direct in leaderboard rows DTO) |
| `server/Features/Analytics/BodReportDtos.cs` | **[MOD]** | Add `ApDetailEntry`, `MomDeltaEntry`, `DmProductivityDto` |

### [MOD] Flutter — Manager & Models
| File | Change Type | Reason |
|---|---|---|
| `lib/features/analytics/manager/bod_analytics_data.dart` | **[MOD]** | Add typed models: `MomDeltaEntry`, `ApDetailEntry`, `DmProductivityEntry` |
| `lib/features/analytics/manager/bod_analytics_manager.dart` | **[MOD]** | Add filter state, live mode flag, 3 new Commands |
| `lib/features/analytics/services/bod_analytics_api_service.dart` | **[MOD]** | Add new API call methods |

### [MOD] Flutter — Widgets
| File | Change Type | Reason |
|---|---|---|
| `lib/features/analytics/pages/bod_analytics_page.dart` | **[MOD]** | Add `_RegionFilterBar` sticky widget & dynamic state badge transition |
| `lib/features/analytics/widgets/bod_kpi_grid.dart` | **[MOD]** | Case 1: Add MoM delta PillChip |
| `lib/features/analytics/widgets/bod_score_trend.dart` | **[MOD]** | Case 1: Highlight prev-month comparison |
| `lib/features/analytics/widgets/bod_store_leaderboard.dart` | **[MOD]** | Case 3: Add sync dot + onTap bottom sheet displaying sync delta |
| `lib/features/analytics/widgets/bod_ap_aging_funnel.dart` | **[MOD]** | Case 4: Add GestureDetector + onTap |
| `lib/features/analytics/widgets/bod_auditor_scatter.dart` | **[MOD]** | Case 5: Add date range + active toggle + search input + DM grouping |

### [NEW] Flutter — New Widgets
| File | Change Type | Reason |
|---|---|---|
| `lib/features/analytics/widgets/bod_region_filter_bar.dart` | **[NEW]** | Case 2: Cascading Province→District dropdowns |
| `lib/features/analytics/widgets/bod_store_sync_modal.dart` | **[NEW]** | Case 3: Sync detail modal (simple sheet) |
| `lib/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart` | **[NEW]** | Case 4: AP list bottom sheet |
| `lib/features/analytics/widgets/bod_mom_delta_chip.dart` | **[NEW]** | Case 1: Reusable +/-% delta pill |

---

<forensic_evidence>
## Forensic Evidence (Executed Commands)

### Audit 1 — Frontend page (265 lines confirmed)
```
view_file: lib/features/analytics/pages/bod_analytics_page.dart
Result: 265 lines. StatefulWidget. _manager.loadReport() in initState().
        6 static widget instances: card1-card6. No filter state. No tap callbacks.
```

### Audit 2 — Backend endpoint (62 lines confirmed)
```
view_file: server/Features/Analytics/GetBodReport.cs
Result: 62 lines. Returns raw jsonb blob from BodReportSnapshot table.
        No query parameters. No province/district filter logic.
        allowedActions computed dynamically from PBAC.
```

### Audit 3 — Calculator (418 lines, 6 sub-queries)
```
view_file: server/Features/Analytics/BodReportCalculator.cs
Result: 418 lines. 6 try/catch blocks for 6 queries.
        Query 3 (Stores): GroupBy(StoreId). No province filter.
        Query 5 (AP Aging): C# in-memory bucket calc — storeId not included.
        Query 6 (Auditors): No date range param. Fixed 30-day window.
```

### Audit 4 — Store entity (Province/District CONFIRMED)
```
view_file: server/Common/Persistence/Entities/StoreAddress.cs
Result: Province (required), District (nullable), Ward (nullable), Street (nullable).
view_file: server/Common/Persistence/Entities/Store.cs
Result: Address2? (StoreAddress owned entity). Submissions navigation exists.
```

### Audit 5 — Sync telemetry (CONFIRMED ABSENT)
```
grep_search: "SyncLog|SyncSession|LastSync|DeviceSync" in server/
Result: No results found.
grep_search: "SyncLog|SyncSession|last_synced|LastSynced" in server/Common/Persistence/Entities/
Result: No results found.
```

### Audit 6 — ActionPlan entity (drill-down fields confirmed)
```
view_file: server/Common/Persistence/Entities/ActionPlan.cs
Result: StoreId (Guid?), StoreManagerName (string?), CriteriaLabel (string),
        CreatedAt (DateTimeOffset), Deadline (DateTimeOffset?), Status (string).
        All fields needed for AP drill-down are present.
```

### Audit 7 — Flutter data model (WEAKLY TYPED confirmed)
```
view_file: lib/features/analytics/manager/bod_analytics_data.dart
Result: 41 lines. BodReportResponse uses Map<String, dynamic> for all fields.
        No typed models. apAging is Map<String,dynamic> not List<BodApAgingBucket>.
        This must be refactored to typed classes before adding interactivity.
```

### Audit 8 — AP Aging widget (no tap confirmed)
```
view_file: lib/features/analytics/widgets/bod_ap_aging_funnel.dart
Result: 127 lines. _buildAgingBox() returns a Container. No GestureDetector.
        apAging read via Map key lookups (wrong bucket key names vs server DTOs).
```

### Audit 9 — Store Leaderboard widget (no tap confirmed)
```
view_file: lib/features/analytics/widgets/bod_store_leaderboard.dart
Result: 128 lines. _buildStoreRow() returns Padding > Column. No InkWell/onTap.
        No sync status indicator. storeName/avgScore from dynamic Map.
```

### Audit 10 — Analytics endpoints (routes confirmed)
```
view_file: server/Features/Analytics/AnalyticsEndpoints.cs
Result: /api/analytics/bod (GET) and /api/analytics/bod/refresh (POST) only.
        4 new routes required for drill-down cases.
```
</forensic_evidence>

---

## @@SCAN — Step 3 Verification

✅ **(1) Alternatives evaluated?** YES — Option A (Snapshot Extend), B (Hybrid Live Query), C (Multi-Snapshot). **Winner: B.**

✅ **(2) 3 Blind spots cited?** YES — Payload Size, Clock Skew, DeviceSyncLog Write Volume.

✅ **(3) >1 Rules Conflict cited?** YES — (1) Concurrent polling collision with filter changes, (2) Query storm risk on regional filter endpoint.

---

## Handoff Block

### Final Verdict: **VIABLE ✅**
**Persistent Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\bod-analytics\research_20260524_193500_1eb2d30e_bod_analytics_boardroom_1eb2d30e.md`

### Effort Sizing: **Track C (Epic — 5 Vertical Slices)**
Each use case is an independent vertical slice. Recommended concurrency: 1 slice per Builder session in order below.

| Slice | Use Case | Effort | Backend Changes | Frontend Changes |
|---|---|---|---|---|
| S-1 | MoM Variance (Case 1) | S | None | `BodKpiGrid`, `BodScoreTrend`, `BodMomDeltaChip` |
| S-2 | Regional Filter (Case 2) | L | `GetBodReportFiltered.cs` | `BodRegionFilterBar`, manager state |
| S-3 | AP Drill-Down (Case 4) | M | `GetApBucketDetail.cs` | `BodApAgingFunnel` tap, `BodApBucketDetailSheet` |
| S-4 | Auditor Filter (Case 5) | M | `GetAuditorProductivity.cs` | `BodAuditorScatter` controls |
| S-5 | Sync Telemetry (Case 3) | XL | `DeviceSyncLog` entity+migration + `GetStoreSyncDetail.cs` + sync writer | `BodStoreLeaderboard` tap, `BodStoreSyncModal` |

**Start with S-1** (zero backend risk, pure client-side, validates MoM delta logic).
**S-5 last** (highest risk — new DB table, migration, write integration).

### AI Agent Mission Brief
The Checkly BoD Analytics Dashboard is a static OLAP snapshot that needs 5 interactive use cases added via **hybrid architecture: keep nightly snapshot for KPIs, add 4 thin live-query endpoints for drill-down**. The Flutter client uses PFA (ChangeNotifier + Commands). Start with S-1 (MoM delta chip, client-side only), then proceed slice by slice.

### Next Workflow Command
```
/implement {C:\Users\HP\Documents\GitHub\Checkly\docs\product\bod-analytics\research_20260524_193500_1eb2d30e_bod_analytics_boardroom_1eb2d30e.md}
```
Start with **Slice S-1 (MoM Variance)** — zero backend risk, validates the architecture pattern.
