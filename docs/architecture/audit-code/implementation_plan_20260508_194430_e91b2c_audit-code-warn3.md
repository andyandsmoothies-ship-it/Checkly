<latent_space_scratchpad>
This task splits a single UI file with 5 classes into 5 separate files + 1 utility file, inside a new directory. Then we replace the original file with a barrel file to export them all so the parent page doesn't need to change its imports.
The complexity is very low, pure file extraction.
Files to create:
- lib/features/programs/widgets/program_wizard_steps/step_info.dart
- lib/features/programs/widgets/program_wizard_steps/step_template.dart
- lib/features/programs/widgets/program_wizard_steps/step_stores.dart
- lib/features/programs/widgets/program_wizard_steps/step_review.dart
- lib/features/programs/widgets/program_wizard_steps/template_picker.dart
- lib/features/programs/widgets/program_wizard_steps/wizard_utils.dart (for `formatWizardDate`)
- lib/features/programs/widgets/program_wizard_steps.dart (barrel file)
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit-code\audit_code_report_20260508_183708_4cf3f41a_audit-code.md` (WARN-3)

## Executive Summary & Out of Scope
`program_wizard_steps.dart` contains 5 distinct wizard step widget classes, breaching the Single Responsibility Principle and padding the file length unnecessarily. We will extract each widget into its own file under a `program_wizard_steps/` folder and replace the original file with a barrel file.

**Out of Scope**:
- We will not change any UI behavior, state management, or validation rules.
- We will not modify `program_create_wizard_page.dart` (the barrel file keeps the import contract intact).

## System Context
- **Architecture**: Flutter widgets. Pure UI components.
- **Offline/Online**: Fully local UI components relying on injected data or managers.

## Lifecycle Context
- **Empty/Success**: Each wizard step maintains its current local and injected state just as before.

## Risk Assessment
Risk is extremely low. This is a pure syntactic refactoring. Blast radius is contained strictly to the file structure within `lib/features/programs/widgets/`.

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-1 | Wizard steps load without import errors | N/A | Code is moved to new files. |

## Verification Plan
Run `flutter analyze` to verify that all imports are correct and `program_create_wizard_page.dart` still resolves the classes correctly.

## Test Fixture & Payloads
- **Fixture**: N/A (Standard Flutter Widget refactoring).

## Tools & Commands
- **Testing**: `flutter analyze`
- **Linting**: `flutter analyze`

## Proposed Changes
- `[DEL]` `lib/features/programs/widgets/program_wizard_steps.dart` (original 369-line file)
- `[NEW]` `lib/features/programs/widgets/program_wizard_steps/wizard_utils.dart`
- `[NEW]` `lib/features/programs/widgets/program_wizard_steps/step_info.dart`
- `[NEW]` `lib/features/programs/widgets/program_wizard_steps/step_template.dart`
- `[NEW]` `lib/features/programs/widgets/program_wizard_steps/step_stores.dart`
- `[NEW]` `lib/features/programs/widgets/program_wizard_steps/step_review.dart`
- `[NEW]` `lib/features/programs/widgets/program_wizard_steps/template_picker.dart`
- `[NEW]` `lib/features/programs/widgets/program_wizard_steps.dart` (barrel file exporting all)

## Concept Diagram
`[program_wizard_steps.dart (369 lines)]` 
--> `[program_wizard_steps.dart (barrel)]`
  --> `[step_info.dart]`
  --> `[step_template.dart]`
  --> `[step_stores.dart]`
  --> `[step_review.dart]`
  --> `[template_picker.dart]`

## Execution Slices

### Execution Phase: Extract Classes
- **Plain English Summary**: Create a new directory and extract the 5 widgets and 1 utility method into separate files. Re-create the original file as a barrel file to export them.
- **Value Delivered**: Resolves SRP violations and decreases cognitive load when maintaining individual wizard steps.
- **Entry/Exit State**:
  - Entry: One massive file with 5 classes.
  - Exit: 6 small files logically grouped and exported via a barrel.
- **Scope**: `lib/features/programs/widgets/`.
- **Acceptance Criteria**: `flutter analyze` passes perfectly.
- **Complexity**: Low. Simple file extraction.
- **Pros & Cons**: 
  - *Pro*: Highly maintainable, testable in isolation.
  - *Con*: More files in the directory tree.

<command_logs>
- `view_file` on `program_wizard_steps.dart`
- `grep_search` on `program_wizard_steps.dart`
</command_logs>

## Handoff Block
The plan is ready to execute.
@[/implement] Execute build for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_194430_e91b2c_audit-code-warn3.md
