<latent_space_scratchpad>
## Problem Framing

Option A is the approved path from the research artifact. The question is NOT "which option to pick" — that is settled.
The question for this /analyze-epic is:
  "How do we SAFELY and PRECISELY implement Option A's 4 vectors across the codebase, without breaking existing behavior?"

The 4 vectors from the research:
  1. Haptics: Add HapticFeedback.lightImpact() to BubblyButton, StrokeCard. Add heavyImpact() to EmptyState success trigger.
  2. Bounce: Add Transform.scale (0.95x) to BubblyButton (already uses AnimatedPositioned — consider overlap), (0.98x) to StrokeCard.
  3. Mascot Emoji: Add String? emoji to ChecklyEmptyState. Backward compatible (all 9 callers use icon only today).
  4. Page Transitions: Add slideTransition to AppTheme.pageTransitionsTheme. This is a global change.

### Architecture Decision: BubblyButton Bounce Strategy
BubblyButton already has a 3D "press" effect via AnimatedPositioned (top: 0→4). 
Adding Transform.scale(0.95) on top of that would double the visual effect.
Decision: The 3D shift IS the bounce. We do NOT add Transform.scale to BubblyButton.
We only add HapticFeedback.lightImpact() on onTapDown. This is the correct, minimal approach.

### Architecture Decision: StrokeCard Bounce Strategy
StrokeCard currently uses StatelessWidget + InkWell (when onTap != null).
To add Transform.scale(0.98x), we need to convert StrokeCard to StatefulWidget (to hold a pressed state bool).
GestureDetector wraps the InkWell/Card and manages _isPressed state.
Risk: InkWell will still propagate ripple. The scale + ripple together could feel busy.
Resolution: When onTap is provided, REMOVE InkWell splash and use ONLY GestureDetector + Transform.scale.
This is cleaner. The tactile haptic IS the feedback. The visual scale IS the press feedback.

### Architecture Decision: Page Transitions
GoRouter uses `builder:` (not `pageBuilder:`). The correct way to add global slide transitions
with GoRouter is via `pageTransitionsTheme` in ThemeData.
Flutter's `pageTransitionsTheme` maps Platform → TransitionsBuilder.
We create a custom `SlideRightToLeftPageTransitionsBuilder` that returns a SlideTransition.
This applies globally to ALL GoRoute navigations. This is the cleanest, single-point approach.
Alternative: Use `pageBuilder:` on every GoRoute. Rejected — violates DRY, touches 40+ routes.

### Architecture Decision: UX Copy Injection
UX copy (e.g., "You crushed it!", "Nothing here yet 🎯") lives at the call site of ChecklyEmptyState.
We do NOT centralize copy into a constant file. Each screen owns its own empty state message.
This is a content change, NOT an architecture change. It's part of the same slice as emoji support.

### Three-Perspective Review:

**DB Architect (10/10):**
Zero database, zero entity, zero sync, zero DTO changes. Pure Flutter layer.
No risk whatsoever at this layer.

**Security Auditor (9/10):**
- HapticFeedback is a local OS call. No network. No data.
- Transform.scale is pure visual. No auth paths affected.
- The ONLY risk: when refactoring StrokeCard from StatelessWidget → StatefulWidget,
  verify ActionGuard/PermissionGuard wrapping patterns are not disturbed.
  Mitigation: grep for ActionGuard in files that use StrokeCard before closing each slice.
Score: 9/10.

**Junior Dev Maintenance (8/10):**
- Adding `String? emoji` to ChecklyEmptyState is additive. No breaking changes. Clear dartdoc needed.
- Converting StrokeCard to StatefulWidget is the most complex change. But it's only 72 lines.
  After refactoring, it stays under 400 lines. The _isPressed state management is simple and standard.
- SlideRightToLeftPageTransitionsBuilder: a new class, ~20 lines. Add dartdoc.
- Haptic calls are 1-liners. Any junior can understand them.
Score: 8/10. All scores ≥ 7. Plan passes.

