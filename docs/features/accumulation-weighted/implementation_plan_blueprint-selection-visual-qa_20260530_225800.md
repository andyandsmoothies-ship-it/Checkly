<latent_space_scratchpad>
## Latent Space Scratchpad

### Boundary Rules & Edge Cases:
1. **Vertical Text Wrapping**:
   - The subtitle descriptions have been expanded to be highly descriptive. On small screens (e.g. iPhone SE / 320px width), the text will wrap over multiple lines. Setting `maxLines: 4` in the `Text` widget prevents text truncation while the mobile responsive `ListView.separated` layout allows cards to grow vertically without height constraints.
2. **Preset Value Mapping**:
   - The card taps return precise technical scoring modes (`'penalty'`, `'accumulation'`, `'survey'`, `'checklist'`). The parent wizard page maps these exact modes to C# Backend and local SQLite databases.
3. **Screen Size Responsiveness**:
   - `size.width > 600` renders a two-column desktop grid with a secure `childAspectRatio: 1.8`.
   - `size.width <= 600` renders a flexible vertical `ListView.separated` layout, completely eliminating layout clipping and overflow errors on mobile.

### Risks:
- Layout overflow when text is very long. Resolved by replacing fixed-height `GridView` on mobile with `ListView.separated` + `maxLines: 4` + dynamic expansion.
- DI and Layout Safety is verified because the widget relies purely on passed parameters and does not instantiate new global dependencies.
</latent_space_scratchpad>

# Implementation Plan: Fix Blueprint Selection Visual Clipping & Copywriting Gaps

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\a684dd5f-1b02-4247-86c8-ad87256b90e1\artifacts\report_visual_qa_guided_creation_20260530_224500.md`
- **Topic**: `blueprint_selection_modal_visual_remediation`
- **Sub-task**: Visual Clipping & Description Enrichment

---

## Executive Summary & Out of Scope
The first screen of the Guided Creation process (the `BlueprintSelectionModal`) had two major gaps identified:
1. **Visual Clipping**: On mobile screens under 600px width, the fixed `childAspectRatio` in `GridView.count` forced rigid card heights, resulting in vertical text clipping on the "Basic Checklist" card.
2. **Copywriting Gaps**: The description subtitles were overly generic and lacked clear technical mapping context compared to the Classic Builder option descriptions.

This plan details how to resolve both gaps by introducing a dynamic responsive layout (using `ListView.separated` for mobile and `GridView` for desktop) and enhancing the copywriting subtitles to explicitly mention the mapped scoring system behavior (e.g., Penalty, Accumulation, Survey, and Checklist).

### Out of Scope
- Modifying subsequent steps in the Guided Creation wizard.
- Changing backend C# calculation logic.
- Adding custom new templates.

---

## System Context
- **Offline-First Integration**: Pure presentation layer enhancement. The selected blueprint mode maps directly to local template configuration.
- **RBAC**: No RBAC logic impacted. Inherits standard template creation permissions.

---

## Lifecycle Context
### 4-State Matrix (UI Component)
- **Success**: All 4 cards render beautifully, adapt perfectly to screen widths, wrap text elegantly up to 4 lines, and emit the correct mode string on selection.
- **Error**: Overflows are completely avoided by using `ListView.separated` scrollable constraints.
- **Empty**: Default fallback displays all 4 predefined blueprints.
- **Loading**: Modal loads instantly with static preset assets.

---

## Constraint Traceability

| Constraint ID | Description | Test Contract ID |
|---------------|-------------|------------------|
| C-VIS-01      | Prevent text clipping on mobile views under 600px width by using dynamic scrollable ListView | TC-VIS-01 |
| C-VIS-02      | Enrich description text to map directly to Classic scoring modes | TC-VIS-02 |
| C-VIS-03      | Tap cards successfully emits matching preset string | TC-VIS-03 |

---

## Test Contracts

### TC-VIS-01: Responsive Layout Validation
- **Description**: Verify that the modal uses scrollable `ListView.separated` on narrow mobile screens (<= 600px) and `GridView` on wide screens (> 600px).
- **Fixtures**: Standard Flutter widget test.
- **Fail-First**: The mobile view renders `GridView` and truncates or clips text.

### TC-VIS-02: Copywriting and Enriched Text Match
- **Description**: Assert that card descriptions include detailed technical mapping words (e.g. `Penalty (Weighted):`, `Accumulation (Weighted):`).
- **Fixtures**: Standard widget test.
- **Fail-First**: Descriptions match older generic copy.

### TC-VIS-03: Selection Callback Emission
- **Description**: Tapping "Basic Checklist" card pops dialog returning `'checklist'` string.
- **Fixtures**: Standard widget test.

---

## Tools & Commands
- **Required Skills**: `flutter-architecture`, `ui-visual-validator`
- **Execution Commands**:
  - `rtk flutter test test/features/templates/widgets/blueprint_selection_modal_test.dart`

---

## Proposed Changes

### `[MOD]` lib/features/templates/widgets/blueprint_selection_modal.dart
- Update subtitles in static `_blueprints` metadata list to match detailed classic builder mappings.
- Replace `GridView.count` on mobile view (`size.width <= 600`) with dynamic scrollable `ListView.separated`.
- Set `maxLines: 4` on card subtitles to prevent truncation of long detailed text.

---

## Concept Diagram

```text
[Dialog.fullscreen]
       │
       ▼ (MediaQuery size.width Check)
 ┌─────┴────────────────────────┐
 │ size.width <= 600            │ size.width > 600
 ▼                              ▼
[ListView.separated]           [GridView.count]
(Dynamic vertical card growth) (Two columns)
```

---

## Risk Assessment
- **Text Clipping**: Low risk of clipping since we replaced fixed-size grid cards with a scrollable list view that allows cards to grow vertically.
- **Callback Breakage**: Card selection continues to pop and return the correct string mode cleanly.

## Verification Plan
- **Automated Verification**: Run the newly created widget test suite covering copywriting and responsiveness:
  `rtk flutter test test/features/templates/widgets/blueprint_selection_modal_test.dart`
- **Global Regression Verification**: Run full Flutter package tests:
  `rtk flutter test`

---

## Execution Slices

### Slice 1 (Happy Path & Copy Enhancement)
- **Summary**: Build responsive card layout and enrich visual subtitles.
- **Value**: Prevents critical layout crashes/truncations on mobile screens and educates users on technical scoring directions.
- **Entry State**: Modal is clipped on mobile viewports. Subtitles are generic.
- **Exit State**: Modal scrolls beautifully on mobile viewports. Subtitles are enriched and test cases pass.
- **Scope**: Modifying `blueprint_selection_modal.dart` and `blueprint_selection_modal_test.dart`.
- **Acceptance Criteria**:
  - Visual check confirms no layout overflows on 320dp width.
  - `blueprint_selection_modal_test.dart` passes.

---

## Handoff Block
- **Plan Path**: `docs/features/accumulation-weighted/implementation_plan_blueprint-selection-visual-qa_20260530_225800.md`
- **Slice Sequence**:
  - **Slice 1**: Plan -> Build -> Verify
