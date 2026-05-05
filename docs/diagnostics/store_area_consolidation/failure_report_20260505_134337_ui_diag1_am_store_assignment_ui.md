what# Failure Report: AM Detail Page Still Shows Area and Missing Store Assignment

## Input Lineage
- **Source Input**: User report & attached screenshot `media__1777956998290.png` showing "ASSIGNED AREA" on the AM detail page, with no multi-store picker.

## Root Cause
The Slice 5 implementation (Admin UI) was incomplete. While the developer correctly refactored the backend payload mappings to pass `virtualAreaId` instead of `areaId`, they failed to implement the corresponding User Experience changes mandated by the Epic. 

Specifically:
1. The label for the Virtual Area shortcut remained `ASSIGNED AREA`, confusing users by making it look like the old 1-to-1 Area hierarchy was still in effect.
2. The UI entirely omitted the required multi-store selection component (a chip array or checklist) that would allow Admins to select specific individual stores for an Area Manager, despite the backend explicitly supporting the `assignedStoreIds` array payload in both `updateUser` and `createUser`.

## Explicit Code Trace (Premises + Proof)
1. **Premise**: The Admin backend API accepts `assignedStoreIds`. 
   **Proof**: Traced to `admin_user_manager.dart` (lines 135 & 188), `saveUser` and `createUser` correctly accept a `List<String>? assignedStoreIds` parameter.
2. **Premise**: The `UserEditSheet` and `UserCreateSheet` widgets do not utilize `assignedStoreIds`.
   **Proof**: Traced to `user_edit_sheet.dart` (lines 200-246). The `area_manager` role only displays a single `DropdownCard` bound to `selectedAreaId` with the label `ASSIGNED AREA`. The `onSave` callback signature inside `user_edit_sheet.dart` (line 33) does not even contain the `assignedStoreIds` parameter.
3. **Premise**: `loadStores` is required for Area Managers to have stores to pick from.
   **Proof**: Currently, `_loadStores()` inside `user_edit_sheet.dart` is conditionally executed *only* when the role switches to `store_manager`.

<forensic_evidence>
- `view_file` -> `docs/architecture/store_area_consolidation/analysis_epic_20260503_215500_2b21e338_area_override.md` (Confirmed Epic mandate).
- `view_file` -> `lib/features/admin/widgets/user_create_sheet.dart` (No multi-store picker).
- `view_file` -> `lib/features/admin/widgets/user_edit_sheet.dart` (No multi-store picker, missing onSave param).
- `grep_search` -> `saveUser` in `lib/features/admin/` (Confirmed backend capability).
- `view_file` -> `lib/features/admin/manager/admin_user_manager.dart` (Confirmed `assignedStoreIds` parameter exists).
</forensic_evidence>

## Proposed Scope-Limited Fix

**Fix Overview**: Implement a Multi-Store Picker component and update the "Virtual Area" dropdown to clearly communicate its batch-assignment purpose.

**Steps**:
1. **UX Refresh**: Update the existing `DropdownCard` for `virtualAreaId` to label it as `BATCH ASSIGN BY VIRTUAL AREA (Shortcut)`.
2. **Multi-Store Picker**: Implement a new UI component in `UserEditSheet` and `UserCreateSheet` (e.g., a Wrap of `FilterChip` widgets or a custom checklist dialog) that allows Admins to explicitly multi-select stores.
3. **State Management**: Modify the local state of both sheets to track `List<String> selectedStoreIds` for Area Managers. Ensure that `_loadStores()` is called when the role switches to *either* `store_manager` or `area_manager`.
4. **Data Piping**: Update the `onSave` and `onCreate` signatures in the sheets to include `List<String>? assignedStoreIds` and pipe that value down to `AdminUserManager`.

### Trade-offs / Pros & Cons
- **Pros**: Perfectly satisfies the Epic requirements; provides Admins with full granular control over store assignments while maintaining the Virtual Area shortcut.
- **Cons**: Requires building a new multi-select UI component since Flutter lacks a built-in `MultiSelectDropdown`. This slightly increases the complexity of the bottom sheets.

---

## Handoff Block

**1. Final Diagnostic Verdict & Persistent Path**
The UI failed to expose the backend's direct store assignment capability. 
*Path*: `docs/diagnostics/store_area_consolidation/failure_report_20260505_134337_ui_diag1_am_store_assignment_ui.md`

**2. Required Fix & Blast Radius**
Add a Multi-Store Picker to the bottom sheets and relabel the Virtual Area dropdown. 
*Blast Radius*: Localized purely to `user_edit_sheet.dart`, `user_create_sheet.dart`, and their immediate parent `user_management_page.dart`. No backend or database changes required.

**3. AI Agent Mission Brief**
The backend already supports `assignedStoreIds` for Area Managers. Your mission is to update `UserEditSheet` and `UserCreateSheet` to include a Multi-Store Picker (e.g., Wrap with FilterChips), relabel the Virtual Area dropdown to clarify it's a batch shortcut, and pipe the selected `assignedStoreIds` array through `UserManagementPage` to the `AdminUserManager`.

**4. Execution Queue**
- [ ] `@[/implement] docs/diagnostics/store_area_consolidation/failure_report_20260505_134337_ui_diag1_am_store_assignment_ui.md`
