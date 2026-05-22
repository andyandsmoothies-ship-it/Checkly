<latent_space_scratchpad>
## Latent Space Scratchpad & Constraints

### Constraints from input documents
- **No speculative abstraction**: Keep it simple. Write the haptic code directly inside `BubblyButton`'s callback, do not write a custom wrapper or helper function unless shared 3+ times.
- **No extra packages**: Use built-in `HapticFeedback.lightImpact()`. Do not pull any custom haptic packages.
- **Disabled button safeguard**: The button must NOT trigger haptic feedback if disabled (`widget.onPressed == null`) or loading (`widget.isLoading == true`).
- **File length limit**: `bubbly_button.dart` is 127 lines, well under the 250/400 lines threshold. Splitting is not required.

### Edge cases & states
- **State: Disabled / Loading**
  - Current logic: `final isEnabled = widget.onPressed != null && !widget.isLoading;` and `onTapDown: isEnabled ? ... : null`.
  - Haptic impact: Since the gesture handler receives `null` when not enabled, no gestures are registered, and haptic is safely bypassed. No manual check is needed, keeping the code simple and clean (DRY & clean logic).
- **State: iOS Hardware vibration off**
  - Expected: Visual button animation continues to run smoothly. `HapticFeedback.lightImpact()` fails silently in Flutter framework if OS-level setting is off, ensuring no crashes.
</latent_space_scratchpad>

## Input Lineage
- **Source Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260522_134514_ds03_spirit_epic.md`

---

## Executive Summary & Out of Scope

This implementation plan covers **Sub-Slice A (Haptic: BubblyButton)** of the "Spirit of Duolingo" Epic. The goal is to add tactile physical feedback to every tap of the custom `BubblyButton` primitive using Flutter's native `HapticFeedback` API.

### Scope:
- ✅ Import `package:flutter/services.dart` in `bubbly_button.dart`.
- ✅ Add `HapticFeedback.lightImpact()` inside the `onTapDown` handler when `isEnabled` is true.

### Out of Scope:
- ❌ Modifying visual press mechanics (already correctly handled by `AnimatedPositioned` / `top` offsets).
- ❌ Modifying other components like `StrokeCard` or `ChecklyEmptyState` (these are handled in subsequent slices).
- ❌ Adding external packages or dependencies.

---

## System Context
- **Runtime Environment**: Offline-first client-side Flutter application.
- **Permissions / RBAC**: None. The haptic feedback is purely a visual/tactile UI enhancement open to all users.
- **APIs / Network**: Offline only. No backend dependencies.

---

## Lifecycle Context

Tactile feedback lifecycle for `BubblyButton`:
| State | Component State | Expected Behavior |
|:---|:---|:---|
| **Loading** | `isLoading = true` | `isEnabled` resolves to `false`. `onTapDown` is `null`. No haptic triggers, no press animation. |
| **Disabled** | `onPressed = null` | `isEnabled` resolves to `false`. `onTapDown` is `null`. No haptic triggers, no press animation. |
| **Active / Enabled**| `isEnabled = true` | `onTapDown` triggers. Tactile vibration occurs, button shifts 4px down. |
| **Success / Tap Up**| `onTapUp` triggers | Parent callback `widget.onPressed()` is executed. Button shifts back up. |

---

## Constraint Traceability

| Constraint ID | Constraint Description | Test Contract ID |
|:---|:---|:---|
| **C-HAP-1** | Must use Flutter's built-in `HapticFeedback.lightImpact()` | TC-HAP-01 |
| **C-HAP-2** | Must only trigger haptic when button is enabled and not loading | TC-HAP-02 |
| **C-HAP-3** | Must not alter visual 3D position changes | TC-HAP-03 |

---

## Test Contracts

| Test ID | Scenario | Expected Behavior | Verification Method |
|:---|:---|:---|:---|
| **TC-HAP-01** | Tap active BubblyButton | Tactile vibration occurs on physical device. | Manual verification / code audit |
| **TC-HAP-02** | Tap disabled/loading BubblyButton | No tactile vibration. `onTapDown` is null. | Code review / widget inspection |
| **TC-HAP-03** | Visual press baseline | Button shifts exactly 4px down during press state. | Code review / widget execution |

---

## Test Fixture & Payloads
No backend seed data or JSON payloads required. The change is isolated to standard Flutter client code.

---

## Tools & Commands
- **Skills**: basic Flutter/Dart knowledge.
- **Test / Verify Command**:
  `rtk flutter analyze` (Must pass with 0 errors).

---

## Proposed Changes

### 1. Primitives Layer

#### `[MOD]` [bubbly_button.dart](file:///C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/widgets/primitives/bubbly_button.dart)
- Add `import 'package:flutter/services.dart';`
- Refactor `onTapDown` parameter:
```dart
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
```

---

## Concept Diagram

```text
[User Tap down on enabled BubblyButton]
                 │
                 ▼
     [GestureDetector.onTapDown]
                 │
      ┌──────────┴──────────┐
      ▼                     ▼
[System Haptics]     [Local State Update]
lightImpact()        _isPressed = true
                            │
                            ▼
                     [AnimatedPositioned]
                     Moves 4px down (3D)
```

---

## Execution Slices

### Execution Phase: Haptic BubblyButton
- **Plain English Summary**: We import Flutter's system services inside `bubbly_button.dart` and trigger a light tactile tick (vibration) when a user initiates a tap down on an active button.
- **Value Delivered**: Tactile "game feel" when pressing buttons, satisfying the physical dimension of the Duolingo gamified spirit.
- **Complexity**: Low. Very simple, highly localized code addition.
- **Entry State Required**: Visual reskin complete, BubblyButton exists in `lib/_shared/widgets/primitives/bubbly_button.dart`.
- **Exit State Guaranteed**: Button triggers tactile feedback on active touch down, continues to animate correctly, passes static analysis.
- **Scope**: `lib/_shared/widgets/primitives/bubbly_button.dart` `[MOD]`
- **Acceptance Criteria**:
  - `import 'package:flutter/services.dart';` added cleanly. ✅
  - `onTapDown` invokes `HapticFeedback.lightImpact();` before updating `_isPressed`. ✅
  - Disabled or loading buttons do not trigger haptic feedback. ✅
  - Static analysis runs clean with 0 warnings/errors. ✅

---

<command_logs>
- Viewed `lib/_shared/widgets/primitives/bubbly_button.dart` L1-127.
</command_logs>

---

## Handoff Block

**Next Steps for Builder:**
Execute **Execution Phase (Sub-Slice A)**.
1. Add `import 'package:flutter/services.dart';` to `lib/_shared/widgets/primitives/bubbly_button.dart`.
2. Locate line 55 containing `onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,`.
3. Replace with:
```dart
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
```
4. Verify by running `rtk flutter analyze`.

**Handoff Roadmap:**
- **Execution Phase**: Plan -> Build

Absolute plan file path:
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\implementation_plan_20260522_135344_ds04_bubbly_button_haptic.md`
