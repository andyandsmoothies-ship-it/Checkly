# Implementation Plan: Empathetic Error UX — Slice 4 (Global Sweep)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260510_185956_errux_good-errors.md`

## Executive Summary & Out of Scope

**Goal:** Sweep the entire `lib/` directory for any remaining raw `ScaffoldMessenger.of(context).showSnackBar` calls that are handling *errors* and replace them with the global `ErrorDisplayService`. This includes missed files in the `admin` module and all other feature modules (`action_plans`, `audit`, `dashboard`, `programs`, `templates`, `user_groups`). 

**Out of Scope (this slice):**
- Modifying `ScaffoldMessenger` calls that show **success** or **informational** messages (e.g., "Saved successfully", "Coming soon"). These must be left alone. `ErrorDisplayService` is exclusively for errors.

---

## Target Files

A global sweep identified the following modules/files containing `ScaffoldMessenger.of`:

**Missed Admin Files (from Slice 2):**
- `lib/features/admin/pages/audit_approval_page.dart`
- `lib/features/admin/pages/store_management_page.dart`
- `lib/features/admin/pages/system_log_detail_page.dart`
- `lib/features/admin/pages/user_management_page.dart`
- `lib/features/admin/pages/widgets/risk_form_sheet.dart`
- `lib/features/admin/pages/widgets/store_form_sheet.dart`
- `lib/features/admin/widgets/area_sheets.dart`
- `lib/features/admin/widgets/schedule_audit_form.dart`
- `lib/features/admin/widgets/user_create_sheet.dart`
- `lib/features/admin/widgets/user_management_dialogs.dart`

**Other Feature Modules:**
- `lib/features/action_plans/pages/action_plan_detail_page.dart`
- `lib/features/action_plans/widgets/stale_conflict_banner.dart`
- `lib/features/action_plans/widgets/submit_evidence_sheet.dart`
- `lib/features/audit/pages/audit_form_page.dart`
- `lib/features/audit/pages/widgets/history_list_view.dart`
- `lib/features/audit/widgets/audit_form_dialogs.dart`
- `lib/features/audit/widgets/audit_photo_section.dart`
- `lib/features/dashboard/pages/widgets/submission_row.dart`
- `lib/features/programs/pages/program_create_wizard_page.dart`
- `lib/features/programs/pages/program_execution_page.dart`
- `lib/features/programs/pages/widgets/program_evidence_form.dart`
- `lib/features/templates/pages/template_builder_page_logic.dart`
- `lib/features/templates/pages/template_wizard_page.dart`
- `lib/features/templates/pages/wizard_validators.dart`
- `lib/features/templates/widgets/template_card.dart`
- `lib/features/templates/widgets/wizard_step_sections.dart`
- `lib/features/user_groups/widgets/create_group_sheet.dart`

*(Note: `lib/features/profile/widgets/settings_section_group.dart` contains a "Coming soon" info message, so it should be skipped.)*

---

## Proposed Changes

**Code Pattern for Error Replacement:**
```dart
// OLD:
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to perform action: $e')),
      );
    }

// NEW:
    } on DioException catch (e) {
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (e) {
      _di<ErrorDisplayService>().show(AppError(code: 'unknown', message: 'Failed to perform action'));
    }
```

*Note on `_di`: Ensure `final _di = GetIt.instance;` is defined at the top of the file if not already present, along with the `AppError` and `ErrorDisplayService` imports.*

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Accidental migration of a success message | Low | Builder agent is strictly instructed to check the content of the `SnackBar`. If the text implies success or info (e.g. "Saved", "Created", "Coming soon"), skip it. |
| Missing `GetIt` or `ErrorDisplayService` imports | Medium | The builder will run `flutter analyze` after refactoring to ensure all imports are properly resolved. |
| Catch block variable scoping | Low | Standardizing on `DioException` and generic `catch` ensures `e` is properly typed where necessary. |

---

## Verification Plan

1. The builder will use regex or search to replace the error `ScaffoldMessenger` blocks.
2. The builder will run `rtk flutter analyze` to catch missing imports or syntax errors.
3. Verify that zero raw `ScaffoldMessenger` *error* calls remain in the `lib/` directory (excluding intentional success/info messages).

---

## Handoff Block

**Summary:** Execute a global sweep to replace remaining error-based `ScaffoldMessenger` catch blocks with `ErrorDisplayService`.

**Strict Constraints for Next Agent:**
1. Iterate over the identified target files.
2. Look at each `ScaffoldMessenger.of(context).showSnackBar` call.
3. **CRITICAL:** If the message inside the SnackBar implies success or is informational (e.g. "Coming soon", "Template updated"), **DO NOT TOUCH IT**.
4. If it is an error (typically found in a `catch` block or logging a failure), replace it with `_di<ErrorDisplayService>().show(...)`. If a `DioException` might be thrown, prefer `AppError.fromDioException`.
5. Add necessary imports:
   ```dart
   import 'package:get_it/get_it.dart';
   import '../../../_shared/services/error_display_service.dart';
   import '../../../_shared/exceptions/app_error.dart';
   import 'package:dio/dio.dart'; // If adding on DioException
   ```
6. Ensure to run `flutter analyze` continuously as you modify files to catch missing imports. This slice involves many files, so process them in batches if needed.

**Route:** Logic/Standard → Build (Route 2)

```
Step 1 — Build:
@[/implement] Execute build for Slice 4 (Global Sweep): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_063500_15a74aa9_errux-slice4.md
```
