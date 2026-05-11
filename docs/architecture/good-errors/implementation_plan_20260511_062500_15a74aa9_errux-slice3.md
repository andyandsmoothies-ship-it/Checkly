# Implementation Plan: Empathetic Error UX — Slice 3 (Profile & Auth)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260510_185956_errux_good-errors.md`

## Executive Summary & Out of Scope

**Goal:** Migrate legacy error handling blocks inside the `lib/features/auth` and `lib/features/profile` directories to use the new centralized `ErrorDisplayService`. This eliminates hardcoded error parsing logic (like searching for '401' strings) and unifies the error UX across the application.

**Out of Scope (this slice):**
- Modifying `lib/features/admin` (Done in Slice 2)
- Sweeping remaining features like templates, audits, action plans (Reserved for Slice 4)
- Changing business logic or states of the widgets. We only replace the error display code.

---

## Target Files

A total of 2 key files have been identified within the `profile` and `auth` features that use legacy error handling.

Files to modify:
1. `lib/features/auth/pages/login_page.dart`
   - **Current State:** Catches errors, uses a local `_parseError` method checking raw string messages (`msg.contains('401')`), and sets a local `_errorMessage` state to display inline.
   - **Change:** Remove `_parseError` and `_errorMessage` entirely. Call `_di<ErrorDisplayService>().show(AppError.fromDioException(e))` and rely on the global error SnackBar.
2. `lib/features/profile/manager/profile_manager.dart`
   - **Current State:** Catches internal DB errors and sets `error = 'Failed to load activity'`.
   - **Change:** Call `_di<ErrorDisplayService>().show(AppError(code: 'unknown', message: 'Failed to load activity'))` instead of storing the error in state, assuming the global service handles it. (If local error state is required by the UI to show an inline error, keep the state but maybe map through `ErrorDictionary`. However, standardizing on `ErrorDisplayService` is preferred). Note: Ensure `AppError` and `ErrorDisplayService` are imported. 

---

## Proposed Changes

**`login_page.dart` Code Pattern:**
```dart
// OLD:
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e);
      });
    } finally { ... }

// NEW:
    } on DioException catch (e) {
      _di<ErrorDisplayService>().show(AppError.fromDioException(e));
    } catch (e) {
      _di<ErrorDisplayService>().show(AppError(code: 'unknown', message: 'Login failed'));
    } finally { ... }
// NOTE: Also remove `_errorMessage`, `_parseError`, and the inline error Container widget.
```

**`profile_manager.dart` Code Pattern:**
```dart
// OLD:
    } catch (e) {
      error = 'Failed to load activity';
    } finally { ... }

// NEW:
    } catch (e) {
      _di<ErrorDisplayService>().show(AppError(code: 'unknown', message: 'Failed to load activity'));
    } finally { ... }
// NOTE: Also remove the `error` state property if it's no longer used in `ActivityHistoryPage`. (Will need to check `ActivityHistoryPage` in `lib/features/profile/pages/activity_history_page.dart` to ensure we don't break the UI).
```

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Breaking `ActivityHistoryPage` by removing `ProfileManager.error` | Medium | If `ActivityHistoryPage` relies on the `error` property to show a "Retry" button instead of a list, removing it could break the UI. Mitigation: leave `error` state for local UI binding, but *also* trigger `ErrorDisplayService` if necessary. Better yet, let `ActivityHistoryPage` handle its own visual states. If we remove `error`, ensure the UI still renders gracefully (e.g. shows empty list or keeps previous list). |
| Removing inline error from `LoginPage` reduces UX | Low | A SnackBar is a standard pattern for login errors. `ErrorDisplayService` is designed to be the central unified way. It is acceptable to switch from inline to SnackBar for standardizing. |
| Missed imports causing compilation errors | Medium | Run `flutter analyze` after refactoring. Ensure `AppError` and `ErrorDisplayService` are imported everywhere they are used. |

---

## Verification Plan

1. Run `rtk flutter analyze` to ensure no syntax errors and all imports are correct.
2. Ensure `_parseError` is fully removed from `LoginPage`.
3. Check `ActivityHistoryPage` builds correctly without referencing `ProfileManager.error` (if removed).

---

## Handoff Block

**Summary:** Refactor error catch blocks in the `auth` and `profile` modules to use the new `ErrorDisplayService`.

**Strict Constraints for Next Agent:**
1. In `login_page.dart`, completely remove the inline `_errorMessage` state, the `_parseError` function, and the UI container displaying the error. Replace the catch block with calls to `ErrorDisplayService`.
2. In `profile_manager.dart`, check if `error` is used by the UI (`lib/features/profile/pages/activity_history_page.dart`). If yes, you may need to update the UI to either not use the `error` field, or keep the field and just update how errors are logged. The goal is to route errors to `ErrorDisplayService`.
3. Remember to import `AppError`, `ErrorDisplayService`, and `GetIt` if not present.

**Route:** Logic/Standard → Build (Route 2)

```
Step 1 — Build:
@[/implement] Execute build for Slice 3 (Profile & Auth): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\good-errors\implementation_plan_20260511_062500_15a74aa9_errux-slice3.md
```
