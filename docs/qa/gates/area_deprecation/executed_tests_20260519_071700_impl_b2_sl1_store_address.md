# Executed Tests: B2 — Server API Layer (SL-1 Store Structured Address)

## Run Info
- **Date**: 2026-05-19 07:22 UTC+7
- **Command**: `rtk dotnet test server/tests/Checkly.Api.Tests/`
- **Result**: 526 passed, 0 failed, 0 warnings

## ATDD Tests (now GREEN after B2)

| Test | Result | Notes |
|---|---|---|
| `TC_SL1_01_DbSchema_HasAddressColumns` | ✅ PASS | B1 |
| `TC_SL1_02_CreateStore_WithInvalidProvince_ReturnsBadRequest` | ✅ PASS | **Was RED** — province validation added |
| `TC_SL1_05_GetLocations_ReturnsProvinceArray` | ✅ PASS | B1 |
| `TC_SL1_08_CreateStore_ReturnsAddressFields` | ✅ PASS | **Was RED** — Address2 in response added |
| `Gap1_CreateStore_WithTooLongStreet_ReturnsBadRequest` | ✅ PASS | **Was RED** — street length check added |
| `Gap2_Hostile_AuditorCannotUpdateStoreAddress` | ✅ PASS | B1 |

## Regression Status
- **521 pre-existing tests**: All GREEN ✅
- **6 ATDD tests**: All GREEN ✅
- **0 regressions** from B2 changes
