<!--
<latent_space_scratchpad>
PROBLEM ANALYSIS:

ISSUE 1 — Aging Bucket Mismatch (HIGH):
- Server emits: "0-7d", "8-30d", "31-90d", "90d+" as {bucket, count} objects in a LIST
- `BodApAging.fromDynamic()` has list-parsing BUT maps by startsWith('0'), startsWith('31'), startsWith('61'), startsWith('90')
  - "8-30d" → starts with '8' → hits NONE of the if-branches → falls through as b0=0
  - "31-90d" → starts with '31' → maps to b31 (bucket31to60) ← WRONG name but correct index position
  - "61-90" → startsWith('61') handles it, but server never sends '61' prefix
  - So effectively: only "0-7d" and "90d+" map correctly; "8-30d" and "31-90d" do not map to anything meaningful
- The widget `bod_ap_aging_funnel.dart` reads from `apAging.toJson()` which returns:
  '0-30', '31-60', '61-90', '90+' keys — completely mismatched from server keys
- ALSO: bucket drill-down sends '0-30 Days', '31-60 Days', '61-90 Days', '90+ Days' to 
  `getApBucketDetail()` — manager normalizes these to '8-30d' etc. but the UI labels 
  are showing wrong names too
- The FULL fix: change Dart model to use server-matching fields + fix widget to use correct labels

ISSUE 2 — Missing KPIs (activeStores, totalAuditors) — MEDIUM:
- Server JSON: kpis.activeStores, kpis.totalAuditors  
- `BodChainKpis.fromJson()` reads json['totalAudits'], json['avgScore'], etc. — NO reads for activeStores/totalAuditors
- `BodKpiGrid` reads chainKpis as raw Map, but the map comes from `chainKpis.toJson()` which also doesn't include these
- Fix: add fields to `BodChainKpis`, update `fromJson` and `toJson`, then add 2 KPI cards to `BodKpiGrid`

ISSUE 3 — GoldenStore Dart model wrong (MEDIUM):
- Server sends: { storeName, avgScore, province } — no storeId
- Dart model reads: json['storeId'] → always empty string, json['storeName'], json['avgScore'] — drops province
- BodKpiGrid uses goldenStore.storeName and goldenStore.avgScore for the flagship subtitle — this works
- But storeId is wired to nothing (no tap on goldenStore), province is completely dropped
- Fix: remove storeId from Dart model, add province field instead

ISSUE 4 — Flagship Benchmark Subtitle — the "subtitle" is already implemented in bod_kpi_grid.dart!
- Line 76-87: if (goldenStore != null) shows the benchmark text
- The issue in the audit report was that there's no FORMAL field on kpis DTO for this
- But reading the actual widget: it uses goldenStore.storeName and goldenStore.avgScore directly
- This is FINE as-is — the goldenStore object IS the mechanism. The doc was unclear.
- However, because storeId is wrong and province is dropped, the display may be incomplete
- Fix is same as Issue 3 — fix GoldenStore model

SCOPE DECISION:
- Issues 1, 2, 3 need code changes
- Issue 4 is already implemented via goldenStore — it needs Issue 3 fix, not a separate fix
- CategoryTags (G1) = separate Epic, NOT in this plan

FILES TO TOUCH:
1. `lib/features/analytics/manager/bod_analytics_data.dart` — BodApAging + BodChainKpis + BodGoldenStore (3 classes)
2. `lib/features/analytics/widgets/bod_ap_aging_funnel.dart` — Update key reads + bucket labels
3. `lib/features/analytics/widgets/bod_kpi_grid.dart` — Add 2 new KPI tiles

FILE LINE COUNTS: 
- bod_analytics_data.dart: 348 lines → OVER 250 LINE THRESHOLD. Plan must NOT add more lines. 
  Consider splitting or just fixing/replacing existing classes.
- bod_ap_aging_funnel.dart: 192 lines ← fine
- bod_kpi_grid.dart: 238 lines ← fine

KEY CONSTRAINTS:
- MUST NOT break mock fallback in BodAnalyticsApiService (line 55-65)
- Mock data uses "0-30", "31-60", "61-90", "90+" — we must update mock data too
- BodKpiGrid receives chainKpis as Map<String,dynamic> (raw toJson) so new fields must appear in toJson()
- No DI changes needed — no new services
- No backend changes at all — server is correct
</latent_space_scratchpad>
-->

