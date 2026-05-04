# Task: Store Assignment Issues
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\services\admin_api_service.dart`

## Root Cause
There are two distinct root causes matching the two symptoms:

**1. UI Does Not Refresh Store Name (Symptom 1):**
When an admin assigns a store manager to a store, the Dart View calls `admin_user_manager.saveUser`. On success, it receives a payload from `PUT /api/admin/users/{id}` and runs an optimistic `_applyUserUpdate(id, updated)` to merge the server response into the local state. 
However, the `UpdateUser.cs` endpoint only returns `{ storeId: X }` and omits `storeName`. The `users[idx] = {...users[idx], ...updated};` spread operator updates the ID correctly but silently preserves the stale `storeName` (usually null or the previous store's name). The View is bound to `storeName`, causing it to never refresh until a full page reload is triggered.

**2. Assigned Store Still Appears in Dropdown (Symptom 2):**
The `ListStores.cs` backend endpoint successfully filters out stores that are already assigned when the `assignable_as=store_manager` query parameter is passed. 
However, the `UserEditSheet._loadStores()` method in Dart calls `widget.loadStores()` without passing *any* arguments. This causes the backend to default to fetching ALL active stores, bypassing the assignment filter entirely. It also fails to pass `exceptUser: widget.user['id']`, meaning even if the filter was active, the user's currently assigned store would be erroneously excluded from their own edit dropdown.

## Explicit Code Trace (Premises + Proof)
**Proof for Symptom 1 (`UpdateUser.cs` line 169):**
```csharp
        return TypedResults.Ok(new
        {
            id = profile.Id,
            role = userRole.Role,
            storeId = profile.StoreId,
            areaId = profile.AreaId,
            transferred = request.ForceReassign && previousManagerName != null,
            previousManagerName,
            // MISSING: storeName = targetStore.Name
        });
```

**Proof for Symptom 2 (`user_edit_sheet.dart` line 88):**
```dart
  Future<void> _loadStores() async {
    try {
      // BUG: Fails to pass assignableAs and exceptUser
      final stores = await widget.loadStores();
      if (mounted) setState(() => assignableStores = stores);
```

## Proposed Scope-Limited Fix

**Fix 1: Backend Payload Enrichment (`server/Features/Admin/UpdateUser.cs`)**
Modify `UpdateUser.cs` to fetch `targetStore.Name` and `targetArea.Name` during validation, and append `storeName` and `areaName` to the `TypedResults.Ok()` response payload.
*Trade-offs:* Zero performance impact as `targetStore` is already loaded via EF Core `.FirstOrDefaultAsync` for validation. Provides the exact contract the frontend optimistic updater expects.

**Fix 2: Frontend Parameter Passing (`lib/features/admin/widgets/user_edit_sheet.dart`)**
Update `_loadStores()` inside the `UserEditSheet` to pass the correct arguments:
```dart
      final stores = await widget.loadStores(
        assignableAs: 'store_manager',
        exceptUser: widget.user['id'] as String,
      );
```
*Trade-offs:* Strictly enforces the business rule without needing a backend change. Requires no new API endpoints.

<forensic_evidence>
- Tested raw SQL `SELECT s.id, s.name FROM stores s WHERE s.id NOT IN ...` to confirm EF Core's LINQ query logic works correctly.
- Traced `admin_user_manager.dart`'s `saveUser` optimistic merge map logic.
- Identified `user_edit_sheet.dart` calling `loadStores()` with no arguments.
</forensic_evidence>

## Handoff Block

**Final Diagnostic Verdict & Persistent path:**
The bug is caused by a mismatched API contract (backend omitting display names) and a missing parameter pass in the frontend `UserEditSheet`. 

**Blast Radius:**
Minimal. Modifying the `UpdateUser.cs` payload adds non-breaking fields to the JSON. Updating `user_edit_sheet.dart` is localized to the admin UI dropdown.

**AI Agent Mission Brief:**
Implement the proposed fixes in `UpdateUser.cs` to return `storeName` and `areaName`, and update `user_edit_sheet.dart` to pass `assignableAs` and `exceptUser` parameters to `loadStores()`.

**Execution Queue:**
- [ ] @[/implement] docs/diagnostics/failure_report_20260503_210931_store_assignment.md
