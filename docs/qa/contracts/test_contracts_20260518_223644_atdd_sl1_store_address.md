# Test Contracts: SL-1 Store Address

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_221700_sl1_store_address.md`

## Smoke Gate Report

| Test Name | Status | Type | Error Summary |
|-----------|--------|------|---------------|
| TC_SL1_01_DbSchema_HasAddressColumns | RED | ✅ Business | "address_province" column not found |
| TC_SL1_02_CreateStore_WithInvalidProvince_ReturnsBadRequest | RED | ✅ Business | Expected BadRequest, got Created |
| TC_SL1_05_GetLocations_ReturnsProvinceArray | RED | ✅ Business | 404 NotFound for /api/reference/locations |
| TC_SL1_08_CreateStore_ReturnsAddressFields | RED | ✅ Business | Missing addressProvince in response |
| Gap1_CreateStore_WithTooLongStreet_ReturnsBadRequest | RED | ✅ Business | Expected BadRequest, got Created |
| Gap2_Hostile_AuditorCannotUpdateStoreAddress | GREEN | ✅ Business | Expected Forbidden, got Forbidden |

### Verdict
- ✅ All failures are Business failures (RED for the right reason). Proceeding to handoff.

## Test Cases

| ID | Given | When | Then |
|---|---|---|---|
| TC-SL1-01 | A fresh test database is initialized | EF Core applies migrations | The `stores` table contains `address_province`, `address_district`, `address_ward`, and `address_street` columns |
| TC-SL1-02 | An admin user is authenticated | They POST `/api/stores` with a `province` that is not in the VietnamLocations allow-list | The API returns 400 Bad Request with a validation error on province |
| TC-SL1-05 | A user is authenticated | They GET `/api/reference/locations` | The API returns 200 OK with a JSON array of province strings |
| TC-SL1-08 | An admin user is authenticated | They POST `/api/stores` with valid province, district, ward, and street | The API returns 201 Created and the response DTO contains the address fields |
| GAP-1 | An admin user is authenticated | They POST `/api/stores` with a `street` exceeding 200 characters | The API returns 400 Bad Request with a validation error on street |
| GAP-2 | An auditor user is authenticated | They POST `/api/stores` | The API returns 403 Forbidden |

## Test Infrastructure Map

### Helper Methods
| Method | Signature | Behavior |
|--------|-----------|----------|
| `LoginBootstrapAdminAsync` | `(HttpClient)` | Logs in as seed admin, returns JWT token |
| `RegisterUserAsync` | `(HttpClient, email, password, fullName, role)` | Creates a user via POST /api/auth/register and returns token & userId |
| `CreateAuthenticatedClient` | `(token)` | Returns HttpClient with Bearer token set |

### Seed Data
- **Admin user**: `bootstrap@admin.test` / `Bootstrap123!@` (seeded by `TestWebApplicationFactory`)
- **Roles**: `admin`, `auditor`, `store_manager`, `area_manager`
- **Database**: Fresh `checkly_test` PostgreSQL database, recreated/migrated per test run

### Expected Response Shapes
```json
// GET /api/reference/locations → 200 OK
[ "Hồ Chí Minh", "Hà Nội", "Đà Nẵng", "..." ]

// POST /api/stores → 201 Created
{
  "id": "guid",
  "name": "string",
  "addressProvince": "string",
  "addressDistrict": "string",
  "addressWard": "string",
  "addressStreet": "string"
}
```
