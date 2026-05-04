# Task: Store Assignment Issues Fix

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260503_210931_store_assignment.md`

## Decision Log

### Fix 1 — Backend Payload Enrichment (`UpdateUser.cs`)
- **Proposed**: Add `storeName` and `areaName` to the `TypedResults.Ok` response.
- **Implemented**: 
  - `storeName` is captured from `targetStore.Name` inside the existing `if (request.StoreId.HasValue)` block — zero additional DB queries.
  - `areaName` fetches `db.Areas.AsNoTracking()` only when `AreaId` is provided, consistent with how the store is fetched.
- **Trade-off**: The area fetch is one extra lightweight query per `UpdateUser` call when `AreaId` is set. Acceptable — this is a low-frequency admin action, not a hot path.

### Fix 2 — Frontend Parameter Pass (`user_edit_sheet.dart`)
- **Proposed**: Pass `assignableAs: 'store_manager'` and `exceptUser: widget.user['id']` to `loadStores()`.
- **Implemented**: Exactly as proposed. The widget callback signature already accepted these named parameters (confirmed at line 18-22 of `UserEditSheet`).
- **Trade-off**: None. The backend filter was already implemented and tested — the frontend was just not using it.

## Verification Handoff
Manual test steps:
1. Open Admin > Users, edit a Store Manager.
2. Verify the store dropdown **shows the user's own current store** (exceptUser works).
3. Verify the dropdown **does not show stores already assigned to another SM** (assignableAs filter works).
4. Save — verify the store name refreshes immediately in the user list **without a page reload** (storeName in response).
5. Edit an Area Manager, save — verify the area name refreshes (areaName in response).

<test_trace>
00:13 +156: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/pages/inbox_page_test.dart: InboxPage ? Tab Filtering TC1.2b: All tab shows all notifications (read + unread)
00:14 +156: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/pages/inbox_page_test.dart: InboxPage ? Tab Filtering TC1.2b: All tab shows all notifications (read + unread)
00:16 +264: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: (setUpAll)
00:47 +440: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)
00:47 +440: All tests passed!
</test_trace>

<forensic_evidence>
rtk flutter analyze lib/features/admin/widgets/user_edit_sheet.dart
Analyzing user_edit_sheet.dart... No issues found! (ran in 2.5s)

rtk dotnet build --no-restore | findstr "error CS"
(no CS compiler errors — only file-lock MSB3027/MSB3021 from live dotnet run process)

rtk flutter test --reporter compact | findstr "All tests passed"
+440: All tests passed!
</forensic_evidence>

## Gotcha Protocol
- **New Gotcha: dotnet build blocked by live server process**: When `dotnet run` is active, `rtk dotnet build` will fail with MSB3027/MSB3021 file-lock errors. These are NOT compile errors. Filter with `findstr "error CS"` to confirm the Roslyn compilation itself is clean.
