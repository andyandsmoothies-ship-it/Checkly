---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
Type: Implementation Plan
Topic: Dynamic Theme & Spirit Swapping (Slice 3 - Test Verification)
Date: 2026-06-02
---

# Implementation Plan: Dynamic Theme & Spirit Swapping (Slice 3)

We will create a comprehensive widget test suite `test/widgets/theme_spirit_dynamic_test.dart` to verify that changing the active theme spirit dynamically updates the styling of `StrokeCard` and `BubblyButton`.

## 1. Architectural Flow

```
[ThemeSpiritNotifier] ---> notifies ---> [ValueListenableBuilder<ThemeSpirit>]
                                                        |
                                            rebuilds MaterialApp with
                                                [AppTheme.light]
                                                        |
                                      injects updated [ChecklyThemeTokens]
                                                        |
                                          reads dynamic values from
                                         Theme.of(context).extension
                                                        |
                                     +------------------+------------------+
                                     |                                     |
                               [StrokeCard]                         [BubblyButton]
                                  |                                    |
                           rebuilds shape &                     rebuilds flat /
                            border widths                       3D tactile layers
```

## 2. Test Cases and Verification Plan

### Test Case: Dynamic Theme Spirit Swapping on Custom Primitives
1. **Initialize Notifier**: Create an instance of `ThemeSpiritNotifier`. By default, it sets the active spirit to `ThemeSpirit.duolingo`.
2. **Build Widget Tree**:
   - Wrap `MaterialApp` in a `ValueListenableBuilder<ThemeSpirit>` hooked to the notifier.
   - Set the theme of `MaterialApp` to `AppTheme.light`.
   - Render `StrokeCard` and `BubblyButton` within a `Scaffold`.
3. **Verify Duolingo Aesthetics (Gamified & Tactile)**:
   - **StrokeCard**:
     - Locate the underlying `Card` widget.
     - Verify `RoundedRectangleBorder` has `borderRadius == BorderRadius.circular(16.0)`.
     - Verify `side.width == 2.0`.
   - **BubblyButton**:
     - Verify that the 3D Shadow Container (rendered when `depth3d > 0`) is present.
     - We assert that there are at least two `Container` widgets inside `BubblyButton` (one for the 3D shadow and one for the interactive button face).
4. **Trigger Toggle**:
   - Call `spiritNotifier.toggleSpirit()`.
   - Rebuild the widget tree using `tester.pumpAndSettle()`.
5. **Verify Minimalist Aesthetics (Flat & Clean)**:
   - **StrokeCard**:
     - Locate the underlying `Card` widget.
     - Verify `RoundedRectangleBorder` has `borderRadius == BorderRadius.circular(4.0)`.
     - Verify `side.width == 1.0`.
   - **BubblyButton**:
     - Verify that the 3D Shadow Container is omitted since `depth3d == 0.0`.
     - We assert that there is exactly one `Container` widget inside `BubblyButton` (only the interactive button face).

## 3. Directory Layout

- **New Test File**: `test/widgets/theme_spirit_dynamic_test.dart`
