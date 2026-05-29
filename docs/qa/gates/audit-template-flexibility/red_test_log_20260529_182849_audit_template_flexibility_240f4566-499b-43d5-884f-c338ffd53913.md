# Red Test Log: Slice 3 - Live Score Simulator

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-flexibility\analysis_epic_20260529_104152_audit_template_flexibility_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md`

## Overview

The TDD widget and responsive layout test suite `test/features/templates/template_linter_slice3_test.dart` has been executed against compilation stubs. All tests compiled successfully but failed cleanly on assertions because the real feature logic is not yet built by the Builder.

---

## Test Executed Command

```cmd
rtk flutter test test/features/templates/template_linter_slice3_test.dart
```

---

## Failures Output

```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_linter_slice3_test.dart
00:00 +0: (setUpAll)
00:00 +0: Widget Tests: LiveScoreSimulator 1. All criteria passing -> simulator shows 100%
EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextContainingWidgetFinder:<Found 0 widgets with text containing 100.00%: []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_linter_slice3_test.dart:51:7)
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)

This was caught by the test expectation on the following line:
  file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_linter_slice3_test.dart line 51
The test description was:
  1. All criteria passing -> simulator shows 100%
```

---

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_linter_slice3_test.dart
00:00 +0: (setUpAll)
00:00 +0: Widget Tests: LiveScoreSimulator 1. All criteria passing -> simulator shows 100%
EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextContainingWidgetFinder:<Found 0 widgets with text containing 100.00%: []>
   Which: means none were found but one was expected
</test_trace>

<forensic_evidence>
- run_command: cmd /c rtk flutter test ../test/features/templates/template_linter_slice3_test.dart
- Created stub file: lib/features/templates/pages/widgets/live_score_simulator.dart
- Verified file paths:docs/qa/gates/audit-template-flexibility/red_test_log_20260529_182849_audit_template_flexibility_240f4566-499b-43d5-884f-c338ffd53913.md
</forensic_evidence>
