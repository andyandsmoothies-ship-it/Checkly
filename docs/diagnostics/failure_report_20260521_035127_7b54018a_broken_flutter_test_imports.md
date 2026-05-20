# Failure Report: Broken Flutter Test Imports after File Splits
**Date:** 2026-05-21T03:51:27+07:00

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\verification_20260521_034746_7b54018a_verify_global_audit_remediation.md`

## Root Cause
During the architectural remediation phase, `app_router.dart` and `main_shell.dart` were refactored (split) into smaller files (`auth_redirect.dart` and `shell_tab.dart`) to comply with the 400-line strict limit (SC-3 and SC-4). However, the corresponding test files (`app_router_test.dart` and `app_router_rbac_test.dart`) were not updated with the new imports for these extracted utility functions.

## Explicit Code Trace (Premises + Proof)
1. **Symptom:** `flutter analyze` failed with:
   - `The function 'shellActiveIndexFromLocation' isn't defined - test\_shared\router\app_router_test.dart`
   - `The function 'authRedirect' isn't defined - test\router\app_router_rbac_test.dart`
2. **Origin trace:** 
   - A `grep_search` confirmed that `shellActiveIndexFromLocation` now lives in `lib\_shared\router\shell_tab.dart`.
   - A `grep_search` confirmed that `authRedirect` now lives in `lib\_shared\router\auth_redirect.dart`.
3. **Conclusion:** The test files are missing imports to the new file locations.

## Proposed Scope-Limited Fix
We need to add the missing imports to the test files.

**Test 1:** `test\_shared\router\app_router_test.dart`
Add `import 'package:checkly/_shared/router/shell_tab.dart';`

**Test 2:** `test\router\app_router_rbac_test.dart` (or wherever it exactly is, probably `test\_shared\router\app_router_rbac_test.dart`)
Add `import 'package:checkly/_shared/router/auth_redirect.dart';`

**Trade-offs / Pros & Cons:**
- **Pros:** Fast and trivially fixes the compilation error. 
- **Cons:** None. It's a mandatory build-fix.

<forensic_evidence>
- `grep_search` on `shellActiveIndexFromLocation` found it in `lib\_shared\router\shell_tab.dart`
- `grep_search` on `authRedirect` found it in `lib\_shared\router\auth_redirect.dart`
- Ran verification on previous step that yielded `flutter analyze` exit code 1.
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict & Persistent path:** 
   Tests are missing imports caused by file splitting. 
   Path: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260521_035127_7b54018a_broken_flutter_test_imports.md`
2. **The required fix and its blast radius:** 
   Add missing imports to two test files. Blast radius: zero impact on production code, localized only to the test suite.
3. **AI Agent Mission Brief:** 
   Open `test\_shared\router\app_router_test.dart` and `test\router\app_router_rbac_test.dart` (or `test\_shared\router\app_router_rbac_test.dart`) and add the missing imports to `shell_tab.dart` and `auth_redirect.dart` respectively so `flutter analyze` passes.
4. **Execution Queue:**
   - [ ] Execute Build Phase: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260521_035127_7b54018a_broken_flutter_test_imports.md`
