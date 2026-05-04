# Task: Slice 3 Admin API Missing assignedStoreIds DTO
Workflow: /diagnose | Track: B2

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260504_173403_q4m7_slice3_admin_api.md` (and prior verify findings)

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | docs/diagnostics/failure_report_20260504_181952_q4m7_slice3_missing_dto.md | Report |

## Formal Reasoning
### Initial Hypothesis
1. `UpdateUser.cs` does not map the newly created `ProfileStoreAssignments` back into the API response `assignedStoreIds` field.
2. `Dtos.cs` `UserDto` was not updated to contain `Guid[]? AssignedStoreIds`.
3. Flutter API layer `admin_api_service.dart` does not send `virtualAreaId` or `assignedStoreIds` in the payload.

### Evidence Gathered
- Reviewing `UpdateUser.cs` line 218:
  ```csharp
  return TypedResults.Ok(new { id = profile.Id, role = userRole.Role, storeId = profile.StoreId, storeName, areaId = profile.AreaId, areaName, transferred = ... });
  ```
- Reviewing `Dtos.cs`: `UserDto` has `AreaId` and `StoreId`, but no `AssignedStoreIds`.
- Reviewing `admin_api_service.dart`: `updateUser` only sends `storeId`, `areaId`, `role`, `fullName`, `forceReassign`.

### Root Cause Identified
(Pending)

### Fix Strategy
(Pending)