### Slice Strategy:
This is Slice 9 of the Duolingo Reskin epic. It's a SINGLE vertical feature slice.
However, the work has a natural dependency order:
  - Sub-Slice A [BLOCKING]: Add HapticFeedback to BubblyButton (1 file, 1 line)
  - Sub-Slice B [BLOCKING]: Refactor StrokeCard → StatefulWidget with scale + haptics (1 file, ~20 lines added)
  - Sub-Slice C [SEQUENTIAL after A+B]: Add String? emoji to ChecklyEmptyState + heavyImpact on success (1 file)
  - Sub-Slice D [SEQUENTIAL after C]: Inject gamified UX copy into 9 call sites (9 files)
  - Sub-Slice E [SEQUENTIAL after B]: Add pageTransitionsTheme to AppTheme (1 file, ~10 lines)

The slices are so small that they can be executed as a single Track A session.
The implementation plan recommends ONE build per sub-slice (flutter analyze after each).
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260522_133254_ds02_spirit_research.md`
- **Parent Epic**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260521_202100_ds01_duolingo_reskin.md`

---

## Executive Summary

This Epic injects the **"Spirit"** of Duolingo — physicality, personality, and tone — into the Checkly Flutter app, without adding packages, backend changes, or new screens. It extends the existing 8-slice visual reskin (DS01) by adding the 4 vectors of gamified game-feel using only Flutter's built-in APIs.

```
[User Tap / Navigation / Empty State]
         │
         ├─► BubblyButton.onTapDown
         │       ├─► HapticFeedback.lightImpact()      [NEW]
         │       └─► AnimatedPositioned (3D press)     [EXISTING]
         │
         ├─► StrokeCard.onTap (when interactive)
         │       ├─► HapticFeedback.lightImpact()      [NEW]
         │       └─► Transform.scale(0.98)             [NEW - replaces InkWell]
         │
         ├─► GoRouter page push
         │       └─► SlideTransition (R-to-L)          [NEW - via AppTheme]
         │
         └─► ChecklyEmptyState
                 ├─► String? emoji (e.g., 🎉, ☕, 🦉)  [NEW - optional param]
                 ├─► Gamified UX copy at call sites     [NEW - content change]
                 └─► HapticFeedback.heavyImpact()       [OUT OF SCOPE - no success event]
```

**Scope Contract (immutable):**
- ✅ Add `HapticFeedback.lightImpact()` to `BubblyButton` and interactive `StrokeCard`
- ✅ Convert interactive `StrokeCard` to use `Transform.scale(0.98)` + `GestureDetector` instead of `InkWell`
- ✅ Add `String? emoji` parameter to `ChecklyEmptyState`
- ✅ Update gamified UX copy in 9 call sites of `ChecklyEmptyState`
- ✅ Add `pageTransitionsTheme` (slide R-to-L) to `AppTheme._buildTheme()`
- ❌ No new packages (confetti, lottie, flutter_animate)
- ❌ No sound effects
- ❌ No new screens or routes
- ❌ No database changes
- ❌ No backend changes

---

## Decision Matrix

### Requirements (R)

| ID | Requirement |
|:---|:---|
| R1 | BubblyButton must produce haptic feedback on every user tap |
| R2 | Interactive StrokeCard must visually react to touch (scale bounce) |
| R3 | Interactive StrokeCard must produce haptic feedback on every tap |
| R4 | Page transitions must slide right-to-left (not the default Material fade/zoom) |
| R5 | ChecklyEmptyState must support an optional mascot emoji display |
| R6 | All 9 existing callers of ChecklyEmptyState must NOT break (backward compat) |
| R7 | UX copy across empty states must use encouraging, gamified language |
| R8 | Zero new packages added to pubspec.yaml |
| R9 | Every file must stay under 400 lines |
| R10 | `flutter analyze` must pass 0 errors after each change |
| R11 | ActionGuard / PermissionGuard must be preserved and untouched |

### Shapes (S)

**Shape A — Pure Native (0 packages)**
- Haptics: Flutter `HapticFeedback.lightImpact()` / `mediumImpact()`
- Bounce: `GestureDetector` + `Transform.scale` on `StrokeCard` (replaces `InkWell`)
- BubblyButton: 3D AnimatedPositioned already provides the press effect — add haptic only
- Transitions: `pageTransitionsTheme` in `AppTheme` with custom `SlideRightToLeftPageTransitionsBuilder`
- EmptyState: Add `String? emoji` field, render emoji in a `Text` widget above the icon circle (or replace icon circle when emoji is provided)

