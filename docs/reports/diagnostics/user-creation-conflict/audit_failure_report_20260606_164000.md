---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
Type: report
Topic: user-creation-conflict-audit
Date: 2026-06-06
---

# Failure Report: User Creation Conflict / Unsaved Changes Guard

## First Principles Gate

### 1. Physics & Limit
- **Limit**: The user's action and API response cycle.
- **Scale Failure Point**: The bug occurs at any scale because it is a synchronous lifecycle race condition between the Flutter widget rebuild queue (triggered by `setState`) and the programmatic pop navigation (`Navigator.maybePop`). 

### 2. Simplicity
- **Approach**: Ensure the widget has completely rebuilt with `isDirty = false` before triggering navigation.
- **Bloat Check**: No extra files or external dependencies are introduced. The scheduling uses standard Flutter lifecycle callbacks.

### 3. Blast Radius
- **Affected Components**: User Creation Sheet, User Edit Sheet, and Risk Form Sheet.
- **Fail-Safe**: If scheduling fails, the forms will simply fail to pop programmatically, which is monitored and verified via widget integration tests.

### 4. Observability
- **Metrics**: Sneak-peek test assertion passes, no "Discard changes?" dialog shows during positive flow.
- **Success Criteria**: `unsaved_changes_guard_sheet_test.dart` passes.

---

## Discovered Flops

### 🔴 Critical: Multi-Submit and Email Conflict
- **Flop**: The race condition blocks the sheet from closing and displays the "Discard changes?" dialog.
- **Consequence**: The user clicks "Keep Editing" and submits the form again. The second request fails with a validation error "a user with this email already existed" because the first request was actually successful and created the user in the database.
- **Mitigation**: Using a robust post-frame callback sequence guarantees the sheet closes immediately on success, preventing double submission.

### 🟡 Warning: Scheduler Phase Misalignment
- **Flop**: Using `addPostFrameCallback` when the scheduler is not `idle` executes the callback at the end of the current frame, before the next frame's rebuild occurs.
- **Consequence**: The `PopScope` reads `isDirty` as `true` during the pop attempt.
- **Mitigation**: Check `WidgetsBinding.instance.schedulerPhase` and nest callbacks when not `idle`.
