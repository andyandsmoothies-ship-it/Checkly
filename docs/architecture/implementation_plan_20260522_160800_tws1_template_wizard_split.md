<latent_space_scratchpad>
We are splitting `template_wizard_page.dart` (390 lines) to prevent exceeding the 400-line threshold.
Since `TemplateWizardPage` and its state class `_TemplateWizardPageState` are tightly coupled with the wizard state variables, controllers, and save triggers, we will use a `part` and `part of` pattern.
This allows us to write an extension `_TemplateWizardLogic` on `_TemplateWizardPageState` in the `template_wizard_page_logic.dart` file.
This extension will have direct access to all private variables and methods (like `setState`, `mounted`, `context`, etc.) without passing references or exposing state publicly.
Edge cases to watch:
1. Ensuring the imports in `template_wizard_page.dart` cover all types used in both the main file and the part file.
2. The `_stepTitles` list and `_totalSavedCriteria` getter can be accessed from the part file if needed, but since they are UI helpers, they can safely reside in the main file's build scope.
3. Ensuring no import statement is left in `template_wizard_page_logic.dart` as part files must not have imports (they inherit imports from the parent file).
4. Running the existing `wizard_payload_test.dart` to verify that our refactoring did not affect any model or business logic.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `lib/features/templates/pages/template_wizard_page.dart`

## Executive Summary & Out of Scope
The `template_wizard_page.dart` file contains 390 lines of code, close to the critical 400-line limit. To keep files small, highly cohesive, and easy for AI/human developers to maintain, we will split this file.
- **In Scope**:
  - Extract state-mutation logic (`_showBlueprintModal`, `_nextStep`, `_prevStep`, `_save`, `_markDirty`) into `template_wizard_page_logic.dart` using the `part`/`part of` pattern.
  - Retain the UI widget declarations, controllers, initState/dispose, and the `build` method in `template_wizard_page.dart`.
  - Validate that the code compiles perfectly with zero warnings/errors.
  - Run the existing wizard-related tests to guarantee no regressions.
- **Out of Scope**:
  - Rewriting wizard steps (`WizardStepName`, `WizardStepStructure`, etc.).
  - Changing API contracts or backend endpoints.
  - Adding new user-facing features or wizard steps.

## System Context
- **Offline/Online**: The page triggers local validation and calls `TemplateManager.saveTemplate` which supports offline persistence under the hood.
- **APIs**: Communicates via `TemplateManager` to POST / save template payloads.
- **RBAC**: Handled by app router and token assertions (not modified in this refactoring).
- **Logs**: Utilizes standard logging/error display via `ErrorDisplayService`.

## Lifecycle Context
- **Success State**: Transition to Step 5 (`Done` / `WizardStepSuccess`) with view/edit options after a successful save.
- **Error State**: Displays `AppError` in an error snackbar/dialog on API failures.
- **Empty State**: Starts with an empty section list after blueprint selection.
- **Loading State**: Displays loading states when `_saving` is `true`.

## Constraint Traceability
| Constraint | Source File / Rule | Test Contract ID | Description |
|---|---|---|---|
| Max 400 lines per file | GEMINI.md / global rules | TC-SIZE-01 | Splitting files to stay well under the line-count limits |
| Part-file compilation | Dart SDK specs | TC-COMP-01 | Verifies that parent file uses `part` and part file uses `part of` correctly |
| Functional parity | Codebase behavior | TC-TEST-01 | Asserts that wizard logic/tests still pass without regressions |

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-SIZE-01 | Verify `template_wizard_page.dart` has < 300 lines | Static check | Fails if the file remains at 390 lines or gets larger |
| TC-COMP-01 | Run `rtk flutter analyze` to prove compilation is perfectly clean | Compile check | Fails if part-of declaration lacks matching part statement, or has missing imports |
| TC-TEST-01 | Run `rtk flutter test test/features/templates/wizard_payload_test.dart` | Test check | Fails if the payload builder or scoring logic config throws runtime assertions |

## Test Fixture & Payloads
Since this is a structural refactor, we rely on the existing tests in `test/features/templates/wizard_payload_test.dart`. No new payloads are introduced.

## Tools & Commands
- **Required Skills**: `flutter-architecture`, `clean-architecture`
- **Commands to run**:
  - Test command: `rtk flutter test test/features/templates/wizard_payload_test.dart`
  - Analyze command: `rtk flutter analyze`

