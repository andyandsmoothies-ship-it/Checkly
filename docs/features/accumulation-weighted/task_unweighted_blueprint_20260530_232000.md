---
ConversationID: f625c2e4-0fdd-4c33-9271-185cf5df427c
Type: Task Checklist
Topic: 5th Guided Creation Option - Accumulation Unweighted Blueprint
Date: 2026-05-30
---

# Task Checklist: 5th Blueprint Option in Guided Creation (Accumulation Simple)

- [x] **Step 1: Add new color to `BlueprintColors`**
  - Add `simpleAssessment` inside `BlueprintColors` in `lib/_shared/theme/app_colors.dart`.
- [x] **Step 2: Add card to `BlueprintSelectionModal`**
  - Add the `Simple Scored Assessment` blueprint tuple to `_blueprints` in `lib/features/templates/widgets/blueprint_selection_modal.dart`.
- [x] **Step 3: Update page state mappings**
  - Update `_showBlueprintModal()` in `lib/features/templates/pages/template_wizard_page_logic.dart` to correctly map `accumulation_unweighted` and `accumulation` mode, setting `_weightedDensity` to `false` or `true` respectively.
- [x] **Step 4: Update Review step mode label**
  - Update `_modeLabel` in `lib/features/templates/widgets/wizard_step_review.dart` to distinguish Accumulation Weighted vs Accumulation Simple based on `widget.weightedDensity`.
- [x] **Step 5: Run widget and integration tests**
  - Update `test/features/templates/widgets/blueprint_selection_modal_test.dart` to include simple scored assessment expectations.
  - Run all widget and integration tests to ensure clean compilation and 100% green status.
