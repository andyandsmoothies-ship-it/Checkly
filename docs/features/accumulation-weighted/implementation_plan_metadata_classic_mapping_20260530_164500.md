# Implementation Plan - Metadata Classic Mapping Alignment

<latent_space_scratchpad>
Target: Align the Dynamic Explanation Box in `MetadataFormCard` (Classic Creation) with the 5 Guided Creation blueprints:
1. Audit & Inspection (down + weighted)
2. Scored Assessment (up + weighted)
3. Simple Scored Assessment (up + unweighted)
4. Basic Checklist (down + unweighted)
5. Form & Survey (none)

Edge Case 1: If scoreDirection is somehow null or an unexpected value. We handle it via a clean switch default block fallback ('Select a scoring mode to see how it works').
Edge Case 2: Layout overflow on narrow viewports. We wrap the text column in `Expanded` inside the `Row` to ensure it wraps perfectly without horizontal clipping.
Edge Case 3: Theme compatibility. The text color will use `Theme.of(context).textTheme.bodyMedium` with slight opacity to support both light and dark modes perfectly.
</latent_space_scratchpad>

## Input Lineage
- Source: USER_REQUEST

## Executive Summary & Out of Scope
The classic creation template configuration card (`MetadataFormCard`) dynamically displays an explanation of the selected scoring settings. To ensure visual cohesion and clarity across both creation modes, this plan maps the 5 scoring options in Classic Creation to match the exact names, descriptions, icons, and colors of the 5 Guided Creation blueprints.

**Out of Scope**:
- Changing the underlying entity schemas or JSON serialization.
- Modifying the wizard steps or wizard flow logic.
- Altering the backend API endpoints.

## System Context
- **Offline/Online**: The presentation changes are entirely local to the frontend UI.
- **RBAC**: No additional authorization capabilities required.

## Lifecycle Context
### 4-State Matrix (Presentation Layer)
- **Success State**: Displays a premium, color-coded custom card containing the blueprint's icon, title, and exact dynamic description matching the selected controls.
- **Error State**: N/A (local UI state only).
- **Loading State**: N/A (instant state change).
- **Empty State**: Displays default helper instructions when no direction is selected.

## Constraint Traceability
| Input Constraint | Technical Requirement | Test Contract ID |
|---|---|---|
| Map 'down' + isWeighted | Display Audit & Inspection details & color | TC-METADATA-01 |
| Map 'up' + isWeighted | Display Scored Assessment details & color | TC-METADATA-02 |
| Map 'up' + !isWeighted | Display Simple Scored Assessment details & color | TC-METADATA-03 |
| Map 'down' + !isWeighted | Display Basic Checklist details & color | TC-METADATA-04 |
| Map 'none' | Display Form & Survey details & color | TC-METADATA-05 |

## Test Contracts
- **TC-METADATA-01**: Verify classic creation with Penalty + Weighted displays "Audit & Inspection" description and uses `BlueprintColors.audit`.
- **TC-METADATA-02**: Verify classic creation with Accumulation + Weighted displays "Scored Assessment" description and uses `BlueprintColors.assessment`.
- **TC-METADATA-03**: Verify classic creation with Accumulation + Unweighted displays "Simple Scored Assessment" description and uses `BlueprintColors.simpleAssessment`.
- **TC-METADATA-04**: Verify classic creation with Penalty + Unweighted displays "Basic Checklist" description and uses `BlueprintColors.checklist`.
- **TC-METADATA-05**: Verify classic creation with Survey displays "Form & Survey" description and uses `BlueprintColors.survey`.

## Test Fixture & Payloads
Standard `MaterialApp` widget test harness using the defined `MetadataFormCard` with variable test states.

## Tools & Commands
- Framework: Flutter / Dart
- Command: `rtk flutter test test/features/templates/widgets/metadata_form_card_test.dart`

## Proposed Changes
### `lib/features/templates/widgets/metadata_form_card.dart` [MOD]
- Import `package:checkly/_shared/theme/app_colors.dart`.
- Replace the raw `Padding` with a dynamic, highly styled `Container` resembling the custom premium cards using the `BlueprintColors` accents, showing the matching name, icon, and dynamic description.

### `test/features/templates/widgets/metadata_form_card_test.dart` [MOD]
- Add comprehensive widget tests verifying that changing the scoring direction and weighted toggles properly displays the matching title and icon.

## Concept Diagram
```
[User toggles controls]
         |
         v
[scoreDirection / isWeighted State changes]
         |
         v
[_buildBlueprintInfoBox builds dynamically]
         |
         +--> Icon (Matches blueprint)
         +--> Title (Matches blueprint)
         +--> Color Accent (Matches blueprint)
         +--> Description (Matches blueprint)
```

## Execution Slices

### Slice 1: Alignment & UI Polish (Happy Path)
- **Summary**: Align all 5 states in `MetadataFormCard` to match the guided blueprints with distinct styling.
- **Value**: Establishes UI consistency and visually informs the user of the scoring mode.
- **Entry State**: Standard classic creation UI.
- **Exit State**: Premium visual container mapping controls directly to blueprint concepts.
- **Complexity**: Easy

### Slice 2: Integration & Coverage Tests
- **Summary**: Update the widget test suite to comprehensively verify all 5 distinct states.
- **Value**: Safeguards visual regression and ensures correct visual rendering under all states.
- **Entry State**: Single test coverage.
- **Exit State**: 100% test coverage of all 5 blueprint states.
- **Complexity**: Medium

<command_logs>
- Viewed lib/features/templates/widgets/metadata_form_card.dart
- Viewed test/features/templates/widgets/metadata_form_card_test.dart
- Viewed lib/features/templates/widgets/blueprint_selection_modal.dart
- Viewed lib/_shared/theme/app_colors.dart
</command_logs>

## Risk Assessment
- **Risk 1: Layout Overflow**: If the description is too long, the card text could overflow on narrow screens.
  - *Mitigation*: Ensure description texts are wrapped inside an `Expanded` widget within their horizontal layout.
- **Risk 2: Color Palette Mismatch**: Colors could look jarring in Dark Mode.
  - *Mitigation*: Leverage centralized `BlueprintColors` accents which scale elegantly for dark/light themes.

## Verification Plan
- **Widget Testing**: Run `rtk flutter test test/features/templates/widgets/metadata_form_card_test.dart` to assert all 5 blueprint states render correct titles, descriptions, and colors.
- **Integration Validation**: Confirm no regression or compilation issues exist in the template creation page.

## Handoff Block
Next Step: **Build Step** for Slice 1 and Slice 2. Please execute them sequentially.
Plan Path: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_metadata_classic_mapping_20260530_164500.md`

