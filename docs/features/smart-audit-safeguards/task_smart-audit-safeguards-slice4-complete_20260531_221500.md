---
ConversationID: "e4a8d231-abcb-46c0-ae41-613c2d8ed2c0"
---
# Task List: Smart Audit Safeguards Slice 4 (COMPLETED)

- [x] Update `TemplateDto` and `TemplateTreeDto` models in `lib/features/templates/models/template_dto.dart`
- [x] Map geofence settings from database rows to models in `lib/_shared/database/dao/template_dao.dart`
- [x] Add geofence bypass fields, getters, setters, and state clearing in `lib/features/audit/manager/audit_manager.dart`
- [x] Map geofence bypass fields in companion insertion in `lib/features/audit/manager/audit_manager_submit.dart`
- [x] Implement `showGeofenceBlockDialog` and `showGeofenceWarningDialog` in `lib/features/audit/widgets/audit_form_dialogs.dart`
- [x] Refactor the submission flow `_onSubmit` inside `lib/features/audit/pages/audit_form_page.dart` to perform bimodal geofence checks
- [x] Run Drift database code generator using build runner
- [x] Implement unit and widget tests for geofence enforcement and outbox database persistence
- [x] Run test suite (`dotnet test` and `flutter test`) to verify all checks pass cleanly
