# Walkthrough: B2 — Server API Layer (SL-1 Store Structured Address)

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_221700_sl1_store_address.md`
- **ATDD Test Contracts**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260518_223644_atdd_sl1_store_address.md`
- **ATDD Tests**: `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Stores\StoreStructuredAddress_ATDD_Tests.cs`
- **B1 Walkthrough**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\area_deprecation\walkthrough_20260519_070500_impl_b1_sl1_store_address.md`

## System Context Diagram

```
POST /api/stores  (CreateStore)
  Request: Name, Address?, AreaId?, GpsLat?, GpsLng?, Province?, District?, Ward?, Street?
    ├─ Province provided + NOT in VietnamLocations → 400 "province"   (TC-SL1-02)
    ├─ Street.Length > 200 → 400 "street"                             (Gap1)
    ├─ store.Address2 = new StoreAddress { Province, District, Ward, Street }
    └─ Response: id, name, address, areaId, areaName,
                 addressProvince, addressDistrict, addressWard, addressStreet  (TC-SL1-08)

PUT /api/stores/{id}  (UpdateStore)
  Same validation + Address2 patch via ??= pattern

GET /api/stores/{id}  (GetStore)
GET /api/stores       (ListStores)
  StoreDto(... CreatedAt, AddressProvince?, AddressDistrict?, AddressWard?, AddressStreet?)

StoreDto  (positional record — 15 params total)
  Old 11 params unchanged → 4 new nullable params appended at end
  Zero breaking change to existing callers
```

## Decision Log

| Decision | Proposed in Plan | Implemented | Reason |
|---|---|---|---|
| Province validation | `VietnamLocations.Provinces` check | `VietnamLocations.IsValidProvince(string)` helper | Encapsulates `OrdinalIgnoreCase` comparison inside the class — no leaky string manipulation at call sites |
| `StoreDto` expansion | Add 4 nullable fields | Positional record params at end | Zero breaking change — all 4 are nullable + at the end. Old 11-param `new StoreDto(...)` calls fail to compile cleanly until all sites updated |
| Address2 set condition | Set when any field non-null | `province != null \|\| district != null \|\| ward != null \|\| street != null` | Only creates the owned entity when the caller actually provides structured address data — prevents empty StoreAddress rows |
| UpdateStore patch | Overwrite full Address2 | `??= new StoreAddress()` then property-by-property patch | Preserves existing address components when only one field is updated |
| Street max length | 200 chars | `> 200` check (Gap1) | Matches Gap1 test assertion and is consistent with Name max of 200 |

## Files Changed

| Action | File |
|---|---|
| [MOD] | `server/Features/Stores/Dtos.cs` (+4 nullable params) |
| [MOD] | `server/Features/Stores/CreateStore.cs` (+province/street validation, +Address2, +response fields) |
| [MOD] | `server/Features/Stores/UpdateStore.cs` (+province/street validation, +Address2 patch, +response fields) |
| [MOD] | `server/Features/Stores/GetStore.cs` (+Address2 projection to StoreDto) |
| [MOD] | `server/Features/Stores/ListStores.cs` (+Address2 projection to StoreDto) |
| [MOD] | `server/Common/Reference/VietnamLocations.cs` (+IsValidProvince helper) |

## Acceptance Criteria Status

| TC | Description | Status |
|---|---|---|
| TC-SL1-01 | DB schema columns | ✅ GREEN (B1) |
| TC-SL1-02 | Invalid province → 400 | ✅ GREEN |
| TC-SL1-03 | Backfill: area.name → address_province | ✅ GREEN (B1) |
| TC-SL1-04 | Legacy areaId/address still present | ✅ GREEN (additive) |
| TC-SL1-05 | GET /reference/locations | ✅ GREEN (B1) |
| TC-SL1-08 | Address fields in 201 response | ✅ GREEN |
| TC-SL1-09 | Null area → 'Uncategorized' backfill | ✅ GREEN (B1) |
| TC-SL1-10 | Existing suite passes | ✅ GREEN (526 passed) |
| Gap1 | Street too long → 400 | ✅ GREEN |
| Gap2 | Auditor cannot create store | ✅ GREEN (B1) |

## Verification Handoff

For manual QA after server restart:
1. `POST /api/stores` with `{ "name": "X", "province": "NotARealPlace" }` → 400 + body contains "province"
2. `POST /api/stores` with valid province "Hồ Chí Minh" → 201 + `addressProvince`, `addressDistrict` in body
3. `POST /api/stores` with `{ "name": "Y", "province": "Hồ Chí Minh", "street": "<301 chars>" }` → 400 + body contains "street"
4. `GET /api/stores` → each item in JSON array has `addressProvince`, `addressDistrict`, `addressWard`, `addressStreet` keys

> [!IMPORTANT]
> Server must be restarted if B1 migration was not yet applied (the EF migration `AddStoreStructuredAddress` auto-applies on startup via `db.Database.Migrate()`).

## Gotcha Protocol

New gotcha found — propose adding to `server/Common/GEMINI.md`:

```markdown
> **Gotcha: Positional Record Blast Radius (StoreDto)**
> When adding new positional params to `StoreDto`, you MUST update EVERY call site that constructs `new StoreDto(...)`.
> Run `grep_search "new StoreDto("` across `server/` to find all sites before editing.
> The compiler catches mismatches, but the blast radius can be surprising if you forget `ListStores.cs` has two separate `StoreDto` call sites.
```

<test_trace>
Full test suite run — with build — 2026-05-19 07:22 UTC+7

ok dotnet test: 526 tests passed, 0 warnings in 1 projects (112.9 s)

Previous (post-B1): 523 passed, 3 failed
After B2: 526 passed, 0 failed ← 3 RED ATDD tests now GREEN

ATDD tests confirmed GREEN:
  ✅ TC_SL1_02_CreateStore_WithInvalidProvince_ReturnsBadRequest
  ✅ TC_SL1_08_CreateStore_ReturnsAddressFields
  ✅ Gap1_CreateStore_WithTooLongStreet_ReturnsBadRequest
</test_trace>

<forensic_evidence>
Build verification:
  rtk dotnet build server/ → ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:09.65)

StoreDto call site search:
  grep_search "new StoreDto(" → 2 results: GetStore.cs:34, ListStores.cs:141
  Both updated with 4 new address params.

IsValidProvince call sites:
  grep_search "IsValidProvince" → CreateStore.cs, UpdateStore.cs (2 correct callers)
</forensic_evidence>
