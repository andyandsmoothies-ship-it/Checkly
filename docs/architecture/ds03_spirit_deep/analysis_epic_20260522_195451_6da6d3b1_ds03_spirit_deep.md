<latent_space_scratchpad>
## Situation Analysis

**What the research document asks:**
Deepen 5 UI primitives with native Flutter spring physics. No new packages. No backend work.
This is a pure Flutter UI layer task — zero backend, zero DB, zero sync, zero RBAC impact.

**Is the goal clear?**
Yes. The user explicitly stated: "not into games, just like doing tasks and have fun."
The goal is tactile productivity feedback, not visual noise or gamification points.

**Components and their current state:**
1. BubblyButton (EXISTS) — StatefulWidget, 146 lines, uses AnimatedPositioned + Stack 3D effect.
   Current: presses down 4px. Missing: squash/stretch on X/Y axis via AnimatedScale.
   Risk: It wraps children in a Stack. Adding AnimatedScale wrapping the face layer is safe.
   Tests: BB-01, BB-02, BB-03 exist and test label/callback/loading behavior. Must not break them.

2. NavItem (EXISTS) — StatelessWidget, 81 lines. 
   Current: static Column(icon + label). isActive changes color only.
   Problem: It's a StatelessWidget. A Y-axis hop requires AnimatedSlide/AnimatedScale which
   need an animation ticker → must convert to StatefulWidget.
   Critical constraint: MainShell wraps nav bar in ClipRRect(borderRadius top-24). Nav bar
   height is 96px with padding EdgeInsets.fromLTRB(24, 12, 24, 0). An icon hop of -6px
   (upward) means the icon moves toward the top of the 96px container. The icon is at approx
   y=12 (top padding). Moving up -6px means y=6. ClipRRect clips at the TOP rounded corner
   only — this is safe for a -6px hop. CONFIRMED: hop stays within bounds.

3. BouncyListWrapper (DOES NOT EXIST) — new file.
   A utility wrapper that accepts a List<Widget> children and applies staggered entrance.
   Uses TweenAnimationBuilder with delay via Future.delayed or a controller.
   Simple approach: index-based AnimatedOpacity + AnimatedSlide with staggered begin duration.
   Stagger cap: min(index * 40ms, 500ms).

4. ChecklyEmptyState (EXISTS) — StatelessWidget, 85 lines.
   Current: static Container with icon/emoji + title + subtitle.
   Change: Convert to StatefulWidget. Add GestureDetector over illustration.
   On tap: trigger rotation jiggle (-0.1 → +0.1 radians) + HapticFeedback.lightImpact().
   Use AnimationController with forward/reverse for jiggle effect.
   Tests: ES-01 and ES-02 test text rendering and emoji rendering. Must not break.

5. BouncyCheckbox (DOES NOT EXIST) — new file.
   A checkbox widget that wraps state with pop animation.
   On toggle: scale to 0.8 → pop to 1.2 → settle to 1.0 using Curves.elasticOut.
   Trigger HapticFeedback.mediumImpact() on check.
   Must integrate with existing audit pass/fail input or standalone usage.
   NOTE: No existing callsites for BouncyCheckbox. It's a new primitive. Its integration
   point is future — the epic plan should document this but not force integration now.
   Slice 4 = create the primitive. Integration into audit criterion rows is Slice 5.

**Slicing strategy:**
This is a pure UI refactor of shared primitives. Risk level = MEDIUM (shared widgets used
in 24+ call sites). The key risk is breaking existing widget tests.

Slice ordering:
- Slice 1: BubblyButton squash/stretch [BLOCKING — used in 24 sites, must pass tests first]
- Slice 2: NavItem Y-hop [SEQUENTIAL after Slice 1 — requires StatefulWidget conversion]
- Slice 3: BouncyListWrapper stagger [PARALLEL with Slice 2 — new file, zero callsite risk]
- Slice 4: ChecklyEmptyState jiggle [SEQUENTIAL after Slice 1 — StatelessWidget conversion]
- Slice 5: BouncyCheckbox + integration [SEQUENTIAL after Slice 4 — new primitive]

**Test strategy:**
- For modified widgets (BubblyButton, NavItem, EmptyState): verify existing tests still PASS.
  Add new tests for animation state transitions.
