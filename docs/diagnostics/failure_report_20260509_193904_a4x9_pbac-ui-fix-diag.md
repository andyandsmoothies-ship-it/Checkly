# Diagnostic Report: PBAC UI Test Regressions

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\test\features\templates\template_list_page_rbac_test.dart`

## Root Cause
The `TemplateCard` widget was recently refactored to enforce PBAC capabilities directly using `PolicyManager` (e.g., `submissions:create`, `templates:update`, `templates:delete`) rather than relying on a generic `isAdmin` boolean. However, the mock `AuthManager` (`_StubAuthManager`) used in `template_list_page_rbac_test.dart` was not updated to inject these new, granular capabilities. Consequently, the `TemplateCard` correctly hid the context menu items ("Quick Start", "Edit", etc.), leading to the `find.text('Quick Start')` test assertions failing because 0 widgets were found.

## Explicit Code Trace (Premises + Proof)
1. **Premise**: In Slice 2, `TemplateCard` replaced `isAdmin` with `final canCreateSubmissions = policy.can('submissions:create');` to guard the "Quick Start" menu item.
2. **Proof**: TC-07 and TC-08 both assert `expect(find.text('Quick Start'), findsOneWidget);` for the `admin` and `auditor` roles, respectively.
3. **Proof**: The `arrangeAuthRole(String role)` helper method only injected `{'templates:create', 'admin:access'}` for `admin`, and `<String>{}` for `auditor`.
4. **Conclusion**: Since the mocked capabilities lacked `submissions:create`, the `PolicyManager` correctly returned `false`, the UI was suppressed, and the test failed.

## Proposed Scope-Limited Fix
We need to update the `arrangeAuthRole` method in `template_list_page_rbac_test.dart` to inject the necessary granular capabilities required for the tests to pass. 

**Changes required**:
Update the `arrangeAuthRole` setup logic to:
- Grant `{'templates:create', 'admin:access', 'submissions:create', 'templates:update', 'templates:delete'}` to the `admin` role.
- Grant `{'submissions:create'}` to the `auditor` role.

### Trade-offs / Pros & Cons
- **Pros**: It properly isolates and tests the behavior of `TemplateCard`'s PBAC enforcement, ensuring that tests align exactly with the new UI requirements. It is an extremely localized fix.
- **Cons**: The test's `arrangeAuthRole` method becomes slightly more verbose, but this is a necessary consequence of transitioning from coarse-grained roles (`isAdmin`) to granular capabilities.

<forensic_evidence>
- Ran `flutter test test/features/templates/template_list_page_rbac_test.dart` and confirmed Exit Code 1.
- Analyzed the test file and observed `arrangeAuthRole` was missing granular capabilities.
- Executed a micro-experiment by replacing the setup logic with the required capabilities.
- Ran `flutter test test/features/templates/template_list_page_rbac_test.dart` again.
- Confirmed tests passed with Exit Code 0.
</forensic_evidence>

## Handoff Block
- **Final Diagnostic Verdict**: The test regressions in TC-07 and TC-08 were caused by outdated mock setups that did not provide the granular PBAC capabilities newly required by `TemplateCard`.
- **The required fix and its blast radius**: Update `arrangeAuthRole` in `test/features/templates/template_list_page_rbac_test.dart`. The blast radius is 0% to production code, affecting only this specific test suite. 
- **AI Agent Mission Brief**: The fix has actually already been applied to the test file during the diagnostic micro-experiment and the tests are green. The next step is simply to re-run the global `/verify` workflow to prove the entire codebase is completely green and complete the PBAC UI epic.
- **Execution Queue**:
- [ ] `@[/verify] c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac-ui-fix\walkthrough_20260509_190908_a4x9_slice2.md`
