<latent_space_scratchpad>
## Full Blast Radius Map

### Source files with scoringMode string (Template Builder scope):

1. metadata_form_card.dart (109L) — Dropdown with 'penalty'/'accumulation'/'checklist'/'survey'
   - props: scoringMode String, onScoringModeChanged
   - helperText switch on scoringMode string
   - Must become: Two Toggles (scoreDirection + isWeighted) + categoryTag field

2. template_builder_page.dart (398L) — State: String _scoringMode = 'penalty'
   - Passes _scoringMode to MetadataFormCard, AdvancedSettingsCard, SectionEditor, LiveScoreSimulator x2
   - Must split into: String _scoreDirection = 'down'; bool _isWeighted = true; String _categoryTag = ''

3. template_builder_page_logic.dart (136L)
   - Line 26: _scoringMode = config['scoringMode'] as String? → must read scoreDirection+isWeighted
   - Line 47: buildScoringLogicConfig(scoringMode: _scoringMode) → must pass new fields

4. template_payload_mapper.dart (133L) — buildScoringLogicConfig()
   - Line 123: 'scoringMode': scoringMode → must write 'scoreDirection' + 'isWeighted'
   - Signature: requires String scoringMode → must change to String scoreDirection, bool isWeighted
   - Also must add categoryTag as top-level field on the API payload (POST/PUT body, not inside scoringLogicConfig)

5. dart_template_linter.dart (200L)
   - Line 95: scoringMode == 'penalty' → must become scoreDirection == 'down' && isWeighted == true
   - Signature: required String scoringMode → must become required String scoreDirection, bool isWeighted
   
6. advanced_settings_card.dart (310L)
   - Line 48-49: _isSurvey = scoringMode == 'survey'; _isChecklist = scoringMode == 'checklist'
   - Line 197: widget.scoringMode != 'accumulation'
   - All 3 string comparisons → must change
   - Existing tests pass scoringMode: 'penalty' etc. → existing tests must not break OR tests updated

## CRITICAL DISCOVERY: categoryTag

The epic says "Add Category Tag mandatory field" to MetadataFormCard.
But what is the categoryTag? A free text field? A dropdown?
Looking at the Drift tables: categoryTags is on CachedGroups and CachedCriteria (as comma-separated strings for criteria grouping). NOT on templates themselves.

The Slice 1 DB migration added category_tag to the templates table (the PostgreSQL table).
The server now expects categoryTag on the template save endpoint.
But the Flutter TemplateManager.saveTemplate() does NOT have a categoryTag parameter.
The server DTO (from Slice 2) expects `categoryTag` as a top-level field.

So the Flutter side needs:
1. A new `_categoryTag` string state in the builder page
2. A text field in MetadataFormCard  
3. saveTemplate() must pass categoryTag to the API

But wait — what does saveTemplate() pass to _api.saveTemplateTree()? Let me check if categoryTag is expected as a top-level body field or inside scoringLogicConfig JSON.

The Slice 1 added category_tag column to templates table. The Slice 2 backend parser reads it as a top-level DTO field. So it's a TOP-LEVEL field on the request body, not inside scoringLogicConfig.

## Deriving the new Two-Toggles UI Design

The epic says: "Replace the scoring mode dropdown with the Two Toggles widget."

Old UI (1 dropdown): penalty / accumulation / checklist / survey

New UI (2 toggles + 1 toggle):
- scoreDirection: "Which way does score go?" → Toggle/Segmented: "Count Down (Start 100%)" vs "Count Up (Start 0%)" vs "No Score (Survey)"
- isWeighted: "Use section weights?" → Switch: ON = weighted (penalty), OFF = flat (checklist/checklist-style)
  - Hidden when scoreDirection = 'none' (no scoring = survey)
  - Mapping: down+true=penalty, down+false=checklist, up=accumulation, none=survey

## What About AdvancedSettingsCard?

AdvancedSettingsCard currently:
- Hides Weighted Density when isChecklist (scoringMode='checklist')
- Hides Progressive Repeat when isChecklist OR scoringMode='accumulation'
- Shows survey banner when isSurvey

