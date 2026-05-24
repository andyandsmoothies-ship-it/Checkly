## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| EF migration fails to apply (ghost column) | High | `db.Database.Migrate()` in `Program.cs` handles auto-apply on restart. Builder MUST warn user to restart. |
| Province free-text entry causes analytics fragmentation | High | Server validates Province against `VietnamLocations.Provinces` static list. Returns 400 on mismatch. |
| `store_form_sheet.dart` exceeds 400 lines | Medium | Map widget extracted to `StoreLocationMapWidget` as Phase B3 first step. |
| Drift schema migration breaks offline cache on app upgrade | Medium | New columns are all nullable. Drift auto-migrates if schema version is bumped. |
| Backfill SQL runs on prod data incorrectly | Low | Backfill is additive-only (UPDATE not DELETE). Stores without Area fallback to "Uncategorized". |

## Verification Plan

| Step | Command | Expected Result |
|---|---|---|
| Server build | `cmd /c rtk dotnet build server/` | 0 errors, 0 warnings |
| Migration generated | `cmd /c rtk dotnet ef migrations list` | New migration appears in list |
| Integration tests | `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests/` | All existing tests pass |
| Reference endpoint | `curl GET /api/reference/locations` | 200 + 63 province strings |
| Province validation | `curl POST /api/stores { province: "Fake" }` | 400 Bad Request |
| Flutter build | `cmd /c rtk flutter build apk --debug` | No compile errors |

---