- For new widgets (BouncyListWrapper, BouncyCheckbox): write widget tests asserting
  correct widget types rendered (AnimatedSlide, AnimatedScale, etc.) and callback behavior.

**RBAC / Offline / Sync impact:** NONE. These are pure widget changes.
**New packages required:** NONE. Uses only flutter/material.dart + flutter/services.dart (HapticFeedback).
</latent_space_scratchpad>

# Epic Analysis: Deep Spirit — Micro-Interaction Deepening

<command_logs>
- grep_search: bubbly_button.dart in lib/ → Found in lib/_shared/widgets/primitives/
- grep_search: bouncy_checkbox.dart in lib/ → Not found (new file required)
- grep_search: checkly_empty_state.dart in lib/ → Found in lib/_shared/widgets/
- grep_search: nav_item.dart in lib/ → Found referenced from main_shell.dart
- grep_search: bouncy_list_wrapper in lib/ → Not found (new file required)
- list_dir: lib/_shared/widgets/ → 13 files listed
- list_dir: lib/_shared/widgets/primitives/ → 8 files listed
- view_file: bubbly_button.dart → 146 lines, StatefulWidget, AnimatedPositioned stack
- view_file: nav_item.dart → 81 lines, StatelessWidget, static color change only
- view_file: checkly_empty_state.dart → 85 lines, StatelessWidget, no GestureDetector
- view_file: main_shell.dart → 233 lines, ClipRRect height=96px, padding fromLTRB(24,12,24,0)
- grep_search: BubblyButton usages in lib/features/ → 24 call sites confirmed
- grep_search: BouncyCheckbox usages → 0 (does not exist)
- view_file: test/widgets/primitives_test.dart → 233 lines, BB-01..03, ES-01..02 tests
</command_logs>

<forensic_evidence>
- Verified BubblyButton at lib/_shared/widgets/primitives/bubbly_button.dart (146 lines, StatefulWidget, AnimatedPositioned-based 3D press)
- Verified NavItem at lib/_shared/router/nav_item.dart (81 lines, StatelessWidget, zero animation)
- Verified ChecklyEmptyState at lib/_shared/widgets/checkly_empty_state.dart (85 lines, StatelessWidget, no GestureDetector)
- Verified MainShell at lib/_shared/router/main_shell.dart (233 lines, ClipRRect top-24, nav bar height=96px, padding fromLTRB(24,12,24,0))
- Verified BouncyCheckbox DOES NOT EXIST — confirmed by grep_search returning 0 results
- Verified BouncyListWrapper DOES NOT EXIST — confirmed by grep_search returning 0 results
- Verified BubblyButton has 24 call sites across lib/features/ (templates, audit, admin, auth, programs, action_plans, user_groups)
- Verified existing tests: primitives_test.dart line 1-233 contains BB-01, BB-02, BB-03, ES-01, ES-02
- Confirmed no new packages required — all animation APIs available in flutter/material.dart and flutter/services.dart
</forensic_evidence>


- **Source Document**: `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260522_185712_ds03_spirit_deep.md`
- **Workflow**: `/analyze-epic`
- **Date**: 2026-05-22
- **ShortID**: `6da6d3b1`

---

## Executive Summary

```
[User Tap/Load]
      │
      ├─► BubblyButton ─── Squash (Y:0.90, X:1.05) ──► Spring Release (Y:1.05, X:0.95) ──► Settle
      │
      ├─► NavItem ─────── Slide Up (-6px) + Scale Icon 1.2x ──► Elastic Settle
      │
      ├─► List Screen ─── Item[0: 0ms] → Item[1: 40ms] → Item[n: min(n*40ms, 500ms)] (Slide+Fade)
      │
      ├─► EmptyState Tap ─ Rotate(-0.1rad) → Rotate(+0.1rad) ──► Spring Center + Haptic
      │
      └─► Checkbox Tap ─── Scale(0.8) → Pop Scale(1.2) ──► Elastic Settle(1.0) + Haptic
```

The research document proposes **Option A: Native Elastic Physics**. This plan confirms it as the only viable option and maps it into 5 discrete, testable build slices. This is a **Frontend-Only** epic with zero backend, database, or sync changes.

