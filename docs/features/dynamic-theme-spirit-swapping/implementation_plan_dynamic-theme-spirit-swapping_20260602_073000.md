---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
Type: Implementation Plan
Topic: Dynamic Theme & Spirit Swapping Architecture
Date: 2026-06-02
---

# Implementation Plan: Dynamic Theme & Spirit Swapping

This plan details the systematic implementation of a dynamic "clothes/spirit" swapping mechanism in the Checkly application. Decoupling visual aesthetics from core UI widgets allows the entire look-and-feel of the application to change dynamically from Duolingo's signature 3D tactile interface to a modern flat minimalist look.

## 1. Context & Goals

Currently, the Checkly design primitives (`StrokeCard`, `BubblyButton`, `BubblySwitch`) query the registered custom `ChecklyThemeTokens` via `Theme.of(context).extension<ChecklyThemeTokens>()`. However, the visual spirit (`ThemeSpirit.activeSpirit`) is defined as a static mutable helper inside `AppTheme` which lacks state reactivity to automatically trigger hot-rebuilding of the widget tree when updated at runtime.

### Architectural Flow:
```text
  [ Profile Settings Switch ] ──► [ ThemeSpiritNotifier ] (ValueNotifier)
                                             │
                                             ▼ (Notifies listeners)
                                  [ ValueListenableBuilder ] (App Root)
                                             │
                                             ▼ (Triggers dynamic rebuild)
                                   [ MaterialApp.router ]
                                             │
                                             ▼ (Loads updated tokens)
                              [ Theme.of(context).extension<ChecklyThemeTokens>() ]
                                             │
                       ┌─────────────────────┴─────────────────────┐
                       ▼                                           ▼
              [ StrokeCard ]                                [ BubblyButton ]
             • Corner Radius: 16.0                         • Corner Radius: 4.0
             • Outline Border: 2.0                         • Outline Border: 1.0
             • 3D Depth: 4.0                               • 3D Depth: 0.0
```

---

## Proposed Changes

Currently, the Checkly design primitives (`StrokeCard`, `BubblyButton`, `BubblySwitch`) query the registered custom `ChecklyThemeTokens` via `Theme.of(context).extension<ChecklyThemeTokens>()`. However, the visual spirit (`ThemeSpirit.activeSpirit`) is defined as a static mutable helper inside `AppTheme` which lacks state reactivity to automatically trigger hot-rebuilding of the widget tree when updated at runtime.

### Vertical Slices

#### Slice 1: State & Decoupling Foundation
* **Goal**: Enable reactive theme spirit toggling and register `ThemeSpiritNotifier` in dependency injection.
* **Details**:
  * Implement `ThemeSpiritNotifier` in `lib/_shared/theme/app_theme_notifier.dart` extending `ValueNotifier<ThemeSpirit>`.
  * Register `ThemeSpiritNotifier` as a lazy singleton in `lib/locator.dart`.
  * Wire it into the `ChecklyApp` state in `lib/main.dart` using a `ValueListenableBuilder<ThemeSpirit>` to rebuild `MaterialApp.router` dynamically when the spirit changes.
  * Update `AppTheme.light` to resolve tokens dynamically from the active state rather than a static mutable helper.

#### Slice 2: UI Swapping Integration
* **Goal**: Provide a clean toggle under a new "SETTINGS" section in `ProfilePage` to swap the spirit.
* **Details**:
  * Add a "SETTINGS" zone in `ProfilePage` (`lib/features/profile/pages/profile_page.dart`) displaying a "Tactile 3D Design" or "Minimalist Flat Design" theme switch.
  * Wire it using a tactile `BubblySwitch` connected to the lazy singleton `ThemeSpiritNotifier`.
  * Ensure standard haptic feedback triggers when changing the setting.

#### Slice 3: Unit & Widget Test Verification
* **Goal**: Ensure the theme toggling works reliably, has zero regression, and has headless test safeguards.
* **Details**:
  * Write a robust widget test `test/widgets/theme_spirit_dynamic_test.dart` asserting that changing the theme spirit successfully updates the rendered corner radius, shadow depth, and border width of `StrokeCard` and `BubblyButton`.
  * Ensure all other global tests continue passing successfully.

---

## Risk Assessment

1. **Null Theme Extensions in Headless Tests**:
   * *Edge Case*: Headless unit and widget tests run without fully loading `MaterialApp` theme extensions, causing `Theme.of(context).extension<ChecklyThemeTokens>()` to return `null`.
   * *Mitigation*: Our design system primitives already use safe fallback defaults via null-coalescing operators (`??`), ensuring tests never throw null reference exceptions. We will maintain this rule.

2. **Thundering Herds on Theme Swapping Rebuilds**:
   * *Edge Case*: Rebuilding the entire app tree can cause visual lag if not optimized.
   * *Mitigation*: Swapping a high-level visual spirit is a low-frequency action. The `MaterialApp.router` rebuild is handled cleanly by Flutter's element tree diffing engine. Animations will check reduced-motion compliance via `MediaQuery.disableAnimationsOf(context)` to snap cleanly if settings are enabled.

---

## Verification Plan

* Execute the automated verification script: `python .agents/scripts/verify_workflow.py`
* Run comprehensive UI unit and integration tests under `test/widgets/` to verify dynamic swap behavior.
* Verify reduced-motion settings in the test suite environment to ensure immediate transition execution.

