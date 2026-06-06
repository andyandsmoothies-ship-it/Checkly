---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
Type: task
Topic: user-creation-conflict
Date: 2026-06-06
---

# Task: User Creation Conflict Fix

This task implements the fix for `UnsavedChangesGuard` programmatic sheet closing race condition in user management and global risk forms.

## Tasks

- [x] Step 1: Diagnose issue and create plan: [plan_user-creation-conflict_20260606_134000.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/features/user-creation-conflict/plan_user-creation-conflict_20260606_134000.md)
- [x] Step 2: Modify `lib/features/admin/widgets/user_create_sheet.dart` to reset `isDirty` and defer `Navigator.maybePop`.
- [x] Step 3: Modify `lib/features/admin/widgets/user_edit_sheet.dart` to reset `isDirty` and defer `widget.onSave`.
- [x] Step 4: Modify `lib/features/admin/pages/widgets/risk_form_sheet.dart` to reset `isDirty` and defer `Navigator.maybePop`.
- [x] Step 5: Verify compilation and run test suite.
