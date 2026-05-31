<latent_space_scratchpad>
- Visual Design Details:
  - Replacing standard Material SegmentedButton in metadata_form_card.dart with a custom premium Row of 3 StrokeCards.
  - Option 1 (down): Label 'Deduct Points', sublabel 'Starts at 100%', Icon Icons.arrow_downward_rounded, color BlueprintColors.audit (Blue).
  - Option 2 (up): Label 'Earn Points', sublabel 'Starts at 0%', Icon Icons.arrow_upward_rounded, color BlueprintColors.assessment (Green).
  - Option 3 (none): Label 'No Score', sublabel 'Data collection', Icon Icons.assignment_outlined, color BlueprintColors.survey (Purple).
  - Selected state: The card uses a 2px active color border and a 0.08 alpha background tint. The icon is enclosed in a circular container with a 0.12 alpha background tint.
  - Unselected state: The card uses standard AppColors.swan border (or transparent/low alpha in dark mode) and AppColors.snow / background.
  - Naming Changes in blueprint_selection_modal.dart and metadata_form_card.dart info box:
    - Audit & Inspection: 'Deduct Points (Weighted): Start with a perfect 100% score. Points are deducted for mistakes. Different sections can have different weight/importance.'
    - Scored Assessment: 'Earn Points (Weighted): Start at 0% score. Points are earned for correct answers. Different sections can have different weight/importance.'
    - Simple Scored Assessment: 'Earn Points (Simple): Start at 0% score. Points are earned for correct answers. The final score is a simple percentage of all correct answers.'
    - Basic Checklist: 'Deduct Points (Simple): Start with a perfect 100% score. Each failed item takes away the exact same amount of points from the total.'
    - Form & Survey: 'No Scoring (Survey): Gather answers without calculating any score. Perfect for general feedback, notes, and custom data collection.'
  - Layout / Overflow Safety:
    - Text wrap: Ensure text inside the custom cards uses proper wrapping, small font sizes (12 for title, 9 for subtitle), and text alignment is centered to prevent overflow in narrow portrait modes.
    - Expanded constraint: Wrap each card inside an Expanded widget to divide horizontal width evenly inside the Row.
</latent_space_scratchpad>

# Implementation Plan: Reskin Scoring Direction Buttons and Simplify Terminology

## Input Lineage
- Source constraint: User request to fix "penalty, accumulate and survey" button visuals and terminology to feel more gamified (Duolingo-like) and less like developer jargon.

## Executive Summary & Out of Scope
- **Goal**: Replace the default Material `SegmentedButton` in `metadata_form_card.dart` with a row of three custom `StrokeCard` selector buttons featuring active colors, bouncy spring-back scales, and clean icons. Simplify technical scoring terms ("Penalty", "Accumulation", "Survey") in both the metadata page and the template blueprint selector modal to friendly, readable Simple English.
- **Out of Scope**:
  - Changing raw internal technical identifiers ('down', 'up', 'none', 'penalty', 'accumulation', etc.) inside database schemas, server-side APIs, or scoring calculations.
  - Editing question editors or other template components outside of the metadata & blueprint selection cards.

## System Context
- Purely presentation-layer modifications within the Flutter UI templates feature.
- No network changes or database schema adjustments are required.

## Lifecycle Context
- The custom buttons toggle the `scoreDirection` string instantly on tap, updating the active visual state of the cards and dynamically redrawing the information box below.

## Constraint Traceability

| ID | Input Constraint | Test Contract ID |
|---|---|---|
| C-1 | Replace SegmentedButton with custom cards | TC_SR_01 |
| C-2 | Simplify technical names to Deduct, Earn, and No Score | TC_SR_02 |
| C-3 | Clean up jargon in the template blueprint selector modal | TC_SR_03 |

## Test Contracts

| ID | Description | State Matrix | Fail-First Explanation |
|---|---|---|---|
| TC_SR_01 | Custom option cards render in MetadataFormCard | Selected 'down' -> Deduct Points highlighted blue, others unselected | Assert that the UI renders the custom choice cards rather than SegmentedButton |
| TC_SR_02 | Copywriting uses clean Simple English | Selected info box displays "Earn Points" or "Deduct Points" | Assert that technical terms like "Penalty" are replaced with friendly terms |
| TC_SR_03 | Blueprint selections utilize friendly names | Selection modal shows "Deduct Points" and "Earn Points" | Assert that blueprints have simplified descriptions |

## Proposed Changes

### UI Components (`lib/features/templates/widgets/`)

| Component | Truncation Limit | Overflow Action | Required New Route |
|---|---|---|---|
| `metadata_form_card.dart` | Compact layout | Wrap text, small fonts, center alignment | Route 1: Direct Build |
| `blueprint_selection_modal.dart` | Expanded card details | Standard vertical wrapping | Route 1: Direct Build |

#### [MOD] `lib/features/templates/widgets/metadata_form_card.dart`
- Create a private `_CustomOptionButton` widget within the file (or define inline inside `Row`).
- Replace the Material `SegmentedButton` with a `Row` containing three `_CustomOptionButton` instances mapped to `'down'`, `'up'`, and `'none'`.
- Update the titles and descriptions in `_buildBlueprintInfoBox` to utilize the new non-jargon copywriting.

#### [MOD] `lib/features/templates/widgets/blueprint_selection_modal.dart`
- Update the static `_blueprints` list with simplified, friendly Simple English descriptions.

## Concept Diagram

```
 [Choose Blueprint (Friendly Copy)] 
               │
               ▼
   [Metadata Form Card] ───► [Custom Row of 3 StrokeCards (Deduct / Earn / No Score)]
               │
               ▼
  [Dynamic Blueprint Info Box (Friendly Text)]
```

## Execution Slices

### Slice 1 (Happy Path & Copywriting Reskin)
- **Summary**: Replace SegmentedButton with custom StrokeCards and simplify terms in MetadataFormCard and BlueprintSelectionModal.
- **Value**: Users immediately experience a premium, gamified, and highly accessible creation flow.
- **Entry State Required**: Template creation wizard opened in classic flow.
- **Exit State Guaranteed**: Custom choice cards are displayed with active/inactive visual selections and simple English descriptions.
- **Acceptance Criteria**:
  - `SegmentedButton` is removed.
  - Three distinct `StrokeCard` option cards are displayed inside a horizontal row.
  - Active scoring option has matching colored borders (Blue, Green, Purple) and background tint.
  - Text description boxes are updated to avoid technical developer jargon.

---

## Handoff Block
- Absolute path: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\scoring-reskin\implementation_plan_scoring-reskin_20260531_101500.md`
- **Execution Strategy**:
  - **Slice 1**: Direct Build (UI & Copywriting updates).
