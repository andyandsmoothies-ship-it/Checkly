# Task: Implement B1 — Server Data Layer (SL-1 Store Structured Address)
Workflow: /implement | Track: B1

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_221700_sl1_store_address.md`
- **ATDD Contracts**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260518_223644_atdd_sl1_store_address.md`
- **ATDD Tests (RED)**: `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Stores\StoreStructuredAddress_ATDD_Tests.cs`

## Upfront
- [x] Pre-Requisite: Implementation Plan exists
- [x] Pre-Requisite: Failing ATDD tests exist (RED confirmed in smoke gate report)

## Active Slice
- [x] B1-1: [NEW] `server/Common/Persistence/Entities/StoreAddress.cs`
- [x] B1-2: [MOD] `server/Common/Persistence/Entities/Store.cs` — add `StoreAddress? Address2`
- [x] B1-3: [MOD] `server/Common/Persistence/Configurations/StoreConfiguration.cs` — add `OwnsOne<StoreAddress>`
- [x] B1-4: [NEW] `server/Common/Reference/VietnamLocations.cs`
- [x] B1-5: [NEW] `server/Features/Reference/GetLocations.cs`
- [x] B1-6: [NEW] `server/Features/Reference/ReferenceEndpoints.cs`
- [x] B1-7: [MOD] `server/Program.cs` — register `MapReferenceEndpoints()`
- [x] B1-8: [NEW] EF Core migration with SQL backfill (`20260519000907_AddStoreStructuredAddress.cs`)
- [x] B1-9: Verify: `rtk dotnet build server/` → 0 errors, 0 warnings
- [x] B1-10: Verify: `rtk dotnet test server/tests/Checkly.Api.Tests/` → 523 passed, 3 RED (B2 scope), 0 regressions

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff → Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | `.agents/active_tasks/area_deprecation/walkthrough_20260519_070500_impl_b1_sl1_store_address.md` | Result |
| [NEW] | `docs/qa/gates/area_deprecation/executed_tests_20260519_070500_impl_b1_sl1_store_address.md` | Test Log |
