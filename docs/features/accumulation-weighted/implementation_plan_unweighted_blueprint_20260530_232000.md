---
ConversationID: f625c2e4-0fdd-4c33-9271-185cf5df427c
Type: Implementation Plan
Topic: 5th Guided Creation Option - Accumulation Unweighted Blueprint
Date: 2026-05-30
---

# Implementation Plan: 5th Blueprint Option in Guided Creation (Accumulation Simple)

## 1. Context & Logical Flow

The Checkly platform supports 5 distinct scoring options but the Guided Creation (`BlueprintSelectionModal`) currently only displays 4 blueprints. This plan adds the 5th blueprint card: **Simple Scored Assessment** (Accumulation Unweighted), so users can easily select it and get the correct scoring defaults.

### Flow Diagram

```
[Blueprint Selection Modal]
   |
   +--> Penalty (Weighted)               --> 'penalty'
   +--> Checklist (Simple Down)          --> 'checklist'
   +--> Scored Assessment (Weighted)     --> 'accumulation'             (weightedDensity = true)
   +--> Simple Scored Assessment         --> 'accumulation_unweighted'  (weightedDensity = false)
   +--> Form & Survey                    --> 'survey'
```

Under the hood:
- `accumulation_unweighted` maps to the `accumulation` scoring mode with `weightedDensity = false`.
- `accumulation` (Scored Assessment) maps to the `accumulation` scoring mode with `weightedDensity = true`.

---

## 2. Technical Architecture & Mappings

### A. Scoring Logic Config Mapping Matrix
| Blueprint Selected | Returned `mode` | `scoreDirection` | `isWeighted` | `weightedDensity` |
| :--- | :--- | :--- | :--- | :--- |
| **Audit & Inspection** | `penalty` | `down` | `true` | `false` |
| **Basic Checklist** | `checklist` | `down` | `false` | `false` |
| **Scored Assessment** | `accumulation` | `up` | `true` | `true` |
| **Simple Scored Assessment** | `accumulation_unweighted` | `up` | `false` | `false` |
| **Form & Survey** | `survey` | `none` | `false` | `false` |

---

## 3. Anticipated Failure Modes & Mitigations

Before writing the implementation, we explicitly identify two potential failure modes under edge conditions:

### Failure Mode 1: Scoring engine division-by-zero on unweighted template with zero criteria
- **Risk**: An unweighted template (`isWeighted = false`, direction `up`) has a total possible points sum of zero. The calculation engine could execute `earnedPoints / totalPossiblePoints * 100` resulting in `NaN` or a division-by-zero exception.
- **Mitigation/Test**: The calculation engine logic must fall back safely to `0.00%` or `100.00%` when `totalPoints` is zero. We will verify the Dart calculator handles this correctly.

### Failure Mode 2: Unweighted accumulation with empty sections crashing list traversal
- **Risk**: When traversing sections, the system might assume all sections are non-empty or try to compute a sub-percentage using a division factor.
- **Mitigation/Test**: The builder wizard validator (`validateWizardStep`) prevents saving empty templates, and the review screen enforces that each section has at least one criterion before saving.

---

## 4. Implementation Steps

### Step 1: Update App Colors
Add `simpleAssessment` color accent to `BlueprintColors` in `lib/_shared/theme/app_colors.dart`:
```dart
static const simpleAssessment = Color(0xFF00838F); // Teal — Simple Scored Assessment (Accumulation Unweighted)
```

### Step 2: Add 5th Card in `BlueprintSelectionModal`
Update `_blueprints` in `lib/features/templates/widgets/blueprint_selection_modal.dart`:
- **Title**: `'Simple Scored Assessment'`
- **Tag**: `'Best for training & quizzes'`
- **Subtitle**: `'Accumulation (Simple): starts at 0% and gains points. Your final score is the simple percentage of points earned out of the total possible (no weighting).'`
- **Color**: `BlueprintColors.simpleAssessment`

### Step 3: Handle Payload and State in `template_wizard_page_logic.dart`
Update `_showBlueprintModal()` to map the selected mode:
- If `mode == 'accumulation_unweighted'`:
  - `_scoringMode = 'accumulation'`
  - `_weightedDensity = false`
  - `_type = 'training'`
- If `mode == 'accumulation'`:
  - `_scoringMode = 'accumulation'`
  - `_weightedDensity = true` (Defaulting to weighted)
  - `_type = 'training'`

### Step 4: Polish Copy in `WizardStepReview`
In `lib/features/templates/widgets/wizard_step_review.dart`, update `_modeLabel` to check `widget.weightedDensity` for `ScoringMode.accumulation`:
```dart
      ScoringMode.accumulation => widget.weightedDensity
          ? 'Training Assessment (Accumulation Weighted)'
          : 'Training Assessment (Accumulation Simple)',
```

---

## 5. Testing & Verification Plan

1. **Unit & Widget Tests**:
   - Update `test/features/templates/widgets/blueprint_selection_modal_test.dart` to assert that 5 blueprints render successfully.
   - Run tests to verify completeness and correctness.

2. **Visual QA Check**:
   - Run a test of `BlueprintSelectionModal` to guarantee proper layout rendering.
