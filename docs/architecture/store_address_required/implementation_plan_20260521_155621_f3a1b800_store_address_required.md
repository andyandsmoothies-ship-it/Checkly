<latent_space_scratchpad>

## Root Cause Analysis

### The EF Core Warning
`OptionalDependentWithoutIdentifyingPropertyWarning` fires because:
- `StoreAddress` is an Owned Entity mapped via `OwnsOne`.
- ALL four properties on `StoreAddress` are `string?` (nullable).
- EF Core cannot determine if a row with all-null `address_*` columns means
  "no address object" or "an address object with all empty fields."
- When no `.IsRequired()` is called on the `OwnsOne`, EF marks the dependent
  as optional — and warns that it has no identifying property.

### Fix Options

**Option A: Add `.IsRequired()` to OwnsOne** (EF-level fix only)
- Tells EF: "Address2 is NEVER null — always populated."
- Requires a migration: adds NOT NULL on the `address_province` column (since
  EF picks the first mapped property as the identifying column when IsRequired).
- Wait — actually with OwnsOne + IsRequired, EF doesn't pick ONE column as NOT
  NULL. It means the entire owned entity IS required (all its columns mapped
  together). This would still allow Province=null if the StoreAddress object
  exists. The warning is suppressed but the data gap remains.

**Option B: Add `.IsRequired()` AND make `Province` non-nullable in C#**
- `StoreAddress.Province: string` (non-nullable string)
- EF config: `a.Property(p => p.Province).HasColumnName(...).IsRequired()`
- This means Province MUST be set when Address2 is created.
- BUT: Address2 is still nullable on Store (Store.Address2 is `StoreAddress?`).
  So the owned entity is optional at the Store level.
- This only enforces Province non-null IF Address2 is provided.
- Does NOT fix the warning by itself (the owned entity is still optional).

**Option C (RECOMMENDED): IsRequired() on OwnsOne + Province required in C# + API validation**
- `OwnsOne(...).IsRequired()` — suppresses the EF warning. Address2 can no
  longer be null in the DB; EF will always write it.
- `StoreAddress.Province: string` — Province is the identifying field and must
  always have a value.
- `CreateStore.Request.Province: string` (non-nullable) — API level enforcement.
- `StoreAddressValidator.Validate()` enhanced to fail if Province is null/empty.
- Flutter `saveStore()` adds Province null guard BEFORE calling the API.

### Migration Impact
- Adding `.IsRequired()` to `OwnsOne` changes the column nullability in the DB.
  Since `address_province` is currently nullable, a migration MUST be generated.
- The migration will: ALTER COLUMN address_province SET NOT NULL (and same for
  other columns if we make them non-nullable).
- Data Risk: existing stores with null `address_province` will BLOCK the migration.
  Strategy: backfill NULL with a default value (e.g., 'Unknown') in the migration
  before changing column type.
- SCOPE DECISION: Only make Province required (NOT District/Ward/Street). This
  is the minimum to identify an address geographically.

### Existing Test Impact
- `StoreCrud_ATDD_Tests.cs` line 90: `CreateAdminClientAsync()` creates a store
  with `new { name = $"Original {Guid.NewGuid()}" }` — NO province.
  This will START FAILING after Province is required. Must update fixture to pass
  a province. THIS IS INTENTIONAL — the test was testing a now-invalid state.
- `StoreCrud_ATDD_Tests.cs` line 127: `DeleteStore_Admin_ExistingStore_Returns204`
  — same issue, no province in payload. Will break.
- `StoreCrud_ATDD_Tests.cs` line 162: `GetStoreDashboard` — same, no province.
- Per GEMINI.md rule "Never change a test and the main code in the same step":
  Approach = write the new ATDD test first (RED), then fix code (GREEN), then
  fix the now-broken StoreCrud tests (which is a consequence fix, not cheating).

### Flutter Impact  
- `store_form_save_logic.dart` L66: `final province = selectedProvince;`
  Province is currently optional — no null guard. After this change, Province=null
  must block the save.
- `store_form_body.dart` L128: Province dropdown label is 'Province' with no *.
  Must change to 'Province *' to signal required.
- The Province dropdown has a null first item `DropdownMenuItem(value: null, ...)`.
  Must validate selectedProvince != null before calling saveStore().

</latent_space_scratchpad>

# Implementation Plan: Make Store Address Required
**ID**: implementation_plan_20260521_155621_f3a1b800_store_address_required
**Date**: 2026-05-21
**Status**: READY FOR REVIEW

---

## Input Lineage
- **Source Input**: User request — fix `OptionalDependentWithoutIdentifyingPropertyWarning` and enforce business rule "Stores must always have an address."

---

