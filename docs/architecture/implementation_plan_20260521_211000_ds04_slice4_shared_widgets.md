<latent_space_scratchpad>
## Latent Space Scratchpad - Slice 4 (Shared Widgets Reskin)

### Problem Framing & Core Goal
The core goal of Slice 4 is to refactor 10 key shared widgets in `lib/_shared/widgets/` to adopt a vibrant, gamified, tactile aesthetic inspired by Duolingo. We must do this while maintaining exact API contracts, avoiding database or API shifts, and preserving the functional guard components:
- `action_guard.dart` (PBAC wrapper - MUST NOT modify)
- `permission_guard.dart` (Role-based logic wrapper - MUST NOT modify)
- `unsaved_changes_guard.dart` (PopScope navigation gate - refactor ONLY the visual dialog part, preserve navigation logic exactly!)

### Edge Cases & Critical Risks
1. **Security Guard Disruption**: If `ActionGuard` or `PermissionGuard` is accidentally modified or visually stripped, it could compromise access controls.
   *Mitigation*: Explicitly document them as out-of-scope and verify zero edits to these files.
2. **Text Overflow in Gamified Primitives**: Card elements like `StatBlock` or `WarmChip` are compact. If font weights increase to Nunito Bold w800/w900, text may overflow.
   *Mitigation*: Enforce `overflow: TextOverflow.ellipsis` and clean padding values.
3. **Score Color Mapping**: `ScoreAvatar` must clearly convey quality via color codes (green = high, yellow = medium, red = low) without causing accessibility/contrast issues.
   *Mitigation*: Use high-contrast brand accents for the text matching the pastel backgrounds (e.g., const Color(0xFF388E3C) on Sea Sponge, Fox on Canary, and Cardinal on Walking Fish).