After change:
- isChecklist = (scoreDirection == 'down' && !isWeighted)
- isSurvey = (scoreDirection == 'none')
- isAccumulation = (scoreDirection == 'up')
- isNotAccumulation = scoreDirection != 'up'

AdvancedSettingsCard MUST change its string comparisons.
But AdvancedSettingsCard has 3 existing widget tests in advanced_settings_card_test.dart.
Those tests pass scoringMode: 'penalty'. If we change the prop name, tests break.

## Decision: Prop Strategy for AdvancedSettingsCard

Option A: Replace `scoringMode` prop with `scoreDirection + isWeighted`.
- All 3 existing tests FAIL immediately because they use scoringMode: 'penalty'.
- We CANNOT change the tests at same time as the code.
- BUT the existing tests only test 'Require Confirmation' and toggle behavior, not the mode-hiding logic.
- We could KEEP scoringMode prop but add internal derivation. NO — that's wrong abstraction.

Option B: Keep scoringMode String prop for now (deferred).
- AdvancedSettingsCard stays with String scoringMode. The builder page translates: if scoreDirection='down'&&isWeighted → pass 'penalty' etc.
- This is a bridge pattern: builder page derives the legacy string.
- IMPLICATION: AdvancedSettingsCard and SectionEditor keep String scoringMode — no change needed.
- DOWNSIDE: Technically keeping legacy string coupling.

**DECISION: Option B — Translate in builder page. AdvancedSettingsCard and SectionEditor keep String scoringMode.**
This means we don't touch AdvancedSettingsCard or SectionEditor. Zero risk to existing tests.
Builder page computes: String get _legacyScoringMode => ...

## Scope Finalized

Files to CHANGE:
1. metadata_form_card.dart — Remove dropdown, add Two Toggles + categoryTag TextFormField (4 new props, 2 removed)
2. template_builder_page.dart — Split _scoringMode into _scoreDirection + _isWeighted + _categoryTag; add _legacyScoringMode getter; update MetadataFormCard call
3. template_builder_page_logic.dart — Load: read scoreDirection+isWeighted+categoryTag from config; Save: pass new fields
4. template_payload_mapper.dart — buildScoringLogicConfig() writes new keys; add categoryTag param to saveTemplate call chain
5. dart_template_linter.dart — Change scoringMode param to scoreDirection+isWeighted

Files NOT changed (no scope):
- advanced_settings_card.dart (uses String scoringMode — bridge pattern)
- section_editor.dart (uses String scoringMode — bridge pattern)
- wizard_step_*.dart — wizard flow (OUT OF SCOPE)
- live_score_simulator.dart (String scoringMode — bridge)
- Any audit display widgets

## File Size Checks
- metadata_form_card.dart: 109L ✅ (will grow ~20L to ~129L)
- template_builder_page.dart: 398L ⚠️ OVER 250L — must NOT add more lines; refactor MetadataFormCard call only
- template_builder_page_logic.dart: 136L ✅
- template_payload_mapper.dart: 133L ✅
- dart_template_linter.dart: 200L ✅

## Tests

DartTemplateLinter tests exist: template_linter_slice2_test.dart, template_linter_slice3_test.dart
These call DartTemplateLinter.lint(scoringMode: 'penalty', ...).
If we change param name → compile error in tests.
We MUST update test files too.

AdvancedSettingsCard tests: pass scoringMode: 'penalty' → NOT BROKEN if we use bridge pattern.

## Proposed Two-Toggles UI

scoreDirection — SegmentedButton (3 options):
- down = "⬇️ Count Down" (starts at 100%)
- up = "⬆️ Count Up" (starts at 0%)  
- none = "📊 No Score" (survey)

isWeighted — Switch: "Use Section Weights"
- Only shown when scoreDirection != 'none'
- Label: "Weighted sections" ON/OFF

categoryTag — TextFormField: "Category Tag"
- Free text, optional
- Placeholder: 'e.g. Food Safety, Hygiene'
</latent_space_scratchpad>

# Implementation Plan: Scoring Redesign — Slice 4: Template Builder UI

