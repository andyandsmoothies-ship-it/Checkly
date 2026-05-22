<latent_space_scratchpad>
## Latent Space Scratchpad & Constraints

### Constraints from input documents
- **Backward Compatibility**: All 9 existing call sites of `ChecklyEmptyState` use only `icon`. To prevent any breaking changes, `emoji` must be an optional nullable `String?` parameter that defaults to `null`.
- **Mascot Emoji visual style**: When `emoji` is provided, it must replace the icon container, rendering as a large `Text` widget with `fontSize: 56`.
- **No package bloat**: Render using native `Text` widget only. No external emoji packages or Lottie animations.

### Edge cases & states
- **State: emoji is null**
  - Expected: Show standard `Container` with the `Icon`. Matches current baseline exactly.
- **State: emoji is empty string ('')**
  - Expected: Should theoretically still render a `Text` widget, but to be robust, we treat `emoji != null && emoji.isNotEmpty` as the condition, or simply trust that non-null means valid. Let's do `emoji != null` which is standard and safe.
- **State: Multi-character emoji / custom glyphs**
  - Supported natively by Flutter's standard `Text` widget, rendering standard Unicode characters perfectly.
</latent_space_scratchpad>

## Input Lineage
- **Source Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260522_134514_ds03_spirit_epic.md`

---

## Executive Summary & Out of Scope

This implementation plan covers **Sub-Slice C (Mascot: ChecklyEmptyState)** of the "Spirit of Duolingo" Epic. The goal is to add support for mascot emojis (e.g. 🎉, 🎯, 🦉) inside our standardized empty state widget, giving screens the ability to display a friendly, gamified visual mascot instead of a dry, generic system icon.

### Scope:
- ✅ Add an optional `String? emoji` property to `ChecklyEmptyState`.
- ✅ Update the widget structure inside `checkly_empty_state.dart` to conditionally render the emoji `Text` widget (fontSize: 56) instead of the default icon circle container when `emoji` is not null.
- ✅ Write widget tests covering both default and emoji empty state pathways.

### Out of Scope:
- ❌ Modifying visual or structural layouts of any other pages or widgets.
- ❌ Modifying the 9 existing call sites to inject emojis (this is Sub-Slice D).
- ❌ Adding animation packages or sound.

---

## Risk Assessment
- **Risk Evaluation**: Very low risk.
- **Architectural Cost**: Zero.
- **Blast Radius**: O(1). Only affects the isolated presentation widget `ChecklyEmptyState`.
- **ROI**: High. Enables gamified reskin of empty screens gracefully with backwards compatibility.

---

## System Context
- **Runtime Environment**: Offline-first client-side Flutter application.
- **Permissions / RBAC**: None. ChecklyEmptyState is a visual Primitive widget.
- **APIs / Network**: Offline only. No backend dependencies.

---

## Lifecycle Context

Visual state lifecycle for `ChecklyEmptyState`:
| Condition | Widget Tree Impact | Expected Visuals |
|:---|:---|:---|
| `emoji == null` (Default) | Render default circular icon container | Classic icon (e.g. `Icons.inbox_outlined`) inside a circular green/sea-sponge border. |
| `emoji != null` (Mascot) | Hide default icon container, render emoji Text | Large centered emoji character (fontSize 56) acting as a visual mascot. |

---

## Constraint Traceability

| Constraint ID | Constraint Description | Test Contract ID |
|:---|:---|:---|
| **C-ES-01** | Add optional nullable `String? emoji` parameter to constructor | TC-ES-01 |
| **C-ES-02** | Hide default icon circle container when emoji is provided | TC-ES-02 |
| **C-ES-03** | Render large emoji (fontSize 56) when emoji is provided | TC-ES-03 |
| **C-ES-04** | Keep default icon circle container when emoji is null (backward compatible) | TC-ES-04 |

---

## Test Contracts

| Test ID | Scenario | Expected Behavior | Verification Method |
|:---|:---|:---|:---|
| **TC-ES-01** | Instantiate ChecklyEmptyState without emoji | Widget compiles, default icon container is rendered, title/subtitle display. | Widget test `ES-01` |
| **TC-ES-02** | Instantiate ChecklyEmptyState with emoji | Default icon container is completely omitted from the tree. | Widget test `ES-02` |
| **TC-ES-03** | Visual verification of emoji size | Emoji rendered at standard size (56.0). | Code review / widget tree inspection |
| **TC-ES-04** | Run all widget tests | No errors or test regressions across the primitives suite. | `rtk flutter test test/widgets/primitives_test.dart` |

---

## Test Fixture & Payloads
No backend seed data or JSON payloads required. The change is isolated to standard Flutter client code.

---

## Tools & Commands
- **Skills**: basic Flutter/Dart knowledge.
- **Test / Verify Command**:
  `rtk flutter test test/widgets/primitives_test.dart` (Must pass all tests including the new EmptyState group).

---

## Proposed Changes

### 1. Common Widgets Layer

#### `[MOD]` [checkly_empty_state.dart](file:///C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/widgets/checkly_empty_state.dart)
- Add `final String? emoji;` field.
- Update constructor parameters to accept `this.emoji` optionally.
- Refactor the icon container in the `build` method to conditionally render the emoji `Text` widget instead:
```dart
              if (emoji != null)
                Text(
                  emoji!,
                  style: const TextStyle(fontSize: 56),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.seaSponge,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.turtle, width: 2),
                  ),
                  child: Icon(icon, size: 36, color: AppColors.featherGreen),
                ),
