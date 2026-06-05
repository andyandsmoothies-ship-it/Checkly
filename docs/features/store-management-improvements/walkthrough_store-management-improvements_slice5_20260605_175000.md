# Walkthrough: Store Management Improvements - Slice 5

This walkthrough documents the validation and testing of Slice 5, which completes the Two-Way Map-Address Form Sync.

## Features Verified

1. **Locate on Map**: Auto-populates coordinates via geocoding when the user inputs an address and presses the "Locate on Map" button.
2. **Reverse Geocoding on Map Tap**: Tap on map reverse-geocodes coordinate values and populates address elements (Street, Ward, District, Province, Display Name).
3. **Un-addressable Region Warning**: Tapping an un-addressable coordinate (e.g. water) preserves coordinates and displays a warning SnackBar instead of failing or clearing input values.
4. **Interactive Loading Guards**: Map actions disable form buttons and show appropriate loaders during active requests.

## Code Changes

### `lib/features/admin/pages/widgets/store_form_body.dart`
- Added dynamic state tracking for province selection in the dropdown using a custom `ValueKey` to ensure proper rebuilds and state preservation under widget tests.

## Test Verification

Executed tests in `test/features/admin/pages/store_management_page_test.dart` and confirmed all passed:
- `Locate on Map button geocodes combined address and updates map coordinates` (Passed)
- `Map tap reverse geocodes coordinates and auto-populates address fields` (Passed)
- `Map tap on un-addressable region preserves coordinates and shows warning SnackBar` (Passed)
