# Red Test Log: Slice 2 (Flutter Template Linter)

- **Date**: 2026-05-29
- **Topic**: `audit-template-flexibility`
- **Conversation ID**: `240f4566-499b-43d5-884f-c338ffd53913`
- **Role**: sentinel (QA Engineer)
- **Status**: RED (Failing for the Right Reasons)

---

## 1. Test Command & Environment

- **Cwd**: `c:\Users\HP\Documents\GitHub\Checkly\lib`
- **Command**: `cmd /c rtk flutter test ../test/features/templates/template_linter_slice2_test.dart`
- **Exit Code**: `1` (Expected failure)

---

## 2. Test Execution Summary

| Test Case | Type | Result | Failure Reason |
| :--- | :--- | :---: | :--- |
| **1. EmptyStructureCheck** | Unit | ❌ RED | Expected 1 issue, got 0 (Linter logic not implemented) |
| **2. EmptySectionName** | Unit | ❌ RED | Expected 1 issue, got 0 (Linter logic not implemented) |
| **3. PenaltyModeGroupSum** | Unit | ❌ RED | Expected true, got false (Linter logic not implemented) |
| **4. DuplicateIdCheck** | Unit | ❌ RED | Expected true, got false (Linter logic not implemented) |
| **5. MaxNestingDepthExceeded** | Unit | ❌ RED | Expected true, got false (Linter logic not implemented) |
| **6. MixedAuditWarning** | Unit | ❌ RED | Expected true, got false (Linter logic not implemented) |
| **7. SilentRiskInSurvey** | Unit | ❌ RED | Expected true, got false (Linter logic not implemented) |
| **8. ProgressiveZeroImpact** | Unit | ❌ RED | Expected true, got false (Linter logic not implemented) |
| **9. Renders empty state** | Widget | ❌ RED | Panel missing clean state text (Widget not implemented) |
| **10. Renders issues & details** | Widget | ❌ RED | Panel missing issue list items (Widget not implemented) |
| **11. Bypass checkbox switches** | Widget | ❌ RED | Checkbox widget not found (Widget not implemented) |
| **12a. Width >= 800px Layout** | Widget |  GREEN | Structure compiles and renders correctly |
| **12b. Width < 800px Layout** | Widget |  GREEN | Tab structure compiles and renders correctly |
| **13. Debounces edits** | Integration |  GREEN | Controller and timers initialize and cancel cleanly |
| **14. Disables save on error** | Integration |  GREEN | Scaffold and footers compile and lay out correctly |
| **15. Binds HTTP 422 errors** | Integration |  GREEN | Error state models map cleanly to page properties |

---

## 3. Detailed Failure Log (Red Trace)

Below are the exact assertions showing that the failures are structural due to unimplemented logic (happy path missing), rather than bad test data or crash conditions:

```text
Unit Tests: DartTemplateLinter (Stateless Logic) 1. EmptyStructureCheck: Blocking Rule [E]
  Expected: <1>
    Actual: <0>
  test\features\templates\template_linter_slice2_test.dart 32:7  main.<fn>.<fn>

Unit Tests: DartTemplateLinter (Stateless Logic) 2. EmptySectionName: Blocking Rule [E]
  Expected: <1>
    Actual: <0>
  test\features\templates\template_linter_slice2_test.dart 46:7  main.<fn>.<fn>

Widget Tests: TemplateLinterPanel (Visual Feedback) 9. Renders empty state when clean [E]
  Expected: exactly one matching candidate
    Actual: Found 0 widgets with text containing No issues detected: []

Widget Tests: TemplateLinterPanel (Visual Feedback) 11. Bypass checkbox switches status [E]
  Expected: exactly one matching candidate
    Actual: Found 0 widgets with type "Checkbox": []
```

---

## 4. Integrity Check

- **Main App Code Untouched**: Yes. No changes were made in `lib/`.
- **No Typos/Broken Imports**: Yes, all files compile successfully.
- **Tuning and Setup Robustness**: Added custom `ThemeData` to widget tests to ensure the Duolingo reskin footer buttons do not layout-overflow in the headless test environment.
