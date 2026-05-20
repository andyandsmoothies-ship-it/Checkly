# Research: Deprecate Area & Implement Structured Address for Vietnam

**ShortID**: `areadep` | **Date**: 2026-05-18 | **Agent**: Scout (Architect) | **Workflow**: `/research`

---

## [ORIGIN_IDEA]
The user's objective is to research the architectural feasibility of replacing the existing `Area`
entity—which currently acts as a geographical grouping mechanism—with a structured, Vietnam-specific
`Address` model (Province/City, District, Ward, Street) within the `Store` entity. The goal is to
perform a systematic audit of current dependencies to determine the impact, identify potential risks,
and outline a migration strategy that replaces unstructured strings with a formal, typed address
hierarchy while safely removing the `Area` dependency.

---

<latent_space_scratchpad>
DEBATE: Does Option B actually work given `AreaBenchmarkSnapshot` uses `AreaId` as its PRIMARY KEY?
- Yes, it IS a PK. This is a real blocker. The snapshot table's entire identity is `AreaId`.
  Deleting Area means this table must either (1) be dropped, (2) be redesigned around Province, or
  (3) be migrated to a new key. If Analytics depends on snapshots (confirmed: GetAnalytics.cs:227),
  removing Area without replacing benchmarks breaks the entire Insight/Radar feature.

DEBATE: Is `Profile.AreaId` still a runtime PBAC concern?
- YES. ReminderService.cs:240 contains `where p.AreaId == areaId && r.Role == "area_manager"`.
  This looks up the area manager by querying `Profile.AreaId`. If we remove this FK, the escalation
  notification finds NO area manager → silently fails to send any overdue escalation.
  This is a **live data integrity risk**, not just a code cleanup.

DEBATE: What replaces `GetAreaLeaderboard`?
- Area Leaderboard filters Stores by `s.AreaId == areaId`. If Area is removed, this entire endpoint
  becomes invalid. The natural replacement is `GET /api/analytics/province-leaderboard?province=HCM`.
  But this must be spec'd as a new feature before deletion.

DEBATE: What is the safest migration strategy for existing prod data?
- Flatten approach (Option A) is actually safer for migration because it avoids a complex EF
  owned-entity migration path. EF Core `ComplexProperty` (Option B) is cleaner DDD but generates
  more complex migration SQL and has known EF Core quirks (null column generation).
- CONCLUSION: Option B is the right long-term choice, but Option A is the safer first step if speed
  matters. We should go Option B with a two-phase migration:
  Phase 1: ADD Province/District/Ward/Street as nullable columns to Stores.
  Phase 2: Backfill data. Phase 3: Drop Area.

DEBATE: Does `ResourceAccessGuard.IsUserAreaAsync` (Common/ResourceAccessGuard.cs:42) survive?
- Partially. The `storeId` branch (line 46-50) uses `ProfileStoreAssignment` and does NOT use AreaId.
  The `areaId` branch (line 52-60) filters `Stores` by `s.AreaId`. When AreaId is removed from Store,
  this branch breaks at the database query level.
  IMPACT: If we remove Store.AreaId, we MUST also remove the `areaId` parameter from `ResourceScope`
  and delete the `areaId` branch from `IsUserAreaAsync`. The `scope.AreaId` path is currently only
  called from SyncSubmissions.cs:91 with a populated areaId. We must change SyncSubmissions too.
</latent_space_scratchpad>

---

## E2E Workflow Map