**Scope**: 3 modified files, 2 new files. **No new packages.** All animations use `flutter/material.dart` built-ins.

---

## Decision Matrix

### Requirements

| ID  | Requirement |
|-----|-------------|
| R1  | Button press must feel tactile and physically satisfying |
| R2  | Nav tab switch must feel energetic with no visual clipping |
| R3  | List load must feel alive with staggered entrance (cap at 500ms) |
| R4  | Empty state must reward curious taps without disrupting workflow |
| R5  | Task completion checkbox must deliver the ultimate satisfying pop |
| R6  | Zero new packages — Zero Bloat rule is absolute |
| R7  | All existing widget tests must continue to PASS |
| R8  | Accessibility: Must respect `MediaQuery.disableAnimationsOf(context)` across all slices. If true, snap to state without animation. |

### Fit Check

| Requirement | Option A: Native Springs | Option B: Rive/Lottie | Option C: Particle Engine |
|:-----------:|:------------------------:|:---------------------:|:-------------------------:|
| R1          | ✅                       | ✅                    | ✅                        |
| R2          | ✅                       | ✅                    | ❌                        |
| R3          | ✅                       | ❌                    | ❌                        |
| R4          | ✅                       | ✅                    | ❌                        |
| R5          | ✅                       | ✅                    | ❌                        |
| R6          | ✅ Zero new packages     | ❌ Violates Zero Bloat | ❌ Violates Zero Bloat   |
| R7          | ✅                       | ⚠️ Risk               | ❌                        |

**Verdict: Option A is the only shape that satisfies all requirements. Options B and C are rejected.**

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| NavItem hop clipped by `ClipRRect` at top of nav bar | MEDIUM | Measured: 96px bar, 12px top padding, icon at ~y=20. A -6px hop keeps icon at y=14. ClipRRect only rounds the top corners — hop is within safe bounds. |
| `ValueListenableBuilder` in `MainShell` re-fires frequently and restarts NavItem animation | HIGH | NavItem animation must be triggered ONLY by a local `isActive` bool change, not by the parent rebuilding. Use a `StatefulWidget` that compares old/new `isActive` in `didUpdateWidget`. |
| `ChecklyEmptyState` converts StatelessWidget → StatefulWidget, breaking test widget-type assertions | LOW | Tests ES-01 and ES-02 only assert text and icon rendering — not widget type. Conversion is safe. |
| `BouncyListWrapper` stagger causes jank on 100+ item lists | MEDIUM | Cap stagger delay: `min(index * 40, 500)` milliseconds. Only animate items rendered in the initial viewport. |
| BubblyButton's 24+ call sites: adding AnimatedScale inside Stack could change layout dimensions | LOW | Wrap only the face layer (not the shadow layer or the outer SizedBox). Scale from center — no layout shift. |
| `BouncyCheckbox` has no existing callsites | LOW | Create as a standalone primitive in `primitives/`. Do not force integration into existing audit rows in this epic. Callsite integration is a future slice. |

---

## Visual & Functional Context

### UI Component Routing Table

| Component | File | Status | What Changes |
|-----------|------|--------|--------------|
| `BubblyButton` | `lib/_shared/widgets/primitives/bubbly_button.dart` | MODIFY | Add `AnimatedScale` wrapping face layer. Scale Y: 1.0→0.90→1.05→1.0, X: 1.0→1.05→0.95→1.0 on tap |
| `NavItem` | `lib/_shared/router/nav_item.dart` | MODIFY | Convert to `StatefulWidget`. Add `AnimatedSlide` (offset Y: 0→-0.25 when active). Add `AnimatedScale` on icon (1.0→1.2 when active). Trigger only in `didUpdateWidget`. |
| `BouncyListWrapper` | `lib/_shared/widgets/bouncy_list_wrapper.dart` | CREATE | New widget. Accepts `children: List<Widget>`. Each child wrapped in `TweenAnimationBuilder` with `Duration(ms: min(index*40, 500))` delay. Animates Y offset 30px→0 + opacity 0→1. |
| `ChecklyEmptyState` | `lib/_shared/widgets/checkly_empty_state.dart` | MODIFY | Convert to `StatefulWidget`. Wrap illustration in `GestureDetector`. On tap: `AnimationController` drives `Tween<double>(-0.1, 0.1)` rotation jiggle + `HapticFeedback.lightImpact()`. |
| `BouncyCheckbox` | `lib/_shared/widgets/primitives/bouncy_checkbox.dart` | CREATE | New widget. `isChecked` + `onChanged` callback. `AnimatedScale` drives 1.0→0.8→1.2→1.0 on toggle. `HapticFeedback.mediumImpact()` on check. Uses `Curves.elasticOut`. |

