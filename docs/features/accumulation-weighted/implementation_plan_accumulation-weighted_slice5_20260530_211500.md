<latent_space_scratchpad>
## Edge Cases & Visual Risks
1. **Empty / Null values**: `isWeighted` defaults to null or false. In this case, `HeaderCard` should hide the info row completely.
2. **Text Overflow in Small Devices**: The info row contains text `'Final score is weighted based on section importance.'`. We must verify that it uses an `Expanded` widget to wrap cleanly without layout overflows.
3. **Purity Checklist**:
   - `HeaderCard` is already written cleanly using `Expanded` on the text.
   - It is also wrapped inside a `StrokeCard` to enforce Duolingo Reskin Aesthetics.
   - No additional layout fixes are needed, but we must verify it in widget tests.
</latent_space_scratchpad>

# Implementation Plan: Slice 5 HeaderCard Info Row

## Input Lineage
- **Source Epic**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\analysis_epic_20260530_172200.md`

## Executive Summary & Out of Scope
- **Goal**: Verify and ensure the `HeaderCard` widget displays the helper info row when the submission has weighted scoring enabled (`isWeighted == true`). This guarantees users understand the calculation math behind their score.
- **Out of Scope**: 
  - Modifying the underlying calculation engines or DB structure.
  - Adding help buttons or tooltip modals to the info row.

## System Context
- **Offline/Online**: Consistent across both states. The detail view displays the cached submission DTO.
- **Capabilities**: Available to all roles. No PBAC limitations.

## Lifecycle Context
### 4-State Matrix (HeaderCard)
- **Success**: Submission details render with appropriate score, and the info row is displayed if `isWeighted == true`.
- **Loading**: Parent detail page shows a shimmer loader; `HeaderCard` is not mounted.
- **Error**: Error state displays a fallback panel; `HeaderCard` is not mounted.
- **Empty**: Fallback template detail panel; `HeaderCard` is not mounted.

## Constraint Traceability

| Constraint ID | Description | Test Contract ID |
|---|---|---|
| C1 | Info row appears when `isWeighted == true` | TC-HC-01 |
| C2 | Info row is hidden when `isWeighted == false` or `null` | TC-HC-02 |

## Test Contracts

| Contract ID | Scenario | Input State | Expected Output / Assertion |
|---|---|---|---|
| **TC-HC-01** | Weighted Accumulation | `SubmissionDetailDto` with `isWeighted: true` | Info row icon and message are visible |
| **TC-HC-02** | Unweighted Accumulation | `SubmissionDetailDto` with `isWeighted: false` | Info row is not rendered |

## Test Fixture & Payloads
- No network payloads needed; this is a pure widget render test.
- A standard mock `SubmissionDetailDto` will be used with varying `isWeighted` states.

## Tools & Commands
- **Flutter SDK**
- Command: `rtk flutter test test/features/audit/widgets/header_card_test.dart`

## Proposed Changes

### UI Component Layout & Text Safeties

| Component | Truncation Limit | Overflow Action | Required New Route |
|---|---|---|---|
| `HeaderCard` Info Row Text | 3 Lines | Wrap to next line gracefully | None (Uses `Expanded` text wrapping) |

### [NEW] `test/features/audit/widgets/header_card_test.dart`
- Write a new widget test that pumps `HeaderCard` with different `SubmissionDetailDto` states and asserts row visibility.

## Concept Diagram
```
[Submission Detail DTO]
        |
        v
 [HeaderCard widget] -- isWeighted == true --> [Renders Info Row with Icon]
        |
        +------------- isWeighted == false --> [Hides Info Row]
```

## Execution Slices

### Slice 5: HeaderCard Info Row verification
- **Summary**: Verify and lock down info row rendering logic via a comprehensive widget test.
- **Value**: Ensure perfect layout safety and prevent visual regressions for weighted scoring modes.
- **Complexity**: 🟢 Safe Scope / Easy
- **Entry State Required**: Existing `HeaderCard` compiles.
- **Exit State Guaranteed**: Widget tests cover all weighted/unweighted visibility paths and pass seamlessly.

## Handoff Block
Next Step: **Write Widget Tests**, then **Build Step** for [Slice 5].
Plan Path: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_accumulation-weighted_slice5_20260530_211500.md`
