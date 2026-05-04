# Failure Report: Missing DTO Fields in Slice 3 Admin API
Workflow: /diagnose | Track: B2

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260504_173403_q4m7_slice3_admin_api.md` (and the failing `/verify` workflow for Slice 3)

## Root Cause
The previous builder implementation for Slice 3 (Virtual Area Assignment) failed to fully execute the implementation plan. Specifically:
1. **Response DTO Omission**: `server/Features/Admin/UpdateUser.cs` was updated to *write* the `ProfileStoreAssignments` to the database, but it returns an anonymous object that omits the `assignedStoreIds` field.
2. **Global DTO Omission**: `server/Features/Admin/Dtos.cs` (`UserDto`) was not updated to include `Guid[]? AssignedStoreIds`, preventing other admin listing endpoints from showing this data.
3. **Flutter API Omission**: `lib/features/admin/services/admin_api_service.dart` (and its manager layer) was explicitly listed in the plan as "Optional immediate compatibility", but was entirely ignored, meaning the UI currently has no way to send `virtualAreaId` or `assignedStoreIds` to the backend.

## Explicit Code Trace (Premises + Proof)
**Premise 1**: `UpdateUser.cs` does not return `assignedStoreIds`.
**Proof**: At line 218, the returned object is:
```csharp
        return TypedResults.Ok(new
        {
            id = profile.Id,
            role = userRole.Role,
            storeId = profile.StoreId,
            storeName,
            areaId = profile.AreaId,
            areaName,
            transferred = request.ForceReassign && previousManagerName != null,
            previousManagerName,
        });
```

**Premise 2**: `Dtos.cs` is missing `AssignedStoreIds`.
**Proof**: `UserDto` has `StoreId`, `StoreName`, `AreaId`, `AreaName`, but no `AssignedStoreIds` array.

**Premise 3**: `admin_api_service.dart` does not support the new fields.
**Proof**: At line 39, `updateUser` only accepts `String? storeId` and `String? areaId`.

## Proposed Scope-Limited Fix

**Action 1: Update Backend Response DTOs**
- Update `server/Features/Admin/Dtos.cs` to include `Guid[]? AssignedStoreIds`.
- Update `server/Features/Admin/UpdateUser.cs` to retrieve the `targetStoreIds` array and return it as `assignedStoreIds` in the anonymous 200 OK object.
- Update `server/Features/Admin/ListUsers.cs` and `GetUser.cs` (if applicable) to populate the `AssignedStoreIds` on the `UserDto` for area managers by querying the `ProfileStoreAssignments` table.

**Action 2: Update Flutter Services**
- Update `lib/features/admin/services/admin_api_service.dart` `updateUser` and `createUser` to accept `String? virtualAreaId` and `List<String>? assignedStoreIds`.
- Update `lib/features/admin/manager/admin_user_manager.dart` to pass these parameters through to the service.

### Trade-offs / Pros & Cons
- **Pros**: Fully aligns the backend and frontend with the Slice 3 architectural plan. The UI will now be capable of rendering and transmitting virtual area assignments.
- **Cons**: Updating `ListUsers.cs` to fetch `AssignedStoreIds` might introduce a slight N+1 query issue if not mapped efficiently via a LEFT JOIN or nested select. We must use an efficient projection (e.g., `.Select(u => new UserDto { ..., AssignedStoreIds = u.ProfileStoreAssignments.Select(a => a.StoreId).ToArray() })`).

<forensic_evidence>
- Scanned `UpdateUser.cs` using `view_file` (Lines 218-230).
- Scanned `Dtos.cs` using `view_file` (Lines 5-16).
- Scanned `admin_api_service.dart` using `view_file` (Lines 39-56).
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict**: The Slice 3 implementation is incomplete. Missing response properties and missing Flutter API contracts.
2. **Fix & Blast Radius**: Requires modifying the Admin DTOs, `UpdateUser` return object, and Flutter API services. Blast radius is isolated to the Admin user management flows.
3. **AI Agent Mission Brief**: Implement the missing DTO fields for `assignedStoreIds` in `UpdateUser.cs`, `Dtos.cs`, and add `virtualAreaId`/`assignedStoreIds` parameters to Flutter's `admin_api_service.dart` and `admin_user_manager.dart`.

**Execution Queue:**
- [ ] @[/implement] docs/diagnostics/failure_report_20260504_181952_q4m7_slice3_missing_dto.md