```
[Current Architecture]

[Flutter: AreaManagementPage /admin/areas]
  |-- GET /api/areas  (ListAreas.cs)
  |-- POST /api/areas (CreateArea.cs)
  |-- PUT /api/areas/{id} (UpdateArea.cs)
  |-- DELETE /api/areas/{id} (DeleteArea.cs)

[Flutter: StoreFormSheet]
  |-- areaId: _selectedAreaId → POST/PUT /api/stores

[Flutter: UserEditSheet]
  |-- areaId: selectedAreaId → PUT /api/admin/users/{id}

[Flutter: AnalyticsManager]
  |-- areaId (from store.areaId) → GET /api/analytics?areaId=...
  |-- GET /api/analytics/area-leaderboard?areaId=...

[Server: ResourceAccessGuard.IsUserAreaAsync]
  |-- scope.AreaId → db.Stores.Where(s.AreaId == areaId)  [USES AREA]
  |-- scope.StoreId → db.ProfileStoreAssignments           [DOES NOT use Area]

[Server: ReminderService.SendOverdueEscalations]
  |-- Store.AreaId → Profile.AreaId (AM lookup)            [USES AREA]

[Server: GetAnalytics]
  |-- Store.AreaId (resolvedAreaId) → AreaBenchmarkSnapshot [USES AREA]

[Server: GetAreaLeaderboard]
  |-- Store.AreaId == areaId                               [USES AREA]

[Server: SyncSubmissions.cs]
  |-- profile.AreaId → query Submissions by Store.AreaId  [USES AREA - dual-path]

[Database]
  |-- Table: areas (Guid PK, Name, Code, Description)
  |-- Table: stores  (Guid? AreaId FK → areas.Id)
  |-- Table: profiles (Guid? AreaId FK → areas.Id)
  |-- Table: area_benchmark_snapshots (Guid AreaId PK → areas.Id)

[Proposed Architecture: Post-Deprecation]

[Flutter: StoreFormSheet]
  |-- Province/District/Ward/Street inputs → POST/PUT /api/stores

[Flutter: UserEditSheet]
  |-- No Area field (AM assigned via VirtualAreaId/store list)

[Flutter: AnalyticsManager]
  |-- province filter → GET /api/analytics?province=HCM
  |-- GET /api/analytics/province-leaderboard?province=HCM (NEW ENDPOINT)

[Server: ResourceAccessGuard]
  |-- REMOVE: IsUserAreaAsync areaId branch
  |-- KEEP: storeId branch (ProfileStoreAssignment — already Province-agnostic)

[Server: ReminderService]
  |-- AM lookup: CHANGE to query ProfileStoreAssignments
                 (find AM assigned to the store, not via Profile.AreaId)

[Server: GetAnalytics]
  |-- Benchmark: REDESIGN AreaBenchmarkSnapshot → ProvinceBenchmarkSnapshot
                 (PK: Province string, not Guid)

[Database]
  |-- Table: stores: ADD Province, District, Ward, Street; DROP AreaId
  |-- Table: profiles: DROP AreaId
  |-- Table: areas: DROP
  |-- Table: area_benchmark_snapshots: DROP → replace with province_benchmark_snapshots
```

---

## Forensic Evidence

<forensic_evidence>

### Evidence 1: Area Entity (server/Common/Persistence/Entities/Area.cs:3-15)
```
Area { Id, Name, Code, Description, CreatedAt, UpdatedAt }
  Navigation: Stores[], Profiles[]
```
Area is a pure grouping bucket with a Name and optional Code. It has NO geographic coordinate data.

### Evidence 2: Store Entity (server/Common/Persistence/Entities/Store.cs:7-25)
```
Store { Id, Name, Address (string?), AreaId (Guid? FK), GpsLat, GpsLng, ... }
  Navigation: Area?, AssignedManagers (ProfileStoreAssignment[])
```
`Address` is a raw unstructured `string?`. `AreaId` is a nullable FK.

### Evidence 3: Profile Entity (server/Common/Persistence/Entities/Profile.cs:7-22)
```
Profile { Id, FullName, Email, AvatarUrl, StoreId (Guid?), AreaId (Guid?), ... }
  Navigation: Area?
```
`Profile.AreaId` is STILL used by `ReminderService.cs:240` to look up the Area Manager.

### Evidence 4: AreaBenchmarkSnapshot (server/Common/Persistence/Entities/AreaBenchmarkSnapshot.cs:7-19)
```
AreaBenchmarkSnapshot { AreaId (Guid PK), CategoryAverages (jsonb), OverallAvgScore, StdDeviation, ... }
  Navigation: Area?
```
`AreaId` is the PRIMARY KEY of this table. Dropping Area requires DROP+RECREATE of this entire table.

### Evidence 5: ResourceAccessGuard (server/Common/ResourceAccessGuard.cs:42-64)
- `IsUserAreaAsync`: if `storeId` provided → uses `ProfileStoreAssignment` (area-safe ✅)
- `IsUserAreaAsync`: if `areaId` provided → queries `Stores.Where(s.AreaId == areaId)` (❌ breaks)
- Called from `SyncSubmissions.cs:91` with both `StoreId` and `AreaId` from `profile.AreaId`

### Evidence 6: ReminderService (server/Common/Services/ReminderService.cs:219-240)
```csharp
(x, st) => new { x.AP, st.AreaId })    // Line 219: joins Store → gets AreaId
.Where(x => x.Notification == null && x.AreaId != null)  // Line 228: filters by AreaId
// Line 240: finds area manager via Profile.AreaId
where p.AreaId == areaId && r.Role == "area_manager"
```
This is a **HARD DEPENDENCY**. Overdue escalation notifications break if both `Store.AreaId`
and `Profile.AreaId` are removed without replacing this logic.

