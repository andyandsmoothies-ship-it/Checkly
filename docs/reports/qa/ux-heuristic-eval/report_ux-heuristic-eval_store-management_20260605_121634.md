---
conversation_id: "196516cd-9f45-4144-9eb4-14a4e0a8f483"
---

# UX Heuristic Evaluation Report: Store Management

- **Scope**: Store Management Page, Store Card, Store Form Sheet
- **User Group**: Admin
- **Device Type**: Mobile (offline-first)

---

## 1. Executive Summary

| Heuristic | Rating | Status | Summary |
|---|---|---|---|
| H1: Visibility of system status | ⚠️ Minor (2) | Warning | Lack of visual lock during async store activation/deactivation. |
| H2: Match between system & real world | ✅ Good (0) | Compliant | UI copy matches real-world conventions (Province, District, Ward). |
| H3: User control and freedom | ✅ Good (0) | Compliant | Form has UnsavedChangesGuard to prevent accidental close. |
| H4: Consistency and standards | ✅ Good (0) | Compliant | Search, filters, cards, and FAB match the rest of the Admin console. |
| H5: Error prevention | ❌ Major (3) | Violation | GPS input fields lack coordinate range validation. |
| H6: Recognition rather than recall | ✅ Good (0) | Compliant | Empty states clearly suggest what action to take (e.g., tap FAB). |
| H7: Flexibility and efficiency of use | ⚠️ Minor (2) | Warning | Setting coordinates requires manually tapping map or copying/pasting. |
| H8: Aesthetic and minimalist design | ✅ Good (0) | Compliant | High-contrast premium StrokeCards and PillChips used. |
| H9: Help users recover from errors | ⚠️ Minor (2) | Warning | Invalid lat/lng entries silently fall back to null instead of informing user. |
| H10: Help and documentation | ✅ Good (0) | Compliant | Screen is self-explanatory. |

---

## 2. Key Findings

### H5: GPS Out-Of-Bounds Values Saved Silently
- **Severity**: 3 (Major)
- **Location**: `StoreFormSheet` -> `store_form_save_logic.dart`
- **Issue**: There is no validation on latitude/longitude text inputs. If a user enters invalid numbers (e.g. `95.0` for latitude, or `190.0` for longitude), the database accepts them or the app parses them and saves them silently. This can break map renderings and location queries.
- **Recommendation**: Add coordinate checks inside `saveStore()`:
  * Latitude must be between `-90` and `90`.
  * Longitude must be between `-180` and `180`.

### H9: Silently Dropping Invalid GPS Formatting
- **Severity**: 2 (Minor)
- **Location**: `StoreFormSheet` -> `store_form_save_logic.dart`
- **Issue**: If a user enters text that cannot be parsed as a double (e.g. `12.34abc`), `double.tryParse` returns `null` and the app silently saves the coordinate as `null` without notifying the user that their input was discarded.
- **Recommendation**: Add validation alerts for invalid double format inputs in the coordinates fields.

### H1: Concurrency Race Condition on Store Deactivation
- **Severity**: 2 (Minor)
- **Location**: `StoreManagementPage` -> `_toggleActive()`
- **Issue**: When a user clicks "Deactivate" or "Activate" in the popup menu, the async request starts. During this time, the card and its controls are not disabled, allowing double-clicks or multiple actions in parallel.
- **Recommendation**: Disable the card interactions or show a loading indicator on the specific card while activation/deactivation is in progress.

### H7: Lack of "Use Current GPS Location" Shortcut
- **Severity**: 2 (Minor)
- **Location**: `StoreFormBody`
- **Issue**: Creating or editing a store at the actual physical site requires manually positioning the map marker or typing coordinates. There is no quick action to fill GPS coordinates using the device's GPS hardware.
- **Recommendation**: Add a "Use Current GPS" shortcut button next to the GPS fields to dynamically grab device location and populate the text fields.

---

## 3. Top 3 Fix Priorities

1. **Implement Coordinate Range Validation (H5)**: Validate that latitude is within `[-90, 90]` and longitude is within `[-180, 180]`.
2. **Warn on Invalid Number Inputs (H9)**: Display a validation snackbar or warning if double parsing fails for coordinate fields.
3. **Disable Actions During Toggle (H1)**: Prevent parallel toggle API requests by adding a local loading lock.
