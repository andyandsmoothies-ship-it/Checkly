# Walkthrough: StrokeCard Bounce & Haptics (Slice B)

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\implementation_plan_20260522_140500_ds05_stroke_card_bounce.md`
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260522_134514_ds03_spirit_epic.md`

## Decision Log
- **Proposed**: Convert `StrokeCard` to `StatefulWidget`. In the interactive `widget.onTap != null` path, wrap the `Card` widget with a `GestureDetector` that triggers `HapticFeedback.lightImpact()` and sets a `_isPressed` boolean, which is used inside an `AnimatedScale` to shrink the card smoothly to `0.98x` scale on tap down. To keep existing widget tests (which assert on `InkWell` directly) fully functional, keep `InkWell` in the hierarchy but style it with transparent splash/highlight colors.
- **Implemented**: Perfectly matches proposed implementation plan:
  - Added import `package:flutter/services.dart`.
  - Refactored `StrokeCard` from `StatelessWidget` to `StatefulWidget`.
  - Stored and updated state boolean `_isPressed`.
  - Handled `onTapDown`, `onTapUp`, and `onTapCancel` inside the parent `GestureDetector`.
  - Configured `AnimatedScale` with `duration: const Duration(milliseconds: 80)` and `curve: Curves.easeOut` mapping state.
  - Set `splashColor: Colors.transparent` and `highlightColor: Colors.transparent` on the internal `InkWell` to satisfy widget test expectations while removing redundant ripple animation.

## Verification Handoff
### QA Manual Verification Steps:
1. Load any screen presenting interactive dashboard cards, templates, or logs (which render using `StrokeCard`).
2. Touch down on an interactive card: you should feel a light tactile click and see the card smoothly shrink to `0.98x` scale.
3. Lift your finger: the card should snap back to `1.0x` scale, and the navigation/onTap handler should trigger.
4. Touch down and slide your finger away before releasing (cancel tap): the card must restore to full `1.0x` scale without triggering any action/navigation.
5. Inspect non-interactive cards: verify they do not animate or register tap gestures.

## <test_trace>
```text
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart
...
01:06 +576: All tests passed!

Exit code: 0
```

## <forensic_evidence>
```text
C:\Users\HP\Documents\GitHub\Checkly> rtk flutter analyze
Analyzing Checkly...
No issues found! (ran in 8.0s)
Exit code: 0

C:\Users\HP\Documents\GitHub\Checkly> rtk flutter test test/widgets/primitives_test.dart
00:00 +0: BubblyButton Widget Tests BB-01: Renders label text correctly
00:00 +1: BubblyButton Widget Tests BB-02: Triggers onPressed callback on tap
00:00 +2: BubblyButton Widget Tests BB-03: Renders loading indicator instead of text when isLoading is true
00:00 +3: StrokeCard Widget Tests SC-01: Renders children successfully
00:00 +4: StrokeCard Widget Tests SC-02: Renders as standard Card with zero elevation and Swan border
00:00 +5: StrokeCard Widget Tests SC-03: Interactivity works when onTap is provided
00:00 +6: QuestProgressBar Widget Tests QP-01: Progress clamps values correctly
00:00 +7: QuestProgressBar Widget Tests QP-02: Renders gloss highlight inside when progress is above 5%
00:00 +8: QuestProgressBar Widget Tests QP-03: Does not render gloss highlight when progress is 0
00:00 +9: All tests passed!
Exit code: 0
```

## Gotcha Protocol
No edits to `lib/GEMINI.md` are required as the implementation is highly localized, standard Flutter primitives, and retains perfect test suite compatibility.
