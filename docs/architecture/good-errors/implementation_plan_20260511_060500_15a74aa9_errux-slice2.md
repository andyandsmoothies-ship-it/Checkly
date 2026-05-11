# Implementation Plan: Empathetic Error UX — Slice 2 (Admin)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260510_185956_errux_good-errors.md`

## Executive Summary & Out of Scope

**Goal:** Migrate all raw `ScaffoldMessenger` catch blocks inside the `lib/features/admin` directory to use the new centralized `ErrorDisplayService`. This is the first adoption slice.

**Out of Scope (this slice):**
- Modifying `lib/features/auth`, `lib/features/profile`, etc. (Reserved for Slices 3-4)
- Changing business logic or states of the widgets. We only replace the error display code.
- Fixing underlying API issues.

---

## Target Files

A total of 41 `ScaffoldMessenger.of(context).showSnackBar` calls have been identified inside `catch` blocks within the `admin` feature.

Files to modify:
1. `lib/features/admin/widgets/user_management_dialogs.dart` (1 call)
2. `lib/features/admin/widgets/user_edit_sheet.dart` (1 call)
3. `lib/features/admin/widgets/user_create_sheet.dart` (2 calls)
4. `lib/features/admin/widgets/schedule_audit_form.dart` (4 calls)
5. `lib/features/admin/widgets/area_sheets.dart` (6 calls)
6. `lib/features/admin/pages/widgets/store_form_sheet.dart` (3 calls)
7. `lib/features/admin/pages/widgets/risk_form_sheet.dart` (8 calls)
8. `lib/features/admin/pages/user_management_page.dart` (7 calls)
9. `lib/features/admin/pages/system_log_detail_page.dart` (1 call)
10. `lib/features/admin/pages/store_management_page.dart` (2 calls)
11. `lib/features/admin/pages/role_detail_page.dart` (1 call)
12. `lib/features/admin/pages/audit_approval_page.dart` (4 calls)
13. `lib/features/admin/pages/admin_dashboard_page.dart` (1 call)

---

## Proposed Changes

**Old Code:**
```dart
} on DioException catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.response?.data?['message'] ?? 'Failed to update user')),
    );
  }
} catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update user: $e')),
    );
  }
}
```

**New Code:**
```dart
} on DioException catch (e) {
  _di<ErrorDisplayService>().show(AppError.fromDioException(e));
} catch (e) {
  _di<ErrorDisplayService>().show(AppError(code: 'unknown', message: 'Failed to update user'));
}
```
*Note: Make sure to import `get_it`, `app_error.dart`, and `error_display_service.dart`. `_di` is usually defined as `GetIt.instance`.*

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Missed imports causing compilation errors | Medium | Run `flutter analyze` after refactoring. Ensure `AppError` and `ErrorDisplayService` are imported everywhere they are used. |
| Dropping custom logic that is currently embedded in catch blocks | Medium | Review catch blocks manually before replacing to ensure no state updates (like `setState(() { isLoading = false; })`) are inadvertently deleted. |

---

## Verification Plan

1. Run `rtk flutter analyze` to ensure no syntax errors and all imports are correct.
2. Ensure 0 usages of `ScaffoldMessenger.of(context).showSnackBar` remain within `lib/features/admin` that deal with error handling.

---

## Handoff Block

**Summary:** Refactor 41 error catch blocks in the `lib/features/admin` module to use the new `ErrorDisplayService`.

**Strict Constraints for Next Agent:**
1. Replace `ScaffoldMessenger.of(context).showSnackBar` with `_di<ErrorDisplayService>().show(AppError.fromDioException(e))` for DioExceptions.
2. For generic `catch (e)` blocks, map it to `AppError(code: 'unknown')`.
3. Do NOT delete any surrounding state changes (like `setState` or `isLoading = false`).
4. Remember to import `AppError`, `ErrorDisplayService`, and `GetIt` if not present.

**Route:** Logic/Standard → Build (Route 2)

```
Step 1 — Build:
@[/implement] Execute build for Slice 2 (Admin): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_060500_15a74aa9_errux-slice2.md
```