## Executive Summary & Out of Scope

**What we build:**
The `StoreAddress` owned entity currently has all-nullable properties and no `IsRequired()` on its `OwnsOne` mapping. This makes EF Core emit a startup warning and allows stores to be created with no address at all. We will:
1. Make `Province` the **required identifying field** for the structured address.
2. Enforce this at 3 layers: EF Core config → API validation → Flutter UI guard.
3. Generate a **migration** to set `address_province NOT NULL` in the DB (with a backfill for existing null rows).

**Out of scope:**
- ❌ Making `District`, `Ward`, or `Street` required (Province is sufficient for identification).
- ❌ Making the legacy free-text `Address` field required (separate column, not the source of the warning).
- ❌ Any changes to the sync endpoint or Flutter offline cache — addresses are not cached locally.
- ❌ Removing the legacy `Address` (`string?`) field — left for backward compatibility per SL-1 design.
- ❌ Making `GpsLat`/`GpsLng` required.

---

## System Context

| Item | Value |
|------|-------|
| **Connectivity** | Live API (app-only, no web backend) |
| **RBAC Gate** | `stores:write` capability gates CreateStore + UpdateStore |
| **Read roles** | All authenticated users (via `RequireAuthorization()`) |
| **Database** | PostgreSQL via EF Core — `stores` table, flat columns |
| **Migration risk** | Medium — existing NULL rows in `address_province` must be backfilled before column goes NOT NULL |

---

## Lifecycle Context (4-State Matrix)

| State | Backend | Flutter Form |
|-------|---------|--------------|
| **Success** | 201 Created with Province in response | Form saves, sheet dismisses, snackbar shown |
| **Error — missing Province** | 400 `{ "error": "Province is required" }` | Red error in Province dropdown before calling API |
| **Empty** | N/A | Province dropdown renders with null placeholder |
| **Loading** | N/A | `isSaving = true` disables all fields and Save button |

---

## Constraint Traceability

| Constraint | Source | Test Contract ID |
|------------|--------|-----------------|
| Stores must always have an address | User request | TC-SA-01 |
| Fix `OptionalDependentWithoutIdentifyingPropertyWarning` | User request | TC-SA-02 |
| Province is the identifying field (minimum required field) | Architect decision (see scratchpad) | TC-SA-01 |
| Existing NULL rows must be backfilled before migration | DB integrity rule | TC-SA-03 |
| Existing ATDD tests that omit Province will fail and MUST be updated | GEMINI.md: "Fix code to pass test, not test to pass code" | TC-SA-04 |
| Flutter must validate Province before API call | UX rule — fail fast client-side | TC-SA-05 |
| No backend changes to District/Ward/Street (optional) | YAGNI | N/A |

---

## Test Contracts

| ID | Test Description | Expected Result | Fails First Because |
|----|-----------------|-----------------|---------------------|
| **TC-SA-01** | `POST /api/stores` with NO `province` → returns 400 with `province` error message | `400 Bad Request` | API currently returns 201 (no Province validation) |
| **TC-SA-02** | Server startup produces ZERO EF Core warnings matching `OptionalDependent` | No warning in log | OwnsOne has no IsRequired today |
| **TC-SA-03** | `POST /api/stores` with `province = "Hồ Chí Minh"` → returns 201 (happy path still works) | `201 Created` | Should still pass |
| **TC-SA-04** | `StoreCrud_ATDD_Tests.CreateStore_Admin_ValidPayload_Returns201WithId` (pre-existing) | Must be UPDATED to include `province` in payload | Will fail after TC-SA-01 enforcement |
| **TC-SA-05** | Flutter: `saveStore()` called with `selectedProvince == null` → does NOT call API, shows error snackbar | Error shown, API NOT called | Flutter has no Province null guard today |
| **TC-SA-06** | `PUT /api/stores/{id}` with `province = null` on an existing store that has no Address2 → stores can be updated without re-sending Province (patch semantics preserved) | `200 OK` | Should still pass (UpdateStore uses patch logic) |

---

## Test Fixture & Payloads

### Fixture State Required
- **Admin client** with `stores:write` capability (use `LoginBootstrapAdminAsync`).
- **TC-SA-03**: Existing store with `address_province = 'Hồ Chí Minh'` (or created inline).
- **TC-SA-01**: Fresh POST with missing province.

### API Payloads

**TC-SA-01 — Fails without Province:**
```json
POST /api/stores
{ "name": "Test Store No Province" }
→ 400 { "error": "Province is required" }
```

**TC-SA-03 — Succeeds with Province:**
```json
POST /api/stores
{ "name": "Test Store HCM", "province": "Hồ Chí Minh" }
→ 201 { "id": "...", "addressProvince": "Hồ Chí Minh", ... }
```

