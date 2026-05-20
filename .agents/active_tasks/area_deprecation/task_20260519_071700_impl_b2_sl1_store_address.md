# Task: Implement B2 — Server API Layer (SL-1 Store Structured Address)
Workflow: /implement | Track: B1

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_221700_sl1_store_address.md`
- **ATDD Tests (RED)**: `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Stores\StoreStructuredAddress_ATDD_Tests.cs`
- **B1 Walkthrough**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\area_deprecation\walkthrough_20260519_070500_impl_b1_sl1_store_address.md`

## Upfront
- [x] Pre-Requisite: Implementation Plan exists
- [x] Pre-Requisite: Failing ATDD tests confirmed RED (TC_SL1_02, TC_SL1_08, Gap1)
- [x] Pre-Requisite: B1 completed and GREEN

## Active Slice (B2 — Server API Layer)
- [x] B2-1: [MOD] `server/Features/Stores/Dtos.cs` — add 4 address params to StoreDto
- [x] B2-2: [MOD] `server/Features/Stores/CreateStore.cs` — accept + validate + save Address2
- [x] B2-3: [MOD] `server/Features/Stores/UpdateStore.cs` — accept + validate + save Address2
- [x] B2-4: [MOD] `server/Features/Stores/GetStore.cs` — project Address2 into StoreDto
- [x] B2-5: [MOD] `server/Features/Stores/ListStores.cs` — project Address2 into StoreDto
- [x] B2-6: Verify: `rtk dotnet build server/` — 0 errors, 0 warnings
- [x] B2-7: Verify: `rtk dotnet test server/tests/Checkly.Api.Tests/` — 526 passed, 0 failed

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff → Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/area_deprecation/walkthrough_20260519_071700_impl_b2_sl1_store_address.md | Result |
| [NEW] | docs/qa/gates/area_deprecation/executed_tests_20260519_071700_impl_b2_sl1_store_address.md | Test Log |
