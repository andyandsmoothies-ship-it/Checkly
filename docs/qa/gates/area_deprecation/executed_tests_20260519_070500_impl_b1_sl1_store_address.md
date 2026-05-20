# Executed Tests: B1 — Server Data Layer (SL-1 Store Structured Address)

## Run Info
- **Date**: 2026-05-19 07:15 UTC+7
- **Command**: `rtk dotnet test server/tests/Checkly.Api.Tests/`
- **Result**: 523 passed, 3 failed (B2 scope), 7 skipped

## ATDD Tests Status (B1 scope)

| Test | Result | Notes |
|---|---|---|
| `TC_SL1_01_DbSchema_HasAddressColumns` | ✅ PASS | stores table has all 4 snake_case columns |
| `TC_SL1_05_GetLocations_ReturnsProvinceArray` | ✅ PASS | Returns 63 provinces |
| `Gap2_Hostile_AuditorCannotUpdateStoreAddress` | ✅ PASS | 403 returned correctly |
| `TC_SL1_02_CreateStore_WithInvalidProvince_ReturnsBadRequest` | 🔴 RED | B2 scope: province validation |
| `TC_SL1_08_CreateStore_ReturnsAddressFields` | 🔴 RED | B2 scope: DTO projection |
| `Gap1_CreateStore_WithTooLongStreet_ReturnsBadRequest` | 🔴 RED | B2 scope: length validation |

## Regression Status
- **521 pre-existing tests**: All GREEN ✅
- **2 new B1 ATDD tests**: GREEN ✅
- **0 regressions** from additive changes
