<!--
<latent_space_scratchpad>
CONSTRAINTS FROM INPUT:
- "Multiple build methods exceed the 150-line critical threshold (up to 305 lines)"
- Critical threshold is 150 lines per build method per GEMINI.md rules
- Max file size is 400 lines total
- Decompose build methods only — do NOT break public API, do NOT rename classes
- Use Dart private helper methods (_buildXxx) within same class to keep the `part` relationship intact

OFFENDERS RANKED (by build method size):
1. criterion_editor_drawer.dart   — 305-line build (single class, no parts file)
2. advanced_settings_card.dart    — 264-line build (single class, no parts file)
3. template_card.dart             — 237-line build (single class, no parts file)
4. criterion_editor.dart          — 167-line build (single class)
5. wizard_step_structure.dart     — 161-line build (single class)
6. review_section_breakdown.dart  — 158-line build (single class)

STRATEGY: Use private helper methods inside same file. No part files needed since these are single-class files.
- For criterion_editor_drawer: extract `_buildInputTypeSelector`, `_buildPointsSection`, `_buildPenaltySection`, `_buildTogglesSection` (each ~50-70 lines)
- For advanced_settings_card: extract `_buildSchedulingGroup`, `_buildScoringGroup`, `_buildSurveyBanner`, `_buildWarningBanner`
- For template_card: extract `_buildIcon`, `_buildContent`, `_buildContextMenu`  
- For criterion_editor: extract `_buildMainRow`, `_buildErrorMessages`
- For wizard_step_structure: extract `_buildEmptyState`, `_buildSectionsList`, `_buildSuggestions`, `_buildTipBanner`
- For review_section_breakdown: extract `_buildSectionCard`, `_buildCriteriaList`, `_buildSubSections`

IMPACT:
- 0 database changes. 0 API changes. 0 routes changes.
- Only these 6 files change. Each file changes internally only.
- Existing tests: advanced_settings_card_test.dart, section_editor_scoring_test.dart must still pass.
- Blast radius: Very low.

SLICING STRATEGY (Maximum Thickness):
- Group by complexity: Files 1-3 (heaviest, 3+ sub-extractions each) = Slice 1
- Files 4-6 (lighter, 2 sub-extractions each) = Slice 2
- Both slices are Route 1 (Direct Build, no new logic)
</latent_space_scratchpad>
-->

## Input Lineage
- **Source Input**: `lib/features/templates/widgets/` (6 files with oversized build methods)

## Executive Summary & Out of Scope

Six template widget `build()` methods exceed the 150-line critical threshold (worst: 305 lines). These monolithic `build()` methods mix layout, conditional logic, and event handlers in a single function body that is impossible to read, review, and test.

The plan decomposes each oversized `build()` into focused private helper methods (`_buildXxx`) **inside the same file**. This is a pure structural refactoring — no logic changes, no public API changes, no route changes.

### Offenders (ranked)
| File | Build Lines | Action |
|---|---|---|
| `criterion_editor_drawer.dart` | **305** | Extract 4 helpers |
| `advanced_settings_card.dart` | **264** | Extract 4 helpers |
| `template_card.dart` | **237** | Extract 3 helpers |
| `criterion_editor.dart` | **167** | Extract 2 helpers |
| `wizard_step_structure.dart` | **161** | Extract 3 helpers |
| `review_section_breakdown.dart` | **158** | Extract 2 helpers |

### Out of Scope
- Renaming classes, changing public widget API, or adding new fields.
- Moving classes into new files or part files.
- Changing any business logic, state math, or conditional rules.
- Touching any page files (`template_builder_page.dart`, `template_wizard_page.dart`, etc.).

---

## System Context
- **Environment**: Flutter/Dart, offline-first, no network calls in these widgets.
- **RBAC**: `template_card.dart` reads `PolicyManager` for canEdit/canDelete. This logic stays exactly as-is inside the extracted `_buildContextMenu` helper.
- **No backend impact**: Pure UI structural refactoring.

## Lifecycle Context
These are stateless or stateful UI-only widgets. No Loading/Error/Empty/Success states change.

---

## Constraint Traceability
| Constraint | Source | Test Contract ID |
|---|---|---|
| Build methods must not exceed 150 lines | GEMINI.md file rule | TC-BUILD-01 |
| Existing tests must not break | GEMINI.md testing rules | TC-REGRESSION-01 |
| No public API changes | Out of Scope rule | TC-API-01 |
| No logic changes (pure structural move) | Out of Scope rule | TC-LOGIC-01 |

---

## Test Contracts
| ID | Exact Text | Why It Fails First |
|---|---|---|
| **TC-BUILD-01** | After refactoring, all 6 files have `build()` methods under 150 lines as confirmed by the scan script | Script would report `<<< OVER 150` |
| **TC-REGRESSION-01** | `rtk flutter test test/features/templates/` passes with no failures | Widget API changed or logic accidentally modified |
| **TC-API-01** | No public constructor signatures, parameter names, or return types change | Compiler error in callers |
| **TC-LOGIC-01** | All conditional logic (scoringMode gates, inputType guards, RBAC checks) remain identical — only moved into a private method | Visual regressions or logic gaps |

---

## Test Fixture & Payloads
- **Baseline test (confirmed passing)**: `rtk flutter test test/features/templates/widgets/advanced_settings_card_test.dart test/features/templates/section_editor_scoring_test.dart` → ✅ 14 tests passed
- **No seeded data required**: purely structural widget refactoring.

