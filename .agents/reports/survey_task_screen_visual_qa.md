# Visual QA Report: Survey Task Screen

**Date**: 2026-05-23
**Module**: Audit / Survey Execution Flow
**Scope**: Expanded Section Card, Collapsed Section Card, Score HUD, and Jump to Section Sheet.

## Phase 2: Visual Inspection Findings

### 1. WCAG AA Contrast Failures
- **Jump to Section Sheet ("N / N done" text)**: 
  - *Observation*: The bright lime green text (`AppTheme.success`) indicating a completed section on the off-white background is extremely low contrast. 
  - *Violation*: Fails WCAG 2.1 AA requirement for regular text (4.5:1 ratio). It is visually harsh and hard to read for accessibility users.

### 2. Layout & Aesthetic Violations
- **Section Card Border Clipping (Expanded State)**:
  - *Observation*: In the expanded state ("Opening Tasks"), the bottom border of the card abruptly flattens out, completely losing its rounded radius and dropping the bottom margin visual.
  - *Violation*: Lack of `clipBehavior: Clip.antiAlias` on the `Card`, combined with standard `ExpansionTile` rendering dividers, causes a broken "cut-off" aesthetic at the bottom edge.
- **Score HUD Container (Survey Mode)**:
  - *Observation*: When operating as a Survey (No Score), the top container defaults to a pale grey (`onSurfaceVariant` / `withAlpha(15)`). The "Live Score" label above "Survey — No Score" creates a confusing visual hierarchy, and the container looks washed out and generic.
  - *Violation*: Poor information architecture. "Live Score" label is irrelevant in a Survey. The grey padding feels claustrophobic without dynamic content.

## Phase 3: Diagnostic Code Mapping

| Visual Element | File Path | Root Cause / Required Fix |
|---|---|---|
| **Expanded Card Border** | `lib/features/audit/widgets/audit_section_card.dart` | The outer `Card` is missing `clipBehavior: Clip.antiAlias`. Additionally, `ExpansionTile` needs `shape: const RoundedRectangleBorder(side: BorderSide.none)` to prevent standard divider lines from bleeding through. |
| **Survey Score HUD** | `lib/features/audit/widgets/audit_score_hud.dart` | The `AuditScoreHud` conditionally renders "Survey — No Score" inside a generic grey box. Needs a dedicated, styled state for surveys (e.g., hiding "Live Score" label, improving typography alignment, or using a distinct "Survey Mode" chip/gradient instead of the hollow grey box). |
| **"X / Y done" Contrast** | `lib/features/audit/widgets/audit_quick_jump_sheet.dart` | In `ListTile`'s trailing text, `isComplete ? AppTheme.success : ...` is used directly for text color. It must be darkened (e.g., a dark green from the color scheme, or a bold high-contrast font weight) to satisfy WCAG AA. |
| **App-wide Card Border Clipping** | `lib/_shared/widgets/primitives/stroke_card.dart` | The `StrokeCard` primitive falls back to a default `Card` with `Clip.none` if an `onTap` callback is not provided. This causes the exact same border clipping issue anywhere this primitive wraps expanding content (e.g., the Template Builder's `SectionEditor`). Needs `clipBehavior: Clip.antiAlias` applied universally. |

## Remediation Plan
1. Update `AuditSectionCard` to strictly clip its children and nullify standard ExpansionTile borders.
2. Refactor `AuditScoreHud` to render a cleaner, distinct "Survey Mode" layout without the redundant "Live Score" sub-text.
3. Update `AuditQuickJumpSheet` to use a WCAG-compliant dark green or standard typography for the "done" text, preserving `AppTheme.success` only for background/icon accents.
4. Update `StrokeCard` (`lib/_shared/widgets/primitives/stroke_card.dart`) to apply `clipBehavior: Clip.antiAlias` unconditionally, ensuring nested contents (like Template Builder sections) never clip through rounded corners.