# Implementation Plan: BOD Analytics Flutter DTO Drift Fixes

**File**: `implementation_plan_20260527_163842_c3563378_bod-drift-fixes_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`  
**Date**: 2026-05-27 | **ShortID**: c3563378

---

## Input Lineage

- Compliance Audit: `C:\Users\HP\.gemini\antigravity\brain\c3563378-9cd7-4609-ae6d-2aba9f71c9ff\feature_compliance_audit.md`
- Requirements: `docs/product/requirements_20260527_155556_8f7d6e5c_bod_analytics_full_scope_v3.md`
- Server truth: `server/Features/Analytics/GetBodReport.cs` L320-326, L369-391

---

## Executive Summary & Out of Scope

**Goal**: Fix 3 Flutter-side DTO contract drift issues where the Flutter app misreads or drops server JSON data. The backend is correct and does not change.

**Fixes in scope:**
1. **AP Aging Bucket Mismatch** — Dart model and widget use wrong key names and wrong bucket split vs server.
2. **Missing KPIs** — `activeStores` and `totalAuditors` dropped in Dart model and not displayed in UI.
3. **GoldenStore Drift** — Dart model reads `storeId` (not in server response), drops `province` (is in server response).

**Explicitly OUT OF SCOPE:**
- `CategoryTags` DB migration — separate Epic.
- Any backend/API changes.
- Category Weaknesses card (no bug found).
- Flagship Benchmark subtitle logic (already implemented via `goldenStore` in KPI grid).

---

## System Context

- **Platform**: Flutter (Dart), offline-first.
- **API contract**: Backend sends JSON over `/api/analytics/bod`. Flutter deserializes it in `BodReportResponse.fromJson()`.
- **Mock fallback**: `BodAnalyticsApiService` has hardcoded fallback JSON when server is offline. Mock data uses wrong bucket names — **must also be updated**.
- **RBAC**: No capability checks needed — no new features, just data fixes.
- **No DI changes**: No new services or registrations needed.

---

## Lifecycle Context

| State | Handler |
|---|---|
| **Loading** | `BodAnalyticsManager._isLoading = true` → shimmer |
| **Success** | `BodReportResponse` deserialized → `BodDashboardBody` renders cards |
| **Error** | `_error` set → error card shown |
| **Empty** | `_isEmpty = true` → empty state shown |

The fixes only affect the **Success** state data binding. No lifecycle state changes needed.

---

## Constraint Traceability

| Constraint | Source | Test Contract ID |
|---|---|---|
| Server emits `"0-7d", "8-30d", "31-90d", "90d+"` as list of `{bucket, count}` | `GetBodReport.cs` L320-326 | TC-01 |
| Dart model must parse all 4 buckets correctly | Audit G3 | TC-01 |
| Funnel widget labels must match server bucket names | Audit G3 | TC-02 |
| Drill-down `bucketName` must match backend `/ap/{bucket}` path format | `BodAnalyticsManager.loadApDetails()` | TC-02 |
| Server sends `kpis.activeStores` and `kpis.totalAuditors` | `GetBodReport.cs` L379-380 | TC-03 |
| Dart `BodChainKpis.fromJson()` must read both fields | Audit G6 | TC-03 |
| UI must display `activeStores` and `totalAuditors` as KPI tiles | Audit G6 | TC-04 |
| Server `goldenStore` sends `{ storeName, avgScore, province }` — no `storeId` | `GetBodReport.cs` L176-181 | TC-05 |
| Dart `BodGoldenStore.fromJson()` must read `province` not `storeId` | Audit G4 | TC-05 |
| Mock fallback data must use correct bucket names so UI works offline | `BodAnalyticsApiService` L55-65 | TC-06 |

---

## Test Contracts

### TC-01: AP Aging Bucket Parsing
- **Input**: `[{"bucket":"0-7d","count":4},{"bucket":"8-30d","count":6},{"bucket":"31-90d","count":15},{"bucket":"90d+","count":12}]`
- **Expected**: `BodApAging(bucket0to7: 4, bucket8to30: 6, bucket31to90: 15, bucket90Plus: 12)`
- **Current Failure**: Only `bucket0to7` and `bucket90Plus` parse correctly. The other two map to zero.

