# Walkthrough - Template Builder Page Logic Split

## Input Lineage
- **Source Input**: `docs/architecture/implementation_plan_20260522_160800_tbls1_template_builder_logic_split.md`

## Decision Log
- **Proposed**: Split `template_builder_page_logic.dart` (395 lines) into three parts to strictly enforce file size limits (<400 lines).
- **Implemented**: Created `template_builder_page_validation.dart` for validation routines and `template_builder_page_mutations.dart` for mutations/computed properties. Cleaned up `template_builder_page_logic.dart` to only contain loading, serializing, and saving logic. All are declared under the shared `part` system of `template_builder_page.dart`.

## Verification Handoff
To verify this safe refactoring:
1. Compile the project.
2. Run standard Flutter and Dart tests. No compiler errors or warnings should appear.
3. Interact with the template builder in the UI; verify adding sections, validating fields, and saving templates work smoothly.

<test_trace>
```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart
00:00 +0: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-1: TemplateApiService.createTemplate exists createTemplate method is callable on TemplateApiService
00:00 +1: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-2: TemplateManager.saveTemplate exists saveTemplate method is callable on TemplateManager
00:00 +2: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-3: TemplateManager.deleteTemplate exists deleteTemplate method is callable on TemplateManager
00:00 +3: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-4: Edit template route templates/edit route is wired — TemplateBuilderPage accepts any ID
00:00 +4: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-5: TemplateBuilderPage has editable form page contains TextFormField for title (not read-only Text)
00:00 +5: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-6: Scoring rules card page has 5 scoring rule SwitchListTiles
00:00 +6: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-6: Scoring rules card page has AP Deadline and Reminder number inputs
00:00 +7: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-7: Section and Criteria editor page has Add Section button
00:00 +8: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-7: Section and Criteria editor page has Add Criteria button per section
00:00 +9: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: AC-8: Template footer page has fixed footer with Save button
00:00 +10: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: GREEN — Existing infrastructure TemplateBuilderPage class exists
00:00 +11: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: GREEN — Existing infrastructure TemplateBuilderPage accepts templateId parameter
00:00 +12: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: GREEN — Existing infrastructure TemplateTreeDto has scoringLogicConfig field
00:00 +13: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: GREEN — Existing infrastructure GroupDto can be constructed for new section
00:00 +14: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: GREEN — Existing infrastructure CriterionDto can be constructed for new criterion
00:00 +15: C:/Users/HP/Documents/GitHub/Checkly/test/template_creation_test.dart: GREEN — Existing infrastructure TemplateApiService has group and criteria CRUD
00:00 +16: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:01 +17: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders toggle in ON state when confirmRequired is true
00:04 +18: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: (setUpAll)
00:04 +18: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:04 +19: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:04 +20: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:04 +21: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:04 +22: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:04 +23: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:05 +24: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06b: FAB is hidden for area_manager role
00:05 +25: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06c: FAB is visible only for admin role
00:05 +26: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 3 items
00:05 +27: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-08: Context menu auditor does not see context menu
00:06 +28: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: (tearDownAll)
00:06 +28: All tests passed!
```
</test_trace>

<forensic_evidence>
```bash
rtk flutter test test/template_creation_test.dart
rtk flutter analyze
```
Executed both test suite and static analysis tools. Analysis returned `No issues found!`.
</forensic_evidence>

## Gotcha Protocol
No additional quirks were found during refactoring; standard Flutter `part`/`part of` conventions were used correctly.
