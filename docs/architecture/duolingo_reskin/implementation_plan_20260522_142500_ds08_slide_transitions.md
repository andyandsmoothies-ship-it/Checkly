# Implementation Plan - Global Slide transitions (Sub-Slice E)

<latent_space_scratchpad>
Edge cases and notes:
- Globally overriding PageTransitionsTheme affects all routes.
- The transition curve should be clean and smooth (e.g. `Curves.easeInOutCubic` or `Curves.easeOutCubic` or `Curves.fastOutSlowIn`).
- Standard GoRouter transitions fallback to theme-defined global transitions unless specifically overridden. We confirmed no `pageBuilder` overrides exist, so global PageTransitionsTheme will apply cleanly everywhere.
- Make sure `_SlideRightToLeftTransitionsBuilder` handles target platforms (Android and iOS) properly and does not crash or cause compilation issues.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260522_134514_ds03_spirit_epic.md`

## Executive Summary & Out of Scope
This plan introduces smooth, premium slide-in transitions (right-to-left) globally across the entire Flutter application by overriding `pageTransitionsTheme` inside the main design theme (`AppTheme`).
- **In Scope**: Add global transitions builders to `AppTheme` for Android and iOS targets. Implement private `_SlideRightToLeftTransitionsBuilder` class using native `SlideTransition` and `Tween`.
- **Out of Scope**: Per-route page overrides, platform-specific native channel navigation packages.

## Risk Assessment
- **Risk / ROI**: High ROI, Low Risk. The transition utilizes standard built-in Flutter theme configurations and native rendering objects.
- **Blast Radius**: Low. Contained completely within `app_theme.dart`.

## System Context
- **Offline/Online**: Offline-first. Navigation transitions are computed entirely client-side.
- **APIs**: None affected.
- **RBAC**: None affected.
- **Logs**: No log impacts.

## Lifecycle Context
### 4-State Matrix
- **Success**: Moving to any screen triggers smooth slide transition from right-to-left. Returning slides out to the right.
- **Error**: None (rendering remains constant).
- **Empty**: None.
- **Loading**: None.

## Constraint Traceability
| Constraint ID | Description | Test Contract ID |
|---|---|---|
| C-TRANS-01 | All global screen transitions must slide from right-to-left | TR-GLOBAL-1 |

## Test Contracts
- **ID**: `TR-GLOBAL-1`
  - **Text**: Verify `app_theme.dart` successfully declares the global transitions theme and compiles without errors.
  - **State Matrix**: Success compile.
  - **Why it fails first**: If `pageTransitionsTheme` key is missing in light/dark `ThemeData`.

## Test Fixture & Payloads
- **Test Fixture**: Standard Flutter application.
- **Payloads**: None.

## Tools & Commands
- **Required Skills**: Flutter / Dart
- **Execution Commands**:
  - `rtk flutter analyze`

## Proposed Changes
### Component: Design System / Theme
#### [MODIFY] [app_theme.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/_shared/theme/app_theme.dart)
Add `pageTransitionsTheme` configuration to `_buildTheme()` method and append private transitions builder class:
```dart
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlideRightToLeftTransitionsBuilder(),
          TargetPlatform.iOS: _SlideRightToLeftTransitionsBuilder(),
        },
      ),
```
Define private builder:
```dart
class _SlideRightToLeftTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideRightToLeftTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
      ),
      child: child,
    );
  }
}
```

---

## Concept Diagram
```
[Route Navigate Target] ──► [AppTheme Globally Intercepts] ──► [SlideTransition (Offset(1, 0) to Offset.zero)]
```

---

## Execution Slices

### Execution Phase
- **Complexity**: Low. Isolated to one theme file.
- **Value Delivered**: Provides a premium, unified visual feedback experience that mimics professional gamified mobile interfaces.
- **Entry State**: Application compiles, GoRouter works.
- **Scope**: Modifying `lib/_shared/theme/app_theme.dart`.
- **Acceptance Criteria**:
  - Global navigation executes slide transitions right-to-left.
  - Compiles cleanly and passes `flutter analyze` with 0 errors.
- **Exit State**: Clean compile, manual navigation slide animation verified.

<command_logs>
- Scanned app_router and app_theme to confirm page transitions configuration.
</command_logs>

## Verification Plan
- Verify clean compilation and zero warnings:
  `rtk flutter analyze`
- Run general tests:
  `rtk flutter test`

## Handoff Block
- **Execution Phase**: Plan -> Build -> Verify
- Path to Plan: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\implementation_plan_20260522_142500_ds08_slide_transitions.md`
