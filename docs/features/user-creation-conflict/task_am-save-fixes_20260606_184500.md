---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
Type: task
Topic: am-save-fixes
Date: 2026-06-06
---

# Tasks: Fix Area Manager and Store Manager Save Bugs

- [x] Implement backend changes in `server/Features/Admin/UpdateUser.cs`
  - [x] Support `JsonElement requestJson` parsing to distinguish explicit null vs omitted fields.
  - [x] If role transitions away from `area_manager`, delete entries in `ProfileStoreAssignments`.
  - [x] If role transitions away from `store_manager`, clear `profile.StoreId = null`.
  - [x] If role is `store_manager` and `storeId` is explicitly provided as null, clear `profile.StoreId = null`.
- [x] Implement frontend changes in `lib/features/admin/widgets/user_edit_sheet.dart`
  - [x] Send `_selectedStoreIds` directly when role is `area_manager`.
- [x] Implement frontend changes in `lib/features/admin/widgets/user_create_sheet.dart`
  - [x] Send `_selectedStoreIds` directly when role is `area_manager`.
- [x] Verify changes
  - [x] Verify backend tests pass.
  - [x] Verify frontend tests pass.