### Evidence 7: GetAnalytics (server/Features/Analytics/GetAnalytics.cs:100-106, 214-227)
```csharp
// Line 103: Filter by Area
.Where(st => st.AreaId == areaIdParsed)
// Line 220: Resolve benchmark area from store
resolvedAreaId = store?.AreaId;
// Line 227: Load benchmark snapshot
.FirstOrDefaultAsync(b => b.AreaId == resolvedAreaId.Value, ct);
```
If `Store.AreaId` is removed, Insight/Radar benchmark data can no longer be resolved.

### Evidence 8: GetAreaLeaderboard (server/Features/Analytics/GetAreaLeaderboard.cs:26)
```csharp
where s.AreaId == areaId
```
Entire endpoint requires `Store.AreaId`. No Province-based equivalent exists yet.

### Evidence 9: SyncSubmissions (server/Features/Submissions/SyncSubmissions.cs:72, 91, 112)
```csharp
areaId = profile.AreaId;  // Line 72: reads Profile.AreaId as fallback
query = query.Where(s => s.Store != null && s.Store.AreaId == areaId.Value);  // Line 112
```
SyncSubmissions has a dual-path: storeId → junction-based (safe) OR areaId → AreaId-based (❌).

### Evidence 10: Flutter Features (lib/features)
- `lib/features/admin/widgets/schedule_audit_form_logic.dart:13,23` — filters auditors by `areaId`
- `lib/features/admin/pages/widgets/store_form_sheet.dart:71` — reads `store.areaId`
- `lib/features/analytics/manager/analytics_manager.dart:68-70` — resolves `areaId` from store
- `lib/_shared/router/app_router.dart:221` — Route `/admin/areas`
- `lib/_shared/database/tables.dart:71` — Drift table has `areaId`, `areaName` columns
- `lib/_shared/services/sync_api_adapter.dart:98,106` — sends `areaId` param to sync endpoint

</forensic_evidence>

---

## Comparative Decision Matrix

| Option | Description | Pros | Cons | Verdict |
|--------|-------------|------|------|---------|
| **(A) Flatten into Store DB with OwnedEntity** | Use `builder.OwnsOne(s => s.Address)` to map a C# `Address` class to flat DB columns. Validate Provinces against a static `readonly string[]` array. | Clean DDD in C#, simple flat columns in DB. Avoids EF Core 8 `ComplexProperty` quirks. Prevents string fragmentation (e.g. HCM vs TP HCM). | Requires maintaining a static Province list on both Frontend and Backend. | **Winner – Recommended** |
| **(B) EF Complex Type (Value Object)** | Use EF Core 8 `ComplexProperty<Address>` inside `Store`. | Clean DDD. | EF Core complex type migrations can be tricky (nullable columns). | **Reject – Stick to standard OwnedEntities** |
| **(C) Standalone Location Service** | Create master tables for Province/District/Ward with IDs, linked via FK. | Highest data integrity. No free-text typos. | Massive migration. Overkill for current scale. | **Reject – Use static lists instead** |

**Recommendation: Option A using `builder.OwnsOne(s => s.Address)`. Pair this with a strict static taxonomy: hardcoded JSON/Dart dictionary for Frontend dropdowns and a static `readonly string[] ValidProvinces` in Backend for validation to prevent analytics string fragmentation.**

---

## UI Component Routing Table

| Component | Current Route | Area Dependency | Action on Deprecation |
|-----------|---------------|-----------------|----------------------|
| `AreaManagementPage` | `/admin/areas` | Full page + CRUD | **DELETE page + route** |
| `AreaCard` widget | (inside AreaManagementPage) | Renders area name, links to stores | **DELETE widget** |
| `StoreFormSheet` | `/admin/stores/create` | `_selectedAreaId` dropdown | **REPLACE: Area dropdown → Cascading static dropdowns for Province/District/Ward** |
| `UserEditSheet` | `/admin/users/edit` | `selectedAreaId` passed to `updateUser` | **REMOVE: Area field. AM assigned via store list only.** |
| `UserCreateSheet` | `/admin/users/create` | `areaId: null` (already dead) | **REMOVE: `areaId` param** |
| `ScheduleAuditFormLogic` | (inline widget) | `storeAreaId` for auditor filtering | **REPLACE: filter auditors by ProfileStoreAssignment** |
| `AnalyticsDashboard` | `/dashboard` | `areaId` param → benchmark lookup | **REPLACE: Province filter + Province-level benchmark** |
| `AdminStoreManager` | `/admin/stores` | `load(areaId: ...)` | **REPLACE: `load(province: ...)` or remove filter** |
| `SyncApiAdapter` | (sync endpoint call) | `areaId` query param | **REMOVE: param entirely** |
| `Drift tables.dart` | (local DB schema) | `areaId`, `areaName` columns on Stores table | **REMOVE columns, ADD Province/District/Ward/Street** |

