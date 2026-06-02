---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
---
# Task: Overdue Action Plans Scroll Lock

Workflow: /diagnose | Track: A

## Input Lineage

- **Source Input**: `lib/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart`
- **Symptom Image**: User screenshot of modal panel titled "All Overdue Action Plans"

## Steps

- [x] Step 2: Symptom Isolation
- [ ] Step 3: Skill & Rule Discovery
- [ ] Step 4: Resolution Plan
- [ ] Step 5: Deliverable Handoff

## Reasoning Steps

### 1. Initial Hypothesis
The modal bottom sheets `BodApBucketDetailSheet` and `AreaBodApBucketDetailSheet` utilize a `ListView.separated` wrapped in a `Flexible` component. However, the scroll physics is hardcoded as `NeverScrollableScrollPhysics()`, which explicitly disables touch-scroll behaviors on the list. Changing the physics will allow proper scroll gestures.

### 2. Evidence Gathered
- **Failing Tests**: Created `test/features/analytics/widgets/bod_ap_bucket_detail_sheet_test.dart` and ran it. It failed with `Actual: NeverScrollableScrollPhysics` for both list views, confirming the root cause is present.
- **Code Trace**:
  - `lib/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart` at line 108: `physics: const NeverScrollableScrollPhysics(),`
  - `lib/features/analytics/widgets/area_bod_ap_bucket_detail_sheet.dart` at line 114: `physics: const NeverScrollableScrollPhysics(),`

### 3. Root Cause Identified
Hardcoded `NeverScrollableScrollPhysics()` on the list views in the bottom sheets, which forces the sheets to remain locked/unscrollable even when the content overflows the screen vertically.

### 4. Fix Strategy
- Replace `NeverScrollableScrollPhysics()` with scrollable physics such as `BouncyScrollPhysics()` (duolingo bounce / premium vibe) or default scroll physics.
- Verify that tests pass.

## Falsifiable Hypotheses
1. **Hypothesis 1**: If the scroll physics is changed from `NeverScrollableScrollPhysics` to `BouncyScrollPhysics`, the widget test checking for `NeverScrollableScrollPhysics` will pass.
2. **Hypothesis 2**: If the list contains more items than the viewport height allows, changing the physics will allow the list to be scrolled without throwing an overflow exception because the outer wrapper is constrained by `Flexible` and the bottom padding respects the keyboard/safe area.
3. **Hypothesis 3**: If we keep `NeverScrollableScrollPhysics` but add a scrollable parent like `SingleChildScrollView`, it will conflict with `ListView` rendering and cause layout crashes, proving that direct scrollable physics on the `ListView` itself is the only correct strategy.

## Artifact Inventory

| Status | File Path | Type |
| [NEW]  | docs/reports/diagnostics/failure_report_overdue_ap_scroll_20260602_084000.md | Report |