### Constraint Mapping
- Max file size: 400 lines (Checked: All modified files are under 150 lines).
- No new dependencies: We only rely on existing packages (`google_fonts` and the core `flutter/material.dart`).
- Existing primitive leverage: We must use `StrokeCard`, `PillChip`, and `BubblyDialog` from Slices 2 and 3.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260521_202100_ds01_duolingo_reskin.md`

---

## Executive Summary & Out of Scope

This implementation plan covers **Slice 4 (Shared Widget Reskin)** of the Duolingo gamified reskin epic. It details the visual transformation of Checkly's 10 shared UI widgets. By leveraging the color constants in `AppColors` and custom primitives (`StrokeCard`, `PillChip`, `BubblyDialog`), these shared widgets will instantly update the entire app's look wherever they are used.

### In Scope
- Refactoring 10 existing shared widgets in `lib/_shared/widgets/` to use gamified themes.
- Utilizing primitives (`StrokeCard`, `PillChip`, `BubblyDialog`) and vibrant brand colors.
- Migrating text elements to Nunito typography.

### Out of Scope
- **NO** changes to database schema, EF Core mapping, or APIs.
- **NO** edits to security guards: `action_guard.dart` and `permission_guard.dart`.
- **NO** logic changes to navigation state or form flags.
- **NO** new screens or behavioral capabilities.

---

## System Context
- **Offline-first Architecture**: No network changes or sync queries. All styling is fully local.
- **PBAC & RBAC Guards**: Keep `ActionGuard` and `PermissionGuard` completely untouched to protect authorization boundaries.
- **Logging & Diagnostics**: Keep debug logs unaltered.

---

## Lifecycle Context
- **Empty State**: `ChecklyEmptyState` is redesigned with pastels (`AppColors.polar`) and clean borders.
- **Validation Alerts**: Discard confirmation in `UnsavedChangesGuard` is migrated to the high-contrast `BubblyDialog`.
- **Status Indicators**: Score avatars use a three-tier semantic color coding for fast comprehension.

---

## Constraint Traceability

| Constraint ID | Epic Requirement | Implementation Plan Mapping | Test Contract Mapping |
|:---|:---|:---|:---|
| **C-SW-01** | Preserved `ActionGuard` | Left `action_guard.dart` unchanged | TC-SW-GUARD-01 |
| **C-SW-02** | Preserved `PermissionGuard` | Left `permission_guard.dart` unchanged | TC-SW-GUARD-02 |
| **C-SW-03** | Use of `PillChip` | `RoleBadge` refactored to use `PillChip` | TC-SW-BADGE-01 |
| **C-SW-04** | Use of `StrokeCard` | `CompactStatusPanel` uses `StrokeCard` | TC-SW-PANEL-01 |
| **C-SW-05** | Nunito Typography | All widgets mapped to Nunito Display & Serif text styles | TC-SW-TEXT-01 |
| **C-SW-06** | File Size Limits | All files kept under 400 lines | TC-SW-HYGIENE-01 |

---

## Test Contracts

| Test ID | Scenario | Given / When / Then | Why it fails first |
|:---|:---|:---|:---|
| **TC-SW-GUARD-01** | Preserve ActionGuard | **Given** ActionGuard is referenced in features;<br>**When** Slice 4 build is run;<br>**Then** ActionGuard logic remains active and unchanged. | Compiler fails if file is modified or removed. |
| **TC-SW-BADGE-01** | PillChip role badge mapping | **Given** a user role is passed to `RoleBadge`;<br>**When** rendered in the UI;<br>**Then** it returns the corresponding themed `PillChip` widget. | Badge still renders legacy container styling instead of primitive. |
| **TC-SW-PANEL-01** | StrokeCard KPI panel wrap | **Given** KPI rows are passed to `CompactStatusPanel`;<br>**When** rendered;<br>**Then** the outer wrap is a flat `StrokeCard` with 2px borders. | Panel uses standard default Material 3 Card. |
| **TC-SW-AVATAR-01** | Gamified ScoreAvatar color | **Given** a score integer is passed to `ScoreAvatar`;<br>**When** score >= 80;<br>**Then** it displays with green SeaSponge tint and Turtle borders. | Avatar displays single standard primary tint regardless of score. |
| **TC-SW-GUARD-03** | Gamified UnsavedChanges confirmation | **Given** UnsavedChangesGuard intercepts back-nav;<br>**When** dialog is requested;<br>**Then** it renders using a `BubblyDialog` container. | Dialog renders standard system AlertDialog. |

---

## Test Fixture & Payloads
Since this is a visual reskin slice, no API payloads or DB schemas are required. We rely on the existing integration and unit test suite to verify compilation and functional integrity:
- Command: `cmd /c rtk flutter test`
- Verification: Clean analyzer run with 0 issues.

---

## Tools & Commands
- **Framework**: Flutter SDK / Dart compiler.
- **Verification tool**: `flutter analyze`.

---

## Proposed Changes

### Modified Files (`[MOD]`)

| Component / File Path | Truncation Limit | Overflow Action | Required New Route / Primitive used |
|:---|:---|:---|:---|
| `lib/_shared/widgets/role_badge.dart` | Single Line | Ellipsis | `PillChip` |
| `lib/_shared/widgets/compact_status_panel.dart` | Single Line | Ellipsis | `StrokeCard` |
| `lib/_shared/widgets/checkly_empty_state.dart` | Auto-wrap | Wrap | `AppColors.polar`, Nunito text |
| `lib/_shared/widgets/checkly_fab.dart` | N/A | Flat Menu | Custom bubbly button and popup styling |
| `lib/_shared/widgets/score_avatar.dart` | Single Line | Fixed font | Gamified pastel colors + borders |
| `lib/_shared/widgets/section_header.dart` | Auto-wrap | Wrap | Bold Nunito displaying |
| `lib/_shared/widgets/stat_block.dart` | Single Line | Ellipsis | `StrokeCard` container look |
| `lib/_shared/widgets/unsaved_changes_guard.dart` | Auto-wrap | Wrap | `BubblyDialog` |
| `lib/_shared/widgets/warm_chip.dart` | Single Line | Wrap | Bubbly selected/unselected chip look |
| `lib/_shared/widgets/read_more_text.dart` | Multi-line | Ellipsis | Nunito bold links |

### Unchanged Files (Protected)
- `lib/_shared/widgets/action_guard.dart`
- `lib/_shared/widgets/permission_guard.dart`

---

## Concept Diagram

```
[Shared UI Page]
       │
       ├─► [RoleBadge] ─────────► [PillChip (Green/Blue/Yellow/Purple)]
       ├─► [ScoreAvatar] ───────► [Gamified Tiered Pastel Circle + Border]
       ├─► [StatBlock] ─────────► [Flat 2px Outline Container]
       ├─► [WarmChip] ──────────► [Bubbly Selected Tab vs Flat Bordered Unselected]
       ├─► [CompactStatusPanel] ► [StrokeCard Wrap + Swan Dividers]
       └─► [UnsavedChanges] ────► [BubblyDialog Confirms Action]