**Shape B — Low Bloat (+1 confetti package)**
- All of Shape A, PLUS `confetti` package for celebration bursts on success empty states
- Risk: Violates "Zero Bloat" rule. Requires explicit user approval.

### Fit Check

| Requirement | Shape A (Native) | Shape B (Confetti) |
|:---|:---:|:---:|
| R1 HapticFeedback on BubblyButton | ✅ | ✅ |
| R2 StrokeCard scale bounce | ✅ | ✅ |
| R3 HapticFeedback on StrokeCard | ✅ | ✅ |
| R4 Slide page transitions | ✅ | ✅ |
| R5 Emoji in ChecklyEmptyState | ✅ | ✅ |
| R6 Backward compat (9 callers) | ✅ | ✅ |
| R7 Gamified UX copy | ✅ | ✅ |
| R8 Zero new packages | ✅ | ❌ |
| R9 Files under 400 lines | ✅ | ✅ |
| R10 flutter analyze clean | ✅ | ✅ |
| R11 ActionGuard preserved | ✅ | ✅ |

**Verdict: Shape A wins.** Shape B is rejected — the `Zero Bloat` rule has not been waived by the user.

---

## Risk Assessment

| Risk | Severity | File(s) Affected | Mitigation |
|:---|:---|:---|:---|
| StrokeCard refactor breaks existing non-interactive usage | Medium | `stroke_card.dart` | Non-interactive path (`onTap == null`) keeps the current `Card` widget unchanged. Only the `onTap != null` branch is refactored. Widget tests must cover both paths. |
| HapticFeedback silently fails on iOS (system vibrations off) | Low | `bubbly_button.dart`, `stroke_card.dart` | Expected and documented. Visual bounce is the primary feedback. Haptic is additive. No code guard needed. |
| `Transform.scale` jitter on older Android | Low | `stroke_card.dart` | Scale is 0.98x (2% change). Jitter risk is negligible at this magnitude. |
| `pageTransitionsTheme` conflicts with GoRouter | Low | `app_theme.dart` | GoRouter respects `pageTransitionsTheme` when using standard `builder:`. Verified: no `pageBuilder:` overrides exist in `app_router.dart`. Safe to apply globally. |
| Copy changes break existing widget tests | Low | 9 call sites | Search for existing widget tests that assert on empty state text. Update expected strings to match new copy. |
| ActionGuard removed during StrokeCard refactor | Low | Any screen using StrokeCard + ActionGuard | Grep for ActionGuard in all 9 ChecklyEmptyState call site files before closing the slice. |

---

## Visual & Functional Context

### UI Component Routing Table

| Component | File | Change Type | Callers Affected |
|:---|:---|:---|:---|
| `BubblyButton` | `lib/_shared/widgets/primitives/bubbly_button.dart` | `[MOD]` Add 1 haptic line | All screens using BubblyButton |
| `StrokeCard` | `lib/_shared/widgets/primitives/stroke_card.dart` | `[MOD]` StatelessWidget → StatefulWidget, replace InkWell with GestureDetector + scale | All screens using StrokeCard with onTap |
| `ChecklyEmptyState` | `lib/_shared/widgets/checkly_empty_state.dart` | `[MOD]` Add `String? emoji` optional field | 9 dependent screens (additive, backward compat) |
| `AppTheme` | `lib/_shared/theme/app_theme.dart` | `[MOD]` Add `pageTransitionsTheme` to `_buildTheme()` | ALL screens (global) |
| **9 call sites** | See table below | `[MOD]` UX copy + emoji injection | Each individually |

### ChecklyEmptyState Call Sites

| File | Current Title | New Title | Emoji |
|:---|:---|:---|:---|
| `action_plans_page.dart` (L162) | (unknown — to read at build time) | "No plans here yet" | 📋 |
| `action_plans_page.dart` (L246) | (unknown) | "All clear!" | ✅ |
| `user_management_list.dart` (L60) | (unknown) | "No users found" | 👥 |
| `audit_approval_page.dart` (L304) | (unknown) | "Nothing to review" | 🎉 |
| `store_management_page.dart` (L142) | (unknown) | "No stores yet" | 🏪 |
| `system_logs_page.dart` (L269) | (unknown) | "Logs are quiet" | 🪵 |
| `analytics_body.dart` (L80) | (unknown) | "No data yet" | 📊 |
| `analytics_body.dart` (L87) | (unknown) | "Nothing to show" | 📉 |