### TC-02: Funnel Widget Labels and Drill-down Names
- **Expected labels**: `"0-7 Days"`, `"8-30 Days"`, `"31-90 Days"`, `"90+ Days"`
- **Expected drill-down names** passed to manager: `"0-7d"`, `"8-30d"`, `"31-90d"`, `"90d+"` (matching API path `/ap/{bucket}`)
- **Current Failure**: Labels show `"0-30 Days"`, `"31-60 Days"`, etc. and drill-down sends wrong names.

### TC-03: KPI Model Includes New Fields
- **Input JSON**: `{ "totalAudits": 125, "avgScore": 85.9, "activeStores": 10, "totalAuditors": 2, ... }`
- **Expected**: `BodChainKpis.activeStores == 10` and `BodChainKpis.totalAuditors == 2`
- **Current Failure**: Both fields are `null` / absent.

### TC-04: KPI Grid Displays New Tiles
- **Expected**: KPI grid card shows "Active Stores: 10" and "Total Auditors: 2" tiles.
- **Current Failure**: Tiles do not exist.

### TC-05: GoldenStore Reads Province
- **Input JSON**: `{ "storeName": "Store A", "avgScore": 91.5, "province": "Hanoi" }`
- **Expected**: `BodGoldenStore.storeName == "Store A"`, `BodGoldenStore.province == "Hanoi"`
- **Current Failure**: `province` is null. `storeId` is always empty string.

### TC-06: Mock Fallback Data Uses Correct Bucket Names
- **Expected**: Offline mock `actionPlanAging` uses `"0-7d"`, `"8-30d"`, `"31-90d"`, `"90d+"` keys.
- **Current Failure**: Mock uses wrong keys that don't match new parsing logic.

---

## Test Fixture & Payloads

**Server JSON shape (live mode) — source of truth:**
```json
{
  "kpis": {
    "totalAudits": 125,
    "avgScore": 85.9,
    "completionRate": 100.0,
    "openActionPlans": 37,
    "overdueActionPlans": 27,
    "activeStores": 10,
    "totalAuditors": 2,
    "avgTtrDays": 0.0
  },
  "goldenStore": {
    "storeName": "Checkly D1 - Nguyen Hue",
    "avgScore": 91.6,
    "province": "Ho Chi Minh City"
  },
  "actionPlanAging": [
    {"bucket": "0-7d",   "count": 4},
    {"bucket": "8-30d",  "count": 6},
    {"bucket": "31-90d", "count": 15},
    {"bucket": "90d+",   "count": 12}
  ]
}
```

---

## Tools & Commands

- **Skill**: None required (pure Flutter model + widget fix).
- **Test command**: `rtk flutter test test/features/analytics/ --reporter=expanded`
- **Lint check**: `rtk flutter analyze lib/features/analytics/`

---

## Proposed Changes

```
[MOD] lib/features/analytics/manager/bod_analytics_data.dart   ← Fix BodApAging, BodChainKpis, BodGoldenStore
[MOD] lib/features/analytics/services/bod_analytics_api_service.dart  ← Fix mock bucket names
[MOD] lib/features/analytics/widgets/bod_ap_aging_funnel.dart  ← Fix key reads + labels + drill-down names
[MOD] lib/features/analytics/widgets/bod_kpi_grid.dart         ← Add activeStores, totalAuditors tiles
```

> [!WARNING]
> `bod_analytics_data.dart` is **348 lines** — above the 250-line watch threshold. Do NOT add new classes here. Only modify existing ones. If field additions push it past 400 lines, the Builder must extract `BodApAging` and `BodGoldenStore` into a separate `bod_analytics_models.dart` file first.

---

## Concept Diagram

```
[Server JSON]
    │
    ├─ kpis.activeStores      → [MISSING] BodChainKpis.fromJson() reads it → BodKpiGrid tile
    ├─ kpis.totalAuditors     → [MISSING] BodChainKpis.fromJson() reads it → BodKpiGrid tile
    │
    ├─ goldenStore.province   → [DROPPED] BodGoldenStore.fromJson() reads it → (available for future use)
    ├─ goldenStore.storeId    → [DOES NOT EXIST] remove from Dart model
    │
    └─ actionPlanAging (list) → [WRONG PARSE] BodApAging.fromDynamic()
            "0-7d" count=4          Should map → bucket0to7 = 4
            "8-30d" count=6         Should map → bucket8to30 = 6
            "31-90d" count=15       Should map → bucket31to90 = 15
            "90d+" count=12         Should map → bucket90Plus = 12
                │
                ↓
        [BodApAging.toJson()] → widget reads these keys
                │
                ↓
        [BodApAgingFunnel] renders 4 boxes, tapping each sends
        bucketName → manager.loadApDetails("0-7d") → API /ap/0-7d
```

