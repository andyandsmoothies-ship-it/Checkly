# Task List: Smart Audit Safeguards Slice 4

- [ ] Update `TemplateDto` and `TemplateTreeDto` models in `lib/features/templates/models/template_dto.dart`
- [ ] Map geofence settings from database rows to models in `lib/_shared/database/dao/template_dao.dart`
- [ ] Add geofence bypass fields, getters, setters, and state clearing in `lib/features/audit/manager/audit_manager.dart`
- [ ] Map geofence bypass fields in companion insertion in `lib/features/audit/manager/audit_manager_submit.dart`
- [ ] Implement `showGeofenceBlockDialog` and `showGeofenceWarningDialog` in `lib/features/audit/widgets/audit_form_dialogs.dart`
- [ ] Refactor the submission flow `_onSubmit` inside `lib/features/audit/pages/audit_form_page.dart` to perform bimodal geofence checks
- [ ] Run Drift database code generator using build runner
- [ ] Implement unit and widget tests for geofence enforcement and outbox database persistence
- [ ] Run test suite (`dotnet test` and `flutter test`) to verify all checks pass cleanly
