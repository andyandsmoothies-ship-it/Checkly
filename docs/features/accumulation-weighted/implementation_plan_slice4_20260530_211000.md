---
ConversationID: a684dd5f-1b02-4247-86c8-ad87256b90e1
---

# Implementation Plan - Slice 4: Template Builder UI Unlock

This vertical slice unlocks the creation and editing of weighted accumulation templates in the Flutter front-end. It ensures the Metadata Form Card, Advanced Settings Card, and Creation Wizard accurately allow, synchronize, and serialize weighted scoring for accumulation mode templates.

## 1. Architectural Changes

We do not introduce new domain layers or outer-to-inner ring imports. We align existing presentation logic with the core scoring engine's capability for Weighted Accumulation (unlocked in Slice 1 & Slice 2).

### Logic Flow

```
[Template Wizard / Builder]
         |
         +--> Toggles Weighted Scoring / Density
         |
         +--> Serializes isWeighted / weightedDensity to JSON config string
         |
         v
[Saved DB Template config] --> {"scoreDirection": "up", "isWeighted": true, "weightedDensity": true}
```

## 2. File Invariants & Rule Compliances

- **File Size**: No file modified exceeds 400 lines (or we split off logic if they approach 400 lines).
- **Mechanical Language Only**: Descriptions specify exact attributes and callbacks.
- **TDD Requirement**: Write a failing widget test asserting that the Metadata Form Card enables and invokes the callback under Accumulation mode, *before* changing the production code.

## 3. Implementation Steps

### Step 1: Write the Failing Widget Test
Create [metadata_form_card_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/metadata_form_card_test.dart):
- Build `MetadataFormCard` in a `testWidgets` run with `scoreDirection: 'up'`.
- Verify the `SwitchListTile` for "Weighted Scoring" is enabled.
- Tap it and verify `onIsWeightedChanged` is invoked with the updated value.

### Step 2: Unlock the Toggle in Metadata Form Card
Modify [metadata_form_card.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/widgets/metadata_form_card.dart):
- Change `SwitchListTile`'s `value` to `scoreDirection == 'none' ? false : isWeighted`.
- Change `SwitchListTile`'s `onChanged` to `scoreDirection == 'none' ? null : (val) => onIsWeightedChanged(val)`.
- Update subtitles and explanation texts to support dynamic accumulation weighted details.

### Step 3: Synchronize Flags in Template Builder Page
Modify [template_builder_page.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_builder_page.dart):
- Ensure `onIsWeightedChanged` and `onDensityChanged` synchronize both `_isWeighted` and `_weightedDensity`.

### Step 4: Map Wizard Payload Correctly
Modify [template_wizard_page_logic.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_wizard_page_logic.dart):
- Update `isWeighted` calculation in `_save` to map `isWeighted: _scoringMode == 'penalty' || (_scoringMode == 'accumulation' && _weightedDensity)`.

## 4. Verification Plan

1. Run the new widget test with:
   ```cmd
   rtk flutter test test/features/templates/widgets/metadata_form_card_test.dart
   ```
2. Run the full unit/widget test suites to verify no regressions:
   ```cmd
   rtk flutter test
   ```
