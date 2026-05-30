# Walkthrough - Weighted Accumulation Scoring Slice 5

## Metadata
- **ConversationID**: `f625c2e4-0fdd-4c33-9271-185cf5df427c`
- **Timestamp**: `2026-05-30T21:15:00`
- **Feature**: Weighted Accumulation Scoring Redesign
- **Slice**: Slice 5 (HeaderCard Info Row Verification)

---

## 1. Executive Summary

This walkthrough documents the visual verification slice for the new **Weighted Accumulation Scoring** info row in the Checkly Submission `HeaderCard`.

We locked down the conditional info row rendering logic via a set of comprehensive widget tests. The info row displays the text `'Final score is weighted based on section importance.'` along with `Icons.info_outline` when `isWeighted` is enabled, and hides the entire row when the submission is unweighted or `isWeighted` is null.

---

## 2. Visual Architecture

```text
[Submission Detail DTO]
        │
        ▼
 [HeaderCard widget] ─── isWeighted == true ───> [Renders Info Row with Icon]
        │
        └────────────── isWeighted == false ──> [Hides Info Row]
```

---

## 3. Detailed Component Review

### 3.1 HeaderCard (`lib/features/audit/widgets/header_card.dart`)
- **Action**: Verified the conditional info row display logic.
- **Math Info**: Displays the helper message inside a flex row with `Expanded` text wrapping to prevent overflows on small screens.

### 3.2 Widget Tests (`test/features/audit/widgets/header_card_test.dart`)
- **Action**: Created a comprehensive test suite to pump `HeaderCard` and assert visibility based on the `isWeighted` property:
  - **TC-HC-01**: Asserts the info row is present when `isWeighted == true`.
  - **TC-HC-02**: Asserts the info row is absent when `isWeighted == false`.
  - **TC-HC-03**: Asserts the info row is absent when `isWeighted == null`.

---

## 4. Verification Methods

### Automated Tests
Run the new widget test suite:
```cmd
rtk flutter test test/features/audit/widgets/header_card_test.dart
```
All tests passed successfully on the first run.
