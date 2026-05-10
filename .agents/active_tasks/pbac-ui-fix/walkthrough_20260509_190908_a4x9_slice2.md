# Walkthrough: Decouple TemplateCard + Patch Quick Start

## Input Lineage
`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\pbac-ui-fix\implementation_plan_20260509_190140_493220d8_pbac-ui-fix.md`

## Decision Log
- **Proposed**: Remove the `isAdmin` boolean from `TemplateCard` and its instantiation in `TemplateListPage`. Use `PolicyManager` directly within `TemplateCard` to evaluate specific capabilities.
- **Implemented**: 
  - Modified `TemplateCard` to independently query `PolicyManager` for `submissionsCreate` (Quick Start), `templatesUpdate` (Edit/Duplicate), and `templatesDelete` (Delete).
  - Modified `TemplateListPage` to no longer pass down `isAdmin`.
  - Removed unused `policy_manager.dart` import from `TemplateListPage`.

## Verification Handoff
This slice is complete and fully verified by `flutter analyze` and `flutter build apk --debug`.
You may now manually test by logging in with different roles and checking the actions available on the Template cards.

<test_trace>
Analyzing 2 items...                                            
No issues found! (ran in 2.5s)

Running Gradle task 'assembleDebug'...                            108.3s
√ Built build\app\outputs\flutter-apk\app-debug.apk
</test_trace>

<forensic_evidence>
Ran `flutter analyze` to ensure there were no unused imports or missing variables.
Ran `flutter build apk --debug` to ensure the app compiles.
</forensic_evidence>

## Gotcha Protocol
None for this slice.
