---
ConversationID: "98883c69-9a72-433e-88d5-9df601e48cd1"
---

# Walkthrough: Geocoding Query Fix

## Input Lineage
- **Task Tracker**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\geocoding-query-fix\task_geocoding-query-fix_20260606_110000.md`
- **Source Code**: `c:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\pages\widgets\store_form_sheet.dart`

## Decision Log
- **Problem**: When a user selects "Locate on Map" for a store with a legacy/unstructured address and a selected province (but empty street, ward, and district fields), the search query defaulted strictly to the province name. This caused Nominatim to return the coordinates of the center of the province (e.g. Da Nang or Binh Dinh province center) rather than searching for the specific store address.
- **Implemented Fix**: We updated the query construction logic in `store_form_sheet.dart` to check if the structured address fields (street, ward, district) are completely empty. If they are empty but the legacy Address field is populated, the search query prioritizes using the Address field directly. Otherwise, it falls back to constructing the query from the structured fields and selected province as before.

## Verification Handoff
- **Automated Verification**: Run the updated widget test suite:
  ```cmd
  flutter test test/features/admin/pages/store_management_page_test.dart
  ```
- **Manual Verification**:
  1. Open a Store Edit form.
  2. Enter `"7 Nguyen Tat Thanh, Quy Nhon, Binh Dinh"` in the legacy "Address" field.
  3. Ensure "Province" dropdown is set to `"Bình Định"`, but "Street", "Ward", and "District" are left empty/unfilled.
  4. Click the **Locate on Map** button.
  5. The map marker should jump to the exact coordinates in Quy Nhon (near the coast) rather than jumping to a mountainous province center.

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/store_management_page_test.dart
00:00 +0: renders search input, status filter pill, and store cards
00:00 +1: hides FAB when storesWrite capability is false
00:01 +2: triggering search submits correct search term to API
00:01 +3: status filter sheet filters stores list client-side
00:01 +4: displays empty states appropriately
00:01 +5: validates coordinates range and formatting on store save
00:02 +6: shows loading indicator and prevents double-taps during toggle active
00:02 +7: province filter selection loads districts and updates province filter pill
00:02 +8: manager filter selection updates manager filter pill and triggers api filter
00:02 +9: Locate on Map button geocodes combined address and updates map coordinates
00:03 +10: Locate on Map button uses legacy address when structured address fields are empty
00:03 +11: Map tap reverse geocodes coordinates and auto-populates address fields
00:04 +12: Map tap on un-addressable region preserves coordinates and shows warning SnackBar
00:04 +13: successful store creation dismisses form sheet and triggers onSaved
00:04 +14: All tests passed!
</test_trace>

<forensic_evidence>
1. Search context: Found query construction logic in `store_form_sheet.dart` line 440-450 using `grep_search`.
2. Code change: Modified query construction to check `streetController.text.trim().isEmpty && wardController.text.trim().isEmpty && districtController.text.trim().isEmpty`. If true and `addressController.text.trim().isNotEmpty`, use `addressController.text.trim()`.
3. Command execution: Ran `flutter test test/features/admin/pages/store_management_page_test.dart` which ran all 14 tests, including our newly added test: `Locate on Map button uses legacy address when structured address fields are empty`.
</forensic_evidence>

## Gotcha Protocol
- None required for this local bugfix.