---

## Tools & Commands
- **Skills**: None required (pure structural refactoring).
- **Build Scan Command**: `cmd /c python .agents/tmp/scan_build_methods.py`
- **Regression Test Command**: `rtk flutter test test/features/templates/`

---

## Proposed Changes
| Action | File | Description |
|---|---|---|
| **MOD** | `lib/features/templates/widgets/criterion_editor_drawer.dart` | Extract `_buildInputTypeSection`, `_buildPointsSection`, `_buildPenaltySection`, `_buildTogglesSection` |
| **MOD** | `lib/features/templates/widgets/advanced_settings_card.dart` | Extract `_buildSchedulingGroup`, `_buildScoringToggles`, `_buildSurveyBanner`, `_buildWarningBanner` |
| **MOD** | `lib/features/templates/widgets/template_card.dart` | Extract `_buildIcon`, `_buildContent`, `_buildContextMenu` |
| **MOD** | `lib/features/templates/widgets/criterion_editor.dart` | Extract `_buildMainRow`, `_buildErrorMessages` |
| **MOD** | `lib/features/templates/widgets/wizard_step_structure.dart` | Extract `_buildEmptyState`, `_buildSectionsList`, `_buildSuggestionsBlock` |
| **MOD** | `lib/features/templates/widgets/review_section_breakdown.dart` | Extract `_buildSectionCard`, `_buildSubSectionsList` |

---

## Concept Diagram
```text
BEFORE:
[CriterionEditorDrawer.build()] ──── 305 lines ──── Everything mixed together
                                                         (header + fields + type selector +
                                                          points + penalty + toggles)

AFTER:
[CriterionEditorDrawer.build()]  ──── ~40 lines  ──── Scaffold only
    │── _buildInputTypeSection() ──── ~60 lines  ──── type chip + bottom sheet callback
    │── _buildPointsSection()    ──── ~60 lines  ──── conditional points logic
    │── _buildPenaltySection()   ──── ~40 lines  ──── penalty row fields
    └── _buildTogglesSection()   ──── ~60 lines  ──── CCP/Risk/Required toggles
```

---

## Execution Slices

### Slice 1: Heaviest Three Files (Drawer + Settings + Card)
- **Complexity**: Low — structural move of existing code only.
- **Value Delivered**: Reduces the worst offenders (305, 264, 237 lines) to under 80 lines each.
- **Entry State**: `criterion_editor_drawer.dart`, `advanced_settings_card.dart`, `template_card.dart` with monolithic build methods.
- **Exit State**: All 3 files have `build()` under 80 lines with private helper methods. Scan script shows no `<<< OVER 150` for these files. All regression tests pass.
- **Scope**: Only these 3 files. No logic changes.
- **Acceptance Criteria**:
  1. `build()` in all 3 files is under 80 lines after refactoring.
  2. `rtk flutter test test/features/templates/` shows no new failures.
  3. Scan script reports no `<<< OVER 150` for the 3 files.

**Pros**: Smallest change batch, easiest review.
**Cons**: Still leaves 3 files unresolved until Slice 2.

---

### Slice 2: Remaining Three Files (CriterionEditor + WizardStructure + ReviewBreakdown)
- **Complexity**: Low — same pattern as Slice 1.
- **Value Delivered**: All 6 files are now compliant with the 150-line rule.
- **Entry State**: Slice 1 complete. 3 remaining files have build methods of 167, 161, and 158 lines.
- **Exit State**: All 6 template widget files have `build()` under 150 lines. Scan script shows green for all.
- **Scope**: `criterion_editor.dart`, `wizard_step_structure.dart`, `review_section_breakdown.dart`.
- **Acceptance Criteria**:
  1. `build()` in all 3 files is under 120 lines.
  2. `rtk flutter test test/features/templates/` passes with no regressions.
  3. Scan script confirms zero `<<< OVER 150` entries across the entire `templates/widgets/` directory.

---

## Risk Assessment
- **Risk Level**: Very Low.
- **Blast Radius**: Purely internal to these 6 widget files. No callers are touched. No public interface changes.
- **Mitigation**: Run scan script before and after each slice to confirm size compliance; run full template test suite to confirm no regressions.

---

## Verification Plan
After each slice, run:
```bash
cmd /c python .agents/tmp/scan_build_methods.py
rtk flutter test test/features/templates/
```
Both must pass before moving to next slice.

---

<command_logs>
- `cmd /c python .agents/tmp/scan_build_methods.py` — identified 6 offending files
- `rtk flutter test test/features/templates/widgets/advanced_settings_card_test.dart test/features/templates/section_editor_scoring_test.dart` — ✅ 14 tests passed (baseline)
</command_logs>

---

## Handoff Block
- **Slice 1**: Plan → **Direct Build** (no tests needed before coding). Files: `criterion_editor_drawer.dart`, `advanced_settings_card.dart`, `template_card.dart`.
- **Slice 2**: Slice 1 must complete first → **Direct Build**. Files: `criterion_editor.dart`, `wizard_step_structure.dart`, `review_section_breakdown.dart`.
- **Absolute Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260522_161500_twbd1_widget_build_decomposition.md`

Execute slices **ONE AT A TIME**. Do not run both at once.
