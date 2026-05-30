<latent_space_scratchpad>
## Hard Discovery: Blast Radius of ScoringMode

The grep revealed that `scoringMode` (the OLD string-based system) is used in 30+ Dart files:

**Layer 1 — Scoring Core (THIS SLICE's scope)**
- `scoring_mode.dart` — 3L: `enum ScoringMode { penalty, accumulation, checklist, survey }`
- `scoring_input.dart` — 23L: `final ScoringMode scoringMode;`
- `scoring_engine.dart` — 110L: switch on `input.scoringMode`
- `scoring_input_mapper.dart` — 215L: `parseScoringMode()` reads `scoringMode` JSON key

**Layer 2 — Snapshot/Submission Parser**
- `audit_snapshot_parser.dart` — 126L: reads `configMap['scoringMode']` from template snapshot JSON

**Layer 3 — Template Builder UI (OUT OF SCOPE → Slice 4)**
- `advanced_settings_card.dart`, `metadata_form_card.dart`, `wizard_step_name.dart`,
  `wizard_step_sections.dart`, `wizard_step_review.dart`, `wizard_step_structure.dart`,
  `wizard_step_sections_parts.dart`, `section_editor.dart`, `section_editor_parts.dart`,
  `criterion_editor.dart`, `criterion_editor_drawer.dart`, `input_type_bottom_sheet.dart`
  — ALL pass `scoringMode` (String) around, and these are ALL template-builder-specific widgets.

**Layer 4 — Audit UI (OUT OF SCOPE → Slice 4 or standalone)**
- `audit_criterion_row.dart`, `read_only_criterion_row.dart`, `header_card.dart`,
  `dynamic_section_summary.dart`, `audit_preview_group_builder.dart`, `audit_card.dart`
  — All read `scoringMode` string from submission DTO

**Layer 5 — Audit Manager**
- `audit_manager.dart:70-72` — `ScoringMode get scoringMode` getter that calls `parseScoringMode()`

**Layer 6 — Score Formatter**
- `score_formatter.dart` — 6 lines, checks `scoringMode == 'survey'`, `'accumulation'`, `'checklist'`

## KEY INSIGHT: The 2-Layer Design
The codebase uses `ScoringMode` enum internally in the scoring engine,
but the **UI and snapshot parser** all pass raw `String` values around
(e.g., `scoringMode: 'penalty'`). This is a pre-existing design choice.

The REAL migration is:
1. `ScoringInputMapper.parseScoringMode()` reads OLD JSON key `scoringMode`
   → MUST change to read NEW keys `scoreDirection` + `isWeighted`
   → MUST return the correct `ScoringMode` equivalent (or a new type)
2. `scoring_engine.dart` switch → MUST route on new fields
3. `ScoringInput` → MUST carry new fields

## Design Decision: Strategy for ScoringMode Enum

Option A: KEEP `ScoringMode` enum in Flutter, map new JSON → existing enum internally.
  - Pros: Zero changes to the 30+ UI files (they still use ScoringMode.penalty etc.)
  - Cons: Technically wrong — user didn't choose "penalty" or "checklist", they chose
          scoreDirection + isWeighted. It's an abstraction leak.
  - Where mapping happens: ScoringInputMapper.parseScoringMode() translates
    scoreDirection + isWeighted → ScoringMode enum internally.

Option B: REPLACE ScoringMode enum with two new fields (scoreDirection enum, isWeighted bool).
  - Pros: Clean model, matches server exactly.
  - Cons: Must touch 30+ files. MASSIVE refactor. High risk of widget test breakage.

**DECISION: Option A — Internal Translation Pattern.**
Keep `ScoringMode` enum for INTERNAL use in the engine. The enum becomes a private
implementation detail. The JSON parser translates the new 2-field JSON into the
existing enum. This way:
- `scoring_engine.dart` — UNCHANGED (math stays the same, dispatch stays the same)
- `scoring_mode.dart` — UNCHANGED (enum still has 4 values)
- ALL 30+ UI files — UNCHANGED
- `scoring_input.dart` — UNCHANGED
- Changes are minimal: ONLY `ScoringInputMapper.parseScoringMode()` +
  `audit_snapshot_parser.dart` need updating.

**RATIONALE**: The epic says "Slice 3: Flutter Core (Enum + Engine)". But after reading
the actual code, the engine uses a stable enum internally. The ONLY breaking change
is the JSON parsing. Rewriting 30+ files for a cosmetic rename is YAGNI.
This is the correct architectural choice: parsing is the boundary layer.

## What Actually Needs to Change

1. `ScoringInputMapper.parseScoringMode()` (line 125-137):
   - NOW: reads `config['scoringMode']` → enum
   - NEW: reads `config['scoreDirection']` + `config['isWeighted']` → enum
   - TRANSLATION TABLE:
     - scoreDirection='none' → ScoringMode.survey (regardless of isWeighted)
     - scoreDirection='up'   → ScoringMode.accumulation
     - scoreDirection='down' + isWeighted=true  → ScoringMode.penalty
     - scoreDirection='down' + isWeighted=false → ScoringMode.checklist
   - FALLBACK: null/empty → ScoringMode.penalty (default unchanged)

2. `audit_snapshot_parser.dart` (line 31-32):
   - NOW: `configMap['mode'] ?? configMap['scoringMode'] ?? 'penalty'`
   - NEW: Must translate scoreDirection+isWeighted → a display string for the read-only audit view.
   - NOTE: `AuditSnapshotResult.scoringMode` is a String used by audit display widgets.
     These widgets compare to 'survey', 'accumulation', 'checklist', 'penalty'.
     So the snapshot parser must still output these legacy strings (the display layer
     hasn't changed yet). The mapping is: scoreDirection='none' → 'survey',
     scoreDirection='up' → 'accumulation', etc.

3. `AuditManager.scoringMode` getter (line 70-72) — calls parseScoringMode, already updated
   by fixing ScoringInputMapper. No file change needed.

## Drift SQLite Schema — Is a Migration Needed?

The epic says "write a local Drift (SQLite) schema migration".
But the grep shows:
- Drift `Templates` table has `scoringLogicConfig` (TextColumn, nullable) — a JSON blob.
- The new fields (scoreDirection, isWeighted) are INSIDE this JSON blob, not as separate columns.
- There is NO separate `scoringMode` column in the Drift Templates table.
- The Drift CachedSubmissions table — we need to check if it has scoringMode.

Let me think: The epic says add `category_tag` to templates. But that's the server-side Postgres.
The Flutter Drift schema stores templates as a JSON blob. So:
- NO Drift schema migration is needed for scoreDirection/isWeighted (they're inside the JSON blob).
- The category_tag column: if the Drift CachedSubmissions table needs category_tag for
  offline analytics, that would need a migration. But the epic's Flutter scope is scoring ONLY.
- CONCLUSION: NO Drift migration needed for Slice 3. The JSON blob approach means
  the templates already "carry" the new JSON format after sync without any schema change.

## Two Failure Modes

1. `parseScoringMode()` parses `scoreDirection='down'` but `isWeighted` key is missing from JSON
   → `config['isWeighted']` returns `null` → null cast to bool? → `isWeighted = false`
   → routes to ScoringMode.checklist (should be penalty if weighted)
   → WRONG SCORE. Fix: explicitly default to false if null.

2. Old snapshot JSON still has `scoringMode='penalty'` (legacy template created before backfill)
   → new parser reads `scoreDirection` key which doesn't exist → null → defaults to 'down'+false → checklist
   → WRONG for old templates that were penalty (weighted).
   Fix: add fallback: if `scoreDirection` is null, also try reading `scoringMode` key for transition period.
   This is a SAFE fallback — NOT backward compat code for new JSON, just a read fallback for existing data.

## File Sizes Check
- scoring_mode.dart: 3L ✅
- scoring_input.dart: 23L ✅
- scoring_engine.dart: 110L ✅ (UNCHANGED)
- scoring_input_mapper.dart: 215L ✅ (touches ~13 lines)
- audit_snapshot_parser.dart: 126L ✅ (touches ~3 lines)

## Test Files That Exist
- test/scoring_engine_test.dart — tests engine dispatch
- test/scoring_engine_conform_guard_test.dart — tests purity guard
- test/features/audit/services/scoring_input_mapper_test.dart — tests parser
- test/features/audit/services/scoring_input_mapper_minus_impact_test.dart — tests minusImpact

## Tests That Need Updating
- `scoring_input_mapper_test.dart` — has tests that call `parseScoringMode` with old JSON
  `{"scoringMode":"penalty"}` → will still work if we add fallback.
  BUT we must add NEW tests for new JSON format `{"scoreDirection":"down","isWeighted":true}`.
- `scoring_engine_test.dart` — tests call `ScoringInput(scoringMode: ScoringMode.penalty, ...)`.
  These tests pass ScoringMode.penalty directly — NOT affected by JSON parsing change.
  These tests will still pass without change. ONLY add new tests.
</latent_space_scratchpad>

# Implementation Plan: Scoring Redesign — Slice 3: Flutter Core (Parser Translation)

**Created**: 2026-05-30T08:28:05+07:00
**Author**: Antigravity AI
**Epic**: SCORING-REDESIGN
**Slice**: 3 of 5
**Status**: PLANNING

---

## Input Lineage

- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Slice 1 Plan**: `...\implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md`
- **Slice 2 Plan**: `...\implementation_plan_20260529_231623_slice2_backend_parser_cdefadc1.md`
- **Entry Dependency**: Slice 1 DB migration complete. Slice 2 backend hard cut complete.

---

## ⚠️ Risk Warning: Architecture Discovery — Scope Corrected

> The epic's original Slice 3 description says "Replace `ScoringMode` enum with two new enums."
> After reading the actual Flutter codebase, this would require touching **30+ files** spanning the
> Template Builder, Audit UI, and Score Formatter. Doing this in one slice is a 🔴 HIGH blast radius.
>
> **Corrected Plan**: The correct boundary for Slice 3 is the **JSON parsing layer only**.
> The internal `ScoringMode` enum is kept as a private implementation detail.
> The mapper translates `scoreDirection + isWeighted` → `ScoringMode` at the boundary.
> This contains all changes to **2 files** with zero impact on the 30+ UI files.
> The full enum rename (if desired) is deferred to **Slice 4 (Template Builder UI)**.
>
> **ROI**: This approach is ✅ LOWER RISK, same functional outcome. The server and Flutter
> now speak the same JSON language. Score math is unchanged.

---

## Executive Summary & Out of Scope

**Goal**: Update the Flutter `ScoringInputMapper.parseScoringMode()` function and the
`AuditSnapshotParser` to read the new `{"scoreDirection": "...", "isWeighted": ...}` JSON
format from the `scoringLogicConfig` blob, and correctly translate it into the existing
internal `ScoringMode` enum for the engine.

```text
OLD flow:
  JSON blob: {"scoringMode":"penalty"}
    → ScoringInputMapper.parseScoringMode()
    → returns ScoringMode.penalty
    → ScoringEngine.calculate() → PenaltyCalculator

NEW flow:
  JSON blob: {"scoreDirection":"down","isWeighted":true}
    → ScoringInputMapper.parseScoringMode() ← ONLY CHANGE
    → maps (down, true) → ScoringMode.penalty ← same internal enum
    → ScoringEngine.calculate() → PenaltyCalculator ← UNCHANGED
```

**Translation Table** (new JSON → internal enum):

| scoreDirection | isWeighted | → ScoringMode enum |
|---|---|---|
| `"none"` | any | `ScoringMode.survey` |
| `"up"` | any | `ScoringMode.accumulation` |
| `"down"` | `true` | `ScoringMode.penalty` |
| `"down"` | `false` | `ScoringMode.checklist` |
| `null` fallback | — | `ScoringMode.penalty` (default) |

**Out of Scope** (NOT in this slice):
- Renaming the `ScoringMode` enum itself (deferred to Slice 4)
- Changing any Template Builder widgets (`wizard_step_*.dart`, `metadata_form_card.dart`, etc.)
- Changing any Audit display widgets (`dynamic_section_summary.dart`, `audit_card.dart`, etc.)
- Changing `score_formatter.dart`
- Adding `category_tag` to Drift tables (not needed — scoring is inside JSON blob)
- No Drift schema migration is required — `scoringLogicConfig` is already a text JSON blob

---

## System Context

| Constraint | Detail |
|---|---|
| Offline-first | Template JSON blob synced from server. Parser runs on device. No network. |
| Enum stability | `ScoringMode` enum stays unchanged. 30+ UI files use it via string comparisons. |
| Legacy fallback | Old snapshot JSON may still have `scoringMode` key (pre-Slice 1 templates). Parser must also try old key as fallback. |
| Mirror rule | `ScoringInputMapper.parseScoringMode()` MUST produce the same dispatch result as `ScoringVerifier.Verify()` on the server for identical templates. |

---

## Lifecycle Context — 4-State Matrix

| State | Behavior |
|---|---|
| **Success** | `parseScoringMode()` reads new JSON keys → returns correct enum → engine dispatches to right calculator. |
| **Error** | `scoreDirection` missing or malformed JSON → catches exception → returns `ScoringMode.penalty` (default). |
| **Empty** | `scoreDirection = "none"` → returns `ScoringMode.survey` → engine returns `totalScore: null`. |
| **Legacy** | Old snapshot with `scoringMode` key → fallback tries `scoringMode` key → returns correct enum. |

---

## Constraint Traceability

| # | Constraint | Test Contract |
|---|---|---|
| C1 | Reads new `scoreDirection` key from JSON | TC-01 |
| C2 | Reads new `isWeighted` key from JSON | TC-01, TC-02, TC-03 |
| C3 | `"none"` → `ScoringMode.survey` | TC-04 |
| C4 | `"up"` → `ScoringMode.accumulation` | TC-03 |
| C5 | `"down"` + `true` → `ScoringMode.penalty` | TC-01 |
| C6 | `"down"` + `false` → `ScoringMode.checklist` | TC-02 |
| C7 | Null JSON → `ScoringMode.penalty` default | TC-05 |
| C8 | Malformed JSON → `ScoringMode.penalty` default | TC-05b |
| C9 | Legacy `scoringMode` key fallback works | TC-06, TC-06b |
| C10 | `isWeighted` missing from JSON → treated as `false` | TC-07 |
| C11 | `AuditSnapshotParser` outputs correct display string | TC-08 |
| C12 | Engine dispatch is UNCHANGED (no regression) | TC-09 (existing, passes) |

---

## Test Contracts

### Unit Tests (scoring_input_mapper_test.dart — ADD new tests)

| ID | Description | Input JSON | Expected ScoringMode |
|---|---|---|---|
| TC-01 | down + weighted → penalty | `{"scoreDirection":"down","isWeighted":true}` | `ScoringMode.penalty` |
| TC-02 | down + unweighted → checklist | `{"scoreDirection":"down","isWeighted":false}` | `ScoringMode.checklist` |
| TC-03 | up → accumulation | `{"scoreDirection":"up","isWeighted":false}` | `ScoringMode.accumulation` |
| TC-04 | none → survey | `{"scoreDirection":"none","isWeighted":false}` | `ScoringMode.survey` |
| TC-05 | null input → penalty default | `null` | `ScoringMode.penalty` |
| TC-05b | malformed JSON → penalty default | `"{ bad"` | `ScoringMode.penalty` |
| TC-06 | legacy scoringMode key still works | `{"scoringMode":"accumulation"}` | `ScoringMode.accumulation` |
| TC-06b | legacy scoringMode=checklist still works | `{"scoringMode":"checklist"}` | `ScoringMode.checklist` |
| TC-07 | scoreDirection present, isWeighted missing → defaults false → checklist | `{"scoreDirection":"down"}` | `ScoringMode.checklist` |

### Unit Tests (audit_snapshot_parser — ADD new tests or create new file)

| ID | Description | Config JSON in snapshot | Expected scoringMode string |
|---|---|---|---|
| TC-08 | New JSON keys → correct display string | `{"scoreDirection":"none","isWeighted":false}` | `"survey"` |
| TC-08b | New down+true → "penalty" string | `{"scoreDirection":"down","isWeighted":true}` | `"penalty"` |
| TC-08c | New up → "accumulation" string | `{"scoreDirection":"up","isWeighted":false}` | `"accumulation"` |
| TC-08d | Legacy key still works | `{"scoringMode":"checklist"}` | `"checklist"` |

### No Engine Tests (TC-09 note)

> `scoring_engine_test.dart` passes `ScoringMode` enum directly to `ScoringInput`. These tests
> do NOT test JSON parsing. They will pass without changes. No regression risk.

---

## Test Fixture & Payloads

### Config JSON shapes (what arrives from server → stored in `scoringLogicConfig`)

```json
// After Slice 2 backend hard cut — NEW format
{"scoreDirection":"down","isWeighted":true,"progressiveRepeat":false}
{"scoreDirection":"down","isWeighted":false,"progressiveRepeat":false}
{"scoreDirection":"up","isWeighted":false,"progressiveRepeat":false}
{"scoreDirection":"none","isWeighted":false,"progressiveRepeat":false}

// OLD format — still in production snapshots (legacy templates)
{"scoringMode":"penalty"}
{"scoringMode":"accumulation"}
{"scoringMode":"checklist"}
{"scoringMode":"survey"}
```

### parseScoringMode() new logic (pseudocode for Builder)

```
parseScoringMode(configJson):
  if null/empty → return penalty
  try:
    config = json.decode(configJson)
    scoreDirection = config['scoreDirection'] as String?
    isWeighted = config['isWeighted'] as bool? ?? false
    
    if scoreDirection != null:
      if scoreDirection == 'none' → return survey
      if scoreDirection == 'up'   → return accumulation
      if scoreDirection == 'down':
        return isWeighted ? penalty : checklist
    
    // FALLBACK: legacy key (for old template snapshots)
    mode = config['scoringMode'] as String?
    if mode == 'accumulation' → return accumulation
    if mode == 'checklist'    → return checklist
    if mode == 'survey'       → return survey
    
  catch (e) → debugPrint, return penalty
  return penalty (default)
```

---

## Tools & Commands

- **Skills**: `tdd` skill
- **Flutter test**: `rtk flutter test test/features/audit/services/scoring_input_mapper_test.dart`
- **Full suite**: `rtk flutter test`

---

## Proposed Changes

Build in this exact order:

| # | Action | File | Lines Changed | Notes |
|---|---|---|---|---|
| 1 | [MOD] | `lib/features/audit/services/scoring_input_mapper.dart` | ~13 | Replace `parseScoringMode()` body: read `scoreDirection` + `isWeighted` first, fallback to `scoringMode`. |
| 2 | [MOD] | `lib/features/audit/utils/audit_snapshot_parser.dart` | ~6 | Replace the `scoringMode =` line (line 31-32) with equivalent 2-key read + fallback to old key. |
| 3 | [MOD] | `test/features/audit/services/scoring_input_mapper_test.dart` | ~40 | Add TC-01 → TC-07 tests. Do NOT delete existing tests. |
| 4 | [NEW] | `test/features/audit/utils/audit_snapshot_parser_test.dart` | ~50 | New file. TC-08 → TC-08d tests. |

**Files NOT touched** (confirmed clean):
- `scoring_mode.dart` — enum stays as-is
- `scoring_input.dart` — struct stays as-is
- `scoring_engine.dart` — dispatcher unchanged
- `penalty_calculator.dart`, `accumulation_calculator.dart`, `checklist_calculator.dart` — math unchanged
- All template builder widgets — deferred to Slice 4
- All audit display widgets — deferred to Slice 4

---

## Concept Diagram

```text
[Server: scoringLogicConfig JSON blob in DB/snapshot]
  {"scoreDirection":"down","isWeighted":true,"progressiveRepeat":false}
              |
     [Flutter Drift: scoringLogicConfig TextColumn]  ← JSON passes through unchanged
              |
              v
  [ScoringInputMapper.parseScoringMode()]  ← ONLY CHANGE (file #1)
    1. Try scoreDirection + isWeighted keys (new format)
    2. Fallback: try scoringMode key (legacy format)
    returns: ScoringMode.penalty        ← same internal enum, unchanged
              |
              v
  [ScoringEngine.calculate(input)]       ← UNCHANGED
    switch(input.scoringMode):
      .penalty → PenaltyCalculator       ← UNCHANGED
      .checklist → ChecklistCalculator   ← UNCHANGED
      .accumulation → AccumulationCalculator ← UNCHANGED
      .survey → null score               ← UNCHANGED
```

```text
[Finalized submission JSON (template snapshot)]
  snapshot["scoringLogicConfig"]["scoreDirection"] = "none"
              |
              v
  [AuditSnapshotParser.parseSnapshot()]  ← CHANGE (file #2)
    reads scoreDirection + isWeighted → maps to display string
    returns: AuditSnapshotResult(scoringMode: "survey")
              |
              v
  [Audit display widgets]                ← UNCHANGED
    header_card.dart, dynamic_section_summary.dart, etc.
    still receive String "survey", "penalty" etc.
```

---

## Execution Slices

### Slice A — Core Parser Translation
**Complexity**: Low
**Entry State**: Slice 2 complete. Server now sends `scoreDirection`+`isWeighted` JSON.
**Exit State**: `parseScoringMode()` correctly translates new + legacy JSON. TC-01 → TC-07 all GREEN. `flutter test` full suite passes.
**Scope**: 2 source files (`scoring_input_mapper.dart`, `audit_snapshot_parser.dart`) + 2 test files.

**Acceptance Criteria**:
1. `ScoringInputMapper.parseScoringMode()` reads `scoreDirection` key first.
2. `ScoringInputMapper.parseScoringMode()` reads `isWeighted` key, defaults to `false` if absent.
3. `("down", true)` → `ScoringMode.penalty`.
4. `("down", false)` → `ScoringMode.checklist`.
5. `("up", any)` → `ScoringMode.accumulation`.
6. `("none", any)` → `ScoringMode.survey`.
7. Fallback: if `scoreDirection` is null, reads `scoringMode` key (legacy).
8. Null/malformed input → `ScoringMode.penalty`.
9. `AuditSnapshotParser` outputs correct display strings for both new and legacy JSON.
10. All 9 TC-01 → TC-07 unit tests + 4 TC-08 tests pass GREEN.
11. Existing tests in `scoring_engine_test.dart` still pass (no regression).
12. `rtk flutter test` — full suite passes.

> ⚠️ **No Drift schema migration needed.** The `scoringLogicConfig` column is already a text JSON blob.
> The new fields are inside that blob. No schema ALTER is required.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Old template snapshots with `scoringMode` key break offline audits | HIGH | Keep legacy fallback in parser. Test TC-06, TC-06b. |
| `isWeighted` missing from new JSON → wrong checklist dispatch | MEDIUM | Default `isWeighted` to `false` if null. Test TC-07. |
| Flutter engine tests break (regression) | LOW | Engine tests don't test JSON parsing. No engine code changes. |
| `AuditSnapshotParser` display string mismatch | MEDIUM | Audit widgets compare strings like `'survey'`. Map correctly. Test TC-08. |

---

## Verification Plan

```bash
# 1. Targeted mapper tests
rtk flutter test test/features/audit/services/scoring_input_mapper_test.dart

# 2. New snapshot parser tests
rtk flutter test test/features/audit/utils/audit_snapshot_parser_test.dart

# 3. Engine regression check
rtk flutter test test/scoring_engine_test.dart

# 4. Full Flutter suite
rtk flutter test
```

<command_logs>
- list_dir: lib/_shared/services → found scoring_mode.dart (3L), scoring_input.dart (23L), scoring_engine.dart (110L), scoring_input_mapper.dart (215L)
- view_file: scoring_mode.dart → enum ScoringMode { penalty, accumulation, checklist, survey }
- view_file: scoring_input.dart → field: ScoringMode scoringMode
- view_file: scoring_engine.dart (110L) → switch on input.scoringMode, 4 arms. UNCHANGED.
- grep_search: ScoringMode|scoringMode in lib/ → 30+ usages across 20+ files
- grep_search: ScoringMode|scoringMode in lib/_shared → only scoring_mode/input/engine/services.dart
- grep_search: ScoringMode|scoringMode in lib/features/audit → audit_manager.dart:70-72, scoring_input_mapper.dart:104-137, audit_snapshot_parser.dart:8-32
- view_file: scoring_input_mapper.dart (215L) → parseScoringMode() at line 125-137, reads old 'scoringMode' key
- view_file: audit_snapshot_parser.dart (126L) → reads 'mode'??'scoringMode'??'penalty' at line 31-32
- grep_search: scoring_mode|scoringMode in lib/_shared/database → NO Drift schema column, only scoringLogicConfig JSON blob
- list_dir: lib/features/audit/services → confirmed scoring_input_mapper.dart (7877 bytes)
- grep_search: *_test.dart matching ScoringInputMapper → found 4 test files
- grep_search: scoringMode in lib/features/templates → 50+ template widget hits (all OUT OF SCOPE)
</command_logs>

---

## Handoff Block

**Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260530_082805_slice3_flutter_core_cdefadc1.md`

**Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\scoring_redesign\task_20260530_082805_slice3_flutter_core_cdefadc1.md`

### Action Sequence — ONE slice, execute in this order

**Route 2 (Unit Tests First)**:

1. **QA** — Write failing unit tests (TC-01 → TC-07) in `scoring_input_mapper_test.dart` (add to file).
   Write failing tests (TC-08 → TC-08d) in new `audit_snapshot_parser_test.dart`.
   Run → confirm RED (old parser reads wrong key). **YIELD.**

2. **Builder: Slice A** — Modify `scoring_input_mapper.dart` (parseScoringMode method).
   Modify `audit_snapshot_parser.dart` (scoringMode= line).
   Run `flutter test` → all tests GREEN. **YIELD for manual verification.**

> ⚠️ Do NOT begin Slice 4 (Template Builder UI) until `flutter test` passes GREEN.
>
> ⚠️ Do NOT rename or modify the `ScoringMode` enum or `ScoringInput` fields in this slice.
> Those 30+ downstream files (template widgets, audit widgets) must remain untouched.