<latent_space_scratchpad>
KEY CONSTRAINTS FROM EPIC:
1. Use `builder.OwnsOne` (NOT ComplexProperty). Explicit HasColumnName for all 4 fields.
2. Province must be validated against a static allow-list (prevent free-text fragmentation in analytics).
3. DB migration MUST backfill `Province` from the store's current `Area.Name`.
4. Keep the old `Address` string as-is (do NOT remove it this slice). Additive only.
5. Keep `AreaId` as-is (do NOT remove it this slice). Additive only.
6. `store_form_sheet.dart` is 378 lines → must be split before adding new fields (File Size Rule).
7. The `GET /api/reference/locations` endpoint must serve the Province hierarchy (Province > District).
   It must be accessible to any authenticated user (no specific capability needed — it's reference data).
8. CachedStores Drift table needs 4 new nullable columns. This triggers a Drift schema migration.
9. SL-1 does NOT delete `areaId`/`areaName` from CachedStores yet — additive only.
10. Per Persistence GEMINI.md: after migration, user must restart server to trigger auto-apply.

PROVINCE DATA:
Vietnam has 63 administrative provinces/cities. Using official GSO names.
Backend: `VietnamLocations.Provinces` static readonly string[] constant.
API: GET /api/reference/locations → returns list of province names.
Phase 2 (district/ward) is out of scope for SL-1 — ward data is very large (~11,000 entries).
SL-1 adds Province only with a free-text District/Ward for simplicity.
Reason: cascading Province→District→Ward data for all 63 provinces = 700+ districts.
This is a future scope item. SL-1 delivers Province dropdown + free-text District/Ward/Street.

OWNED ENTITY COLUMN NAMES:
Province → "address_province"
District → "address_district"
Ward     → "address_ward"
Street   → "address_street"

FILE SPLIT DECISION:
store_form_sheet.dart (378 lines) must be split before adding ~80 more lines.
Split: extract map widget logic into a separate `StoreLocationMapWidget` stateless widget file.
This reduces store_form_sheet.dart to ~280 lines.

BACKFILL SQL:
UPDATE stores SET address_province = a.name
FROM areas a WHERE stores.area_id = a.id;
-- fallback for stores with no area:
UPDATE stores SET address_province = 'Uncategorized'
WHERE address_province IS NULL;

This runs INSIDE the EF migration's Sql() call. The migration must run BEFORE any analytics depend
on Province, so it is safe to do this here with a nullable column.
</latent_space_scratchpad>

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260518_194804_areadep_area_deprecation.md`

## Executive Summary & Out of Scope

**Goal**: Additive-only slice. Add structured address fields to `Store` (Province, District, Ward, Street) via an EF Core OwnedEntity. Add a reference endpoint for Province data. Update Store create/edit UI to capture Province. Run DB migration with SQL backfill. No deletions in this slice.

**Out of Scope (YAGNI for SL-1)**:
- ❌ Removing `AreaId` or `area_id` from `Store`, `Profile`, or Drift (SL-5 only)
- ❌ Removing `areaName` from `CachedStores` (additive only)
- ❌ Updating Analytics, ReminderService, or ResourceAccessGuard (SL-2/3/4)
- ❌ Full Province→District→Ward cascading hierarchy with 700+ districts (too large for SL-1; District/Ward remain free-text)
- ❌ Deleting `Area` entity, table, or any `Areas` feature files (SL-5 only)
- ❌ Updating `ListStores` `areaId` filter param (not touched this slice)

---

## System Context

| Property | Value |
|---|---|
| **Online/Offline** | Offline-first. `CachedStores` Drift table must be updated in sync with backend schema change. |
| **RBAC** | `GET /api/reference/locations` — any authenticated user. `POST/PUT /api/stores` — requires `stores:write` capability (existing). |
| **API Contracts** | Three server endpoints updated: `CreateStore`, `UpdateStore`, `GetStore`. One new endpoint added: `GET /api/reference/locations`. `ListStores` response DTO updated to include new address fields. |
| **Logs** | Backfill SQL must log unmapped Area names (Stores where `Area.Name` could not be used). |
| **DB Gotcha** | Per `Persistence/GEMINI.md`: EF auto-applies migrations on server restart in Development. Builder MUST emit a WARNING to user to restart after migration. |

---

## Lifecycle Context (4-State Matrix for Store Form UI)

| State | Province Field | District/Ward/Street |
|---|---|---|
| **Loading** | Dropdown shows "Loading provinces…" shimmer | Free-text fields disabled |
| **Success (Create)** | Dropdown selectable, no initial value | Free-text fields enabled |
| **Success (Edit)** | Dropdown shows existing Province value | Free-text fields pre-populated |
| **Error** | Province fetch fails → fallback hardcoded list shown | Fields remain enabled |

---

## Constraint Traceability

| # | Constraint (from Epic) | Test Contract ID |
|---|---|---|
| C1 | OwnedEntity with explicit HasColumnName (not ComplexProperty) | TC-SL1-01 |
| C2 | Province validated against static allow-list (no free-text fragmentation) | TC-SL1-02 |
| C3 | DB migration MUST backfill Province from Area.Name | TC-SL1-03 |
| C4 | Old `Address` string and `AreaId` are NOT deleted this slice | TC-SL1-04 |
| C5 | GET /api/reference/locations returns valid province list | TC-SL1-05 |
| C6 | store_form_sheet.dart must be split before exceeding 400 lines | TC-SL1-06 |
| C7 | CachedStores Drift table gains 4 new nullable columns | TC-SL1-07 |
| C8 | StoreDto (server + Flutter) exposes new address fields | TC-SL1-08 |
| C9 | Stores with no Area.Name fallback to "Uncategorized" in backfill | TC-SL1-09 |
| C10 | New migration must not break existing Store CRUD integration tests | TC-SL1-10 |

---

## Test Contracts

| ID | Test | Precondition | Expected | Why it fails first |
|---|---|---|---|---|
| TC-SL1-01 | EF migration generates columns `address_province`, `address_district`, `address_ward`, `address_street` (not `Address_Province`) | Fresh test DB migration applied | Column names are snake_case in `stores` table | Configuration missing `HasColumnName` |
| TC-SL1-02 | `POST /api/stores` with `province: "NotARealPlace"` returns `400 Bad Request` | Admin token | 400 + error message "Invalid province" | No validation exists yet |
| TC-SL1-03 | After migration, stores previously assigned to an Area have `address_province` set to that Area's name | DB seeded with stores with `area_id` | `address_province` is NOT null for seeded stores | Backfill SQL not added to migration |
| TC-SL1-04 | `GET /api/stores/{id}` still returns `areaId` and `address` fields | Existing store | Both legacy AND new fields present | Breaking change if DTO dropped old fields |
| TC-SL1-05 | `GET /api/reference/locations` returns JSON array with 63 items including `"Hồ Chí Minh"` | Authenticated user | 200 + JSON array of province strings | Endpoint doesn't exist yet |
| TC-SL1-06 | `store_form_sheet.dart` line count < 400 after changes | Map widget extracted | File < 400 lines | File already at 378 before new fields |
| TC-SL1-07 | Drift migration succeeds after schema version bump in `CachedStores` | App cold start after update | Local DB migrates cleanly | Schema version not bumped |
| TC-SL1-08 | `POST /api/stores` with address fields returns them in response | Admin token, valid Province | 201 + `addressProvince`, `addressDistrict`, etc. in response | DTO not updated |
| TC-SL1-09 | Stores with NULL `area_id` after backfill have `address_province = 'Uncategorized'` | Store with null area_id | `address_province` = `'Uncategorized'` | Fallback UPDATE not in migration |
| TC-SL1-10 | Existing `dotnet test` suite passes after migration is applied | Clean test DB | All existing tests green | Additive migration breaks compile/runtime |

---

## Test Fixture & Payloads

**Required Fixture State**: Admin client, 2 seeded Stores — one with `AreaId` set, one with `AreaId = null`.

**TC-SL1-02 Request (bad province)**:
```json
POST /api/stores
{ "name": "Test Store", "province": "NotARealPlace" }
```
**Expected Response**: `400 Bad Request`
```json
{ "error": "Province 'NotARealPlace' is not a valid Vietnam administrative province." }
```

**TC-SL1-08 Request (happy path)**:
```json
POST /api/stores
{
  "name": "Cửa hàng HCM",
  "province": "Hồ Chí Minh",
  "district": "Quận 1",
  "ward": "Phường Bến Nghé",
  "street": "123 Nguyễn Huệ"
}
```
**Expected Response**: `201 Created`
```json
{
  "id": "...",
  "name": "Cửa hàng HCM",
  "address": null,
  "areaId": null,
  "addressProvince": "Hồ Chí Minh",
  "addressDistrict": "Quận 1",
  "addressWard": "Phường Bến Nghé",
  "addressStreet": "123 Nguyễn Huệ"
}
```

**TC-SL1-05 Response**:
```json
GET /api/reference/locations
→ 200 OK
["An Giang", "Bà Rịa - Vũng Tàu", "Bắc Giang", ..., "Hồ Chí Minh", ..., "Vĩnh Long", "Vĩnh Phúc", "Yên Bái"]
```

---

## Tools & Commands

- **Skills**: `ef-core`, `dotnet-scaffolding`
- **Test Commands**:
  - `cmd /c rtk dotnet build server/` — verify no compile errors
  - `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests/ --no-build` — verify integration suite

---

## Proposed Changes

### Server-Side
| Action | File | Notes |
|---|---|---|
| [NEW] | `server/Common/Persistence/Entities/StoreAddress.cs` | Owned entity value object with 4 properties |
| [MOD] | `server/Common/Persistence/Entities/Store.cs` | Add `StoreAddress? Address2` owned property (keeping `Address` string) |
| [MOD] | `server/Common/Persistence/Configurations/StoreConfiguration.cs` | Add `OwnsOne<StoreAddress>` with explicit `HasColumnName` for all 4 columns |
| [NEW] | `server/Common/Reference/VietnamLocations.cs` | Static `readonly string[]` of 63 official GSO province names |
| [NEW] | `server/Features/Reference/GetLocations.cs` | `GET /api/reference/locations` handler |
| [NEW] | `server/Features/Reference/ReferenceEndpoints.cs` | Route registration |
| [MOD] | `server/Program.cs` | Register `ReferenceEndpoints` |
| [MOD] | `server/Features/Stores/Dtos.cs` | Add `AddressProvince`, `AddressDistrict`, `AddressWard`, `AddressStreet` to `StoreDto` |
| [MOD] | `server/Features/Stores/CreateStore.cs` | Accept province/district/ward/street in Request; validate province; set `store.Address2` |
| [MOD] | `server/Features/Stores/UpdateStore.cs` | Accept province/district/ward/street in Request; validate province; update `store.Address2` |
| [MOD] | `server/Features/Stores/GetStore.cs` | Project `s.Address2` fields into `StoreDto` |
| [MOD] | `server/Features/Stores/ListStores.cs` | Project `s.Address2` fields into `StoreDto` |
| [NEW] | `server/Common/Persistence/Migrations/[timestamp]_AddStoreStructuredAddress.cs` | EF migration with `MigrationBuilder.Sql()` for backfill |

> [!WARNING]
> After the Builder generates the EF Core migration, the user MUST restart the `server/` process to trigger `db.Database.Migrate()` and apply the migration to the local PostgreSQL database.

### Flutter-Side
| Action | File | Notes |
|---|---|---|
| [NEW] | `lib/features/stores/widgets/store_location_map_widget.dart` | Extract `FlutterMap` widget from `store_form_sheet.dart` to reduce its line count |
| [MOD] | `lib/features/admin/pages/widgets/store_form_sheet.dart` | Remove Area dropdown; add Province `DropdownButtonFormField` (loaded from `/api/reference/locations`) + 3 `TextFields` for District, Ward, Street. Pass `areas: []` or remove the parameter. |
| [MOD] | `lib/features/stores/model/store_dto.dart` | Add `addressProvince?`, `addressDistrict?`, `addressWard?`, `addressStreet?` fields + `fromJson` mapping |
| [MOD] | `lib/features/stores/services/store_api_service.dart` | Add `province`, `district`, `ward`, `street` params to `createStore` and `updateStore`; add `fetchProvinces()` method calling `GET /api/reference/locations` |
| [MOD] | `lib/_shared/database/tables.dart` | Add 4 nullable columns to `CachedStores`; keep `areaId`/`areaName` (additive only) |

**UI Routing Table for `store_form_sheet.dart`:**
| Component | Overflow/Truncation | Route/Action |
|---|---|---|
| Province Dropdown | Province string max ~35 chars — single line OK | No overflow issue |
| District TextField | Free text, 100 char limit | No routing |
| Ward TextField | Free text, 100 char limit | No routing |
| Street TextField | Free text, 200 char limit | No routing |

---

## Concept Diagram

```
[Store Form Sheet — Flutter]
  State: _selectedProvince (String?), _districtCtrl, _wardCtrl, _streetCtrl

  on mount → GET /api/reference/locations → _provinceOptions = [...63 provinces]
  User selects Province → _selectedProvince = "Hồ Chí Minh"
  User types District/Ward/Street (free text)
  
  on Save → StoreApiService.createStore(
               name, province: _selectedProvince,
               district: _districtCtrl.text, ...)
           → POST /api/stores { name, province, district, ward, street }
  
[CreateStore.HandleAsync — Server]
  Validate: Province ∈ VietnamLocations.Provinces
  If not → 400 { "error": "Invalid province" }
  Create Store entity with store.Address2 = new StoreAddress {
    Province = request.Province, District = request.District, ...
  }
  db.Stores.Add(store) → EF maps to flat columns in stores table:
    address_province, address_district, address_ward, address_street

[DB: stores table]
  (existing)  id | name | address | area_id | ...
  (new)       address_province | address_district | address_ward | address_street

  Backfill (runs in migration):
    UPDATE stores SET address_province = a.name
    FROM areas a WHERE stores.area_id = a.id;
    UPDATE stores SET address_province = 'Uncategorized'
    WHERE address_province IS NULL;

[GET /api/reference/locations]
  Returns: ["An Giang", "Bà Rịa - Vũng Tàu", ..., "Hồ Chí Minh", ...]
  Source: VietnamLocations.Provinces (static in-memory constant)
  No DB query.
```

---

## Execution Slices (Micro-Specs)

### Phase B1: Server Data Layer (DB + OwnedEntity + Reference Endpoint)
**Complexity**: Medium (EF Core OwnedEntity config + migration SQL + new endpoint)

**Plain English**: Create the `StoreAddress` owned entity class, configure it in `StoreConfiguration`, create `VietnamLocations` static list, add the reference endpoint, and generate + customize the EF migration to include the SQL backfill.

**Value Delivered**: The database has the 4 new address columns, pre-filled with province data from existing Area assignments. The reference API is live.

**Entry State Required**: `server/` builds cleanly. Existing tests pass.

**Exit State Guaranteed**: `dotnet build` succeeds. The migration file exists. After server restart, `stores` table has `address_province`, `address_district`, `address_ward`, `address_street` columns. `GET /api/reference/locations` returns 200 with 63 provinces. TC-SL1-01, TC-SL1-03, TC-SL1-05, TC-SL1-09 pass.

**Scope**:
- [NEW] `StoreAddress.cs`
- [MOD] `Store.cs` (add `StoreAddress? Address2`)
- [MOD] `StoreConfiguration.cs` (add `OwnsOne` config)
- [NEW] `VietnamLocations.cs`
- [NEW] `GetLocations.cs`
- [NEW] `ReferenceEndpoints.cs`
- [MOD] `Program.cs`
- [NEW] EF migration

**Acceptance Criteria**: TC-SL1-01, TC-SL1-03, TC-SL1-04, TC-SL1-05, TC-SL1-09, TC-SL1-10

---

### Phase B2: Server API Layer (Store Endpoints + DTOs)
**Complexity**: Low (straightforward field additions to existing handlers)

**Plain English**: Update `StoreDto`, `CreateStore`, `UpdateStore`, `GetStore`, and `ListStores` to accept and project the 4 new address fields. Add province validation against `VietnamLocations.Provinces`.

**Value Delivered**: The Store API now accepts structured addresses and returns them in responses. TC-SL1-02 and TC-SL1-08 pass.

**Entry State Required**: Phase B1 complete. `stores` table has address columns. Server builds.

**Exit State Guaranteed**: `POST /api/stores` with valid province returns 201 with address fields. `POST /api/stores` with invalid province returns 400. `GET /api/stores/{id}` returns both legacy `address`/`areaId` AND new address fields.

**Scope**:
- [MOD] `Dtos.cs` (server)
- [MOD] `CreateStore.cs`
- [MOD] `UpdateStore.cs`
- [MOD] `GetStore.cs`
- [MOD] `ListStores.cs`

**Acceptance Criteria**: TC-SL1-02, TC-SL1-04, TC-SL1-08, TC-SL1-10

---

### Phase B3: Flutter Layer (DTO + Service + UI)
**Complexity**: Medium (Drift schema migration + form UI refactor with file split)

**Plain English**: Add address fields to the Flutter `StoreDto` model and `StoreApiService`. Add a `fetchProvinces()` method. Split `store_form_sheet.dart` by extracting the map widget. Replace the Area dropdown with a Province dropdown loaded from the API + 3 free-text fields. Update `CachedStores` Drift table.

**Value Delivered**: The Store Create/Edit form captures Province (validated via API dropdown), District, Ward, and Street. The Area dropdown is removed from this form. Offline cache stores address fields.

**Entry State Required**: Phase B2 complete. Server is running and returning new address fields.

**Exit State Guaranteed**: App compiles. Store create form shows Province dropdown (63 items), District/Ward/Street text fields. Saving a store sends address fields to API correctly. `CachedStores` Drift table schema migrates cleanly.

**Scope**:
- [NEW] `store_location_map_widget.dart`
- [MOD] `store_form_sheet.dart` (remove Area dropdown, add address fields, import map widget)
- [MOD] `store_dto.dart` (Flutter)
- [MOD] `store_api_service.dart`
- [MOD] `tables.dart` (Drift schema)

**Acceptance Criteria**: TC-SL1-06, TC-SL1-07, TC-SL1-08 (Flutter side)

---

<command_logs>
grep_search "AreaId" → confirmed Store.cs, StoreConfiguration.cs, CreateStore.cs, UpdateStore.cs, Dtos.cs, store_form_sheet.dart, store_dto.dart, StoreApiService.dart all reference AreaId.
grep_search "store_form_sheet" → found in store_management_page.dart and admin_store_manager.dart.
view_file store_form_sheet.dart → 378 lines, must split before adding more (>250 line rule triggers split, >400 is hard fail).
view_file StoreConfiguration.cs → uses explicit HasColumnName already — confirmed pattern to follow.
view_file AppDbContext.cs → Areas DbSet confirmed; no reference endpoint exists.
view_file tables.dart → CachedStores has areaId and areaName at lines 71-72.
grep_search "/reference|/location" in server → no existing reference endpoint found.
</command_logs>

---

## Handoff Block

**Builder Instructions**: Execute phases ONE AT A TIME in order. Do NOT start B2 until B1's `dotnet build` is green and migration file exists. Do NOT start B3 until B2's integration tests pass.

| # | Phase | Target | Input |
|---|---|---|---|
| 1 | **ATDD Phase** (Server) | Write integration test stubs for TC-SL1-01, TC-SL1-02, TC-SL1-03, TC-SL1-05 | `docs/architecture/implementation_plan_20260518_221700_sl1_store_address.md` |
| 2 | **Implementation Phase B1** | Server Data Layer | Same plan |
| 3 | **Implementation Phase B2** | Server API Layer | Same plan |
| 4 | **Implementation Phase B3** | Flutter Layer | Same plan |

> ⚠️ Route 3 (ATDD) is recommended for B1/B2 because this slice touches the database migration and API contracts.
> Route 2 (Direct Build) is acceptable for B3 (Flutter UI — no new business logic, no auth dependency).

**Concurrency**: B1 → B2 → B3 are strictly sequential. No parallel execution.
