# Task: Fix Program Create Wizard UX Issues

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_172548_a1b2c3d4_program_wizard_ux.md`

## Decision Log
- **Emergency Close Button**: Added an `IconButton` with `Icons.close` directly to the `actions` array of the `AppBar` in `program_create_wizard_page.dart`. This ensures users can exit the wizard at any point.
- **Asynchronous Data Loading**: Modified `_pickTemplate()` to open the `showModalBottomSheet` immediately and fire `_templateManager.loadTemplates()` asynchronously without blocking.
- **Dynamic State Handling**: Refactored `TemplatePicker` to accept `TemplateManager` instead of a static list. Wrapped its body in a `ListenableBuilder` to responsively render `CircularProgressIndicator` on load, surface actual error strings + a retry button on failure, and display an actionable prompt when empty.
- **Quality Improvement**: Cleaned up two minor `flutter analyze` non-null assertion warnings in `program_store_selector_page.dart` while modifying adjacent code.

## Verification Handoff
- The UI handles all loading states seamlessly without locking the interface.
- 440 tests are passing.

<test_trace>
00:15 +156: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/pages/inbox_page_test.dart: InboxPage ??? Tab Filtering TC1.2b: All tab shows all notifications (read + unread)             
00:15 +157: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/pages/inbox_page_test.dart: InboxPage ??? Tab Filtering TC1.2b: All tab shows all notifications (read + unread)             
00:18 +264: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: (setUpAll)                                                                                 
00:43 +440: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)                                                                                     
00:43 +440: All tests passed!
</test_trace>

<forensic_evidence>
cmd /c rtk flutter analyze lib/features/programs 2>&1
Analyzing programs...                                           
No issues found! (ran in 3.1s)
</forensic_evidence>

## Gotcha Protocol
- No new Gotchas identified. `ListenableBuilder` with `ChangeNotifier` remains the primary UI update pattern for Managers.
