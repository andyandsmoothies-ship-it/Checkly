# Executed Tests: Phase B Wizard & Store Selector UI

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md`

## Test Results

```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/pages/program_create_wizard_page_test.dart
test/features/programs/pages/program_create_wizard_page_test.dart:1:8: Error: Error when reading 'lib/features/programs/pages/program_create_wizard_page.dart': The system cannot find the file specified
import 'package:checkly/features/programs/pages/program_create_wizard_page.dart';
       ^
test/features/programs/pages/program_create_wizard_page_test.dart:6:8: Error: Error when reading 'lib/features/templates/managers/template_manager.dart': The system cannot find the path specified
import 'package:checkly/features/templates/managers/template_manager.dart';
       ^
test/features/programs/pages/program_create_wizard_page_test.dart:10:51: Error: Type 'TemplateManager' not found.
class MockTemplateManager extends Mock implements TemplateManager {}
                                                  ^^^^^^^^^^^^^^^
test/features/programs/pages/program_create_wizard_page_test.dart:20:31: Error: 'TemplateManager' isn't a type.
    GetIt.I.registerSingleton<TemplateManager>(mockTemplateManager);
                              ^^^^^^^^^^^^^^^
test/features/programs/pages/program_create_wizard_page_test.dart:29:13: Error: Method not found: 'ProgramCreateWizardPage'.
      home: ProgramCreateWizardPage(),
            ^^^^^^^^^^^^^^^^^^^^^^^
test/features/programs/pages/program_create_wizard_page_test.dart:68:14: Error: Undefined name 'ProgramCreateWizardPage'.
      expect(ProgramCreateWizardPage, isNotNull);
             ^^^^^^^^^^^^^^^^^^^^^^^

test/features/programs/pages/program_store_selector_page_test.dart:1:8: Error: Error when reading 'lib/features/programs/pages/program_store_selector_page.dart': The system cannot find the file specified
import 'package:checkly/features/programs/pages/program_store_selector_page.dart';
       ^
test/features/programs/pages/program_store_selector_page_test.dart:8:13: Error: Method not found: 'ProgramStoreSelectorPage'.
      home: ProgramStoreSelectorPage(),
            ^^^^^^^^^^^^^^^^^^^^^^^^
test/features/programs/pages/program_store_selector_page_test.dart:17:14: Error: Undefined name 'ProgramStoreSelectorPage'.
      expect(ProgramStoreSelectorPage, isNotNull);
             ^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -2: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/pages/program_store_selector_page_test.dart [E]
```

Tests have failed correctly at compile time due to missing `ProgramCreateWizardPage` and `ProgramStoreSelectorPage` widgets, ensuring the Builder has a strictly defined target.