## Proposed Changes
| Status | File Path | Description |
|---|---|---|
| `[MOD]` | `lib/features/templates/pages/template_wizard_page.dart` | Keep imports and UI layout (Scaffold, AppBar, PageView, build). Declare `part 'template_wizard_page_logic.dart';` |
| `[NEW]` | `lib/features/templates/pages/template_wizard_page_logic.dart` | Declare `part of 'template_wizard_page.dart';`. Move extension methods `_showBlueprintModal`, `_nextStep`, `_prevStep`, `_save`, `_markDirty` here |

## Concept Diagram
```text
           [template_wizard_page.dart] (Main UI Page)
              ├── Imports & Main Widget Declarations
              ├── _TemplateWizardPageState variables, initState, dispose
              ├── build() UI Layout & appBar / PageView / bottomNavigationBar
              └── [part 'template_wizard_page_logic.dart';]
                               │
                               ▼
        [template_wizard_page_logic.dart] (Part of Main Page)
              ├── [part of 'template_wizard_page.dart';]
              └── extension _TemplateWizardLogic on _TemplateWizardPageState:
                   ├── _markDirty()
                   ├── _showBlueprintModal()
                   ├── _nextStep()
                   ├── _prevStep()
                   └── _save()
```

## Execution Slices (Micro-Specs)

### Execution Phase: Structural Split
- **Plain English Summary**: We will create `template_wizard_page_logic.dart`, add the `part of` directive, move all state-mutation methods to an extension on `_TemplateWizardPageState`, reference it via `part` inside `template_wizard_page.dart`, and delete the moved methods from `template_wizard_page.dart`.
- **Value Delivered**: Ensures compliance with the 400-line maximum file size rule, improves code scannability, and keeps logic separated from the UI presentation layer.
- **Entry State Required**: File `template_wizard_page.dart` exists with 390 lines. Code compiles with zero analyzer warnings.
- **Exit State Guaranteed**: Code compiles and analyzes with zero warnings. Both files are under 260 lines. All tests in `test/features/templates/wizard_payload_test.dart` pass successfully.
- **Acceptance Criteria**:
  1. `template_wizard_page.dart` has `< 260` lines.
  2. `template_wizard_page_logic.dart` has `< 150` lines.
  3. `rtk flutter analyze` passes with zero errors/warnings.
  4. `rtk flutter test test/features/templates/wizard_payload_test.dart` passes.

---

### Complexity: Low
This is a low-complexity refactoring task. The `part`/`part of` language-level feature guarantees compiler-enforced variable scoping and zero runtime performance overhead.

---

### Pros & Cons of the Split Pattern
- **Pros**:
  - Direct access to private states (`_sections`, `_currentStep`, etc.) without boilerplate or state management overrides.
  - Zero refactoring impact on other classes or pages.
  - File size drops by ~40% for the main UI file.
- **Cons**:
  - Tight coupling between the two files remains (by design of Dart part-files).

<command_logs>
- `rtk flutter test test/features/templates/wizard_payload_test.dart`
- `rtk flutter analyze`
</command_logs>

## Handoff Block
Next Phase: **Build Phase** for Execution Phase.
Input: `docs/architecture/implementation_plan_20260522_160800_tws1_template_wizard_split.md`
Action Sequence:
1. Create `lib/features/templates/pages/template_wizard_page_logic.dart` and populate it with `part of 'template_wizard_page.dart';` and the `_TemplateWizardLogic` extension.
2. Edit `lib/features/templates/pages/template_wizard_page.dart` to add `part 'template_wizard_page_logic.dart';` at line 22, and remove the moved state-mutation methods.
3. Verify compilation, run code analysis (`rtk flutter analyze`), and run tests (`rtk flutter test test/features/templates/wizard_payload_test.dart`).

## Risk Assessment
- **Structural Integrity**: Low risk. Dart part-files share the exact scope, so there's no risk of scope leaks or private field access failures.
- **Dependency Scope**: Zero risk. No external packages are installed or altered.
- **Performance Impact**: Zero risk. Pure compilation grouping without runtime overhead.

## Verification Plan
- **Verification Step 1**: Run `rtk flutter analyze` to verify the refactored code has zero compiler issues.
- **Verification Step 2**: Run `rtk flutter test test/features/templates/wizard_payload_test.dart` to verify template wizard state/models still function perfectly.
- **Verification Step 3**: Manually verify file lines count for both files to confirm compliance.

