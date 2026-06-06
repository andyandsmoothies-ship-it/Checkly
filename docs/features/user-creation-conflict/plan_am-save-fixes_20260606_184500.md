---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
Type: plan
Topic: am-save-fixes
Date: 2026-06-06
---

# Plan: Fix Area Manager and Store Manager Save Bugs

This plan addresses the bugs where:
1. Clearing all store assignments for an Area Manager fails because the frontend sends `null` instead of `[]`, which the backend ignores.
2. Demoting an Area Manager to another role (like Auditor) leaves their assignments in the `profile_store_assignments` junction table.
3. Unassigning a Store Manager's store assignment is ignored by the backend due to `request.StoreId.HasValue` checking.

## Diagnostic Diagram

```
[Frontend (user_edit_sheet)]
   |
   +--> Send empty list `[]` for Area Manager stores instead of `null`
   +--> Send `storeId: null` for Store Manager store unassignment
   |
   v
[Backend (UpdateUser.cs)]
   |
   +--> Use `JsonElement` to inspect property presence (distinguish omitted vs null)
   +--> If role changed FROM area_manager TO other, delete junction table entries
   +--> If role changed FROM store_manager TO other, set Profile.StoreId = null
   +--> If `storeId` explicitly sent as null, set Profile.StoreId = null
```

## Proposed Changes

### 1. Backend: `server/Features/Admin/UpdateUser.cs`
- Change signature of `HandleAsync` to accept `JsonElement requestJson`.
- Deserialize `requestJson` to `Request request` internally.
- Check presence of `"storeId"` and `"assignedStoreIds"` using `requestJson.TryGetProperty(...)`.
- If `effectiveRole != "area_manager"`, delete all existing junction table entries in `ProfileStoreAssignments`.
- If `effectiveRole == "area_manager"` and `"assignedStoreIds"` is present:
  - If null, treat as empty array `[]`.
  - Process update (remove unselected, add new).
  - If not present, load current database assignments into `targetStoreIds` so the response DTO matches the DB.
- If `effectiveRole != "store_manager"`, clear `profile.StoreId = null`.
- If `effectiveRole == "store_manager"` and `"storeId"` is present:
  - If has value, validate and assign.
  - If null, set `profile.StoreId = null`.

### 2. Frontend: `lib/features/admin/widgets/user_edit_sheet.dart`
- In `onSave`, update the ternary for `assignedStoreIds` to send `_selectedStoreIds` directly when role is `area_manager`, even if empty:
  ```dart
  assignedStoreIds: selectedRole == AppRoles.areaManager ? _selectedStoreIds : null,
  ```

### 3. Frontend: `lib/features/admin/widgets/user_create_sheet.dart`
- Similarly update the ternary for `assignedStoreIds`:
  ```dart
  assignedStoreIds: selectedRole == AppRoles.areaManager ? _selectedStoreIds : null,
  ```

## Verification Strategy
- Run the admin backend unit/integration tests to ensure no regressions:
  ```cmd
  cmd /c "cd server ; dotnet test --filter Category=Admin"
  ```
- Run the frontend tests:
  ```cmd
  cmd /c "cd lib ; flutter test test/features/admin"
  ```
