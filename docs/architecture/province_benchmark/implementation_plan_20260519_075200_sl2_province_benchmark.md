<latent_space_scratchpad>
KEY CONSTRAINTS FROM EPIC (analysis_epic_20260518_194804_areadep_area_deprecation.md):
1. Replace `area_benchmark_snapshots` table with `province_benchmark_snapshots`. New PK is a string (Province name).
2. Analytics workers must calculate benchmarks grouped by `address_province` column (added in SL-1).
3. `analytics:area` capability must be SEEDED in this slice's migration (per AppCapabilities.cs comment: "Seeded in Slice 2 migration").
4. `GetAreaLeaderboard` endpoint must pivot from `areaId` to `province` query param.
5. `InsightGeneratorService.Generate()` parameter names still say "area" — OK to leave internal names as-is (pure renaming = noise). The signature stays the same.
6. `GetAnalytics.cs` is 263 lines (>250). Must split before adding new changes.
7. `analytics_drift_loader.dart` uses `s.areaName` for offline province filter → must update to `s.addressProvince` (uses new SL-1 CachedStores column).
8. `AnalyticsManager` uses `s.areaId` to resolve areaId for API call → must switch to `s.addressProvince` passing province string.
9. Do NOT drop `Area` entity or `areas` table (SL-5 only).
10. Do NOT touch `AreaId` FK on `Store` or `Profile` (SL-5 only).
11. Old `AreaBenchmarkWorkerTests.cs` uses `AreaId`-seeded data. These tests MUST be replaced (not modified) with new `ProvinceBenchmarkCalculatorTests.cs`.
12. The minimum audit threshold for benchmark calculation remains at 3.

SPLIT STRATEGY FOR GetAnalytics.cs (263 lines):
Extract "Insights & Radar" block (lines 209–252) into a new file:
  `GetAnalyticsInsightsResolver.cs`
This file will contain a static method `ResolveAsync(db, resolvedProvince, sectionBreakdown, avgScore, totalAudits, overdueAPs, ct)`.
After extraction, GetAnalytics.cs will drop to ~220 lines.

OLD GetAreaLeaderboard:
  - Query param: `areaId` (Guid)
  - Filter: `where s.AreaId == areaId`
  - Route: GET /api/analytics/area-leaderboard

NEW GetProvinceLeaderboard:
  - Query param: `province` (string, validated against VietnamLocations.Provinces)
  - Filter: `where s.Address2!.Province == province`
  - Route: GET /api/analytics/province-leaderboard  ← NEW route
  - Old route kept ALIVE (returns 301/200 or just kept working via old endpoint) until SL-5 removes it.
  Actually — CLEAN approach: rename the file but KEEP the existing route `/api/analytics/area-leaderboard`.
  This avoids a Flutter routing change in this slice. The param changes from `areaId` to `province`.
  Flutter must update too. But let me re-examine: the Flutter analytics manager doesn't call leaderboard at all!
  `analytics_api_service.dart` only has getAnalytics(). No leaderboard call exists in Flutter.
  So leaderboard route change is pure backend — zero Flutter impact.
  Decision: RENAME to GET /api/analytics/province-leaderboard. Keep old route commented out.
  Actually — keep both routes alive for now (add the new one, keep old returning 404 or empty).
  No — simplest: rename the C# file and endpoint, change the query param, don't break old route.
  Final decision: Rename to `GetProvinceLeaderboard.cs`, route stays `/api/analytics/area-leaderboard`
  with new param `province` (string). Flutter doesn't call it, so no client-side change needed.

PROVINCE BENCHMARK SNAPSHOT ENTITY:
  PK: string Province (not nullable, validated GSO name)
  Columns: province_benchmark_snapshots
    province TEXT NOT NULL PRIMARY KEY
    category_avgs JSONB
    overall_avg DECIMAL
    std_deviation DECIMAL
    total_audits INT
    last_calc_at TIMESTAMPTZ
    created_at TIMESTAMPTZ