---

## Execution Slices

### Slice 1 — Fix Data Layer (Models + Mock Data)
**Summary**: Fix all 3 Dart model classes in `bod_analytics_data.dart` and update the mock fallback in `bod_analytics_api_service.dart`.

**Value**: All downstream widgets automatically receive correct data once models are correct.

**Entry State**: `bod_analytics_data.dart` exists with broken `BodApAging`, `BodChainKpis`, and `BodGoldenStore`.

**Exit State**: All 3 model classes parse server JSON correctly. Mock data uses correct bucket names. Flutter builds without errors. TC-01, TC-03, TC-05, TC-06 pass.

**Scope (2 files)**:

**File 1: `lib/features/analytics/manager/bod_analytics_data.dart`**

| Class | What to change |
|---|---|
| `BodApAging` | Rename fields: `bucket0to30` → `bucket0to7`, `bucket31to60` → `bucket8to30`, `bucket61to90` → `bucket31to90`. Fix `fromDynamic()` list parsing to match on `"0-7"`, `"8-30"`, `"31-90"`, `"90"`. Fix `toJson()` to use new key names. |
| `BodChainKpis` | Add `final int activeStores` and `final int totalAuditors` fields. Update constructor, `fromJson()` to read `json['activeStores']` and `json['totalAuditors']`, and `toJson()` to include them. |
| `BodGoldenStore` | Remove `storeId` field. Add `final String province`. Update constructor and `fromJson()`. |

**File 2: `lib/features/analytics/services/bod_analytics_api_service.dart`**

Update the hardcoded mock `actionPlanAging` array (lines 55-59) from:
```dart
{"bucket": "0-7d", "count": 4}, // CORRECT — keep
{"bucket": "8-30d", "count": 6}, // CORRECT — keep
{"bucket": "31-90d", "count": 15}, // CORRECT — keep
{"bucket": "90d+", "count": 12} // CORRECT — keep
```
> Actually the mock already uses `"0-7d"` etc. — the issue is that `BodApAging.fromDynamic()` misparses them. After fixing the model, verify mock still works.

**Acceptance Criteria:**
- `BodApAging.fromDynamic([{"bucket":"8-30d","count":6}])` → `bucket8to30 == 6`
- `BodChainKpis.fromJson({"activeStores": 10, "totalAuditors": 2})` → both fields non-zero
- `BodGoldenStore.fromJson({"storeName":"X","avgScore":91.5,"province":"Hanoi"})` → `province == "Hanoi"`
- `flutter analyze` passes

**Complexity**: Low.

---

### Slice 2 — Fix Funnel Widget Labels & Drill-down Names
**Summary**: Update `BodApAgingFunnel` to read new model field names and pass correct API-compatible bucket names to drill-down.

**Value**: Funnel boxes show correct counts from server. Tapping a bucket opens the correct detail sheet.

**Entry State**: Slice 1 complete. `BodApAging.toJson()` now returns `'0-7'`, `'8-30'`, `'31-90'`, `'90+'` keys (or whatever we standardize in Slice 1).

**Exit State**: Widget renders correct numbers. Labels show `"0-7 Days"`, `"8-30 Days"`, `"31-90 Days"`, `"90+ Days"`. Drill-down calls pass `"0-7d"`, `"8-30d"`, `"31-90d"`, `"90d+"` to manager. TC-02 passes.

**Scope (1 file)**:

**File: `lib/features/analytics/widgets/bod_ap_aging_funnel.dart`**

Lines 39-42: Replace key lookups from `apAging['0-30']` etc. to use the new model keys from `toJson()`:
```
age0to7   = apAging['0-7']  (maps to bucket0to7)
age8to30  = apAging['8-30'] (maps to bucket8to30)
age31to90 = apAging['31-90'](maps to bucket31to90)
ageOver   = apAging['90+']  (maps to bucket90Plus)
```

