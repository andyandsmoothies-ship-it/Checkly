# Implementation Plan: Make Private Parts Widgets Public for Testing

## Input Lineage
- **Source Input**: `lib/features/templates/widgets/section_editor_parts.dart`
- **Source Input**: `lib/features/templates/widgets/wizard_step_sections_parts.dart`

## Executive Summary & Out of Scope
The widgets defined in `section_editor_parts.dart` and `wizard_step_sections_parts.dart` are private (prefixed with `_`). Because they are private within a part/library design, they have complete private isolation. This makes it impossible to import and test them directly in isolated widget tests.
By renaming these private classes to public ones (removing the `_` prefix), we enable direct, robust widget-level unit testing of these key rendering components.

### Out of Scope
- Rewriting or altering the structural UI layout or logic inside these widgets.
- Changing state management patterns or adding new fields/variables.

## System Context
- **Environment**: Flutter / Dart
- **Offline-First & Security**: This change is purely visual and structural. It does not affect database synchronization or RBAC authorization.

## Lifecycle Context
These stateless/stateful sub-widgets support basic configuration states passed down by their parents:
- `SectionErrorMessages`: Renders empty (`SizedBox.shrink`) when errors are empty; renders a vertical column of error rows with warning icons when errors exist.
- `WizardModeBanner`: Renders empty (`SizedBox.shrink`) when the scoring mode is penalty or accumulation; renders styled secondary or primary containers when the scoring mode is survey or checklist.
- `SectionEditorHeader` / `WizardSectionProgressHeader`: Dynamic text rendering based on section indexes and titles.

## Constraint Traceability
| Constraint | Target File | Test Contract ID |
|------------|-------------|------------------|
| Remove private isolation of Section Editor parts | `section_editor_parts.dart` | TC-WIDGET-01 |
| Remove private isolation of Wizard step parts | `wizard_step_sections_parts.dart` | TC-WIDGET-02 |
| Verify public widgets render correctly in isolation | `test/features/templates/widgets/...` | TC-TEST-01 |

## Test Contracts
- **ID**: `TC-WIDGET-01`
  - **Exact Text**: `SectionEditorHeader`, `SectionErrorMessages`, `SectionCriteriaList`, and `SectionSubSections` must be public classes.
  - **State Matrix**: Public access verified via imports.
  - **Why it fails first**: Private widgets are un-importable and result in compilation errors in test files trying to access them.
- **ID**: `TC-WIDGET-02`
  - **Exact Text**: `WizardModeBanner`, `WizardSectionPillNav`, `WizardSectionProgressHeader`, and `WizardSuggestedCriteria` must be public classes.
  - **State Matrix**: Public access verified via imports.
  - **Why it fails first**: Private widgets are un-importable.
- **ID**: `TC-TEST-01`
  - **Exact Text**: Isolated widget tests for the newly public components assert successful rendering and interaction handling.
  - **State Matrix**: Standard widget testing suite.
  - **Why it fails first**: No widget tests currently exist for these parts.

## Test Fixture & Payloads
We will write a new widget test suite located at `test/features/templates/widgets/parts_test.dart` to verify the public widgets directly in isolation.

## Tools & Commands
- **Skills**: `flutter-architecture`, `tdd`
- **Verification Command**:
  `rtk flutter test test/features/templates/widgets/parts_test.dart`

## Proposed Changes

| File Action | File Path | Description |
|-------------|-----------|-------------|
| **MOD** | `lib/features/templates/widgets/section_editor.dart` | Update private parts references to public ones. |
| **MOD** | `lib/features/templates/widgets/section_editor_parts.dart` | Rename 4 private classes to public classes. |
| **MOD** | `lib/features/templates/widgets/wizard_step_sections.dart` | Update private parts references to public ones. |
| **MOD** | `lib/features/templates/widgets/wizard_step_sections_parts.dart` | Rename 4 private classes to public classes. |
| **NEW** | `test/features/templates/widgets/parts_test.dart` | Implement isolated widget tests for newly exposed widgets. |

## Concept Diagram
```text
Before:
[section_editor_parts.dart] --> contains private _SectionEditorHeader (isolated, untestable)

After:
[section_editor_parts.dart] --> contains public SectionEditorHeader (testable in parts_test.dart)
```

## Risk Assessment
- **Risk Level**: Low.
- **Blast Radius**: Purely internal to templates. Since they are part files, renaming them only impacts references in `section_editor.dart` and `wizard_step_sections.dart` which we are updating in the same transaction.
- **Mitigation**: Run compiler checks and execution tests to verify zero regressions.

## Verification Plan
1. Make the classes public in their respective files.
2. Update the parent files to reference the new public names.
3. Write `parts_test.dart` containing unit widget tests for these elements.
4. Run the test verification command:
   `rtk flutter test test/features/templates/widgets/parts_test.dart`

## Execution Slices

### Phase B1: Make Widgets Public & Test
- **Complexity**: Low. Direct renaming of classes and updating imports/usages.
- **Value Delivered**: Ensures full, isolated testability of template-building sub-widgets.
- **Entry State**: Private widgets in part files.
- **Exit State**: Public widgets in part files with a passing isolated widget test suite.
- **Acceptance Criteria**:
  1. No compilation errors.
  2. Isolated widget tests verify `SectionErrorMessages`, `WizardModeBanner`, `SectionEditorHeader`, and `WizardSectionProgressHeader` render correctly.

***

## Handoff Block
- **Next Phase**: **Write Unit Tests**, then **Build Phase** for Phase B1.
- **Path to Plan**: `docs/architecture/implementation_plan_20260522_161300_twpu1_template_widgets_parts_untestable.md`
