# Walkthrough - Weighted Accumulation Scoring Slice 4

## Metadata
- **ConversationID**: `f625c2e4-0fdd-4c33-9271-185cf5df427c`
- **Timestamp**: `2026-05-30T21:10:00`
- **Feature**: Weighted Accumulation Scoring Redesign
- **Slice**: Slice 4 (UI Wizard Integration)

---

## 1. Executive Summary

This walkthrough documents the UI integration slice for the new **Weighted Accumulation Scoring** feature in the Checkly Template Wizard.

We unlocked the "Weighted Scoring" toggle in the template creation wizard, ensuring it is only visible when the user selects "Up" (Accumulation Mode) as the scoring type. Changing the scoring mode away from "Up" automatically resets the `isWeighted` configuration flag to `false`. Finally, we ensured the `isWeighted` flag is mapped correctly within the creation wizard's payload logic and verified everything with widget tests.

---

## 2. Visual Architecture

```text
  [Template Wizard Page] <--- (User input: Scoring Mode & Weighted toggle)
            │
            ▼
  [TemplateWizardPageLogic] ─── (Maps data model payload: isWeighted)
            │
            ▼
   [MetadataFormCard] ─── (Displays StrokeCard UI with interactive toggles)
```

---

## 3. Detailed Component Review

### 3.1 MetadataFormCard (`lib/features/templates/widgets/metadata_form_card.dart`)
- **Action**: Unlocked and styled the "Weighted Scoring" toggle inside a premium `StrokeCard` layout.
- **Rules**:
  - Only visible when `scoringType == ScoringType.up`.
  - Added accessibility/visual tips inside the toggle layout explaining that weights are defined at the section level.

### 3.2 TemplateBuilderPage (`lib/features/templates/pages/template_builder_page.dart`)
- **Action**: Synchronized the local `isWeighted` flag state whenever `scoringType` changes.
- **Logic**: If `scoringType != ScoringType.up`, reset `isWeighted` to `false` to avoid invalid combinations.

### 3.3 TemplateWizardPageLogic (`lib/features/templates/pages/template_wizard_page_logic.dart`)
- **Action**: Mapped the `isWeighted` configuration parameter into the `TemplateWizardPagePayload` mapping code.

---

## 4. Verification Methods

### Automated Tests
Run the newly created widget test suite:
```cmd
rtk flutter test test/features/templates/widgets/metadata_form_card_test.dart
```

### Manual Validation Check
1. Navigate to **Templates** > **Create New Template**.
2. Set the scoring mode to **Down** (Deduction Mode).
   - Observe: The "Weighted Scoring" toggle is hidden.
3. Change the scoring mode to **Up** (Accumulation Mode).
   - Observe: The "Weighted Scoring" toggle animates/appears.
4. Toggle "Weighted Scoring" to **ON**, then switch the scoring mode back to **Down**.
   - Observe: The toggle disappears, and the builder state resets `isWeighted` to `false` automatically.