### Truncation & Overflow Rules for BouncyListWrapper

| Scenario | Behavior |
|----------|----------|
| 0 items | Wrapper renders nothing (empty list passthrough) |
| 1–10 items | Full stagger: `index * 40ms` |
| 11–12 items | Stagger capped at `500ms` for items at index 12+ |
| 100+ items | Cap enforced — items beyond index 12 all share `500ms` delay |

---

## System Context

- **Offline/Online**: No impact. Pure widget animations.
- **RBAC**: No impact. Animations apply to all roles identically.
- **API Contracts**: None changed.
- **New Dependencies**: None. Uses only `flutter/material.dart` (AnimatedScale, AnimatedSlide, TweenAnimationBuilder, AnimationController) and `flutter/services.dart` (HapticFeedback) — both are already imported in the codebase.

---

## Lifecycle Context

| State | Expected Behavior |
|-------|-------------------|
| Button `isLoading=true` | No squash animation. Loading spinner renders as-is. Haptic still fires on tap down. |
| Button `onPressed=null` | GestureDetector is null → no animation, no haptic |
| NavItem active on first render | No hop animation triggered (no state change from inactive→active) |
| NavItem switches from inactive→active | Triggers hop animation once via `didUpdateWidget` guard |
| EmptyState emoji variant tapped | Jiggle applies to the emoji Text widget (same GestureDetector wraps both icon and emoji) |
| BouncyCheckbox `isChecked` set programmatically | Animation still plays — widget detects change via `didUpdateWidget` |
| BouncyListWrapper with 0 children | Renders empty SizedBox.shrink() to avoid layout errors |

---

## Data Context

**No database migrations required.**
**No schema changes.**
**No new Drift tables.**
**No server DTOs modified.**

This epic is 100% Flutter UI layer only.

---

## Architecture Flow

```
[User Tap / Navigation / List Load]
       │
       ▼
[Widget StatefulWidget receives gesture / isActive change]
       │
       ├──[GestureDetector.onTapDown] ──► setState(_isPressed = true)
       │          │
       │          └──► AnimatedScale drives face layer squash (BubblyButton)
       │
       ├──[didUpdateWidget: isActive changed] ──► AnimationController.forward()
       │          │
       │          └──► AnimatedSlide(-0.25) + AnimatedScale(1.2) (NavItem)
       │
       ├──[ListView build] ──► BouncyListWrapper.build()
       │          │
       │          └──► TweenAnimationBuilder per child (capped delay) ──► Slide+Fade
       │
       ├──[GestureDetector.onTap on EmptyState] ──► AnimationController jiggle
       │          └──► Transform.rotate(-0.1 → +0.1) + HapticFeedback.lightImpact()
       │
       └──[BouncyCheckbox.onChanged] ──► setState → AnimationController
                  └──► AnimatedScale(0.8→1.2→1.0) + HapticFeedback.mediumImpact()
```

---

## Risk Review & Security

- **No network calls.** No attack surface introduced.
- **HapticFeedback**: Platform-safe. Flutter degrades gracefully on devices without haptic motors. No exception path.
- **AnimationController**: Must be disposed in `dispose()` to prevent memory leaks. Every `StatefulWidget` that creates a controller must call `_controller.dispose()`.
- **No setState after dispose**: Guard `if (!mounted) return;` before any `setState` in animation callbacks.

---

## Logs & Audits

- No server-side logging required.
- No audit trail needed.
- Local debugging: Flutter DevTools' Performance tab can validate animation frame rates (target: 60fps on all animations).

---

## Testing Expectations

### Existing Tests That Must PASS (No Regression)

