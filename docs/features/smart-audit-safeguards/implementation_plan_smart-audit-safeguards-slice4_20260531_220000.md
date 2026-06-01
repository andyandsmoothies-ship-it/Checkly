# Implementation Plan - Smart Audit Source Safeguards (Slice 4)

## Architecture Flow

```
[Auditor Taps "Submit"]
        │
        ▼
[ showSubmitConfirmDialog ]
        │
        ├── (Cancel) ──► [Abort Submission]
        ▼ (Submit)
[ Get Store Lat/Lng & Template Geofence Mode ]
        │
        ▼
[ GeofenceService.validate ] ──► (none / In Range) ──► [Submit Audit]
        │
        ├── (strict & Out of Range / GPS Error) ──► [showGeofenceBlockDialog] ──► [Abort]
        │
        └── (lax & Out of Range / GPS Error) ──► [showGeofenceWarningDialog]
                                                        │
                                                        ├── (Cancel) ──► [Abort]
                                                        ▼ (Bypass)
                                            [manager.setGeofenceBypass]
                                                        │
                                                        ▼
                                                 [Submit Audit]
```

## Proposed Changes

### 1. Data Transfer Objects (DTOs)
Add `geofenceMode` and `geofenceRadiusMeters` properties to `TemplateDto` and `TemplateTreeDto` in `lib/features/templates/models/template_dto.dart`.

### 2. Local Database Access Object (DAO)
Update `template_dao.dart` to map the `geofenceMode` and `geofenceRadiusMeters` fields from `CachedTemplate` to `TemplateDto` and `TemplateTreeDto`.

### 3. Drift Database Tables & Schema Compilation
Update `PendingSubmissions` companion insertion inside `lib/features/audit/manager/audit_manager_submit.dart` to persist the geofence telemetry fields `isGeofenceBypassed` and `distanceMetersOff`.

### 4. Audit Execution Manager
- Add fields `_isGeofenceBypassed` (bool) and `_distanceMetersOff` (int?) with public getters to `AuditManager` in `lib/features/audit/manager/audit_manager.dart`.
- Clear/reset them in `startAudit()` and `reset()`.
- Add a setter method: `void setGeofenceBypass({required bool isBypassed, int? distanceMetersOff})`.

### 5. UI Dialogs
Add `showGeofenceBlockDialog` and `showGeofenceWarningDialog` inside `lib/features/audit/widgets/audit_form_dialogs.dart` to display warning and block interstitials with modern, premium styling.

### 6. Submission Page Flow Integration
Update `_onSubmit` method inside `lib/features/audit/pages/audit_form_page.dart` to evaluate proximity checks via `GeofenceService`, intercept out-of-range states, show warnings or blocks accordingly, and log bypass flags before completing the transaction.

## Verification & Testing Plan
- Run Drift database `build_runner` to compile database extensions.
- Write isolated unit tests in `test/features/audit/manager/audit_manager_submit_test.dart` to assert outbox mapping of geofence parameters.
- Write widget/integration tests in a new file `test/features/audit/geofence_sub_test.dart` or expand existing test files to verify strict block and lax warning dialog sequences.
- Run complete test suites (`dotnet test` and `flutter test`) to ensure zero-regression compliance.
