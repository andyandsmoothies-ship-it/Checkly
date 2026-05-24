<latent_space_scratchpad>
- Goal: Completely remove dark mode out of the app.
- Areas to hit: `main.dart` (theme config), `locator.dart` (DI), `app_theme.dart` (dark theme config), `profile_page.dart` (UI toggle), `theme_manager.dart` (state).
- Deleting `ThemeManager` class entirely.
- In `profile_page.dart`, the `SettingsSectionGroup` currently ONLY has `themeToggle`. Removing it makes the section empty, so we should delete `SettingsSectionGroup` entirely from `ProfilePage` for now, or just leave it empty and not rendered. (It checks `items.isNotEmpty || themeToggle`, so it won't render if empty). We will remove it from `ProfilePage` completely.
- Need to delete files: `theme_manager.dart` and `theme_toggle_tile.dart`.
</latent_space_scratchpad>

# Task: Remove Dark Mode
Workflow: /analyze-feature | Track: B1

## Input Lineage
User Request: completely remove the darkmode out of my app

## Executive Summary & Out of Scope
**Goal:** Completely strip Dark Mode from the application to streamline theme definitions and state management.
**Out of Scope:** We will not refactor the Light Mode (Apothecary) aesthetics.

## System Context
- **Framework:** Flutter.
- **State Management:** `GetIt` for Dependency Injection, `ChangeNotifier` for legacy theme state (to be removed).

## Lifecycle Context
- **Success:** Application loads statically in Light mode. No theme flickering.
- **Empty/Error:** N/A (UI structural change).

## Constraint Traceability
| Constraint | Test Contract ID |
|---|---|
| Completely remove dark mode | RM-DM-01 |

## Test Contracts
| Contract ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| RM-DM-01 | App strictly uses Light Theme. Dark theme mode and preferences are fully removed. | Success | Failing due to `ThemeManager` active injection. |

## Test Fixture & Payloads
- **Required Setup:** Standard Flutter application run.

## Tools & Commands
- `rtk flutter analyze`
- `rtk flutter test`

## Proposed Changes
- `[MOD]` `lib/main.dart`: Remove `themeMode`, `darkTheme`, and `ThemeManager` init.
- `[MOD]` `lib/locator.dart`: Remove `ThemeManager` registration.
- `[MOD]` `lib/_shared/theme/app_theme.dart`: Delete `dark` theme getter.
- `[MOD]` `lib/features/profile/pages/profile_page.dart`: Remove `SettingsSectionGroup` block.
- `[MOD]` `lib/features/profile/widgets/settings_section_group.dart`: Remove `themeToggle` logic.
- `[DEL]` `lib/_shared/theme/theme_manager.dart`
- `[DEL]` `lib/features/profile/widgets/theme_toggle_tile.dart`

## Concept Diagram
```text
[User] -> [Profile Page]
            (No Settings Section)
[App] -> [MaterialApp(theme: AppTheme.light)]
```

## Execution Slices

### Execution Phase: Remove Dark Mode Plumbings
- **Plain English Summary:** We will delete `ThemeManager`, `theme_toggle_tile.dart`, and remove dark theme configurations from `main.dart`, `locator.dart`, and `app_theme.dart`.
- **Value Delivered:** Streamlines codebase, removes unneeded settings, enforcing strict light-mode design.
- **Entry/Exit State:** App currently has dark mode toggle -> App is light-only.
- **Scope:** Modify 5 files, Delete 2 files.
- **Acceptance Criteria:** `ThemeManager` is completely removed. App compiles and passes all widget tests (which may need minor updates if they tested the profile page).
- **Complexity:** Low. Pure structural deletions.
- **Pros & Cons:** Pro: Less code, simpler UI. Con: Users lose dark mode preference.

<command_logs>
- `grep_search` darkTheme
- `grep_search` ThemeMode
- `view_file` main.dart, locator.dart, app_theme.dart, profile_page.dart, settings_section_group.dart
</command_logs>

## Risk Assessment
**Risk Level:** Low.
**Why:** Completely stripping an aesthetic theme mode doesn't affect business logic.

## Verification Plan
1. **Manual Check:** Run the app, verify that the profile page compiles without the theme toggle.
2. **Automated Check:** Run widget tests and verify there are no test failures related to `ThemeManager` being missing.

## Handoff Block
- **Execution Phase**: Plan -> Build
Input: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260523_131348_uxe6_remove_darkmode.md`