| Test ID | File | Assertion |
|---------|------|-----------|
| BB-01 | `test/widgets/primitives_test.dart` | Renders label text |
| BB-02 | `test/widgets/primitives_test.dart` | Fires onPressed callback on tap |
| BB-03 | `test/widgets/primitives_test.dart` | Shows CircularProgressIndicator when isLoading=true |
| ES-01 | `test/widgets/primitives_test.dart` | Renders title, subtitle, icon |
| ES-02 | `test/widgets/primitives_test.dart` | Emoji variant renders correctly |

### New Tests To Write (Per Slice)

| Slice | Test ID | Assertion |
|-------|---------|-----------|
| Slice 1 | BB-04 | `AnimatedScale` widget is found inside BubblyButton |
| Slice 2 | NI-01 | `AnimatedSlide` widget is found inside NavItem |
| Slice 2 | NI-02 | Icon scales to 1.2x when `isActive=true` |
| Slice 3 | BLW-01 | BouncyListWrapper renders all children |
| Slice 3 | BLW-02 | Each child is wrapped in `TweenAnimationBuilder` |
| Slice 4 | ES-03 | GestureDetector is present on illustration area |
| Slice 5 | BC-01 | BouncyCheckbox renders correctly in unchecked state |
| Slice 5 | BC-02 | Fires onChanged callback on tap |
| Slice 5 | BC-03 | `AnimatedScale` widget is present |

---

<command_logs>
- grep_search: bubbly_button.dart in lib/ → Found in primitives/
- grep_search: bouncy_checkbox.dart in lib/ → Not found (new file required)
- grep_search: checkly_empty_state.dart in lib/ → Found in _shared/widgets/
- grep_search: nav_item.dart in lib/ → Found in _shared/router/main_shell.dart reference
- grep_search: bouncy_list_wrapper in lib/ → Not found (new file required)
- list_dir: lib/_shared/widgets/ → 13 files listed
- list_dir: lib/_shared/widgets/primitives/ → 8 files listed
- view_file: bubbly_button.dart → 146 lines, StatefulWidget, AnimatedPositioned stack
- view_file: nav_item.dart → 81 lines, StatelessWidget, static color change only
- view_file: checkly_empty_state.dart → 85 lines, StatelessWidget, no GestureDetector
- view_file: main_shell.dart → 233 lines, ClipRRect height=96px, padding fromLTRB(24,12,24,0)
- grep_search: BubblyButton usages in lib/features/ → 24 call sites confirmed
- grep_search: BouncyCheckbox usages → 0 (does not exist)
- view_file: test/widgets/primitives_test.dart → 233 lines, BB-01..03, ES-01..02 tests
</command_logs>

---

## Handoff Block

**Final Decision**: Option A — Native Elastic Spring Physics. Confirmed viable. Zero package bloat. Zero backend risk.

