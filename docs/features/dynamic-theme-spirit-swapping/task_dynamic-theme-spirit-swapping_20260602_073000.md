---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
Type: Task List
Topic: Dynamic Theme & Spirit Swapping Tasks
Date: 2026-06-02
---

# Tasks: Dynamic Theme & Spirit Swapping

- [x] **Slice 1: State & Decoupling Foundation**
  - [x] Create `lib/_shared/theme/app_theme_notifier.dart` with `ThemeSpiritNotifier` extending `ValueNotifier<ThemeSpirit>`
  - [x] Register `ThemeSpiritNotifier` in `lib/locator.dart`
  - [x] Wrap `MaterialApp.router` in `lib/main.dart` with `ValueListenableBuilder<ThemeSpirit>` using `ThemeSpiritNotifier`
  - [x] Update `AppTheme.light` to resolve tokens dynamically from the active spirit
  - [x] Run backend and frontend build to verify compilation

- [ ] **Slice 2: UI Swapping Integration**
  - [ ] Add a visual toggle in the settings section of `ProfilePage` (`lib/features/profile/pages/profile_page.dart`)
  - [ ] Use `BubblySwitch` and wire it up to `ThemeSpiritNotifier`
  - [ ] Verify visually via widget tests or UI flow

- [ ] **Slice 3: Unit & Widget Test Verification**
  - [ ] Create dynamic theme widget test `test/widgets/theme_spirit_dynamic_test.dart`
  - [ ] Ensure that changing the spirit updates `StrokeCard` and `BubblyButton` styling dynamically
  - [ ] Run full test suite via `rtk` commands

## Artifact Inventory

| Status | File Path | Type |
|---|---|---|
| [NEW] | docs/features/dynamic-theme-spirit-swapping/implementation_plan_dynamic-theme-spirit-swapping_20260602_073000.md | Implementation Plan |
| [NEW] | docs/features/dynamic-theme-spirit-swapping/task_dynamic-theme-spirit-swapping_20260602_073000.md | Task List |
| [NEW] | docs/features/dynamic-theme-spirit-swapping/walkthrough_dynamic-theme-spirit-swapping_slice1_20260602_073000.md | Walkthrough |

