---
conversation_id: "43a6d3be-90b3-4a93-b845-d4413b14705f"
type: "concept_brief"
topic: "store-management-redesign"
created_at: "2026-06-05T11:15:00+07:00"
---

# Concept Brief: Store Management Page Redesign

## 1. Context & Goal
The current Admin Store Management page has inconsistent UI patterns compared to the rest of the Admin console:
*   It lacks search capabilities.
*   It lacks status filtering (Active / Inactive / All).
*   The creation button ("+") is located in the AppBar, whereas the User Management page uses a Floating Action Button (FAB).
*   The overall layout needs visual alignment with the User Management page for consistent, premium aesthetics.

The goal is to align the Store Management page layout, search mechanism, status filtering, and action entries with the established patterns of the User Management page.

---

## 2. Visual Layout (ASCII Mockup)

```
+-------------------------------------------------+
| < (Back)              Store Management          |
+-------------------------------------------------+
|                                                 |
|  [ Q Search by store name or address...      ]  |
|                                                 |
|  [ Status: All v ]                              |
|                                                 |
|  +-------------------------------------------+  |
|  | (🏪) Checkly Binh Thanh - Landmark 81     |  |
|  |      o Vinhomes Central Park, Binh Th...  |  |
|  |      o SM: Store Manager 1                |  |
|  |                                           |  |
|  |      [ Active ]                           |  |
|  +-------------------------------------------+  |
|  | (🏪) Checkly D1 - Bui Vien                |  |
|  |      o Bui Vien, District 1...            |  |
|  |      o SM: Store Manager 10               |  |
|  |                                           |  |
|  |      [ Active ]                           |  |
|  +-------------------------------------------+  |
|  ...                                            |
|                                                 |
|                                            ( + )|
+-------------------------------------------------+
```

---

## 3. Structural & Functional Changes

### A. Search Bar Implementation
*   **Widget:** Styled `TextField` matching the search bar of `UserManagementPage`.
*   **Properties:** Rounded corners (`BorderRadius.circular(16)`), Nunito font, leading `Icons.search`, trailing clear button (visible when query is not empty).
*   **Trigger:** Triggers API loading on submit via `_onSearch()`.

### B. Status Filter Pill & Modal Bottom Sheet
*   **Widget:** `DropdownFilterPill` with label "Status" and displaying the selected status ("All", "Active", "Inactive").
*   **Action:** Tapping it triggers `showStoreStatusFilterSheet`, a modal bottom sheet matching `showUserRoleFilterSheet` in look and feel.
*   **Logic:** Filter applies client-side dynamically to the retrieved stores list, keeping operations snappy and lightweight.

### C. Floating Action Button (FAB)
*   **Change:** Remove the "+" icon from the AppBar actions.
*   **Replacement:** Add a green circle `FloatingActionWidget` (FAB) in the Scaffold:
    *   `backgroundColor`: `AppColors.featherGreen`
    *   `foregroundColor`: `Colors.white`
    *   `shape`: `CircleBorder()`
    *   `onPressed`: Triggers `showStoreFormSheet()`

### D. Empty States
*   Maintain the existing `ChecklyEmptyState` but update its copy to point users to the new FAB instead of the previous AppBar icon.

---

## 4. Affected Layers & Files

### State Manager
*   `[MOD] lib/features/admin/manager/admin_store_manager.dart`
    *   Add `String? search` to the `load({String? search})` signature.
    *   Forward `search` to `StoreApiService.getStores(includeInactive: true, search: search)`.

### UI Components
*   `[NEW] lib/features/admin/pages/widgets/store_status_filter_sheet.dart`
    *   New modal bottom sheet displaying the filter options: "All Stores", "Active", and "Inactive".
    *   Includes counts for each option dynamically using the retrieved store list.
*   `[MOD] lib/features/admin/pages/store_management_page.dart`
    *   Refactor Scaffold layout: implement search `TextField`, `DropdownFilterPill` for Status, and move the creation flow to a FAB.
    *   Hook status filtering and search triggers to the list builder.
*   `[MOD] lib/features/admin/pages/widgets/store_card.dart`
    *   Minor styling polish if necessary to match margins and padding of the user cards.