**TC-SA-06 — Update without Province (patch semantics, still valid):**
```json
PUT /api/stores/{id}
{ "name": "New Name" }
→ 200 { "name": "New Name", ... }
```

---

## Tools & Commands

| Tool | Skill / Command |
|------|----------------|
| **Backend test** | `cmd /c rtk dotnet test tests/Checkly.Api.Tests/ --filter "StoreAddress"` |
| **Backend full test** | `cmd /c rtk dotnet test tests/Checkly.Api.Tests/` |
| **Migration** | `cmd /c rtk dotnet ef migrations add MakeStoreAddressProvinceRequired --project Checkly.Api` (run from `server/`) |
| **Migration apply** | `cmd /c rtk dotnet ef database update --project Checkly.Api` (run from `server/`) |
| **Build check** | `cmd /c rtk dotnet build server/` |
| **Flutter test** | `cmd /c flutter test` (run from `lib/`) |

---

## Proposed Changes

| # | File | Action | Reason |
|---|------|--------|--------|
| 1 | `server/Common/Persistence/Entities/StoreAddress.cs` | **[MOD]** | Change `Province` from `string?` to `string` (non-nullable) |
| 2 | `server/Common/Persistence/Configurations/StoreConfiguration.cs` | **[MOD]** | Add `.IsRequired()` to `OwnsOne` + `a.Property(Province).IsRequired()` |
| 3 | `server/Features/Stores/StoreAddressValidator.cs` | **[MOD]** | Add null/empty guard for Province — returns 400 if Province is null or whitespace |
| 4 | `server/Features/Stores/CreateStore.cs` | **[MOD]** | Province is now required — validator called unconditionally (not only when address fields present) |
| 5 | `server/Migrations/` | **[NEW]** | Migration: backfill NULL `address_province` → `'Unknown'`, then set NOT NULL |
| 6 | `lib/features/admin/pages/widgets/store_form_body.dart` | **[MOD]** | Province label → `'Province *'`. Add `errorText` to InputDecoration when province is null after attempted save |
| 7 | `lib/features/admin/pages/widgets/store_form_save_logic.dart` | **[MOD]** | Add null guard for `selectedProvince` before calling API. Show error if null |
| 8 | `server/tests/Checkly.Api.Tests/Features/Stores/StoreStructuredAddress_ATDD_Tests.cs` | **[MOD]** | Add **TC-SA-01** test case: POST without province → 400 |
| 9 | `server/tests/Checkly.Api.Tests/Features/Stores/StoreCrud_ATDD_Tests.cs` | **[MOD]** | Add `province = "Hồ Chí Minh"` to ALL create-store payloads (consequence fix: existing tests created stores without address — now invalid) |

> [!WARNING]
> **Migration Risk**: The `address_province` column currently allows NULL. Existing rows in `checkly` (production) and `checkly_test` may have NULL values. The migration **MUST** contain a `Sql("UPDATE stores SET address_province = 'Unknown' WHERE address_province IS NULL")` step BEFORE the `AlterColumn` that sets NOT NULL. Without this, the migration will fail on both databases.

---

## Concept Diagram

```
[Admin taps Save in StoreFormSheet]
        │
        ▼
[Flutter: selectedProvince == null?]
   YES → Show "Province is required" error, STOP
   NO  ▼
[POST /api/stores { name, province, ... }]
        │
        ▼
[API: StoreAddressValidator.Validate(province, street)]
   province null/empty → 400 "Province is required"
   province invalid     → 400 "Province X is not valid"
   province valid       ▼
[Store entity created: Address2 = new StoreAddress { Province = ... }]
        │
        ▼
[EF Core: OwnsOne IsRequired → Address2 never null in DB]
        │
        ▼
[201 Created — warning suppressed at startup]
```

---

## Execution Slices

### Slice 1 — Backend: Validation + EF Config + Migration
**Complexity**: Medium (migration with backfill is the risk)

**Plain English Summary:**
Make the API reject a Create request with no Province. Fix EF Core configuration to silence the warning. Generate and apply the DB migration.

**Value Delivered:** Server startup is warning-free. API enforces the business rule. No Store can exist without an address Province.

**Entry State:** `address_province` is nullable. `CreateStore` accepts stores without any province. EF warns on startup.

**Exit State:** `address_province` is NOT NULL in DB. `POST /api/stores` without `province` returns 400. Server starts without the EF warning.

