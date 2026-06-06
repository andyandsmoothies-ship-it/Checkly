---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
Type: plan
Topic: fix-unsaved-changes-guard
Date: 2026-06-06
---

# Plan: Fix Unsaved Changes Guard in Admin Sheets

This plan addresses the race condition where `UnsavedChangesGuard` / `PopScope` intercepts programmatic sheet closure because `isDirty` is still true or the widget has not rebuilt before the pop fires.

## Diagnostic Diagram

```
[User Forms (Create/Edit User/Risk)]
   |
   +--> User modifies fields (isDirty = true)
   |
   +--> User clicks Save/Create
   |       |
   |       +--> API Success / Action Triggered
   |       |       |
   |       |       +--> [BUG] Navigator.maybePop() fired synchronously
   |       |       |     |
   |       |       |     +--> PopScope reads OLD isDirty=true
   |       |       |     +--> Shows "Discard changes?" dialog
   |       |       |
   |       |       +--> [FIX] setState(isDirty = false)
   |       |       +--> [FIX] Defer maybePop() to next frame (addPostFrameCallback)
   |       |             |
   |       |             +--> PopScope builds with isDirty=false
   |       |             +--> Pops cleanly without dialog
```

## Proposed Changes

### 1. `lib/features/admin/widgets/user_create_sheet.dart`
- In `_submit`, when `widget.onCreate` succeeds, set `isDirty = false` inside `setState`.
- Schedule sheet closure based on `WidgetsBinding.instance.schedulerPhase` to ensure clean pop:
  ```dart
  void pop() {
    if (mounted) Navigator.maybePop(context, true);
  }
  if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
    WidgetsBinding.instance.addPostFrameCallback((_) => pop());
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pop());
    });
  }
  ```

### 2. `lib/features/admin/widgets/user_edit_sheet.dart`
- In `onSave` callback, set `isDirty = false` inside `setState`.
- Schedule the parent's `onSave` callback execution to prevent premature pop:
  ```dart
  void save() {
    widget.onSave(...);
  }
  if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
    WidgetsBinding.instance.addPostFrameCallback((_) => save());
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => save());
    });
  }
  ```

### 3. `lib/features/admin/pages/widgets/risk_form_sheet.dart`
- In `FilledButton.onPressed` handler, for `isEdit` (save), new risk (create), and deactivation paths, set `isDirty = false` inside `setState`.
- Schedule sheet closure based on `schedulerPhase`:
  ```dart
  void pop() {
    if (context.mounted) Navigator.maybePop(context);
  }
  if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
    WidgetsBinding.instance.addPostFrameCallback((_) => pop());
  } else {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pop());
    });
  }
  ```

## Verification Strategy

### Verification Commands
We will run Flutter integration/widget tests:
```cmd
cmd /c "cd lib ; flutter test test/features/admin"
```
*(We will inspect if there are admin tests in the next steps).*