```

### 2. Test Layer

#### `[MOD]` [primitives_test.dart](file:///C:/Users/HP/Documents/GitHub/Checkly/test/widgets/primitives_test.dart)
- Add `import 'package:checkly/_shared/widgets/checkly_empty_state.dart';`
- Add a new test group `ChecklyEmptyState Widget Tests` containing:
  - Test `ES-01`: Verify standard layout displays title, subtitle, and default icon container.
  - Test `ES-02`: Verify providing `emoji` hides the icon and displays the mascot emoji correctly.

---

## Concept Diagram

```text
ChecklyEmptyState.build()
          │
          ▼
   [emoji != null?]
          │
          ├──► Yes ──► Render: Text(emoji, fontSize: 56) (Mascot)
          │
          └──► No  ──► Render: Container(icon circle) (Backward compat)
```

---

## Execution Slices

### Execution Phase: Mascot Empty State
- **Plain English Summary**: Modify the standard empty state widget to optionally accept an emoji character. If provided, render that emoji as a large visual icon instead of the default circular icon. Add robust widget tests in the primitives suite to verify both visual paths.
- **Value Delivered**: Provides the UI infrastructure needed to inject a friendly mascot and warm tone into empty dashboard/listing screens, supporting the personality dimension of the Duolingo reskin.
- **Complexity**: Low. Isolated property and condition addition.
- **Entry State Required**: Visual reskin complete, standard `ChecklyEmptyState` exists as a stateless widget.
- **Exit State Guaranteed**: `ChecklyEmptyState` compiles cleanly, displays the large emoji when specified, falls back to default icon circle when null, and passes all widget tests.
- **Scope**: `lib/_shared/widgets/checkly_empty_state.dart` `[MOD]`, `test/widgets/primitives_test.dart` `[MOD]`
- **Acceptance Criteria**:
  - `String? emoji` added cleanly to the widget fields. ✅
  - Large mascot emoji displayed (fontSize 56) when `emoji != null`. ✅
  - Standard icon container hidden when `emoji != null`. ✅
  - Standard icon container remains visible when `emoji == null`. ✅
  - Widget tests verify both conditions. ✅
  - All widget tests pass successfully with 0 errors. ✅

---

## Verification Plan
### Automated Tests
- Run `rtk flutter test test/widgets/primitives_test.dart` to verify that both standard empty states and emoji empty states function as expected.

---

<command_logs>
- Ran `rtk flutter analyze` (Clean).
- Viewed `lib/_shared/widgets/checkly_empty_state.dart`.
- Viewed `test/widgets/primitives_test.dart`.
</command_logs>

---

## Handoff Block

**Next Steps for Builder:**
Execute **Execution Phase (Sub-Slice C)**.
1. In `lib/_shared/widgets/checkly_empty_state.dart`, add the optional field `final String? emoji;` and configure it in the constructor.
2. In the `build` method, conditionally render `Text(emoji!, style: const TextStyle(fontSize: 56))` when `emoji != null`.
3. In `test/widgets/primitives_test.dart`, import `checkly_empty_state.dart`.
4. Add the `ChecklyEmptyState Widget Tests` group at the end of `main()`.
5. Verify changes by running `rtk flutter test test/widgets/primitives_test.dart`.

Absolute plan file path:
`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\implementation_plan_20260522_141000_ds06_empty_state_emoji.md`