**Created**: 2026-05-30T09:20:25+07:00
**Epic**: SCORING-REDESIGN | **Slice**: 4 of 5
**Status**: PLANNING

---

## Input Lineage

- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Slice 3 Plan**: `...\implementation_plan_20260530_082805_slice3_flutter_core_cdefadc1.md`
- **Entry Dependency**: Slice 3 complete (`parseScoringMode()` reads new JSON keys).

---

## Executive Summary & Out of Scope

**Goal**: Replace the 4-item `scoringMode` dropdown in `MetadataFormCard` with Two Toggles (`scoreDirection` segmented button + `isWeighted` switch) and add a `categoryTag` free-text field. Update the builder page state, linter, and JSON serializer to write the new fields.

```text
OLD: String _scoringMode = 'penalty'
     → Dropdown → 4 items → writes 'scoringMode' JSON key

NEW: String _scoreDirection = 'down'; bool _isWeighted = true; String _categoryTag = ''
     → SegmentedButton (down/up/none) + Switch (isWeighted) + TextField (categoryTag)
     → writes 'scoreDirection' + 'isWeighted' + 'categoryTag' JSON keys
```

**Bridge Pattern** — `AdvancedSettingsCard`, `SectionEditor`, and `LiveScoreSimulator` still receive a `String scoringMode`. The builder page derives it from the new fields via a getter (`_legacyScoringMode`). These widgets are NOT touched. This protects all 3 existing widget tests.

**Out of Scope**:
- `AdvancedSettingsCard` — no change (uses bridge string)
- `SectionEditor` — no change (uses bridge string)
- `wizard_step_*.dart`, `template_wizard_page.dart` — out of scope (separate wizard flow)
- `live_score_simulator.dart` — no change (uses bridge string)
- Renaming `ScoringMode` enum in `lib/_shared/` — already handled by Slice 3
- Audit display widgets — not changed

---

## System Context

| Constraint | Detail |
|---|---|
| Offline-first | Template builder writes JSON blob to server. On load, reads config back from server/cache. |
| Bridge pattern | `_legacyScoringMode` getter translates new fields → legacy string for widgets not yet migrated. |
| categoryTag | Top-level field on the API request body (not inside `scoringLogicConfig` JSON blob). |
| Linter tests | `template_linter_slice2_test.dart` and `template_linter_slice3_test.dart` call `DartTemplateLinter.lint(scoringMode: ...)`. Both must be updated to new signature when linter changes. |
| Builder page size | `template_builder_page.dart` is 398L — already over limit. Do NOT add lines here. Only swap prop calls. |

---

## Lifecycle Context

| State | Behavior |
|---|---|
| **Success** | New template saved with `scoreDirection`, `isWeighted`, `categoryTag` in payload. On reload, fields populated from config JSON. |
| **Error** | `categoryTag` empty when server requires it → linter error surfaces in panel. |
| **Empty** | New template → default: `scoreDirection='down'`, `isWeighted=true`, `categoryTag=''` |
| **Legacy load** | Old template's config has `scoringMode='penalty'` → Slice 3 parser translates → builder reads `scoreDirection='down'`, `isWeighted=true` from mapper. |

---

## Constraint Traceability

| # | Constraint | Test Contract |
|---|---|---|
| C1 | Dropdown replaced by SegmentedButton (down/up/none) | TC-01 |
| C2 | `isWeighted` switch hidden when `scoreDirection='none'` | TC-02 |
| C3 | categoryTag free text field present | TC-03 |
| C4 | Linter `PenaltyModeGroupSum` fires on `down+true` | TC-04 |
| C5 | Linter receives `scoreDirection` + `isWeighted` params | TC-04 |
| C6 | `buildScoringLogicConfig()` writes `scoreDirection` key | TC-05 |
| C7 | `buildScoringLogicConfig()` writes `isWeighted` key | TC-05 |
| C8 | categoryTag passed to server as top-level payload field | TC-06 |
| C9 | On load: `scoreDirection` + `isWeighted` read from config | TC-07 |
| C10 | Bridge: `AdvancedSettingsCard` still receives String | EXISTING TESTS PASS |
| C11 | Bridge: `LiveScoreSimulator` still receives String | EXISTING TESTS PASS |