```

---

## Execution Slices

### Execution Phase: Refactoring Shared Widgets

*   **Complexity**: Medium.
*   **Plain English Summary**: Update the 10 visual shared widgets in `lib/_shared/widgets/` to use new gamified primitives and color tokens while keeping security guards completely untouched.
*   **Value Delivered**: The entire app gains consistent gamified styling immediately since these widgets are reused globally on every screen.
*   **Entry State**: Primitives (`StrokeCard`, `PillChip`, `BubblyDialog`) are available.
*   **Exit State**: All 10 widgets compile correctly and pass the visual/functional checks.
*   **Pros & Cons**:
    *   *Pro*: One unified sweep updates styling globally across 37 screens at once.
    *   *Con*: High layout/regression testing area. Must ensure no text overflows or hidden buttons.

#### Acceptance Criteria
1. `RoleBadge` translates Admin to Purple PillChip, Auditor to Blue PillChip, Store Mgr to Yellow PillChip, and Area Mgr to Green PillChip.
2. `ChecklyEmptyState` displays with `AppColors.polar` background and bold Nunito labels.
3. `CompactStatusPanel` uses `StrokeCard` and Swan dividers.
4. `ScoreAvatar` shows Green/Yellow/Red colors corresponding to score ranges.
5. `UnsavedChangesGuard` triggers a `BubblyDialog` modal.
6. `flutter analyze` returns 0 issues.

---

<command_logs>
- `cmd /c rtk flutter test` -> Confirmed all 576 existing tests pass perfectly.
</command_logs>

## Handoff Block
- **Execution Plan**: Proceed with the Shared Widget Reskin step-by-step.
- **Sequence**:
  1. Build & refactor `role_badge.dart` to use `PillChip`.
  2. Refactor `compact_status_panel.dart` to use `StrokeCard`.
  3. Refactor `checkly_empty_state.dart` with pastel background and Nunito text.
  4. Refactor `score_avatar.dart` to support tiered gamified colors.
  5. Refactor `stat_block.dart` to adopt flat Swan borders.
  6. Refactor `warm_chip.dart` for tab-style selected states.
  7. Refactor `checkly_fab.dart` to show a custom bubbly FAB button.
  8. Refactor `unsaved_changes_guard.dart` to display `BubblyDialog`.
  9. Refactor `read_more_text.dart` and `section_header.dart` for typography compliance.
  10. Run verification with `flutter analyze` and `flutter test`.

---

## Risk Assessment
- **Visual Regression**: Modifying 10 widgets changes multiple screens at once. Layout issues (text truncation, clipping) could happen.
  *Mitigation*: Ensure responsive sizing, proper ellipsis on text widgets, and test layouts across diverse viewports.
- **Guard Component Disruption**: Modifying logic inside navigation or action guards could break security or cause state drift.
  *Mitigation*: Absolutely zero changes allowed to `action_guard.dart` and `permission_guard.dart`. Refactor only the visual modal part of `unsaved_changes_guard.dart` while preserving PopScope mechanics exactly.

---

## Verification Plan
### Automated Tests
- Command: `cmd /c rtk flutter test`
- Verification: Verify all 576 existing tests continue to pass with zero failures.

### Static Analysis
- Command: `cmd /c flutter analyze`
- Verification: Verify zero analyzer warning/error reports.

---

Plan Location: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260521_211000_ds04_slice4_shared_widgets.md`