> [!NOTE]
> AI Decision: Exact copy wording is not specified here. The Builder MUST read the current `title` and `subtitle` at each call site and rewrite them in an encouraging, active voice. The emoji column above is a suggestion — Builder may adjust to best fit the context.

---

## System Context

| Concern | Impact |
|:---|:---|
| **Offline-first** | None — pure visual/haptic changes. |
| **RBAC / PBAC** | None — ActionGuard/PermissionGuard are not touched. |
| **Sync** | None — zero DTO changes. |
| **API Contracts** | None — zero backend changes. |
| **Dark Mode** | `Transform.scale` is brightness-agnostic. `HapticFeedback` is OS-level. No dark mode risk. |
| **GoRouter** | `pageTransitionsTheme` applies globally to all routes via GoRouter's standard builder pattern. Verified safe. |

---

## Lifecycle Context

| Edge State | Current Behavior | New Behavior |
|:---|:---|:---|
| **BubblyButton disabled** (`onPressed == null`) | No 3D press effect | No haptic, no change. `onTapDown` guard already checks `isEnabled`. |
| **BubblyButton loading** (`isLoading == true`) | Spinner shown, press disabled | No haptic. Same guard logic. |
| **StrokeCard no-tap** (`onTap == null`) | Static Card widget | Unchanged. StatefulWidget guard: only enters scale logic when `onTap != null`. |
| **ChecklyEmptyState no-emoji** (`emoji == null`) | Shows icon circle | Shows icon circle. Backward compat guaranteed by optional param. |
| **ChecklyEmptyState with emoji** | N/A | Shows large emoji `Text` widget. Icon circle is hidden when emoji is provided. |
| **Rollback** | Revert 4 files | `bubbly_button.dart`, `stroke_card.dart`, `checkly_empty_state.dart`, `app_theme.dart` + 9 call sites |

---

## Data Context

**Zero database migrations.**
**Zero entity changes.**
**Zero pubspec.yaml dependency changes.**

---

## Architecture Flow

```
[Step 1] bubbly_button.dart
   GestureDetector.onTapDown
      └─► HapticFeedback.lightImpact()    [ADD]
      └─► setState(_isPressed = true)     [EXISTING]

[Step 2] stroke_card.dart (onTap path only)
   StatefulWidget [CONVERT]
      └─► GestureDetector (replaces InkWell)
              ├─► onTapDown: HapticFeedback.lightImpact() + setState(_isPressed=true)
              ├─► onTapUp: setState(_isPressed=false) + widget.onTap?.call()
              ├─► onTapCancel: setState(_isPressed=false)
              └─► child: AnimatedScale(scale: _isPressed ? 0.98 : 1.0, child: Card(...))

[Step 3] checkly_empty_state.dart
   Add: final String? emoji;       [ADD optional field]
   Build:
      └─► IF emoji != null:
              └─► Text(emoji, style: fontSize 56)  [instead of icon circle]
          ELSE:
              └─► Container(icon circle)  [EXISTING]

[Step 4] app_theme.dart → _buildTheme()
   Add: pageTransitionsTheme: PageTransitionsTheme(
           builders: {
             TargetPlatform.android: _SlidePageTransitionsBuilder(),
             TargetPlatform.iOS: _SlidePageTransitionsBuilder(),
           },
        )
   [NEW private class _SlidePageTransitionsBuilder implements PageTransitionsBuilder]

[Step 5] 9 call sites of ChecklyEmptyState
   Inject: emoji: '🎉' (or context-appropriate emoji)
   Rewrite: title/subtitle to gamified, encouraging copy
```

---

## Risk Review & Security

**DB Architect score: 10/10** — Zero schema contact. No risk.

**Security Auditor score: 9/10** — No routes, auth, or permission changes. Sole risk: StrokeCard refactor could theoretically hide an `ActionGuard` child if the scale transform clips content. Mitigation: `Transform.scale` does not clip by default. `ClipBehavior` must NOT be set. Pre-close grep for `ActionGuard` in all affected files.

