---
ConversationID: "e4a8d231-abcb-46c0-ae41-613c2d8ed2c0"
---
# Walkthrough: Smart Audit Safeguards Slice 4 Implementation

[UI Page Submission] --> [Geofence Proximity Validation]
                               |
              +----------------+----------------+
              | (Lax Mode)                      | (Strict Mode)
              v                                 v
      [Warning Dialog]                 [Blocking Dialog]
              |                                 |
     (Accept / Bypass)                  (Always Abort)
              v
     [Save to Outbox]
     - captures GPS Coordinates
     - writes isGeofenceBypassed & distanceMetersOff to SQLite

---

## Technical Summary of Work Done

We successfully implemented **Slice 4: Mobile Proximity Warning and Strict Geofence UI Integration** for the **Smart Audit Safeguards** feature.

### 1. Template Models and Mapping Extensions
* **File Edited:** [template_dto.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/models/template_dto.dart)
  * Added `geofenceMode` and `geofenceRadiusMeters` properties to `TemplateDto` and `TemplateTreeDto`.
  * Configured optional parameters with defaults (`geofenceMode = 'none'` and `geofenceRadiusMeters = 100`) to guarantee backwards compatibility and prevent breaking existing code seeders and widget tests.
* **File Edited:** [template_dao.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/_shared/database/dao/template_dao.dart)
  * Mapped geofence parameters from SQLite `CachedTemplates` rows to domain DTOs inside `_rowToTemplateDto`, `_templateToCompanion`, and `getTemplateTree`.

### 2. Audit Execution Manager Extensions
* **File Edited:** [audit_manager.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/audit/manager/audit_manager.dart)
  * Added `_isGeofenceBypassed` (bool) and `_distanceMetersOff` (int?) telemetry fields.
  * Added `isGeofenceBypassed` and `distanceMetersOff` getters, along with a `setGeofenceBypass` setter.
  * Extended `startAudit` and `reset` to clear the bypass parameters.

### 3. SQLite Outbox Telemetry Insertion
* **File Edited:** [audit_manager_submit.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/audit/manager/audit_manager_submit.dart)
  * Mapped the `isGeofenceBypassed` and `distanceMetersOff` values to the generated companion fields of `PendingSubmissionsCompanion` when writing to the SQLite database outbox.

### 4. Warning and Blocking Dialogs
* **File Edited:** [audit_form_dialogs.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/audit/widgets/audit_form_dialogs.dart)
  * Implemented high-quality `showGeofenceBlockDialog` and `showGeofenceWarningDialog` widgets containing responsive location metrics, custom icons, clear messaging, and bypass controls.

### 5. Submission Flow Integration
* **File Edited:** [audit_form_page.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/audit/pages/audit_form_page.dart)
  * Imported `GpsService`, `GeofenceService`, and `StoreManager`.
  * Refactored `_onSubmit` method to perform bimodal verification before submitting. It retrieves the store's coordinates, performs validation via `GeofenceService`, and intercepts submissions appropriately:
    * **Strict mode**: Blocks with blocking dialog and halts submission.
    * **Lax mode**: Warns with warning dialog. If the user decides to bypass, it sets geofence bypass parameters in the manager and proceeds; otherwise, it halts.
    * Captures precise GPS coordinates using `GpsService` post-validation.

---

## Verifying Implementation with Automated Tests

1. **Unit and Integration Tests**:
   * **File:** [audit_manager_submit_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/audit/manager/audit_manager_submit_test.dart)
   * Added `TC-11-06` to verify that `setGeofenceBypass` correctly updates the bypass flags and `reset` clears them.
   * Added `TC-11-07` to verify that `submitAudit` correctly forwards geofence bypass telemetry to the SQLite database outbox companion.
   * All tests passed!

2. **Global Verification Suite**:
   * Ran `flutter test` - **818 tests passed successfully!**
   * Ran `dotnet test` - **All server tests compiled and passed perfectly!**
