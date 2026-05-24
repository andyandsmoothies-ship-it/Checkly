# Test Contracts: Slice 3 Admin API Virtual Area Assignment
Workflow: /atdd | Track: B2

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_173100_q4m7s3k1_slice3_admin_api.md`

## Accepted Scenarios

| Scenario ID | Description | Type | Status |
|---|---|---|---|
| TC-3.1 | Updating AM with `virtualAreaId=X` creates assignments for all active stores in area X | Boundary | 🔴 RED |
| TC-3.2 | Updating AM with `assignedStoreIds=[A,B]` upserts direct assignments and does not duplicate existing rows | Boundary | 🔴 RED |
| TC-3.3 | S10 removed: update to area_manager with occupied legacy area does not return 409 | Happy | 🔴 RED |
| TC-3.4 | Mixed payload union: `virtualAreaId` + extra `assignedStoreIds` results in union set | Boundary | 🔴 RED |
| TC-3.5 | Invalid `assignedStoreIds` containing unknown store returns 400 with clear error | Negative | 🔴 RED |
| TC-3.6 | Non-admin update still forbidden even with new payload fields | Negative | 🟢 GREEN |
| TC-3.7 | CreateUser for AM no longer fails S10 when area occupied | Happy | 🔴 RED |
| TC-3.8 | Empty assignments and no `virtualAreaId` clears all assignments | Negative/Edge | 🔴 RED |

## Test Infrastructure Map
- `UpdateUserVirtualAreaTests.cs`:
  - `TC_3_1_UpdatingAM_WithVirtualAreaId_CreatesAssignmentsForAllActiveStoresInArea`
  - `TC_3_2_UpdatingAM_WithAssignedStoreIds_UpsertsDirectAssignments_AndIsIdempotent`
  - `TC_3_3_UpdateAM_OccupiedLegacyArea_DoesNotReturn409`
  - `TC_3_4_MixedPayloadUnion_ResultsInUnionSet`
  - `TC_3_5_InvalidAssignedStoreIds_Returns400`
  - `TC_3_6_NonAdminUpdate_Forbidden`
  - `TC_3_8_EmptyAssignmentsAndNoVirtualAreaId_ClearsAllAssignments`
- `CreateUserVirtualAreaTests.cs`:
  - `TC_3_7_CreateUser_AM_NoLongerFailsS10_WhenAreaOccupied`