---

## Blind Spots

1. **🔴 `ReminderService` Area Manager Lookup — Live Data Integrity Risk**
   `SendOverdueEscalations` (line 238-241) finds the Area Manager by querying `Profile.AreaId == store.AreaId`.
   If both FKs are removed, this query returns `Guid.Empty` and overdue escalation notifications
   are silently not sent. This is not a build error — it is a **silent runtime failure**. The
   replacement must query `ProfileStoreAssignments` to find AMs assigned to the overdue store's stores.

2. **🔴 `AreaBenchmarkSnapshot` Primary Key = `AreaId`**
   The Analytics Insight/Radar feature depends on looking up `AreaBenchmarkSnapshot` by `resolvedAreaId`
   (`GetAnalytics.cs:227`). This table's PK IS the AreaId. If Area is dropped, the entire benchmark
   infrastructure breaks. A `ProvinceBenchmarkSnapshot` table (PK: `Province string`) must be designed
   and the background `AreaBenchmarkCalculator` must be re-written to group by Province before Area
   can be dropped. This is a **non-trivial data infrastructure work item**.

3. **🟡 Historical Data Migration — The "Derive from Area" Fallback**
   The current `Store.Address` is an unstructured raw string. A backfill script to parse this into
   Province/District/Ward/Street fields is too complex.
   Instead, the migration MUST derive the new `Province` column from the store's current `Area.Name`
   (e.g., "Mekong Delta" or "Ho Chi Minh"). If an area doesn't perfectly match a province, map it to
   an "Uncategorized" province or closest parent. This guarantees that `ProvinceBenchmarkSnapshot` has
   data on Day 1 without needing an AI-powered address parser. The old `Address` string should be KEPT
   during the transition.

---

## Rules Conflicts

1. **Conflict with Gotcha: The 7 Sync Steps**
   Removing an entity is the INVERSE of the 7 Sync Steps and must proceed in REVERSE:
   (7→1) Delete capabilities seed, then Flutter DTOs, then Sync endpoints, then Endpoint projections,
   then Server DTOs, then DbContext, then Entity file. Missing any layer leaves orphaned code and
   breaks compilation.

2. **Conflict with Prune Unwired Code Rule**
   `Features/Areas/` (7 files: AreasEndpoints, CreateArea, DeleteArea, GetArea, ListAreas, UpdateArea, Dtos)
   must be **deleted, not commented out**. Leaving dead endpoint files violates the Prune rule.
   Additionally, `AreaManagementPage.dart`, `AreaCard.dart`, `AreaCampaignListPage.dart` in Flutter
   must be physically deleted.

3. **Conflict with Blast Radius Rule (Auth + Shared Infra)**
   `ResourceAccessGuard.cs` is in `Common/` — a **🔴 High Impact** file per the Impact Map.
   Any change to `IsUserAreaAsync` triggers the `[BLAST_RADIUS]` gate. The Builder MUST be warned
   that modifying this file breaks all role-based access control across the platform if done incorrectly.

---

## Effort Sizing