---

## Test Contracts

### Unit Tests — DartTemplateLinter (update existing calls)

| ID | Description | Inputs | Expected |
|---|---|---|---|
| TC-04 | `PenaltyModeGroupSum` fires on down+true mode | `scoreDirection:'down', isWeighted:true`, weights sum ≠ 100 | `errors` contains `PenaltyModeGroupSum` |
| TC-04b | `PenaltyModeGroupSum` silent on down+false | `scoreDirection:'down', isWeighted:false`, weights sum ≠ 100 | No error (checklist mode) |
| TC-04c | `PenaltyModeGroupSum` silent on up | `scoreDirection:'up'` | No error |

> Note: TC-04 replaces old tests using `scoringMode: 'penalty'`. Same logic, new param names.

### Unit Tests — TemplatePayloadMapper

| ID | Description | Expected JSON key |
|---|---|---|
| TC-05 | `buildScoringLogicConfig(scoreDirection:'down', isWeighted:true)` | JSON has `scoreDirection:'down'`, `isWeighted:true`. NOT `scoringMode`. |
| TC-05b | `buildScoringLogicConfig(scoreDirection:'none', isWeighted:false)` | JSON has `scoreDirection:'none'`, `isWeighted:false` |

### Widget Tests — MetadataFormCard (new tests)

| ID | Description | Expected |
|---|---|---|
| TC-01 | Renders SegmentedButton not DropdownButtonFormField | `find.byType(SegmentedButton)` — finds one |
| TC-02 | isWeighted switch hidden when none selected | Select 'none' → `find.text('Use Section Weights')` not found |
| TC-03 | categoryTag field renders | `find.widgetWithText(TextFormField, 'Category Tag')` — finds one |

### No-Regression Constraint

> `advanced_settings_card_test.dart` (3 tests, 116L) — must remain GREEN without modification.
> These tests pass `scoringMode: 'penalty'` to `AdvancedSettingsCard`. Since we use the bridge pattern, the widget's API is unchanged.

---

## Tools & Commands

```bash
# Targeted unit tests
rtk flutter test test/features/templates/

# Full suite regression
rtk flutter test
```

---

## Proposed Changes (build order)

| # | Action | File | Lines | Notes |
|---|---|---|---|---|
| 1 | [MOD] | `lib/features/templates/utils/template_payload_mapper.dart` | ~10 | Change `buildScoringLogicConfig()` signature: replace `String scoringMode` with `String scoreDirection, bool isWeighted`. Write new keys. Add `categoryTag` param (passed through separately). |
| 2 | [MOD] | `lib/features/templates/utils/dart_template_linter.dart` | ~5 | Change `lint()` signature: replace `String scoringMode` with `String scoreDirection, bool isWeighted`. Line 95 check: `scoreDirection=='down' && isWeighted`. |
| 3 | [MOD] | `lib/features/templates/widgets/metadata_form_card.dart` | ~40 | Replace dropdown with SegmentedButton + isWeighted Switch + categoryTag TextFormField. New props: `scoreDirection`, `isWeighted`, `onScoreDirectionChanged`, `onIsWeightedChanged`, `categoryTag`, `onCategoryTagChanged`. Remove: `scoringMode`, `onScoringModeChanged`. |
| 4 | [MOD] | `lib/features/templates/pages/template_builder_page.dart` | ~10 | Split `_scoringMode` → `_scoreDirection`, `_isWeighted`, `_categoryTag`. Add `_legacyScoringMode` getter. Update MetadataFormCard call only. |
| 5 | [MOD] | `lib/features/templates/pages/template_builder_page_logic.dart` | ~15 | Load: read `scoreDirection`+`isWeighted`+`categoryTag` from config JSON (with fallback). Save: pass `scoreDirection`, `isWeighted`, `categoryTag` to `buildScoringLogicConfig()`. Pass `categoryTag` to `saveTemplate()`. |
| 6 | [MOD] | `lib/features/templates/manager/template_manager.dart` | ~5 | Add `categoryTag` param to `saveTemplate()` and pass it to `_api.createTemplate()` and `_api.saveTemplateTree()`. |
| 7 | [MOD] | `test/features/templates/template_linter_slice2_test.dart` | ~varies | Update `lint()` calls: `scoringMode: 'penalty'` → `scoreDirection: 'down', isWeighted: true`. |
| 8 | [MOD] | `test/features/templates/template_linter_slice3_test.dart` | ~varies | Same — update all `lint(scoringMode: ...)` calls. |

