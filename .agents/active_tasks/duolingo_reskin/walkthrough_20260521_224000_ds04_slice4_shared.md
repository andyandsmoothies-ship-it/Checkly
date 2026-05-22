# Walkthrough: Duolingo Reskin - Slice 4 (Shared Widgets Reskin)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260521_211000_ds04_slice4_shared_widgets.md`

## Decision Log

- **RoleBadge**:
  - *Proposed*: Migrate role-to-color mapping to use `PillChip` primitive.
  - *Implemented*: Replaced `Container`/`BoxDecoration` rendering with `PillChip(label:, type:)`. Maps `admin → PillChipType.purple`, `auditor → PillChipType.blue`, `storeManager → PillChipType.yellow`, `areaManager → PillChipType.green`. Public API preserved exactly (`role`, `size`).

- **CompactStatusPanel**:
  - *Proposed*: Outer container to use `StrokeCard` and Swan dividers.
  - *Implemented*: Replaced `Card(...)` outer wrap with `StrokeCard(child:...)`. Divider color changed from `AppTheme.sageGray.withValues(alpha:0.15)` to `AppColors.swan` (const — no runtime computation). Text colors use `AppColors.eel` and `AppColors.hare` directly instead of `Theme.of(context).colorScheme.onSurface.withValues(...)`.

- **ChecklyEmptyState**:
  - *Proposed*: Polar background and bold Nunito labels.
  - *Implemented*: Wrapped content in `Container` with `AppColors.polar` fill, 24px rounded corners, and 2px Swan border. Added a SeaSponge-tinted icon circle with `AppColors.turtle` border. Title set to `FontWeight.w900`.

- **ScoreAvatar**:
  - *Proposed*: Three-tier gamified pastel color map (green ≥80, yellow ≥50, red <50).
  - *Implemented*: Added private `_ScoreTier` enum. Resolved `bg`, `border`, and `textColor` per tier with high-contrast semantic text colors (`const Color(0xFF388E3C)` for green, `AppColors.fox` for yellow, `AppColors.cardinal` for red). 2px border applied to all circles.

- **StatBlock**:
  - *Proposed*: Swan 2px border on compact variant, brand pastel defaults.
  - *Implemented*: Changed `StatBlock.compact` bg from `Colors.white` to `AppColors.polar`. Border changed from `AppColors.sageGray.withValues(alpha:0.5)` to `const Border.all(color: AppColors.swan, width: 2)`. Label weight elevated to `FontWeight.w700`.

- **WarmChip**:
  - *Proposed*: FeatherGreen fill for selected state, Swan-bordered unselected.
  - *Implemented*: Replaced `theme.colorScheme.primary` with `AppColors.featherGreen` for selected fill. Unselected state uses `Colors.white` bg + 2px Swan border. Wrapped in `AnimatedContainer` (150ms) for smooth transition. Radius changed to `100` (fully pill-shaped).

- **ChecklyFab**:
  - *Proposed*: FeatherGreen fill, flat elevation, brand-themed popup.
  - *Implemented*: FAB `backgroundColor` set to `AppColors.featherGreen`, `elevation: 0`. Popup menu icons use semantic colors (`featherGreen` for audit, `macaw` for assign). Popup `shape` adds 2px Swan border, `elevation: 0`, `color: Colors.white`.

- **UnsavedChangesGuard**:
  - *Proposed*: Show `BubblyDialog` instead of `AlertDialog`. PopScope logic untouched.
  - *Implemented*: Replaced `AlertDialog(...)` builder with `BubblyDialog(title:, content:, actions:)`. The entire `PopScope`, `canPop`, `onPopInvokedWithResult`, and `Navigator.of(context).pop()` logic is preserved character-for-character.

- **SectionHeader**:
  - *Proposed*: Bold Nunito display style for primary, w900 for sub.
  - *Implemented*: Primary variant uses `AppFonts.displayStyle(fontWeight: FontWeight.w800, letterSpacing: 2.5, color: AppColors.wolf)`. Sub variant uses `textTheme.titleMedium.copyWith(fontWeight: FontWeight.w900, color: AppColors.eel)`. Text is auto-uppercased inside `build()` for primary variant (no contract break since callers still pass plain strings).

- **ReadMoreText**:
  - *Proposed*: FeatherGreen link color with bold Nunito weight.
  - *Implemented*: Toggle link uses `AppColors.featherGreen` and `FontWeight.w800`. Vertical gap between text and toggle increased to 4px for improved tap target.

## Verification Handoff
QA should manually check on the device:
1. Navigate to any list page — confirm `RoleBadge` renders colored pill chips instead of plain containers.
2. Open a submission detail page — confirm `CompactStatusPanel` has a flat 2px Swan border (StrokeCard).
3. Filter any list — confirm `WarmChip` animates to green fill on select and flat Swan border on deselect.
4. Trigger back-navigation on a dirty form — confirm `UnsavedChangesGuard` shows a round-cornered `BubblyDialog` (not a system dialog).
5. Verify `ScoreAvatar` shows green/yellow/red circles based on score range.

<test_trace>
01:01 +575: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: TC-F1-01: AC_429_ReturnsRetryScheduled_NoDelay
01:05 +576: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: (tearDownAll)
01:05 +576: All tests passed!

Exit code: 0
</test_trace>

<forensic_evidence>
Analyzing Checkly...
No issues found! (ran in 80.4s)
Exit code: 0
</forensic_evidence>

## Gotcha Protocol
Proposed additions to `lib/GEMINI.md`:
- **Gotcha 29: CompactStatusPanel Divider Color**: The divider was previously calculated at runtime as `AppTheme.sageGray.withValues(alpha:0.15)`. It is now `AppColors.swan` (a const). Do not re-introduce alpha-computed dividers — use Swan directly.
- **Gotcha 30: SectionHeader Auto-Uppercase**: The primary `SectionHeader` variant now auto-uppercases the text inside `build()`. Callers must pass plain text (not already-uppercased strings) to avoid double-uppercase on screens.
