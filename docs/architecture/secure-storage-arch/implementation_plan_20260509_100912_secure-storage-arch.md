# Task: Secure Storage Architectural Fix
Workflow: /analyze-feature | Track: B1

<latent_space_scratchpad>
- The current `ThemeManager` uses `flutter_secure_storage` to save a non-sensitive setting (`app_theme_mode`).
- `flutter_secure_storage` is an encrypted vault meant for tokens and secrets.
- `SecureStorageService.clearAll()` was crashing on Windows because it tried to sequentially delete the token and session (to preserve the theme). 
- We patched it by making it backup the theme and call `deleteAll()`, but the *real* fix is moving `ThemeManager` to `shared_preferences`.
- Risk: If we drop the old secure storage key, users who have set "Dark Mode" explicitly will be reset to the system default/light mode upon upgrade. Since it's just a theme setting, a migration script is overkill. We will accept the reset as an acceptable tradeoff.
- We need to add `shared_preferences` to `pubspec.yaml`.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `docs/diagnostics/failure_report_20260509_100153_secure-storage.md`

## Executive Summary & Out of Scope
**Summary**: Decouple `ThemeMode` persistence from `FlutterSecureStorage` by migrating `ThemeManager` to the industry-standard `shared_preferences` package. This allows `SecureStorageService.clearAll()` to become a pure, ignorant `deleteAll()` wrapper, permanently resolving any file locking and architectural mixing of secrets and preferences.

**Out of Scope**: 
- Writing a migration script to copy the old secure theme value to the new unencrypted preferences. The user's theme will reset to default upon upgrade.
- Upgrading or changing any other state managers.

> [!WARNING]
> **Risk Evaluation**: Adding a new dependency (`shared_preferences`) increases app bundle size marginally. Users' existing theme preference will be reset. The ROI is high as it fully decouples secrets from standard UI preferences and stabilizes the auth-logout flow completely.

## Risk Assessment
Adding a new dependency (`shared_preferences`) increases app bundle size marginally. Users' existing theme preference will be reset. The ROI is high as it fully decouples secrets from standard UI preferences and stabilizes the auth-logout flow completely.

## System Context
- **Offline/Online**: N/A. Pure local state.
- **RBAC**: N/A.
- **Environment**: Cross-platform (Android, iOS, Windows).

## Lifecycle Context
- **Success**: The `ThemeManager` smoothly reads the string from `SharedPreferences` on app load.
- **Empty**: Defaults to `ThemeMode.light` if no key exists.
- **Loading**: `ThemeManager.init()` is awaited synchronously in `main.dart` before `runApp`.

## Test Contracts

| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-SEC-01 | ThemeManager reads/writes from SharedPreferences | Success | `ThemeManager` currently relies on `FlutterSecureStorage`. |
| TC-SEC-02 | SecureStorageService calls deleteAll blindly | Success | It currently contains logic to backup and restore `app_theme_mode`. |

## Test Fixture & Payloads
- **Requires**: `flutter test` execution. Since `ThemeManager` is lightly mocked in existing tests, the swap should not break UI tests, but all 467 tests must pass.

## Tools & Commands
- **Skills**: `flutter-architecture`, `flutter-api`.
- **Commands**: 
  - `rtk flutter pub add shared_preferences`
  - `rtk flutter test`

## Verification Plan
1. Ensure the app builds with `shared_preferences` installed.
2. Toggle the theme, close the app, reopen, and ensure the theme was restored.
3. Call `SecureStorageService.clearAll()` via logout and ensure no file lock exceptions occur and the theme isn't wiped.

## Proposed Changes
- `[MOD]` `pubspec.yaml`: Add `shared_preferences`.
- `[MOD]` `lib/_shared/theme/theme_manager.dart`: Refactor to use `SharedPreferencesAsync`.
- `[MOD]` `lib/features/auth/services/secure_storage_service.dart`: Simplify `clearAll()`.

## Concept Diagram
```text
[ThemeManager] --> (SharedPreferences) 
[SecureStorageService] --> (FlutterSecureStorage)
   ↳ clearAll() --> _storage.deleteAll() (No more theme backup logic)
```

## Execution Slices

### Execution Phase: Storage Decoupling
- **Plain English Summary**: Add `shared_preferences`, rewrite `ThemeManager` to use it, and strip the theme-backup logic out of `SecureStorageService.clearAll()`.
- **Value Delivered**: Perfect architectural separation of secrets and standard preferences.
- **Entry/Exit State**: `ThemeManager` uses secure storage → `ThemeManager` uses shared preferences.
- **Scope**: `pubspec.yaml`, `theme_manager.dart`, `secure_storage_service.dart`.
- **Acceptance Criteria**: App compiles, theme changes persist between reboots, tests pass.
- **Complexity**: Low. Simple API swap.
- **Pros & Cons**: 
  - *Pros*: Clean architecture, prevents future `clearAll()` bugs.
  - *Cons*: User theme preference is reset on update.

## Handoff Block
The architectural fix has been evaluated. It is a straightforward dependency addition and API swap.
- [ ] `@[/implement] docs/architecture/implementation_plan_20260509_100912_secure-storage-arch.md`