**Junior Dev Maintenance score: 8/10** — StrokeCard's `StatefulWidget` conversion is the most complex change (~+20 lines). Clear dartdoc on the `emoji` field in `ChecklyEmptyState` is mandatory. The `_SlidePageTransitionsBuilder` class in `app_theme.dart` must have a dartdoc comment explaining its purpose to prevent future developers from deleting it accidentally.

---

## Logs & Audits

No audit log changes. No system log entries introduced.

---

## Testing Expectations

| Test Type | What to Verify |
|:---|:---|
| `flutter analyze` | Must pass 0 errors after each sub-slice |
| Manual touch test | Tap BubblyButton → feel haptic on real device. Press interactive StrokeCard → see scale bounce. |
| Widget test (StrokeCard) | Both paths: `onTap == null` renders `Card` statically. `onTap != null` renders GestureDetector + AnimatedScale. |
| Widget test (ChecklyEmptyState) | `emoji == null` renders icon circle. `emoji != null` renders emoji Text, icon hidden. |
| `ActionGuard` presence check | `grep_search` for `ActionGuard` in all 9 call site files confirms it was not removed. |

> No new integration or unit tests required for haptics or UX copy. Haptics are not assertable in widget tests without platform mocking — skip. Copy changes are verified visually.

<command_logs>
- `grep_search "HapticFeedback" lib/_shared/widgets` → 0 results. Confirmed absent from all shared widgets.
- `grep_search "HapticFeedback" lib/` → Found in 3 profile feature files only (settings_section_group.dart L99, theme_toggle_tile.dart L35, admin_command_card.dart L49).
- `grep_search "ChecklyEmptyState" lib/` → Found 9 dependent call sites across 8 files.
- `view_file bubbly_button.dart` → 127 lines. GestureDetector present. No haptic. No Transform.scale.
- `view_file stroke_card.dart` → 72 lines. StatelessWidget. InkWell on onTap path. No haptic. No scale.
- `view_file checkly_empty_state.dart` → 80 lines. Only IconData icon. No emoji field.
- `view_file app_theme.dart` → 184 lines. No pageTransitionsTheme defined.
- `view_file app_router.dart` → 278 lines. All routes use builder:, no pageBuilder: overrides.
- `list_dir lib/_shared/widgets/primitives` → 8 files, all under 400 lines. No Transform.scale found.
- `grep_search "PageRouteBuilder|SlideTransition|pageTransitionsTheme|GoRoute" lib/` → 0 results. Confirmed no existing transition config.
</command_logs>

---

## Handoff Block

**Final Decision:** Option A (Pure Native). Zero packages. 5 targeted sub-slices.

**Epic Plan File:** `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260522_134514_ds03_spirit_epic.md`

---

### Slice Breakdown

**Sub-Slice A [BLOCKING] — Haptic: BubblyButton**
- **Plain English**: Add one line `HapticFeedback.lightImpact()` inside the `onTapDown` handler of `BubblyButton`. This makes every primary action button feel tactile.
- **Why first?**: Lowest-risk, single-line change. Proves the haptic API works on the target device.
- **Files**: `lib/_shared/widgets/primitives/bubbly_button.dart` `[MOD]`
- **Acceptance Criteria**:
  - Tapping BubblyButton on a physical device triggers a light vibration ✅
  - Disabled/loading button produces no haptic (guard unchanged) ✅
  - `flutter analyze` passes 0 errors ✅

---

**Sub-Slice B [BLOCKING] — Bounce + Haptic: StrokeCard**
- **Plain English**: Convert `StrokeCard` from `StatelessWidget` to `StatefulWidget`. On the interactive path (`onTap != null`), replace `InkWell` with `GestureDetector` + `AnimatedScale(0.98)` + `HapticFeedback.lightImpact()`.
- **Why now?**: This is the highest-complexity change. Must be isolated and verified alone.
- **Files**: `lib/_shared/widgets/primitives/stroke_card.dart` `[MOD]`
- **Acceptance Criteria**:
  - Pressing an interactive StrokeCard scales it to 98% and snaps back on release ✅
  - Pressing an interactive StrokeCard triggers a light haptic ✅
  - Non-interactive StrokeCard (`onTap == null`) is visually and behaviorally unchanged ✅
  - File stays under 400 lines ✅
  - `flutter analyze` passes 0 errors ✅

