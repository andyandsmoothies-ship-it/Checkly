# Task: Store Saving Hang

Workflow: /implement | Track: B1

## Input Lineage

- **Source Input**: `lib/features/admin/pages/widgets/store_form_save_logic.dart`

## Steps

- [x] Step 2: Symptom Isolation
- [x] Step 3: Skill & Rule Discovery
- [x] Step 4: Resolution Plan
- [x] Step 5: Deliverable Handoff

## Diagnostic Log

### 1. Initial Hypothesis
The `saveStore` method sets `isSaving = true` but never resets it to `false` in the success path. Simultaneously, `isDirty` is set to `false` without triggering a `setState` rebuild. This leaves `isDirty` as `true` in the widget tree, blocking the `Navigator.maybePop(context)` via `UnsavedChangesGuard`'s `PopScope`, which causes the saving progress indicator to spin indefinitely.

### 2. Evidence Gathered
- In `store_form_save_logic.dart`:
  - Line 114: `setState(() => isSaving = true);` is called at the start of the save pipeline.
  - Line 156-157: On success, `isDirty = false;` is set directly (no `setState`), followed by `Navigator.maybePop(context)`.
  - Line 169-178: In the `catch` block, `setState(() => isSaving = false);` is called.
  - No `setState(() => isSaving = false)` is called on the success path.
- In `store_form_sheet.dart`:
  - `UnsavedChangesGuard` wraps the body, bound to `isDirty`. Because `setState` is not called, `UnsavedChangesGuard` still sees `isDirty == true`, preventing the pop.

### 3. Falsifiable Hypotheses
1. **Hypothesis A**: Changing `isDirty = false;` to a `setState` block that sets both `isDirty = false` and `isSaving = false` before popping will allow the `Navigator.maybePop` to succeed, and even if it does not, it will stop the spinner.
2. **Hypothesis B**: If `Navigator.maybePop` is blocked by some other route guard, the saving spinner will still stop if we reset `isSaving = false` on success.
3. **Hypothesis C**: The API call does not complete, but logs show PUT responded 200, so the API is successful.

### 4. Root Cause Identified
State mutation (`isDirty = false`) occurred outside a `setState` callback on successful store saving, leaving the `UnsavedChangesGuard` in a stale dirty state that blocked route popping. In addition, the `isSaving` flag was never reset to `false` in the success path.

### 5. Fix Strategy
Wrap the state mutations (`isDirty = false`, `isSaving = false`) on successful store save in a `setState` callback before calling `Navigator.maybePop(context)`.

## Artifact Inventory

| Status | File Path | Type |
| :--- | :--- | :--- |
| [NEW] | docs/reports/diagnostics/failure_report_20260605_164000.md | Report |
| [NEW] | docs/features/store-save-hang/walkthrough_store-save-hang_20260605_234400.md | Walkthrough |
| [NEW] | docs/reports/qa/store-save-hang/green_test_log_store-save-hang_20260605_234400.md | Test Log |