Lines 87, 101, 115, 129: Update the `onTap` bucket names passed to `_openBucketDetails`:
- `'0-30 Days'` → `'0-7d'`
- `'31-60 Days'` → `'8-30d'`
- `'61-90 Days'` → `'31-90d'`
- `'90+ Days'` → `'90d+'`

Lines 91, 105, 119, 133: Update the display label strings passed to `_buildAgingBox`:
- `'0-30 Days'` → `'0-7 Days'`
- `'31-60 Days'` → `'8-30 Days'`
- `'61-90 Days'` → `'31-90 Days'`
- `'90+ Days'` (keep same)

**Acceptance Criteria:**
- Funnel card shows 4 boxes with labels `0-7 Days`, `8-30 Days`, `31-90 Days`, `90+ Days`
- Tapping box sends correct name to `manager.loadApDetails()`
- `flutter analyze` passes

**Complexity**: Low.

---

### Slice 3 — Add Missing KPI Tiles to Grid
**Summary**: Add `Active Stores` and `Total Auditors` KPI tiles to `BodKpiGrid`.

**Value**: Executives can see store and auditor headcount on the main dashboard without drilling down.

**Entry State**: Slice 1 complete. `BodChainKpis.toJson()` now includes `activeStores` and `totalAuditors`.

**Exit State**: KPI grid shows 6 tiles (was 4). No layout overflows. TC-04 passes.

**Scope (1 file)**:

**File: `lib/features/analytics/widgets/bod_kpi_grid.dart`**

Lines 32-38: Add two new reads from the raw `chainKpis` map:
```dart
final activeStores = chainKpis['activeStores'] ?? 0;
final totalAuditors = chainKpis['totalAuditors'] ?? 0;
```

Add a third `Row` inside the `Column` at L64-145 with 2 new `_buildKpiCard` widgets:
- "Active Stores" → `'$activeStores'` — description: `'Number of stores with audit activity'`
- "Total Auditors" → `'$totalAuditors'` — description: `'Unique auditors active last 30 days'`

> [!IMPORTANT]
> Each row already uses `Expanded` widgets for equal sizing. The new row must follow the same pattern — wrap each new card in `Expanded`. Check that the full `Column` still renders without overflow on a 375px-wide device.

**Acceptance Criteria:**
- `BodKpiGrid` renders 3 rows of 2 KPI tiles (6 total)
- `activeStores` and `totalAuditors` show correct numeric values
- No `RenderFlex overflow` exceptions on narrow screen widths
- `flutter analyze` passes

**Complexity**: Low.

---

<command_logs>
- grep BodApAging lib/features/analytics/manager/bod_analytics_data.dart (via view_file L77-138)
- grep actionPlanAging server/Features/Analytics/GetBodReport.cs → L320-326: confirmed "0-7d","8-30d","31-90d","90d+"
- grep activeStores server → confirmed sent at L379
- view_file bod_ap_aging_funnel.dart → confirmed wrong keys L39-42, wrong labels L87-134
- view_file bod_kpi_grid.dart → confirmed no activeStores/totalAuditors tiles
- view_file bod_dashboard_body.dart → confirmed apAging passed as report.apAging.toJson()
- view_file GetBodReport.cs L176-181 → confirmed goldenStore has storeName/avgScore/province only
</command_logs>

---

## Handoff Block

**Absolute Plan Path**:  
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-drift-fixes\implementation_plan_20260527_163842_c3563378_bod-drift-fixes_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

**Execute ONE SLICE AT A TIME, in order. Do not start the next slice until the previous one builds and tests pass.**

| Slice | Route | Action |
|---|---|---|
| **Slice 1** (Models + Mock) | Route 1 — Direct Build | Build → `rtk flutter analyze lib/features/analytics/` |
| **Slice 2** (Funnel Widget) | Route 1 — Direct Build | Build → `rtk flutter analyze lib/features/analytics/` |
| **Slice 3** (KPI Tiles) | Route 1 — Direct Build | Build → `rtk flutter analyze lib/features/analytics/` |

All 3 slices are **Route 1 (Direct Build)** — pure UI/model fixes, no business logic, no network contract changes, no test-first required.

> [!NOTE]
> AI Decision: Skipped Route 3 (Acceptance Tests First) for all 3 slices because no server contract changes are made. The backend is already verified correct. These are pure Dart model parsing fixes.