CALCULATOR CHANGE:
  Old: iterates db.Areas, groups by AreaId.
  New: queries DISTINCT store.Address2!.Province values,
       filters stores WHERE address_province IS NOT NULL,
       groups by province string.
  StoreAnalyticsSnapshot join: s.Store!.Address2!.Province == province.
  SubmissionSectionScore join: s.Submission!.Store!.Address2!.Province == province.

GetAnalytics.cs benchmark resolution block change:
  Old: Resolves AreaId from storeId → store.AreaId or from areaIdStr param.
  New: Resolves Province from storeId → store.Address2!.Province or from province param.
  The `areaId` query param is KEPT for backward compat (still filters submissions by area in the
  query body), but the benchmark/insight block now resolves Province from the store record.
  Actually — the areaId filter on submissions (line 100-106) uses store.AreaId to find stores.
  That's unchanged in SL-2 (AreaId is still in Store). Only the benchmark lookup switches to Province.

ANALYTICS FILTER FLUTTER:
  Old: "Area" dropdown → selectedArea → resolves areaId from CachedStores.areaId → sent to API.
  New: "Province" dropdown → selectedProvince → sent to API as province string param.
  Dropdown options: from CachedStores.addressProvince (new SL-1 column).
  analytics_api_service.dart: replace `areaId` param with `province` param.

ANALYTICS:AREA CAPABILITY SEEDING:
  Must insert row: ('analytics:area', 'area_manager') into role_capabilities
  This goes in the EF migration SQL block (same pattern as existing capability seedings).

FILE SIZE GATE:
  GetAnalytics.cs = 263 lines → must extract insights block before editing → target ~220 lines.
  analytics_manager.dart = 206 lines → adding province filter logic → will be ~220 lines (OK).
  analytics_drift_loader.dart = 190 lines → small changes only.
