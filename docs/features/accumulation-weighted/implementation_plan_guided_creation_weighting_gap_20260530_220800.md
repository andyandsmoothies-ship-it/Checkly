<latent_space_scratchpad>
## Latent Space Scratchpad

### Boundary Rules & Edge Cases:
1. **Dynamic Navigation**:
   - If the user enables "Weighted Density" in Step 4, then navigates back to Step 3, the section weights must immediately be visible and interactive.
   - If the user disables "Weighted Density" in Step 4, then navigates back to Step 3, the section weights must be hidden.
2. **Scoring Mode Verification**:
   - Only `penalty` (Audit) and `accumulation` (Scored Assessment) modes support the custom section weighting. Survey and Checklist modes do not.
   - The toggle is automatically hidden/disabled for other modes in `AdvancedSettingsCard`.

### Risks:
- Layout overflow when section weight input field is rendered in narrow screens. Since it is nested inside `SectionEditor`'s header part, we must verify that it matches surrounding style and doesn't crash layout.
- DI and Layout Safety is verified because `SectionEditor` already supports `densityEnabled` natively (it is used in Classic Builder). No new global services or unconstrained layouts are introduced.
</latent_space_scratchpad>

# Implementation Plan: Fix Section Weighting Input Gap in Guided Creation Wizard

## Input Lineage
- **Source Epic**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\analysis_epic_20260530_172200.md`
- **Topic**: `guided_template_creation_wizard`
- **Sub-task**: Weighting Gap Fix in Step 3

---

## Executive Summary & Out of Scope
The Guided Creation Wizard provides a simplified flow for creating templates. However, in `WizardStepSections` (Step 3), the `SectionEditor` is instantiated with `densityEnabled: false` hardcoded. When users toggle "Weighted Density" in Step 4 (Advanced Settings) and go back to Step 3, the weight input fields remain invisible.

This plan details how to dynamically bridge this gap by passing `weightedDensity` state from the wizard parent page down to the step sections view.

### Out of Scope
- Modifying the C# backend calculations or templates endpoints (this was already successfully implemented in previous slices).
- Adding new modes or editing Classic Builder behavior.

---

## System Context
- **Offline-First Integration**: State is kept purely in the frontend models (`EditableGroup`, `EditableCriterion`) using standard Flutter `TextEditingController` controllers, then compiled recursively upon Step 4 save action.
- **RBAC**: No direct RBAC changes. Standard template creation capabilities apply.

---

## Lifecycle Context
### 4-State Matrix (UI Component)
- **Success**: Weighted input displays and preserves state correctly when switching steps or saving.
- **Loading**: Standard save shimmer is displayed during atomic template persistence.
- **Error**: Validation errors (e.g. invalid weight integers) are captured dynamically in Step 4 and printed using `ErrorDisplayService`.
- **Empty**: Default weight behavior falls back gracefully when inputs are blank.

---

## Constraint Traceability

| Constraint ID | Description | Test Contract ID |
|---------------|-------------|------------------|
| C-WIZ-01      | Pass `_weightedDensity` state dynamically from Wizard parent to `WizardStepSections` | TC-WIZ-01 |
| C-WIZ-02      | Enable/disable `densityEnabled` in `SectionEditor` based on passed state | TC-WIZ-02 |
| C-WIZ-03      | State changes in Step 4 immediately update the visibility of weights in Step 3 | TC-WIZ-03 |

---

## Test Contracts

### TC-WIZ-01: Parent-to-Step State Threading
- **Description**: Verify that the wizard page successfully binds `_weightedDensity` to `WizardStepSections`.
- **Fixtures**: Standard widget test harness.
- **Fail-First**: The wizard page fails to compile or doesn't provide the constructor property.

### TC-WIZ-02: SectionEditor Prop Binding
- **Description**: Verify that `SectionEditor` receives `densityEnabled: widget.weightedDensity` in Step 3.
- **Fixtures**: Standard widget test.
- **Fail-First**: `densityEnabled` is hardcoded to `false`.

### TC-WIZ-03: Reactive State Updates
- **Description**: Verify that toggling the density switch in Step 4 and returning to Step 3 immediately triggers visibility transitions of section weight input fields.
- **Fixtures**: Standard integration/widget test matching `template_wizard_page`.

---

## Tools & Commands
- **Required Skills**: `flutter-architecture`, `interaction-design`
- **Verification Commands**:
  - `rtk flutter test test/features/templates/widgets/parts_test.dart`
  - `rtk flutter test test/features/templates/wizard_payload_test.dart`

---

## Proposed Changes

### `[MOD]` lib/features/templates/pages/template_wizard_page.dart
- Update the instantiation of `WizardStepSections` inside `children` list around line 180 to pass `weightedDensity: _weightedDensity`.

### `[MOD]` lib/features/templates/widgets/wizard_step_sections.dart
- Add `final bool weightedDensity;` parameter to the `WizardStepSections` class constructor.
- Replace the hardcoded `densityEnabled: false` inside the build block around line 233 with `densityEnabled: widget.weightedDensity`.

---

## Concept Diagram

```text
[template_wizard_page.dart]
   |
   +---> passes _weightedDensity state
   |
   v
[wizard_step_sections.dart]
   |
   +---> delegates densityEnabled: widget.weightedDensity
   |
   v
[SectionEditor]
   |
   +---> Renders weight textboxes inline!
```

---

## Execution Slices

### Slice 1 (Happy Path & Prop Threading)
- **Summary**: Thread the state through the classes.
- **Value**: Establishes correct state communication between Step 4 setting changes and Step 3 views.
- **Entry State**: `weightedDensity` is not passed to the wizard step widgets.
- **Exit State**: `weightedDensity` is correctly passed and delegated to `SectionEditor`.
- **Scope**: Modifying `template_wizard_page.dart` and `wizard_step_sections.dart`.
- **Acceptance Criteria**:
  - Code compiles without warnings or errors.
  - Widget tests pass without regressions.

---

## Handoff Block
- **Plan Path**: `docs/features/accumulation-weighted/implementation_plan_guided_creation_weighting_gap_20260530_220800.md`
- **Slice Sequence**:
  - **Slice 1**: Plan -> Build -> Verify
