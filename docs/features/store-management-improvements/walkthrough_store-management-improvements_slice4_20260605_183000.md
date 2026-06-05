---
ConversationID: 43a6d3be-90b3-4a93-b845-d4413b14705f
---

# Walkthrough: Store Management Improvements - Slice 4

This walkthrough details the changes verified in Slice 4 (UI Filters Integration).

## Technical Changes

### Store Management Page Filters
File: `lib/features/admin/pages/store_management_page.dart`
- Integrated `DropdownFilterPill` widgets for Province, District, and Manager filters.
- Wired tap handlers to trigger custom bottom sheets:
  - `showStoreProvinceFilterSheet`
  - `showStoreDistrictFilterSheet`
  - `showStoreManagerFilterSheet`
- District filter requires selection of a province first, failing which it raises a warning snackbar.
- Evaluated `hasUnassigned` to pass to the district filter sheet, allowing admins to select "Unassigned / Other" if any stores have empty/null districts under the selected province.

### District Filter Bottom Sheet
File: `lib/features/admin/pages/widgets/store_district_filter_sheet.dart`
- Leverages `StoreApiService.fetchDistricts` to retrieve dynamic list of districts for the chosen province.
- Offers an option for "Unassigned / Other" mapped to the special value `'Unassigned'` when `hasUnassigned` is true.
- Updates `AdminStoreManager.selectedDistrict` state and refreshes the store list.

## Decision Log
- **District Dependency on Province**: To avoid overwhelming dropdowns, we strictly enforce selecting a Province before selecting a District.
- **Unassigned Fallback**: District filtering by "Unassigned / Other" maps to `'Unassigned'` string value to handle stores with null or empty district records.

## Verification Handoff

Run the Flutter unit tests verifying the filters behavior:
```powershell
cmd /c "rtk proxy flutter test test/features/admin/pages/store_management_page_test.dart"
```

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/store_management_page_test.dart
00:00 +0: renders search input, status filter pill, and store cards
00:01 +3: status filter sheet filters stores list client-side
00:01 +4: displays empty states appropriately
00:01 +5: validates coordinates range and formatting on store save
00:02 +6: shows loading indicator and prevents double-taps during toggle active
00:03 +7: province filter selection loads districts and updates province filter pill
00:03 +8: district filter triggers warning SnackBar when no province is selected, and allows selection when selected
00:03 +9: manager filter selection updates manager filter pill and triggers api filter
00:03 +10: changing province clears selected district
00:04 +11: district filter shows Unassigned option and filters by Unassigned
00:04 +12: All tests passed!
</test_trace>

<forensic_evidence>
Ran `flutter analyze` ensuring zero compiler/linter warnings. Removed unused imports in `test\_shared\services\geocoding_service_test.dart` and `test\features\admin\pages\store_management_page_test.dart`.
</forensic_evidence>