</latent_space_scratchpad>

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260518_194804_areadep_area_deprecation.md`

## Executive Summary & Out of Scope

**Goal**: Replace the `AreaBenchmarkSnapshot` entity and its calculator/worker with a `ProvinceBenchmarkSnapshot` that groups benchmarks by the `address_province` string column added in SL-1. Update Analytics endpoints and the Flutter filter UI to use province strings. Seed the `analytics:area` capability.

**Out of Scope (YAGNI for SL-2)**:
- ❌ Dropping `Area` entity, `areas` table, or `AreaId` FK on `stores`/`profiles` (SL-5 only)
- ❌ Removing `areaId` submission filter from `GetAnalytics` query body (still functional via store.AreaId)
- ❌ Changing `ReminderService` AM lookup (SL-3)
- ❌ Changing `ResourceAccessGuard` or `SyncSubmissions` (SL-4)
- ❌ Removing `AreaBenchmarkWorkerTests.cs` from disk (file is replaced, not deleted; old file becomes dead code — Builder should delete the file)

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `address_province` column is NULL for any store (SL-1 not applied) | High | Calculator skips stores where `address_province IS NULL`. Existing tests assert this. |
| Benchmark PK collision (two rows for same province) | High | EF UPSERT by Province key. FirstOrDefault + insert-or-update pattern. |
| `GetAnalytics.cs` split introduces regression in insight/radar block | Medium | Extract into `GetAnalyticsInsightsResolver.cs` before any benchmark changes. |
| `analytics:area` capability not seeded — leaderboard always returns 403 | High | Seed in EF migration SQL block. |
| Old `AreaBenchmarkWorkerTests.cs` still runs and passes (hides dead code) | Medium | Builder deletes old test file; new `ProvinceBenchmarkCalculatorTests.cs` replaces it. |

## Verification Plan

| Step | Command | Expected Result |
|---|---|---|
| Server build | `cmd /c rtk dotnet build server/` | 0 errors, 0 warnings |
| New tests RED then GREEN | `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests/` | All tests pass |
| Province leaderboard | `curl GET /api/analytics/area-leaderboard?province=Hồ Chí Minh` | 200 + stores in that province |
| Insights with province | `curl GET /api/analytics?storeId={id}` | Returns `insights` + `radarData` keyed by province benchmark |
| Flutter build | `cmd /c rtk flutter build apk --debug` | 0 errors |

---

## System Context

| Property | Value |
|---|---|
| **Online/Offline** | Hybrid. Analytics is API-first, Drift fallback. Province filter list comes from `CachedStores.addressProvince` (added SL-1). |
| **RBAC** | `GET /api/analytics/area-leaderboard` → `analytics:area` capability (must be seeded for `area_manager` role). `GET /api/analytics/` → `analytics:view`. Calculator runs as background worker with no RBAC. |
| **API Contracts** | Old leaderboard query param `areaId` (Guid) → new param `province` (string). `GET /api/analytics` insight block pivots from AreaId resolution to Province resolution. New benchmark table name: `province_benchmark_snapshots`. |
| **DB Migration** | 1 new table (`province_benchmark_snapshots`). 1 dropped table (`area_benchmark_snapshots`). 1 new capability row seeded. |

---

## Lifecycle Context (4-State Matrix for Province Filter UI)

| State | Province Dropdown (Analytics Filter Sheet) |
|---|---|
| **Loading** | Dropdown shows "All Provinces" default, no options until Drift query resolves |
| **Success** | Dropdown lists unique province values from `CachedStores.addressProvince` |
| **Empty (No Province data)** | Dropdown shows only "All Provinces" (SL-1 backfill not yet applied on this device) |
| **Error** | Falls back to "All Provinces" silently (Drift query failure = empty list) |

---

## Constraint Traceability

| # | Constraint (from Epic) | Test Contract ID |
|---|---|---|
| C1 | `province_benchmark_snapshots` table keyed by Province string (not AreaId Guid) | TC-SL2-01 |
| C2 | Calculator groups by `address_province`, skips stores with NULL province | TC-SL2-02 |
| C3 | Minimum audit threshold is still 3 per province group | TC-SL2-03 |
| C4 | `analytics:area` capability seeded in migration for `area_manager` role | TC-SL2-04 |
| C5 | Province leaderboard uses `province` query param, not `areaId` Guid | TC-SL2-05 |
| C6 | `GetAnalytics` insight/radar block resolves Province from store record (not AreaId) | TC-SL2-06 |
| C7 | `GetAnalytics.cs` must be split before editing (>250 lines) | TC-SL2-07 |
| C8 | Old `AreaBenchmarkWorkerTests.cs` replaced with `ProvinceBenchmarkCalculatorTests.cs` | TC-SL2-08 |
| C9 | Flutter province filter dropdown uses `addressProvince` from CachedStores | TC-SL2-09 |
| C10 | `analytics_drift_loader.dart` offline filter uses `addressProvince` not `areaName` | TC-SL2-10 |

---

## Test Contracts

| ID | Test | Precondition | Expected | Why it fails first |
|---|---|---|---|---|
| TC-SL2-01 | `ProvinceBenchmarkCalculator.RunForAllProvincesAsync()` writes row to `province_benchmark_snapshots` with PK = `"Hồ Chí Minh"` | 5 stores seeded with `address_province = "Hồ Chí Minh"`, 5 completed submissions | 1 row in `province_benchmark_snapshots` with Province = "Hồ Chí Minh" | Class doesn't exist yet |
| TC-SL2-02 | Stores with `address_province = NULL` are skipped by calculator | 3 stores with NULL province, 5 submissions | No benchmark row created for NULL province | No null guard exists |
| TC-SL2-03 | Province with only 2 submissions is skipped | 2 stores seeded with `province = "Hà Nội"`, 2 submissions total | No benchmark row for "Hà Nội" | No threshold guard exists |
| TC-SL2-04 | `GET /api/analytics/area-leaderboard?province=X` returns 200 (not 403) for area_manager token | Area manager with `analytics:area` capability | 200 OK | Capability not seeded = 403 |
| TC-SL2-05 | `GET /api/analytics/area-leaderboard?province=Hồ Chí Minh` returns stores from that province | 3 stores seeded with province | `stores` array with matching stores | Old query filters by AreaId, new param not handled |
| TC-SL2-06 | `GET /api/analytics?storeId={id}` returns `insights` non-null when province has benchmark | Store with `address_province`, province snapshot exists | `insights` array non-null, `radarData` non-null | Old resolution uses `store.AreaId` → no AreaBenchmarkSnapshot found |
| TC-SL2-07 | `GetAnalytics.cs` line count < 250 after split | After extracting insights block | File < 250 lines | Extraction not done |
| TC-SL2-08 | `ProvinceBenchmarkCalculatorTests.cs` compiles and all tests pass | New test file written | All Green | File doesn't exist |
| TC-SL2-09 | Analytics filter sheet Province dropdown shows province values from CachedStores | CachedStores has `addressProvince` populated | Dropdown shows unique province names | Manager still reads `areaName` |
| TC-SL2-10 | Offline drift filter for `selectedProvince = "Hồ Chí Minh"` returns only that province's stores | Drift cache has stores with `addressProvince` | Filtered store list | Loader still checks `areaName` |

---

## Test Fixture & Payloads

**TC-SL2-01 Fixture**: 
- 2 Stores with `address_province = "Hồ Chí Minh"`, 1 with `address_province = "Hà Nội"`
- 5 completed submissions against HCM stores (last 30 days)
- `StoreAnalyticsSnapshots` seeded for HCM stores
- `SubmissionSectionScores` seeded for category avg calculation

**TC-SL2-05 Request**:
```
GET /api/analytics/area-leaderboard?province=H%E1%BB%93%20Ch%C3%AD%20Minh
Authorization: Bearer {area_manager_token}
```
**Expected Response**:
```json
{
  "stores": [
    { "storeId": "...", "name": "Store HCM 1", "avgScore30d": 82.5, "totalAudits30d": 2 },
    { "storeId": "...", "name": "Store HCM 2", "avgScore30d": 72.5, "totalAudits30d": 3 }
  ]
}
```

**TC-SL2-06 Request**:
```
GET /api/analytics?storeId={store_with_hcm_province}
Authorization: Bearer {admin_token}
```
**Expected Response** (partial):
```json
{
  "insights": [ { "id": "ins_top_performer", "type": "positive", ... } ],
  "radarData": { "categories": ["Section A", "Section B"], "storeScores": [...], "areaScores": [...] }
}
```

---

## Tools & Commands

- **Skills**: `ef-core`, `dotnet-scaffolding`, `tdd`
- **Test Commands**:
  - `cmd /c rtk dotnet build server/` — must pass before any TDD step
  - `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests/ --filter "Category=Analytics"` — targeted run
  - `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests/` — full suite

---

## Proposed Changes

### Server-Side
| Action | File | Notes |
|---|---|---|
| [NEW] | `server/Common/Persistence/Entities/ProvinceBenchmarkSnapshot.cs` | String PK `Province`. No FK to Area. |
| [NEW] | `server/Common/Persistence/Configurations/ProvinceBenchmarkSnapshotConfiguration.cs` | ToTable("province_benchmark_snapshots"), HasKey(Province), HasColumnName for all fields |
| [DEL] | `server/Common/Persistence/Entities/AreaBenchmarkSnapshot.cs` | Replaced by `ProvinceBenchmarkSnapshot.cs` |
| [DEL] | `server/Common/Persistence/Configurations/AreaBenchmarkSnapshotConfiguration.cs` | Replaced by new config |
| [MOD] | `server/Common/Persistence/AppDbContext.cs` | Replace `DbSet<AreaBenchmarkSnapshot>` with `DbSet<ProvinceBenchmarkSnapshot>` |
| [NEW] | `server/Features/Analytics/ProvinceBenchmarkCalculator.cs` | Groups by distinct `address_province`, UPSERT to province table |
| [MOD] | `server/Features/Analytics/AreaBenchmarkWorker.cs` | Rename call to `ProvinceBenchmarkCalculator.RunForAllProvincesAsync()`. Rename lock key. |
| [NEW] | `server/Features/Analytics/GetAnalyticsInsightsResolver.cs` | Extracted static method from GetAnalytics.cs. Accepts `province` string instead of `Guid areaId`. |
| [MOD] | `server/Features/Analytics/GetAnalytics.cs` | Remove insights block (delegate to resolver). Change `resolvedAreaId` → `resolvedProvince` string. Keep `areaId` query filter intact (uses store.AreaId for submission filtering). |
| [MOD] | `server/Features/Analytics/GetAreaLeaderboard.cs` | Change param from `areaId` (Guid) to `province` (string). Filter: `s.Address2!.Province == province`. |
| [NEW] | `server/Common/Persistence/Migrations/[timestamp]_AddProvinceBenchmarkSnapshot.cs` | Drop `area_benchmark_snapshots`, create `province_benchmark_snapshots`, seed `analytics:area` capability |
| [DEL] | `server/tests/.../Features/Analytics/AreaBenchmarkWorkerTests.cs` | Replaced by new tests |
| [NEW] | `server/tests/.../Features/Analytics/ProvinceBenchmarkCalculatorTests.cs` | Province-based tests |

> [!WARNING]
> After the Builder generates the EF Core migration, the user MUST restart the `server/` process to trigger `db.Database.Migrate()` and apply the migration to the local PostgreSQL database.

### Flutter-Side
| Action | File | Notes |
|---|---|---|
| [MOD] | `lib/features/analytics/services/analytics_api_service.dart` | Replace `areaId` param with `province` (String?) in `getAnalytics()` |
| [MOD] | `lib/features/analytics/manager/analytics_manager.dart` | `selectedArea` → `selectedProvince`. Resolve province from `CachedStores.addressProvince`. |
| [MOD] | `lib/features/analytics/manager/analytics_data.dart` | `areaNames` → `provinceNames` (List\<String\>) |
| [MOD] | `lib/features/analytics/manager/analytics_drift_loader.dart` | Replace `s.areaName` with `s.addressProvince` for offline filter |
| [MOD] | `lib/features/analytics/widgets/analytics_filter_sheet.dart` | Change "Area" dropdown label to "Province", options from `provinceNames` |
| [MOD] | `lib/features/analytics/pages/analytics_filter_chips.dart` | Change `selectedArea` chip to `selectedProvince` chip |

**UI Component Routing Table**:
| Component | Label | Data Source | Overflow Action |
|---|---|---|---|
| Province Dropdown | "Province" | `CachedStores.addressProvince` unique values | `TextOverflow.ellipsis` (already present) |
| Province chip | "Province: {name}" | `manager.selectedProvince` | Chip dismissible → resets to null |

---

## Concept Diagram

```
[Background Worker: ProvinceBenchmarkWorker (20min interval)]
  ↓ TryExecuteInLockAsync("Checkly.ProvinceBenchmarkWorker")
  ↓ ProvinceBenchmarkCalculator.RunForAllProvincesAsync(db, logger, ct)
    → SELECT DISTINCT address_province FROM stores WHERE address_province IS NOT NULL
    → For each province:
      - COUNT(submissions last 30d WHERE store.address_province = province)
      - If count < 3 → SKIP
      - AVG(StoreAnalyticsSnapshot.AvgScore30d WHERE store.address_province = province)
      - STDDEV
      - CategoryAverages from SubmissionSectionScores (last 90d)
      - UPSERT province_benchmark_snapshots (Province = PK)