| Layer | Files Deleted | Files Modified | Files Added | Risk |
|-------|-------------|----------------|-------------|------|
| **Server: Entities** | `Area.cs`, `AreaBenchmarkSnapshot.cs` | `Store.cs`, `Profile.cs` | `ProvinceBenchmarkSnapshot.cs` | 🔴 High |
| **Server: DbContext / Config** | `AreaConfiguration.cs`, `AreaBenchmarkSnapshotConfiguration.cs` | `AppDbContext.cs`, `StoreConfiguration.cs`, `ProfileConfiguration.cs` | `ProvinceBenchmarkSnapshotConfiguration.cs` | 🔴 High |
| **Server: Features** | `Features/Areas/` (7 files), `GetAreaLeaderboard.cs` | `ResourceAccessGuard.cs`, `ResourceScope.cs`, `ReminderService.cs`, `SyncSubmissions.cs`, `GetAnalytics.cs`, `UpdateStore.cs`, `CreateStore.cs`, `ListStores.cs`, `GetStore.cs`, `UpdateUser.cs`, `ListUsers.cs`, `SearchUsers.cs` | `GetProvinceLeaderboard.cs` | 🔴 High |
| **Server: DB Migration** | (old migration files remain) | — | New migration: AddStructuredAddressDropArea | 🔴 High |
| **Flutter: Models** | — | `store_dto.dart`, `tables.dart` (Drift schema) | — | 🟡 Medium |
| **Flutter: Services** | — | `store_api_service.dart`, `sync_api_adapter.dart`, `admin_api_service.dart`, `analytics_api_service.dart` | — | 🟡 Medium |
| **Flutter: Managers** | — | `admin_store_manager.dart`, `admin_user_manager.dart`, `analytics_manager.dart`, `admin_audit_manager.dart` | — | 🟡 Medium |
| **Flutter: Pages/Widgets** | `area_management_page.dart`, `area_card.dart`, `area_campaign_list_page.dart` | `store_form_sheet.dart`, `user_edit_sheet.dart`, `user_create_sheet.dart`, `schedule_audit_form_logic.dart` | — | 🟡 Medium |
| **Flutter: Router** | — | `app_router.dart` (remove `/admin/areas` route) | — | 🟢 Safe |
| **Tests** | Area-specific test seeds in `SubmissionDelegationAuthTests`, `StoreAuthorizationTests`, `ProfileStoreAssignmentTests`, `OverdueEscalationTests` | Multiple test files | — | 🟡 Medium |
| **DB Migration Script** | — | — | Backfill SQL to populate Province from Area.Name | 🔴 High |

**Track: C (Epic-level). This is NOT a single-slice feature. It spans the full stack and requires a sequenced multi-slice approach.**

---

## Recommended Slice Sequence

```
SL-1: Add structured address fields to Store (no deletions yet)
  → Server: Configure Address using `builder.OwnsOne` + DB Migration.
  → DB Migration: MUST include a SQL script to backfill `Province` for existing stores by mapping from their current `Area.Name` (prevents blank dashboards in SL-2).
  → Server: Expose fields in DTOs and validate Province against static `string[] ValidProvinces`.
  → Flutter: Add Store DTO fields + StoreFormSheet cascading dropdowns (from static JSON).
  → Tests: Verify store CRUD with new fields

SL-2: Replace ProvinceBenchmarkSnapshot (unblock Analytics)
  → Server: Create ProvinceBenchmarkSnapshot entity (PK: Province string)
  → Server: Update GetAnalytics to use Province-level benchmark
  → Server: Replace GetAreaLeaderboard with GetProvinceLeaderboard
  → Tests: Analytics integration tests

SL-3: Migrate ReminderService AM Lookup off Profile.AreaId
  → Server: Change SendOverdueEscalations to resolve AM via ProfileStoreAssignment
  → Tests: OverdueEscalationTests

SL-4: Remove AreaId from ResourceScope + SyncSubmissions
  → Server: Remove areaId branch from IsUserAreaAsync
  → Server: Update SyncSubmissions dual-path fallback
  → Tests: SyncSubmissions + delegation tests

SL-5: Delete Area entity, table, and all orphaned code
  → Server: DROP Areas + AreaBenchmarkSnapshot + all Area endpoints (7 files)
  → Server: DROP Profile.AreaId + Store.AreaId columns (migration)
  → Flutter: DELETE area pages/widgets/routes + areaId DTO fields
  → Tests: Remove all Area seeding from integration tests
```

---

## Handoff Block

### 1. Final Verdict
**VIABLE — Option A (Flat DB columns via C# OwnedEntities `builder.OwnsOne`) paired with strict static taxonomy validation to prevent analytics fragmentation.**
- Research Artifact: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260518_172535_areadep_area_deprecation.md`

### 2. Effort Sizing & Concurrency
- **Track: C** (Epic — 5 vertical slices, must execute sequentially due to inter-slice DB dependencies)
- **Concurrency**: NONE. Slices must execute in order SL-1 → SL-5. Each slice has a DB migration gate.
- **Estimated Impact**: 🔴 High. Touches Auth infrastructure, Analytics, Notifications, and all platform sync.

### 3. AI Agent Mission Brief
Deprecate the `Area` entity across the full Checkly stack in 5 ordered slices, starting by adding
structured address fields (Province, District, Ward, Street) to `Store`, then rebuilding Analytics
benchmarks around Province, then migrating ReminderService AM lookup to `ProfileStoreAssignment`,
then cleaning `ResourceScope`/`SyncSubmissions`, and finally deleting all Area code and tables.

### 4. Next Workflow
```
/analyze-epic C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260518_172535_areadep_area_deprecation.md
```
