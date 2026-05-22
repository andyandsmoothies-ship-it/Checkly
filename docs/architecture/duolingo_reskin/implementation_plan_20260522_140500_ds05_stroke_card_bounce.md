<latent_space_scratchpad>
## Latent Space Scratchpad & Constraints

### Constraints from input documents
- **Preserve InkWell in Tests**: Existing widget test SC-03 explicitly asserts on the presence of `InkWell`. To avoid breaking this test (violating "Never change a test and the main code in the exact same step"), we must keep `InkWell` in the tree but style it to have no visual ripple/highlight (splashColor and highlightColor = Colors.transparent).
- **Scale factor**: StrokeCard scale bounce should scale the card to exactly `0.98x` when tapped/held and snaps back on release.
- **Haptic feed**: Interactive StrokeCard must trigger `HapticFeedback.lightImpact()` on tap down.
- **Stateless to Stateful conversion**: Converting StrokeCard from StatelessWidget to StatefulWidget to store the `_isPressed` boolean.
- **Disabled state guard**: Non-interactive StrokeCard (`onTap == null`) must remain visually and behaviorally static. The StatefulWidget build method must return a standard static card without `GestureDetector`, `AnimatedScale`, or `InkWell` to ensure performance and visual stability.

### Edge cases & states
- **State: Tap Cancel**
  - If the user touches the card, then drags their finger outside before lifting, `onTapCancel` must reset `_isPressed = false` immediately so that the card does not stay permanently scaled down.
- **State: Fast Double Tap**
  - AnimatedScale with 80ms duration handles fast taps gracefully by interpolating the scale smoothly without sudden visual jumps.
</latent_space_scratchpad>

## Input Lineage
- **Source Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260522_134514_ds03_spirit_epic.md`

---

## Executive Summary & Out of Scope

This implementation plan covers **Sub-Slice B (Bounce + Haptic: StrokeCard)** of the "Spirit of Duolingo" Epic. The goal is to add premium physical bounce (scale animation to 0.98x) and tactile click haptics to every interactive `StrokeCard` widget in the application, while perfectly maintaining 100% compatibility with existing test suites.

### Scope:
- ✅ Refactor `StrokeCard` to `StatefulWidget`.
- ✅ Add a state boolean `_isPressed` to track active touch state.
- ✅ Implement `GestureDetector` on the interactive path to handle `onTapDown`, `onTapUp`, and `onTapCancel`.
- ✅ Trigger `HapticFeedback.lightImpact()` inside `onTapDown`.
- ✅ Wrap the card in an `AnimatedScale` that transforms to `0.98x` when `_isPressed` is true.
- ✅ Preserve `InkWell` inside the interactive path, passing `splashColor: Colors.transparent` and `highlightColor: Colors.transparent` to bypass the default ripple while satisfying the SC-03 test assertions.

### Out of Scope:
- ❌ Modifying any other primitives (BubblyButton is Slice A, others are future slices).
- ❌ Modifying callers of `StrokeCard`.
- ❌ Modifying the existing widget test files (tests must pass cleanly without modification).

---

## System Context
- **Runtime Environment**: Offline-first client-side Flutter application.
- **Permissions / RBAC**: None. StrokeCard is a visual Primitive widget.
- **APIs / Network**: Offline only. No backend dependencies.

---

## Lifecycle Context

Tactile & Visual bounce lifecycle for `StrokeCard`:
| State | Component State | Expected Behavior |
|:---|:---|:---|
| **Non-Interactive** | `onTap == null` | Standard static `Card` rendered. No `GestureDetector`, `AnimatedScale`, or `InkWell` wrapped. |
| **Interactive: Idle** | `onTap != null` & `_isPressed = false` | Rendered at full `1.0x` scale. |
| **Interactive: Press**| `onTapDown` triggers | Tactile vibration occurs. `_isPressed` becomes true. Card shrinks smoothly to `0.98x` scale over 80ms. |
| **Interactive: Release**| `onTapUp` triggers | `_isPressed` becomes false. Card returns to `1.0x` scale. Parent `onTap()` callback executes. |
| **Interactive: Cancel** | `onTapCancel` triggers | `_isPressed` becomes false. Card returns to `1.0x` scale without invoking `onTap()`. |

---

## Constraint Traceability

| Constraint ID | Constraint Description | Test Contract ID |
|:---|:---|:---|
| **C-SC-01** | Convert StrokeCard from StatelessWidget to StatefulWidget | TC-SC-01 |
| **C-SC-02** | Add tactile vibration on tap down | TC-SC-02 |
| **C-SC-03** | Scale visually to 0.98x on press | TC-SC-03 |
| **C-SC-04** | Keep InkWell with transparent splash to pass existing test SC-03 | TC-SC-04 |
| **C-SC-05** | Standard non-interactive path is unchanged | TC-SC-05 |

---

## Test Contracts

| Test ID | Scenario | Expected Behavior | Verification Method |
|:---|:---|:---|:---|
| **TC-SC-01** | Compile and Analyze | Code builds cleanly with no static analyzer warnings. | `rtk flutter analyze` |
| **TC-SC-02** | Touch down on interactive StrokeCard | Light haptic feedback triggered. `_isPressed` becomes true. | Physical touch test / mock audit |
| **TC-SC-03** | Press interactive StrokeCard | Renders wrapped in `AnimatedScale` with scale target `0.98`. | Widget tree inspection / manual validation |
| **TC-SC-04** | Widget test suite execution | `primitives_test.dart` passes cleanly, confirming `InkWell` is found. | `rtk flutter test test/widgets/primitives_test.dart` |
| **TC-SC-05** | Non-interactive StrokeCard | Standard Card rendered without GestureDetector or AnimatedScale. | Code review / widget structure check |

---

## Test Fixture & Payloads
No backend seed data or JSON payloads required. The change is isolated to standard Flutter client code.

---

## Tools & Commands
- **Skills**: basic Flutter/Dart knowledge.
- **Test / Verify Command**:
  `rtk flutter test test/widgets/primitives_test.dart` (Must pass 100% of the 9 tests).

---

## Proposed Changes

### 1. Primitives Layer

#### `[MOD]` [stroke_card.dart](file:///C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/widgets/primitives/stroke_card.dart)
- Convert `StrokeCard` to `StatefulWidget`.
- Import `package:flutter/services.dart`.
- Refactor interactive path (`widget.onTap != null`):
  - Add parent `GestureDetector` managing `onTapDown`, `onTapUp`, `onTapCancel`.
  - Add intermediate `AnimatedScale` widget with `scale: _isPressed ? 0.98 : 1.0`, `duration: const Duration(milliseconds: 80)`, `curve: Curves.easeOut`.
  - Wrap existing `Card` with `InkWell`. Pass `splashColor: Colors.transparent` and `highlightColor: Colors.transparent` to disable visual ripples while keeping `InkWell` in the widget tree for tests.

#### Component UI Routing / Overflow Table
| Component | Truncation Limit | Overflow Action | Required New Route |
|:---|:---|:---|:---|
| `StrokeCard` | N/A (Primitive) | N/A | None (Self-contained) |

---

## Concept Diagram

```text
[User taps StrokeCard]
          │
          ▼
   [GestureDetector] (captures touch down)
          │
          ├─► HapticFeedback.lightImpact()   [Tactile Click]
          ├─► setState(() => _isPressed = true)
          │
          ▼
    [AnimatedScale] ──► Shrinks smoothly from 1.0x to 0.98x
          │
          ▼
       [Card]
          │
          ▼
      [InkWell] (triggers onTap, holds transparent splash for tests)
          │
          ▼
       [Child]
