---
conversation_id: "196516cd-9f45-4144-9eb4-14a4e0a8f483"
---

# Walkthrough: Store Management Redesign

This walkthrough documents the technical modifications and implementation details for the Store Management Redesign.

## 1. Architecture Overview

A simple representation of the architecture flow:
`[UI] <--> [AdminStoreManager] <--> [StoreApiService] <--> [Backend API]`

- **`StoreManagementPage`**: The view layer that renders the search bar, filter pill, store cards, and FAB.
- **`AdminStoreManager`**: A state manager using the Pragmatic Flutter Architecture (PFA) manager pattern, maintaining the loading state, lists of stores, and triggering API queries.
- **`StoreApiService`**: The backend communication layer mapping CRUD store operations.

## 2. Technical Modifications

### A. View Layer: `StoreManagementPage`
- Replaced local states (`_stores`, `_isLoading`) with a reference to `AdminStoreManager`.
- Wrapped the content body with `ListenableBuilder` to reactively update the UI when the manager state shifts.
- Aligned custom filter elements (`DropdownFilterPill` and `showStoreStatusFilterSheet`) with Checkly design standards and added unique key selectors to assist in widget tests.
- Replaced the direct use of standard cards with theme-compliant design tokens, utilizing `Theme.of(context).extension<ChecklyThemeTokens>()` to style lists and widgets.

### B. Widget: `StoreCard` & `StoreStatusFilterSheet`
- Refactored `StoreCard` to render as a `StrokeCard` using custom theme values.
- Integrated `PillChip` for displaying the active/inactive status.
- Added `Key('store_status_filter_sheet')` to the filter sheet to allow targeted testing without colliding with store status indicators in the background view.

### C. Logic: `AdminStoreManager`
- Implemented state handling for loading indicators, error recovery states, and local caching of retrieved stores.
- Built-in search debouncing hooks and integrated the API calls cleanly.

### D. Testing: `store_management_page_test.dart`
- Leveraged `mocktail` for mocking of dependency services.
- Added tests verifying search submission, client-side status filtering, capabilities-based FAB rendering, and displays of empty states.
- Utilized `find.byWidgetPredicate` to bypass class representation duplicates caused by relative vs package import paths.
