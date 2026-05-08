# Task: WARN-5 Magic Strings in WizardStepReview
Workflow: /analyze-feature | Track: B1

## Input Lineage
- **Source Input**: `docs/diagnostics/audit-code/audit_code_report_20260508_183708_4cf3f41a_audit-code.md` (WARN-5)

## Executive Summary & Out of Scope
**Goal**: Eliminate magic string literal comparisons (`'penalty'`, `'survey'`) in `wizard_step_review.dart` by converting its `scoringMode` property to use the strongly-typed `ScoringMode` enum.

**Out of Scope**: 
- A full refactoring of the `_scoringMode` state variable inside `TemplateBuilderPage` and `TemplateWizardPage`. The blast radius of converting every single child widget (`WizardStepName`, `WizardStepStructure`, `SectionEditor`, `MetadataFormCard`) to `ScoringMode` is too high for this warning. We will only harden the boundary of `WizardStepReview` as targeted by the audit.
- Modifying `AdvancedSettingsCard` signature (it will continue to accept a `String`, and we will pass `widget.scoringMode.name` to it).

## System Context
- **Layer**: Presentation / UI (Templates Feature).
- **Architecture**: Enforces strong typing at the widget input boundary to prevent typos in business logic (like checking `isScored` or `isSurvey`).

## Lifecycle Context
- **N/A**: This is a pure typing and syntactic refactor. No state transitions are altered.

## Risk Assessment
**Risk Level**: Low.
We are changing a single property type from `String` to an `enum` and using a `switch` expression. The caller (`template_wizard_page.dart`) will be updated to map its internal string to the enum before passing it down. The only risk is a mapping failure if the string is invalid, which is mitigated by using an `orElse` fallback.

## Test Contracts
| ID | Description | Initial State | Trigger | Expected Outcome |
|---|---|---|---|---|
| TC-1 | Mode Label Mapping | `_scoringMode = 'accumulation'` | Widget mounts | Label renders as 'Training Assessment (Accumulation)' |
| TC-2 | Fallback Mapping | `_scoringMode = 'invalid'` | Widget mounts | Safely falls back to `ScoringMode.penalty` |

## Verification Plan
1. Run `flutter analyze lib/features/templates` to verify zero type mismatches.
2. Manually open the Template Wizard, navigate to Step 4 (Review), and verify the "Mode" row displays the correct human-readable text.

## Test Fixture & Payloads
- **Fixture**: N/A — structural refactor.

## Tools & Commands
- `flutter analyze`

## Proposed Changes
- `[MOD]` `lib/features/templates/widgets/wizard_step_review.dart`: 
  - Change `final String scoringMode;` to `final ScoringMode scoringMode;`
  - Import `../../../_shared/services/scoring_mode.dart`.
  - Update `_isSurvey` and `isScored` conditions to use enum values instead of string literals.
  - Convert `_modeLabel` to a `switch` expression over the enum.
  - Update the `AdvancedSettingsCard` call to pass `widget.scoringMode.name`.
- `[MOD]` `lib/features/templates/pages/template_wizard_page.dart`:
  - Update the `WizardStepReview` instantiation to map the string to the enum: `ScoringMode.values.firstWhere((e) => e.name == _scoringMode, orElse: () => ScoringMode.penalty)`.
  - Import `../../../_shared/services/scoring_mode.dart`.

## Concept Diagram
```text
[TemplateWizardPage] (String _scoringMode)
      |
      |--maps to--> ScoringMode.values.byName
      v
[WizardStepReview] (ScoringMode scoringMode)
      |
      |--uses--> switch (scoringMode) { ... }
      |
      |--maps to--> scoringMode.name
      v
[AdvancedSettingsCard] (String scoringMode)
```

## Execution Phase
**Summary**: Convert `WizardStepReview.scoringMode` from a `String` to the `ScoringMode` enum to eliminate magic string comparisons. Update the parent caller to handle the boundary mapping.
**Value Delivered**: Type safety and elimination of magic string duplication.
**Entry State**: `wizard_step_review.dart` uses `switch (widget.scoringMode)` with string literals.
**Exit State**: `wizard_step_review.dart` uses `ScoringMode` enum.
**Scope**: Presentation layer typing.
**Acceptance Criteria**:
- `WizardStepReview` no longer uses string literals like `'penalty'` or `'survey'`.
- `flutter analyze` passes.

**Complexity**: Low. Isolated type change with clear boundary mappings.

## Handoff Block
```markdown
@[/implement] Execute build for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-code\implementation_plan_20260508_210900_4cf3f4_audit-code-warn5.md
```