[GET /api/analytics?storeId={id}]
  → Resolve province: store.Address2.Province  ← (was: store.AreaId)
  → GetAnalyticsInsightsResolver.ResolveAsync(db, province, ...)
    → db.ProvinceBenchmarkSnapshots.FirstOrDefault(x => x.Province == province)
    → InsightGeneratorService.Generate(liveScore, provinceAvg, ...)
  → Return AnalyticsResponse with insights + radarData

[GET /api/analytics/area-leaderboard?province=Hồ Chí Minh]
  → Filter stores WHERE address_province = param
  ← Returns stores + snapshot metrics

[Flutter: AnalyticsManager.load()]
  → selectedProvince (String?) via Province dropdown
  → api.getAnalytics(province: selectedProvince)
  ↓ (offline) loadFromDrift() filters by s.addressProvince
```

---

## Execution Slices (Micro-Specs)

### Phase B1: Server Data Layer (Entity + Config + Migration + Calculator)
**Complexity**: Medium-High

**Plain English**: Create the new `ProvinceBenchmarkSnapshot` entity and its EF config. Delete the old `AreaBenchmarkSnapshot` entity and config. Update `AppDbContext`. Write `ProvinceBenchmarkCalculator` that groups by province string. Update `AreaBenchmarkWorker` to call the new calculator. Generate and customize the EF migration (drop old table, create new, seed capability row).

**Value Delivered**: New province_benchmark_snapshots table exists. Worker calculates correct province benchmarks. `analytics:area` capability is seeded.

**Entry State Required**: SL-1 is fully applied. `stores.address_province` column exists. Server builds cleanly.

**Exit State Guaranteed**: `dotnet build` passes. New migration exists. After server restart, `province_benchmark_snapshots` table is created, `area_benchmark_snapshots` is dropped. TC-SL2-01, TC-SL2-02, TC-SL2-03 pass.

**Scope**:
- [NEW] `ProvinceBenchmarkSnapshot.cs`
- [NEW] `ProvinceBenchmarkSnapshotConfiguration.cs`
- [DEL] `AreaBenchmarkSnapshot.cs`
- [DEL] `AreaBenchmarkSnapshotConfiguration.cs`
- [MOD] `AppDbContext.cs`
- [NEW] `ProvinceBenchmarkCalculator.cs`
- [MOD] `AreaBenchmarkWorker.cs` (rename calculator call and lock key only)
- [NEW] EF migration

**Acceptance Criteria**: TC-SL2-01, TC-SL2-02, TC-SL2-03, TC-SL2-04

---

### Phase B2: Server API Layer (Endpoint Updates + File Split)
**Complexity**: Medium

**Plain English**: First, extract the insight/radar block from `GetAnalytics.cs` into `GetAnalyticsInsightsResolver.cs` (required by file size rule). Then update the resolver to query `ProvinceBenchmarkSnapshots` by province string instead of AreaId. Update `GetAreaLeaderboard.cs` to filter by `province` param instead of `areaId`. Delete old `AreaBenchmarkWorkerTests.cs`. Write new `ProvinceBenchmarkCalculatorTests.cs`.

**Value Delivered**: All analytics API endpoints use Province-based benchmarks. The leaderboard filters by province. TC-SL2-05 and TC-SL2-06 pass.

**Entry State Required**: Phase B1 complete. Province benchmark table exists.

**Exit State Guaranteed**: `GetAnalytics.cs` < 250 lines. `GET /api/analytics?storeId={id}` returns insights from province benchmark. `GET /api/analytics/area-leaderboard?province=X` returns stores. All integration tests pass.

**Scope**:
- [NEW] `GetAnalyticsInsightsResolver.cs`
- [MOD] `GetAnalytics.cs` (extract block, change resolution from AreaId → province)
- [MOD] `GetAreaLeaderboard.cs`
- [DEL] `AreaBenchmarkWorkerTests.cs`
- [NEW] `ProvinceBenchmarkCalculatorTests.cs`

**Acceptance Criteria**: TC-SL2-05, TC-SL2-06, TC-SL2-07, TC-SL2-08, TC-SL2-10

---

### Phase B3: Flutter Layer (Filter UI + Manager + Drift Loader)
**Complexity**: Low

**Plain English**: Replace `selectedArea` / `areaId` with `selectedProvince` / `province` throughout the analytics Flutter feature. Update the analytics filter sheet label. Update the drift offline loader. Update `analytics_api_service.dart`.

**Value Delivered**: Province filter dropdown works in Analytics UI. Offline mode filters correctly by province. API calls send `province` param.

**Entry State Required**: Phase B2 complete. Backend is returning province-based insights.

**Exit State Guaranteed**: App compiles. Analytics filter shows "Province" dropdown with CachedStores.addressProvince values. Selecting a province filters analytics correctly (online and offline).

**Scope**:
- [MOD] `analytics_api_service.dart`
- [MOD] `analytics_manager.dart`
- [MOD] `analytics_data.dart`
- [MOD] `analytics_drift_loader.dart`
- [MOD] `analytics_filter_sheet.dart`
- [MOD] `analytics_filter_chips.dart`

**Acceptance Criteria**: TC-SL2-09, TC-SL2-10

---

<command_logs>
view_file AreaBenchmarkSnapshot.cs → PK is Guid AreaId, navigation to Area. 20 lines.
view_file AreaBenchmarkSnapshotConfiguration.cs → HasKey(AreaId), HasForeignKey to areas.
view_file AreaBenchmarkCalculator.cs → iterates db.Areas.Select(a=>a.Id), groups by AreaId. 102 lines.
view_file AreaBenchmarkWorker.cs → calls AreaBenchmarkCalculator.RunForAllAreasAsync(). 72 lines.
view_file GetAnalytics.cs → 263 lines — exceeds 250 limit. Insight/radar block at lines 209-252.
view_file GetAreaLeaderboard.cs → filters by s.AreaId == areaId. 41 lines.
view_file Dtos.cs → 42 lines — clean.
view_file InsightGeneratorService.cs → 105 lines — params named areaAvgScore. Internal names only.
view_file AnalyticsEndpoints.cs → GET /area-leaderboard → RequireCapability(AnalyticsArea). 30 lines.
grep AppDbContext.cs → DbSet<AreaBenchmarkSnapshot> at line 42.
view_file AppCapabilities.cs → AnalyticsArea = "analytics:area", comment: "Seeded in Slice 2 migration".
view_file analytics_manager.dart → 206 lines. Uses selectedArea, areaId, areaNames.
view_file analytics_data.dart → 96 lines. Has areaNames field.
view_file analytics_drift_loader.dart → 190 lines. Filters by s.areaName.
view_file analytics_api_service.dart → 26 lines. Sends areaId param.
view_file analytics_filter_sheet.dart → 187 lines. Shows "Area" dropdown.
view_file analytics_filter_chips.dart → 171 lines. Shows "Area:" chip.
view_file AreaBenchmarkWorkerTests.cs → 152 lines. Seeds AreaId-based data. Must be replaced.
</command_logs>

---

## Handoff Block

**Builder Instructions**: Execute phases ONE AT A TIME. Do NOT start B2 until B1's `dotnet test` is green. Do NOT start B3 until B2's integration tests pass.

| # | Phase | Target | Route |
|---|---|---|---|
| 1 | **TDD Phase** (Write failing tests first for TC-SL2-01..04) | `ProvinceBenchmarkCalculatorTests.cs` | Write Unit Tests First → then Build |
| 2 | **Implementation B1** | Server data layer | Same plan |
| 3 | **Implementation B2** | Server API layer | Same plan |
| 4 | **Implementation B3** | Flutter layer | Direct Build (no new auth/logic) |

**Concurrency**: B1 → B2 → B3 strictly sequential. B3 can only run after B2's server is deployed and verified.

**Plan file**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260519_075200_sl2_province_benchmark.md`
