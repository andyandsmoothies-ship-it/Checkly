# Task: Implement B3 — Flutter Layer (SL-1 Store Structured Address)
Workflow: /implement | Track: B1

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_221700_sl1_store_address.md`
- **ATDD Tests**: `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Stores\StoreStructuredAddress_ATDD_Tests.cs`
- **B2 Walkthrough**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\area_deprecation\walkthrough_20260519_071700_impl_b2_sl1_store_address.md`

## Upfront
- [x] Pre-Requisite: Implementation Plan exists
- [x] Pre-Requisite: B1 + B2 completed and GREEN (526 server tests passing)

## Active Slice (B3 — Flutter Layer)
- [x] B3-1: [NEW] `lib/features/stores/widgets/store_location_map_widget.dart` — extract FlutterMap
- [x] B3-2: [MOD] `lib/features/stores/model/store_dto.dart` — add 4 address fields + fromJson
- [x] B3-3: [MOD] `lib/features/stores/services/store_api_service.dart` — add address params + fetchProvinces()
- [x] B3-4: [MOD] `lib/_shared/database/tables.dart` — add 4 nullable columns to CachedStores
- [x] B3-5: [MOD] `lib/features/admin/pages/widgets/store_form_sheet.dart` — replace Area dropdown, add address UI, remove areas param
- [x] B3-6: [MOD] `lib/features/admin/pages/store_management_page.dart` — remove areas: param from call sites
- [x] B3-7: Verify: `rtk flutter analyze lib/` — No issues found!

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff → Terminate session

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/area_deprecation/walkthrough_20260519_072600_impl_b3_sl1_store_address.md | Result |
| [NEW] | docs/qa/gates/area_deprecation/executed_tests_20260519_072600_impl_b3_sl1_store_address.md | Test Log |