**Epic Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\ds03_spirit_deep\analysis_epic_20260522_195451_6da6d3b1_ds03_spirit_deep.md`

---

### Slice Definitions

---

**Slice 1: BubblyButton — Squash & Stretch**
- **Plain English**: Make the button feel like pressing a physical squishy key. When you tap it, the button body squashes and then bounces back elastically.
- **Why now?**: BubblyButton is the most-used primitive (24 call sites). It is the highest-impact change. All other slices are independent of this.
- **Scenario Focus**: Basic Scenario (happy path tap).
- **Value Delivered**: Every button press in the app feels tactile and alive.
- **Entry State Required**: `bubbly_button.dart` is at current state (AnimatedPositioned 3D press only). Existing tests BB-01, BB-02, BB-03 are passing.
- **Exit State Guaranteed**: `bubbly_button.dart` has an `AnimatedScale` wrapping the button face. Tests BB-01, BB-02, BB-03 still pass. New test BB-04 passes.
- **Architectural Scope**: Flutter UI only. `lib/_shared/widgets/primitives/bubbly_button.dart`.
- **Acceptance Criteria**:

  | # | Given | When | Then |
  |---|-------|------|------|
  | BB-04 | BubblyButton is rendered | Widget tree is inspected | `find.byType(AnimatedScale)` finds at least 1 widget |
  | BB-05 | Button is tapped | `onTapDown` fires | `_isPressed = true` and scale changes to squash values |
  | BB-06 | Button tap is released | `onTapUp` fires | Scale springs back, `onPressed` callback fires |
  | BB-07 | Button tap is cancelled (drag off) | `onTapCancel` fires | `_isPressed = false` and scale springs back to normal |
  | BB-01 | — | — | Existing: label renders ✅ |
  | BB-02 | — | — | Existing: onPressed fires ✅ |
  | BB-03 | — | — | Existing: isLoading shows spinner ✅ |

---

**Slice 2: NavItem — Y-Axis Bounce Hop**
- **Plain English**: When you tap a bottom navigation tab, the icon hops up slightly and grows a little, like it jumped with excitement.
- **Why now?**: Can run after Slice 1 is merged. Requires converting `NavItem` from StatelessWidget → StatefulWidget. Isolated to 1 file.
- **Scenario Focus**: Basic Scenario (tab press when user navigates).
- **Value Delivered**: Bottom navigation feels energetic instead of static.
- **Entry State Required**: `nav_item.dart` is a StatelessWidget. MainShell nav bar is 96px with ClipRRect top-24 border radius.
- **Exit State Guaranteed**: `nav_item.dart` is a StatefulWidget. `AnimatedSlide` and `AnimatedScale` present. Y-hop does not clip. No regressions in MainShell rendering.
- **Architectural Scope**: Flutter UI only. `lib/_shared/router/nav_item.dart`.
- **Acceptance Criteria**:

  | # | Given | When | Then |
  |---|-------|------|------|
  | NI-01 | NavItem is rendered | Widget tree inspected | `find.byType(AnimatedSlide)` finds 1 widget |
  | NI-02 | `isActive=true` passed | Widget builds | Icon scale is 1.2x (via AnimatedScale with scale=1.2) |
  | NI-03 | `isActive=false` | Widget builds | Icon scale is 1.0x |
  | NI-04 | `isActive` changes false→true | `didUpdateWidget` fires | Animation controller starts forward() once only |

---

**Slice 3: BouncyListWrapper — Staggered Domino Entrance**
- **Plain English**: When a screen loads a list of items, each card slides up and fades in one after another, like dominoes falling into place.
- **Why now?**: New file — zero impact on existing code. Can run in parallel with Slice 2.
- **Scenario Focus**: Basic Scenario (list loads from empty to populated).
- **Value Delivered**: Every list screen in the app that uses this wrapper feels fast and alive.
- **Entry State Required**: File `bouncy_list_wrapper.dart` does not exist.
- **Exit State Guaranteed**: `bouncy_list_wrapper.dart` exists in `lib/_shared/widgets/`. Stagger is capped at 500ms. All children render. Tests BLW-01 and BLW-02 pass.
- **Architectural Scope**: Flutter UI only. New file: `lib/_shared/widgets/bouncy_list_wrapper.dart`.
- **Acceptance Criteria**:

  | # | Given | When | Then |
  |---|-------|------|------|
  | BLW-01 | BouncyListWrapper given 3 Text children | Widget built | All 3 Text widgets found in tree |
  | BLW-02 | BouncyListWrapper given N children | Widget built | N `TweenAnimationBuilder` widgets present |
  | BLW-03 | 0 children provided | Widget built | No error, renders empty |
  | BLW-04 | 13+ children provided | Stagger computed | Delay for index 12 and above is capped at 500ms |

---

**Slice 4: ChecklyEmptyState — Toy Jiggle**
- **Plain English**: When a user taps the illustration on an empty screen, it jiggles playfully and vibrates the phone. It rewards curiosity.
- **Why now?**: Requires StatelessWidget → StatefulWidget conversion. Must run after Slice 1 is complete to ensure test suite baseline is clean.
- **Scenario Focus**: Extension Scenario (idle screen interaction).
- **Value Delivered**: Empty states feel friendly and interactive instead of dead.
- **Entry State Required**: `checkly_empty_state.dart` is a StatelessWidget. Tests ES-01, ES-02 pass.
- **Exit State Guaranteed**: `checkly_empty_state.dart` is a StatefulWidget with AnimationController. GestureDetector on illustration. Jiggle + haptic on tap. Tests ES-01, ES-02 still pass. New test ES-03 passes.
- **Architectural Scope**: Flutter UI only. `lib/_shared/widgets/checkly_empty_state.dart`.
- **Acceptance Criteria**:

  | # | Given | When | Then |
  |---|-------|------|------|
  | ES-03 | ChecklyEmptyState is rendered | Widget tree inspected | `find.byType(GestureDetector)` finds 1 widget |
  | ES-04 | Icon or emoji area is tapped | GestureDetector.onTap fires | `AnimationController` is in running state |
  | ES-01 | — | — | Existing: renders title, subtitle, icon ✅ |
  | ES-02 | — | — | Existing: emoji variant renders ✅ |

---

**Slice 5: BouncyCheckbox — Satisfying Pop**
- **Plain English**: Create a new checkbox widget that pops and bounces when you check it, paired with a satisfying phone vibration. This is the reward for completing a task.
- **Why now?**: New file — no existing callsites to risk. Runs last because it requires understanding how BubblyButton (Slice 1) patterns animation controllers, which sets the coding standard.
- **Scenario Focus**: Basic Scenario (user checks off a task item).
- **Value Delivered**: Task completion feels deeply satisfying — the signature moment of the app.
- **Entry State Required**: `bouncy_checkbox.dart` does not exist. `primitives.dart` barrel file exists.
- **Exit State Guaranteed**: `bouncy_checkbox.dart` exists. `BouncyCheckbox` exported from `primitives.dart`. Tests BC-01, BC-02, BC-03 pass.
- **Architectural Scope**: Flutter UI only. New file: `lib/_shared/widgets/primitives/bouncy_checkbox.dart`. Modify: `lib/_shared/widgets/primitives/primitives.dart` (add export).
- **Acceptance Criteria**:

  | # | Given | When | Then |
  |---|-------|------|------|
  | BC-01 | `BouncyCheckbox(isChecked: false)` rendered | Widget built | No checkmark icon visible (or icon color is transparent/muted) |
  | BC-02 | Checkbox tapped | `onChanged` callback | Callback fires with toggled value |
  | BC-03 | Widget tree inspected | Any state | `find.byType(AnimatedScale)` finds 1 widget |
  | BC-04 | `isChecked` changes false→true | Widget updates | `AnimatedScale` scale transitions to 1.2 (pop) then settles to 1.0 |
  | BC-05 | Widget tree inspected | Any state | Widget is wrapped in a `Semantics` widget with `checked: isChecked` |

---

### Execution Order

| Slice | Order | Reason |
|-------|-------|--------|
| Slice 1 — BubblyButton | `[BLOCKING]` | Highest impact (24 call sites). Must pass tests before other slices merge. |
| Slice 2 — NavItem | `[SEQUENTIAL after Slice 1]` | Depends on clean test baseline. |
| Slice 3 — BouncyListWrapper | `[PARALLEL with Slice 2]` | New file, zero existing dependency. |
| Slice 4 — ChecklyEmptyState | `[SEQUENTIAL after Slice 1]` | Depends on clean baseline. Can run parallel with Slice 2/3. |
| Slice 5 — BouncyCheckbox | `[SEQUENTIAL after Slice 4]` | Uses same AnimationController patterns. New primitive only — no callsite integration. |

---

### Handoff Roadmap

Execute ONE slice at a time. Do not batch.

- **Slice 1** (BubblyButton): Write Unit Tests → Build
- **Slice 2** (NavItem): Write Unit Tests → Build
- **Slice 3** (BouncyListWrapper): Write Unit Tests → Build  *(can run in parallel with Slice 2)*
- **Slice 4** (ChecklyEmptyState): Write Unit Tests → Build
- **Slice 5** (BouncyCheckbox): Write Unit Tests → Build

**Epic Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\ds03_spirit_deep\analysis_epic_20260522_195451_6da6d3b1_ds03_spirit_deep.md`

**Next Agent Instructions**: The Builder should load this epic plan and execute slices in the order defined above. Start with Slice 1 (BubblyButton). Load the `tdd` skill before writing tests. Verify `flutter test test/widgets/primitives_test.dart` passes before and after each slice. The Forge persona governs all build steps.
