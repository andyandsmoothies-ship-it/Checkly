# Research — The "Spirit" of Duolingo

[ORIGIN_IDEA]
The user observed that after 8 slices of purely visual changes (colors, fonts, shapes), the app feels like it only has the "skin" of Duolingo, but lacks its "spirit". The goal is to inject gamified spirit (juiciness, game feel, and personality) without adding new business logic, database changes, or sound effects (explicitly excluded for this phase).

<latent_space_scratchpad>
If we cannot add new features (XP/streaks) and we cannot add sound, what is left of the "Duolingo Spirit"?
1. **Haptics (Physicality)**: The app needs to feel tactile. When a button is pressed, it should vibrate.
2. **Micro-Animations (Bounciness)**: The UI needs to react elastically. Buttons should squish, pages should slide dynamically.
3. **Mascots / Personality**: Empty states and error screens should have character. Since we can't load heavy 3D assets, using large Emojis (🎉, 🦉, 🚧, ☕) is a perfect native workaround.
4. **UX Copywriting (Tone)**: The language must be rewritten from "sterile corporate" to "encouraging gamified".

Status Quo Check:
- `HapticFeedback` is only used in 3 profile settings files. It is missing from `BubblyButton`, `StrokeCard`, and `QuestProgressBar`.
- `ChecklyEmptyState` uses a rigid `IconData` (e.g., `Icons.inbox_outlined`) and standard typography.
- Navigations use standard fade/zoom Material transitions.

Option A (Zero packages) relies strictly on Flutter's built-in `HapticFeedback`, `Transform.scale`, and `PageRouteBuilder`.
Option B (Low bloat) adds `confetti` for celebrations.
Given the "Zero Bloat" rule, Option A is the safest and most architecturally sound baseline, but we can propose `confetti` as an optional add-on.
</latent_space_scratchpad>

## E2E Workflow Map

```text
[User Interaction] 
       │
       ├─► (Tap) ─► [BubblyButton / StrokeCard] 
       │                 │
       │                 ├─► TRIGGER: Transform.scale (0.95x)
       │                 └─► TRIGGER: HapticFeedback.lightImpact()
       │
       ├─► (Navigation) ─► [GoRouter / Navigator]
       │                 │
       │                 └─► TRIGGER: SlideTransition (Right-to-Left)
       │
       └─► (Empty/Success State) ─► [ChecklyEmptyState / SnackBar]
                         │
                         ├─► DISPLAY: Mascot Emoji (e.g., 🎉 or ☕)
                         ├─► TEXT: Gamified UX Copy ("You crushed it!")
                         └─► TRIGGER: HapticFeedback.heavyImpact()
```

## Impact Spectrum

| Vector | Option A: Native Physics & Emojis | Option B: 'Confetti' Package + Native | Option C: Full Animation Suite (Lottie) |
|:---|:---|:---|:---|
| **Packages Added** | `0` | `1` (`confetti`) | `2+` (`lottie`, `flutter_animate`) |
| **Juiciness Level** | Medium-High (Haptics, bouncy cards) | High (Haptics + particles) | Extreme |
| **Rule Conflicts** | None | High ("Zero Bloat" package rule) | High ("Zero Bloat" rule) |
| **Performance Risk**| Minimal | Low (canvas drawing) | High (JSON parsing & asset size) |
| **Verdict** | **[APPROVED]** Strict Native Fit | [REJECTED] Unless explicitly requested | [REJECTED] Too heavy |

## Blind Spots

1. **Haptic Hardware Limitations**: Haptics do not trigger on iOS if the user has system vibrations turned off, leading to an inconsistent experience where only visual bounce is present.
2. **Text Anti-Aliasing Jitter**: Extensive use of `Transform.scale` on `GestureDetector.onPanDown` can cause text anti-aliasing jitter on older Android devices during the animation frame.
3. **[RESOLVED] Interface Drift on Empty States**: By adding an optional `String? emoji` field to `ChecklyEmptyState` instead of replacing `IconData icon`, we preserve backwards compatibility and prevent the other 6 screens in the app from breaking.

## Conflicts with Rules

1. **Zero Bloat vs Juiciness**: True game-feel often relies on particle systems (like confetti). Installing a package like `confetti` directly conflicts with the "Zero Bloat" rule unless explicitly allowed by the user. Thus, Option A avoids it entirely.
2. **Sound vs Spirit**: Game feel heavily relies on audio. However, the user explicitly stated "we will not implement sound on this phase". This rule strictly overrides standard gamification best practices for this epic.

## UI Component Routing Table

| Component | Target File | Overflow Limit | Next Route |
|:---|:---|:---|:---|
| `ChecklyEmptyState` | `lib/_shared/widgets/checkly_empty_state.dart` | Mascot Emoji: `String? emoji` (Optional fallback) | Static Display |
| `BubblyButton` | `lib/_shared/widgets/primitives/bubbly_button.dart` | Scale animation: 0.95x bounds | Triggers parent `onPressed` |
| `StrokeCard` | `lib/_shared/widgets/primitives/stroke_card.dart` | Scale animation: 0.98x bounds | Triggers parent `onTap` |

<forensic_evidence>
- `grep_search` executed for `HapticFeedback` across `lib/`: Verified absence in core primitives.
- `grep_search` executed for `ChecklyEmptyState` across `lib/`: Verified 6 dependent files that are protected by the new `String? emoji` fallback plan.
- Checked `pubspec.yaml`: Confirmed no existing animation packages (like `lottie` or `confetti`).
</forensic_evidence>

## Handoff Block
- **Final Verdict**: Viable (Option A). We can inject immense "spirit" using purely native flutter physics (Transform animations), Haptic APIs, and semantic tone overrides (Emojis & Copywriting) without adding a single package or modifying backend logic.
- **Effort Sizing**: Track A (Fast Execution). High breadth (modifying primitive wrappers) but extremely low complexity.
- **AI Agent Mission Brief**: Implement Slice 9 by wrapping `BubblyButton` (0.95x scale) and interactive `StrokeCard`s (0.98x scale) in scaling `GestureDetector`s with `HapticFeedback.lightImpact()`. Refactor `ChecklyEmptyState` with an optional `String? emoji` field to preserve compatibility, and inject encouraging gamified UX copy instead of sterile messages.
- **Next Step**: The user should run `/implement` and provide the absolute path to this artifact: `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260522_133254_ds02_spirit_research.md`
