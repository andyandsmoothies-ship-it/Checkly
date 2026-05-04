# Failure Report: Criteria Input Type Selection Bug

## Input Lineage
- **Source Input**: `User Bug Report: Cannot select Single/Multi Choice or Text Input when Checklist Mode is active.`

## Root Cause
The `CriterionEditorDrawer` widget contained a premature `Navigator.pop(context)` call immediately before `await showModalBottomSheet(...)`. This caused the drawer to unmount while the user was interacting with the `InputTypeBottomSheet`. When the bottom sheet returned the user's selection, the `context.mounted` safety check evaluated to `false` because the parent drawer no longer existed in the widget tree. Consequently, the state update block (`widget.criterion.inputType = selected;`) was entirely bypassed, leaving the input type stuck at its default (`pass_fail`).

## Explicit Code Trace (Premises + Proof)
1. **Premise 1**: When tapping the "Input Type" `ActionChip` in `criterion_editor_drawer.dart`, it executes `Navigator.pop(context)` followed by `await showModalBottomSheet<String>(...)`.
2. **Premise 2**: `Navigator.pop(context)` removes `CriterionEditorDrawer` from the Flutter widget tree, rendering its `BuildContext` unmounted.
3. **Proof**: After the `await` resumes (user selects an input type), the code attempts `if (selected != null && context.mounted)`. Since the widget was already popped, `context.mounted` is `false`, and the assignment `widget.criterion.inputType = selected` is ignored.

## Proposed Scope-Limited Fix
The bug was resolved via a micro-experiment by removing the premature `Navigator.pop(context)` at line 101 of `criterion_editor_drawer.dart`.

**Trade-offs / Pros & Cons**:
- *Pros*: The drawer stays mounted in the background while the input type selector is open. When the user selects a new type, `context.mounted` remains `true`, the state updates, and `widget.onRequestRebuild()` safely handles the closure and reopening of the drawer to refresh the UI.
- *Cons*: Visually, the user will now see two Bottom Sheets stacked momentarily (the selector overlapping the drawer), which is standard Material Design behavior but slightly different from the previous (broken) intent of swapping them out.

<forensic_evidence>
cmd /c rtk flutter analyze lib/features/templates/widgets/criterion_editor_drawer.dart
Analyzing criterion_editor_drawer.dart...
No issues found! (ran in 2.9s)
</forensic_evidence>

## Handoff Block
1. **Verdict**: The bug is a premature widget unmount causing state-loss during an async `BuildContext` execution gap.
2. **Fix & Blast Radius**: Removed 1 line (`Navigator.pop(context);`) from `criterion_editor_drawer.dart`. Blast radius is completely isolated to the criterion editor UI. No backend or data schema changes.
3. **Mission Brief**: The UI bug preventing input type changes in the criteria builder has been successfully patched and analyzed. No further coding is required.

**Execution Queue**:
- [x] Bug verified, patched, and analyzed.
- [ ] You may close this session or proceed to the next feature request.