```

---

## Execution Slices

### Execution Phase: Bounce + Haptic: StrokeCard
- **Plain English Summary**: Convert the `StrokeCard` widget to support state, wrap the interactive layout with a gesture detector and an animated scale widget, and trigger a native light haptic click on touch down. Keep an invisible `InkWell` underneath to fulfill the requirements of the existing widget tests.
- **Value Delivered**: Delivers tactile physical feedback and premium micro-animations to every tap on dashboard items, templates, and cards across the entire application.
- **Complexity**: Medium. Requires careful state updates and maintaining test compatibility.
- **Entry State Required**: Visual reskin complete, standard `StrokeCard` exists as a stateless widget.
- **Exit State Guaranteed**: Card scales and vibrates on tap down, behaves normally when tap is null, and all existing widget tests pass successfully.
- **Scope**: `lib/_shared/widgets/primitives/stroke_card.dart` `[MOD]`
- **Acceptance Criteria**:
  - `StrokeCard` is converted to a `StatefulWidget`. ✅
  - `HapticFeedback.lightImpact()` is executed inside `onTapDown`. ✅
  - `AnimatedScale` scales to `0.98` during active press state. ✅
  - `InkWell` remains in the tree with transparent splash colors. ✅
  - Non-interactive path has no scaling, gesture detectors, or haptic hooks. ✅
  - Widget tests in `primitives_test.dart` pass completely with 0 failures. ✅

---

<command_logs>
- Ran `rtk flutter analyze` from `lib/` (Clean, No issues found).
- Ran `rtk flutter test test/widgets/primitives_test.dart` from root (Clean, All 9 tests passed).
- Viewed `lib/_shared/widgets/primitives/stroke_card.dart` L1-72.
</command_logs>

---

## Handoff Block

**Next Steps for Builder:**
Execute **Execution Phase (Sub-Slice B)**.
1. In `lib/_shared/widgets/primitives/stroke_card.dart`, add `import 'package:flutter/services.dart';`.
2. Convert `StrokeCard` to `StatefulWidget`.
3. In `_StrokeCardState`, add a boolean field `bool _isPressed = false;`.
4. In the `build` method, update references to constructor fields to use `widget.` prefix.
5. In the `widget.onTap != null` block, wrap the `Card` in `AnimatedScale` and `GestureDetector` as specified:
```dart
    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: Card(
            elevation: 0,
            margin: widget.margin ?? EdgeInsets.zero,
            color: cardColor,
            shape: cardShape,
            clipBehavior: Clip.antiAlias, // Ensures the splash doesn't bleed out of the rounded corners
            child: InkWell(
              onTap: widget.onTap,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(16.0),
                child: widget.child,
              ),
            ),
          ),
        ),
      );
    }
```
6. Run `rtk flutter test test/widgets/primitives_test.dart` to verify that everything compiles and passes beautifully.

Absolute plan file path:
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\implementation_plan_20260522_140500_ds05_stroke_card_bounce.md`