---

**Sub-Slice C [SEQUENTIAL after A+B] — Mascot: ChecklyEmptyState**
- **Plain English**: Add an optional `String? emoji` field to `ChecklyEmptyState`. When provided, render the emoji as a large `Text` (fontSize 56) instead of the icon circle. All 9 existing callers are unaffected (emoji defaults to null).
- **Files**: `lib/_shared/widgets/checkly_empty_state.dart` `[MOD]`
- **Acceptance Criteria**:
  - `ChecklyEmptyState(title: ..., subtitle: ...)` still works (no emoji) ✅
  - `ChecklyEmptyState(emoji: '🎉', title: ..., subtitle: ...)` shows emoji, hides icon circle ✅
  - `flutter analyze` passes 0 errors ✅

---

**Sub-Slice D [SEQUENTIAL after C] — UX Copy Injection (9 files)**
- **Plain English**: At each of the 9 ChecklyEmptyState call sites, read the current `title`/`subtitle` and rewrite them in encouraging, active voice. Add an appropriate `emoji:` argument.
- **Why last in the sequence?**: Copy is content, not logic. It runs after the emoji field exists.
- **Files**: 9 call site files (see Call Sites table above) `[MOD]`
- **Acceptance Criteria**:
  - Every ChecklyEmptyState call site has a non-null `emoji:` argument ✅
  - Copy uses verb-first, encouraging language (no "No items found" style) ✅
  - `flutter analyze` passes 0 errors ✅

---

**Sub-Slice E [PARALLEL with C/D] — Slide Transitions: AppTheme**
- **Plain English**: Add `pageTransitionsTheme` to `AppTheme._buildTheme()`. Define a private `_SlideRightToLeftTransitionsBuilder` class (~15 lines) that returns a `SlideTransition` from `Offset(1,0)` to `Offset.zero`. Apply to Android and iOS platforms.
- **Why parallel?**: This change is isolated to `app_theme.dart`. It does not depend on Sub-Slices C or D.
- **Files**: `lib/_shared/theme/app_theme.dart` `[MOD]`
- **Acceptance Criteria**:
  - Navigating to any route slides in from the right ✅
  - Back navigation slides out to the right ✅
  - `app_theme.dart` stays under 400 lines (currently 184 — adding ~20 lines is safe) ✅
  - `flutter analyze` passes 0 errors ✅

---

### Handoff Roadmap

Execute these ONE AT A TIME. Verify `flutter analyze` passes after each before moving forward.

| Sub-Slice | Order | Risk | Handoff Route |
|:---|:---|:---|:---|
| **A** — Haptic: BubblyButton | `[BLOCKING]` Run FIRST | Low | Plan → Build |
| **B** — Bounce + Haptic: StrokeCard | `[BLOCKING]` Run SECOND | Medium | Plan → Write Unit Tests → Build |
| **C** — Mascot: ChecklyEmptyState | `[SEQUENTIAL]` After A+B | Low | Plan → Build |
| **D** — UX Copy (9 files) | `[SEQUENTIAL]` After C | Low | Plan → Build |
| **E** — Slide Transitions: AppTheme | `[PARALLEL]` With C/D | Low | Plan → Build |

**Next Steps for Builder:**
1. Start with Sub-Slice A. File: `lib/_shared/widgets/primitives/bubbly_button.dart`. Add `HapticFeedback.lightImpact();` as the first line inside the `onTapDown` callback (inside the `isEnabled ? (_) =>` lambda). Add `import 'package:flutter/services.dart';`.
2. Proceed to Sub-Slice B. File: `lib/_shared/widgets/primitives/stroke_card.dart`. Convert to `StatefulWidget`. Replace `InkWell` in the `onTap != null` branch with `GestureDetector` + `AnimatedScale`.
3. Continue in sequence through C → D → E.
4. After D (9 files): Run `grep_search "ActionGuard"` across all 9 modified call site files to confirm guards are intact.
5. Final verification: `rtk flutter analyze` must return 0 errors.