**Files NOT touched**: `advanced_settings_card.dart`, `section_editor.dart`, `live_score_simulator.dart`, all wizard pages, all audit widgets.

---

## Concept Diagram

```text
[MetadataFormCard — NEW]
  SegmentedButton:  down | up | none
  Switch (hidden when 'none'): Use Section Weights
  TextFormField:    Category Tag
       |
       | onScoreDirectionChanged / onIsWeightedChanged / onCategoryTagChanged
       v
[template_builder_page.dart state]
  _scoreDirection = 'down'   _isWeighted = true   _categoryTag = ''
  
  getter _legacyScoringMode:
    if none → 'survey'
    if up   → 'accumulation'
    if down && isWeighted  → 'penalty'
    if down && !isWeighted → 'checklist'
       |                          |
       |                          └─ passed to AdvancedSettingsCard, SectionEditor,
       |                              LiveScoreSimulator (BRIDGE — no change)
       v
  _buildScoringConfig() → buildScoringLogicConfig(
      scoreDirection: _scoreDirection,    ← NEW key
      isWeighted: _isWeighted,            ← NEW key
      ...existing fields...
  )
       |
       v
  _save() → saveTemplate(
      ...existing fields...,
      categoryTag: _categoryTag           ← NEW top-level field
  )
       |
       v
  [TemplateManager.saveTemplate() → _api.saveTemplateTree()]
  
  DartTemplateLinter.lint(
      scoreDirection: _scoreDirection,    ← NEW
      isWeighted: _isWeighted,            ← NEW
      ...
  )
```

---

## Execution Slices

### Slice A — Linter + Payload Mapper (Logic Layer)
**Entry**: Slice 3 complete. Tests pass for mapper/parser.
**Exit**: `buildScoringLogicConfig()` writes new keys. Linter uses new params. All existing linter unit tests updated and GREEN.
**Scope** (4 files):
1. `template_payload_mapper.dart` — new signature, new JSON keys
2. `dart_template_linter.dart` — new signature, `PenaltyModeGroupSum` check updated
3. `test/features/templates/template_linter_slice2_test.dart` — update `lint()` calls
4. `test/features/templates/template_linter_slice3_test.dart` — update `lint()` calls

**Acceptance Criteria**:
- `buildScoringLogicConfig()` output has `scoreDirection` key, NOT `scoringMode`
- `DartTemplateLinter.lint()` compiles with `scoreDirection` + `isWeighted` params
- `PenaltyModeGroupSum` fires for `down+true`, not for `down+false` or `up`
- All `rtk flutter test test/features/templates/` pass GREEN

**Route**: Route 2 (Unit Tests First — update existing tests before touching code)
**Complexity**: Low

---

### Slice B — MetadataFormCard UI Redesign
**Entry**: Slice A complete.
**Exit**: MetadataFormCard renders Two Toggles + categoryTag field. New widget tests TC-01, TC-02, TC-03 pass GREEN.
**Scope** (2 files):
1. `metadata_form_card.dart` — replace dropdown with SegmentedButton + Switch + TextFormField
2. `test/features/templates/widgets/metadata_form_card_test.dart` — NEW test file (TC-01, TC-02, TC-03)

**Acceptance Criteria**:
- `DropdownButtonFormField` for scoring is gone
- `SegmentedButton` renders with 3 segments: Count Down, Count Up, No Score
- `Use Section Weights` switch hidden when `scoreDirection='none'`
- `Category Tag` TextFormField renders
- `advanced_settings_card_test.dart` (3 existing tests) still GREEN (bridge, not touched)
- `template_linter_slice3_test.dart` widget tests 7 & 8 still GREEN

