---
ConversationID: 43a6d3be-90b3-4a93-b845-d4413b14705f
---

# Walkthrough: Store Management Improvements - Slice 2

This walkthrough details the changes made in Slice 2 (Frontend API and Manager Wiring).

## 1. Technical Changes

### Admin API Service
File: `lib/features/admin/services/admin_api_service.dart`
- Updated the `getUsers` method signature to accept an optional `String? role` parameter.
- Appended `role` to the request query parameters when calling `/admin/users` to allow listing of users filtered by role.

### Store API Service
File: `lib/features/stores/services/store_api_service.dart` (Completed prior to Slice 2 logic wiring)
- Extended `getStores` method signature to support `province`, `district`, and `managerName`.
- Added the `fetchDistricts(String province)` service method calling `/reference/districts`.

### Admin Store Manager
File: `lib/features/admin/manager/admin_store_manager.dart`
- Added state properties for active filters:
  - `String? selectedProvince;`
  - `String? selectedDistrict;`
  - `String? selectedManagerName;`
- Updated the `load` method to pass active filters to the backend store search endpoint via `StoreApiService.getStores`.
- Implemented state updates and reload trigger methods:
  - `setProvince(String?)` — sets the selected province, clears the selected district (to prevent invalid district selections for a new province), and reloads the store list.
  - `setDistrict(String?)` — sets the selected district and reloads the store list.
  - `setManagerName(String?)` — sets the selected manager name query and reloads the store list.
  - `clearFilters()` — resets all filter values and reloads the store list.

## 2. Test Verification

Run the Flutter unit tests to verify proper manager behavior:
```powershell
cmd /c "rtk proxy flutter test ../test/features/admin/manager/admin_store_manager_test.dart"
```

All 6 test cases passed, confirming:
- Initial state has null filters.
- `load` includes active filters in API requests.
- `setProvince` successfully clears any selected district.
- `setDistrict`, `setManagerName`, and `clearFilters` update the state and trigger reloading correctly.