**Scope:**
- `StoreAddress.cs`: `Province` → `string` (not `string?`)
- `StoreConfiguration.cs`: `OwnsOne(...).IsRequired()` + `a.Property(Province).IsRequired()`
- `StoreAddressValidator.cs`: Province null/empty check added
- `CreateStore.cs`: Remove the conditional block `if (Province is not null || ...)` — Address2 MUST always be set on Create (since Province is required). Logic: `Address2 = new StoreAddress { Province = request.Province!, ... }`.
- New migration with backfill SQL.

**Acceptance Criteria:**
- TC-SA-01: POST without province → 400 ✅
- TC-SA-02: No `OptionalDependentWithoutIdentifyingPropertyWarning` on startup ✅
- TC-SA-03: POST with valid province → 201 ✅
- TC-SA-06: PUT without province → 200 (UpdateStore still uses patch logic) ✅

---

### Slice 2 — Backend Tests: Write & Run ATDD
**Complexity**: Low

**Plain English Summary:**
Write the TC-SA-01 test (RED). Run the full test suite to confirm TC-SA-01 fails, TC-SA-04 (existing tests) also fail. Then Slice 1 is applied to turn everything GREEN.

**Entry State:** TC-SA-01 test written but failing. StoreCrud tests failing because they send stores without province.

**Exit State:** All tests GREEN. StoreCrud tests updated with `province = "Hồ Chí Minh"` payloads.

**Scope:**
- `StoreStructuredAddress_ATDD_Tests.cs`: Add `TC_SA_01_CreateStore_WithNoProvince_ReturnsBadRequest` test.
- `StoreCrud_ATDD_Tests.cs`: Add `province = "Hồ Chí Minh"` to all `new { name = ... }` payloads used in CreateStore calls.

**Acceptance Criteria:**
- TC-SA-01 passes ✅
- TC-SA-04 passes (existing tests fixed) ✅
- Full `dotnet test` is GREEN ✅

---

### Slice 3 — Flutter: Form Validation Guard
**Complexity**: Low

**Plain English Summary:**
Add a client-side guard in `saveStore()` that blocks the API call if Province is not selected. Update the form label to show Province as required.

**Entry State:** Flutter sends requests without Province. No client-side Province guard exists.

**Exit State:** Flutter shows an error if Province is not selected. Province field shows `*` indicator.

**Scope:**
- `store_form_save_logic.dart`: Add Province null guard before `setState(() => isSaving = true)`.
- `store_form_body.dart`: Province label → `'Province *'`.

**Acceptance Criteria:**
- TC-SA-05: Tapping Save with no Province → shows error, does NOT call API ✅
- Province label shows `*` ✅

---

## Pros & Cons (Key Decision)

### Should `UpdateStore` also require Province?

| Option | Pros | Cons |
|--------|------|------|
| **A: UpdateStore also requires Province** | Consistent rule — you can never clear an address | Breaks existing store updates where no Province is sent (all CRUD tests). Large blast radius. |
| **B: UpdateStore keeps patch semantics (RECOMMENDED)** | Minimal blast radius. Existing stores with Province can be updated for name/gps without re-sending address. | A store created before this change with no Province can still be updated without adding one. |

**Recommendation: Option B** — Apply the Province-required rule only on **Create**, not on Update. This is consistent with how `Name` validation works today (UpdateStore accepts `name = null` to keep the existing name).

---

<command_logs>
- grep_search: server/ for StoreAddress, Address2
- view_file: Store.cs, StoreAddress.cs, StoreConfiguration.cs, StoreAddressValidator.cs
- view_file: CreateStore.cs, UpdateStore.cs, Dtos.cs, ListStores.cs
- view_file: StoreStructuredAddress_ATDD_Tests.cs, StoreCrud_ATDD_Tests.cs
- view_file: store_management_page.dart, store_form_body.dart, store_form_save_logic.dart
- list_dir: server/Features/Stores, lib/features/stores/model, lib/features/admin/pages
</command_logs>

---

## Handoff Block

**Primary artifact (this file):**
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_address_required\implementation_plan_20260521_155621_f3a1b800_store_address_required.md`

**Execution sequence — execute ONE AT A TIME:**

- **Slice 1 (Backend — DB + API)**: Write Acceptance Test (TC-SA-01) → confirm RED → Build (StoreAddress.cs, StoreConfiguration.cs, StoreAddressValidator.cs, CreateStore.cs, Migration) → Run `dotnet test` → confirm GREEN
- **Slice 2 (Backend — Fix broken fixtures)**: Fix `StoreCrud_ATDD_Tests.cs` payloads → Run `dotnet test` → confirm all GREEN
- **Slice 3 (Flutter — UI guard)**: Build (store_form_save_logic.dart, store_form_body.dart) → Manual test on device

> [!IMPORTANT]
> Do NOT run Slice 3 until Slice 1 and 2 are GREEN. The Flutter guard must match the backend contract.