**Route**: Route 1 (Direct Build — UI only, no new logic)
**Complexity**: Low-Medium

---

### Slice C — Builder Page State Wiring
**Entry**: Slice B complete.
**Exit**: Builder page compiles with new state fields. Template saves and loads correctly. `rtk flutter test` full suite GREEN.
**Scope** (4 files):
1. `template_builder_page.dart` — new state fields, `_legacyScoringMode` getter, update MetadataFormCard call
2. `template_builder_page_logic.dart` — load/save with new fields
3. `template_manager.dart` — add `categoryTag` param
4. (verify `template_api_service.dart` already has categoryTag or add it)

**Acceptance Criteria**:
- State: `_scoreDirection`, `_isWeighted`, `_categoryTag` fields exist in builder page
- `_legacyScoringMode` getter correctly maps new fields to legacy string
- `AdvancedSettingsCard` still receives String via `_legacyScoringMode`
- On load: old config with `scoringMode:'penalty'` → `_scoreDirection='down'`, `_isWeighted=true`
- On save: payload contains `scoreDirection`, `isWeighted` in `scoringLogicConfig` AND `categoryTag` as top-level
- `rtk flutter test` all pass GREEN

**Route**: Route 2 (test save/load logic before wiring)
**Complexity**: Medium

---

<command_logs>
- view_file: metadata_form_card.dart (109L) — dropdown with scoringMode String prop + helperText switch
- view_file: template_builder_page.dart (1-60, 60-160, 160-250) — String _scoringMode = 'penalty'; passes to MetadataFormCard, AdvancedSettingsCard, SectionEditor, LiveScoreSimulator
- view_file: template_builder_page_logic.dart (136L) — line 26 reads config['scoringMode']; line 47 calls buildScoringLogicConfig(scoringMode:)
- view_file: template_payload_mapper.dart (133L) — buildScoringLogicConfig() writes 'scoringMode' key at line 123
- view_file: dart_template_linter.dart (200L) — line 95: scoringMode == 'penalty'
- view_file: advanced_settings_card.dart (310L) — _isSurvey = scoringMode == 'survey'; _isChecklist = scoringMode == 'checklist'; line 197 scoringMode != 'accumulation'
- view_file: template_manager.dart (202L) — saveTemplate() signature does NOT have categoryTag
- grep_search: categoryTag in lib/ → exists in CachedGroups, CachedCriteria Drift tables, NOT on Templates table in Flutter
- grep_search: scoringMode in lib/features/templates/pages → builder_page.dart:67, logic:26,47, validation:22,96, wizard:53,167,176,182,194
- grep_search: TemplateLinter in test/ → template_linter_slice2_test.dart, template_linter_slice3_test.dart
- view_file: advanced_settings_card_test.dart (116L) — 3 tests, all pass scoringMode: 'penalty' — will break if AdvancedSettingsCard prop changes
- view_file: template_linter_slice3_test.dart (349L) — tests 1-6: LiveScoreSimulator with scoringMode: 'penalty'/'survey' strings
</command_logs>

---

## Handoff Block

**Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260530_092025_slice4_template_builder_ui_cdefadc1.md`

**Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\scoring_redesign\task_20260530_092025_slice4_template_builder_ui_cdefadc1.md`

### Action Sequence — Execute ONE slice at a time

1. **Slice A** [Route 2 — Unit Tests First]:
   - Update linter tests (`slice2_test`, `slice3_test`) — change `scoringMode:` calls to new params → run → confirm RED
   - Build: change `dart_template_linter.dart` + `template_payload_mapper.dart`
   - Run `rtk flutter test test/features/templates/` → GREEN

2. **Slice B** [Route 1 — Direct Build]:
   - Write new `metadata_form_card_test.dart` (TC-01, TC-02, TC-03)
   - Build: rewrite `metadata_form_card.dart` (Two Toggles + categoryTag)
   - Run `rtk flutter test test/features/templates/widgets/` → GREEN

3. **Slice C** [Route 2 — Unit Tests First for save/load]:
   - Build: wire new state in builder page + logic + manager
   - Run `rtk flutter test` → full suite GREEN
