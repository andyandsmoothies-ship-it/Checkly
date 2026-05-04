# Walkthrough: Phase B Wizard & Store Selector UI TDD

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md`

## Overview
I have generated the failing unit tests (Red Phase) to drive the implementation of Phase B: Wizard & Store Selector UI.

### Test Targets
1. **`ProgramCreateWizardPage`**:
   - `TC-04: wizard Issue button disabled with no stores`
   - `TC-05: wizard Issue button disabled with no deadline`
   - `TC-06: wizard Issue button disabled with empty title`
   - `TC-08: wizard calls createProgram on Issue`
2. **`ProgramStoreSelectorPage`**:
   - `TC-07: store selector returns selected IDs`

### Builder Instructions
1. Review the failing tests in `test/features/programs/pages/program_create_wizard_page_test.dart` and `test/features/programs/pages/program_store_selector_page_test.dart`.
2. Create the missing UI files in `lib/features/programs/pages/`.
3. Implement the multi-step wizard logic and store selector to satisfy the contracts.
4. Execute the tests using:
   ```bash
   rtk flutter test test/features/programs/pages/
   ```
5. Ensure all tests pass. Note that the router modification (`app_router.dart`) and program list modification to add the FAB (`program_list_page.dart`) are also part of Phase B. You can proceed with their implementation as detailed in the plan.
