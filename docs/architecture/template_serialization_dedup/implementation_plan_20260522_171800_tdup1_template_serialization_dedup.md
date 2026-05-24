<!--
<latent_space_scratchpad>
FULL INVESTIGATION RESULTS:

Three files involved:
1. lib/features/templates/utils/builder_payload_mapper.dart (88 lines)
   - DEAD CODE: `buildGroupsPayload()` is only referenced within itself. ZERO external imports found.
   - Was likely a previous iteration that got abandoned when builder_page_logic took over.
   - Must be DELETED per GEMINI.md "Prune Dead Code" rule.

2. lib/features/templates/pages/wizard_payload_builder.dart (99 lines)
   - LIVE: imported by template_wizard_page.dart only.
   - Contains: `buildCriterion()`, `buildGroupsRecursive()`, `buildGroups()`, `buildScoringLogicConfig()`
   - WIZARD path (create-only): No `id` fields in criteria (new records only).
   - Criteria metadata: flat top-level keys (separate `if (isScaleType)` entries). `isRequired` is a flat top-level key.
   - Groups: Missing weight, maxDeductionPoints, minusPerFault, metadata fields.

3. lib/features/templates/pages/template_builder_page_logic.dart (395 lines, part-of)
   - LIVE: used only within template_builder_page.dart (part-of relationship).
   - Contains: `_buildScoringConfig()`, `_buildGroupsRecursive()`, `_buildGroups()`
   - BUILDER path (create + edit): Includes `id` fields for edit reconciliation.
   - Criteria metadata: map-based `meta{}` pattern encoded together.
   - Groups: full payload including weight, maxDeductionPoints, minusPerFault, metadata.

DIVERGENCE TABLE (confirmed by code read):
| Field                | builder_page_logic | wizard_payload_builder |
|---                   |---                 |---                     |
| Group `id`           | YES                | NO (create-only)       |
| Group `weight`       | YES                | NO (missing)           |
| Group `maxDeduct`    | YES                | NO (missing)           |
| Group `minusPerFault`| YES                | NO (missing)           |
| Group `metadata`     | YES (subSection)   | NO (missing)           |
| Criterion `id`       | YES                | NO (create-only)       |
| isRequired location  | in meta{} JSON     | flat top-level key     |
| metadata encoding    | map merge pattern  | separate if chains     |
| Scoring config       | IDENTICAL          | IDENTICAL              |

CONCLUSION:
- builder_payload_mapper.dart → DELETE (dead code)
- wizard_payload_builder.dart → KEEP (it IS the shared util — it just needs fields added to match builder)
- template_builder_page_logic.dart → MIGRATE to call wizard_payload_builder after enhancing it
- The canonical function lives in wizard_payload_builder (utils-adjacent, already in pages/ though)
- Better home: MOVE wizard_payload_builder.dart → utils/template_payload_mapper.dart 
  (rename for clarity and put in the right folder)

MIGRATION DESIGN:
The canonical mapper needs ONE parameter: `bool isEditMode`.
- isEditMode=true → include `id` fields in groups and criteria
- isEditMode=false (wizard) → omit `id` fields

The scoring config function is already 100% identical — easy unification.

IMPACT:
- template_wizard_page.dart: update import, update call sites (3 calls)
- template_builder_page_logic.dart: replace _buildGroupsRecursive/_buildGroups/_buildScoringConfig with calls to the canonical mapper
- builder_payload_mapper.dart: DELETE

Callers:
- wizard_payload_builder.buildGroups → template_wizard_page.dart L195
- wizard_payload_builder.buildScoringLogicConfig → template_wizard_page.dart L184
- _buildGroups() → template_builder_page_logic.dart L284
- _buildScoringConfig() → template_builder_page_logic.dart L282

Tests:
- ZERO unit tests for payload building logic. This is the main risk.
- Must write unit tests for the canonical mapper BEFORE migration (Route 2).

CONSTRAINTS FROM GEMINI.md:
- "Prune Dead Code" → must delete builder_payload_mapper.dart
- "Keep it Simple" → do not make bad abstractions; bool flag isEditMode is clean
- "Fix Warnings First" → baseline tests pass (87 passed, exit 0)
- File limit: template_builder_page_logic.dart is 395 lines (≤400, borderline safe; removing ~80 lines of duplication will help)
- No new external packages
- Folder: canonical mapper belongs in utils/ not pages/
- Function moved to utils/ means it can be imported by both pages — clean layering

RISK ASSESSMENT:
- Moderate risk: touches the critical save path for both Template Builder and Template Wizard
- Mitigation: write unit tests FIRST before migrating callers
- The criteria serialization logic carries business rules (BL-2: pointsWeight exclusion for text/choice types, isRequired+confirmCorrect gate, CCP/Risk flags) — these must be verified by tests
</latent_space_scratchpad>
-->

## Input Lineage
- **Source Input**: `lib/features/templates/` (3 files with duplicated serialization routines)
  - `lib/features/templates/utils/builder_payload_mapper.dart` (88 lines — DEAD CODE)
  - `lib/features/templates/pages/wizard_payload_builder.dart` (99 lines — wizard-only)
  - `lib/features/templates/pages/template_builder_page_logic.dart` (395 lines — builder-only)

---

## Executive Summary & Out of Scope

The templates feature has **three separate implementations** of the same recursive JSON payload builder that converts `EditableGroup` trees into the backend's group/criteria shape. Two of them are live and have silently diverged. One is dead code.

### The Problem: Silent Divergence
The Wizard path (`wizard_payload_builder.dart`) and the Builder path (`template_builder_page_logic.dart`) started from the same algorithm but now produce **different payloads**:

| Field | Template Builder | Template Wizard |
|---|---|---|
| Group `id` | ✅ Included | ❌ Missing |
| Group `weight` | ✅ Included | ❌ Missing |
| Group `maxDeductionPoints` | ✅ Included | ❌ Missing |
| Group `minusPerFault` | ✅ Included | ❌ Missing |
| Group `metadata` (sub-section) | ✅ Included | ❌ Missing |
| Criterion `id` | ✅ Included | ❌ Missing |
| `isRequired` encoding | In `meta{}` JSON blob | Flat top-level key |
| Scoring config body | Identical | Identical |

Every future change to the payload shape must now be made in **two places**. If one is missed (as happened), data silently goes to the backend with missing fields.

### Discovery: Dead Code
`builder_payload_mapper.dart` in `utils/` is **entirely dead** — it has zero external imports. It was a previous iteration abandoned when `template_builder_page_logic.dart` was written. It must be deleted per the GEMINI.md "Prune Dead Code" rule.

### Plan
1. **Delete** `builder_payload_mapper.dart` (dead code).
2. **Move and enhance** `wizard_payload_builder.dart` → `utils/template_payload_mapper.dart`.
3. **Add `isEditMode` flag** to include/exclude `id` fields (edit path needs them; wizard create-only path does not).
4. **Migrate callers**: `template_wizard_page.dart` and `template_builder_page_logic.dart` both call the single canonical function.

### Out of Scope
- Changing the JSON shape itself (keys, values, nesting) — the builder's payload is the correct canonical shape.
- Adding new fields to the payload.
- Changing any page-level UI logic, validation, or state management.
- Touching any backend server code.
- The `buildGroups()` pass-through shim in `wizard_payload_builder.dart` — it disappears with the rename.

---

## System Context
- **Environment**: Offline-first Flutter app. The serialization runs entirely on-device and produces a `Map<String, dynamic>` passed to `TemplateManager.saveTemplate()`.
- **RBAC**: None — payload building has no auth gate.
- **API Contract**: The builder's payload shape is the canonical one (it's the older, more complete implementation). The wizard has been silently under-sending group fields.
- **Logs**: No logging in the serialization path.

---

## Lifecycle Context
No UI state changes. This is a pure data-layer refactoring.

| State | Current | After |
|---|---|---|
| Loading | Unchanged | Unchanged |
| Empty | Unchanged | Unchanged |
| Error | Unchanged | Unchanged |
| Success | Wizard silently missing fields | Wizard sends complete payload |

---

## Constraint Traceability
| Constraint | Source | Test Contract ID |
|---|---|---|
| Dead code must be deleted | GEMINI.md "Prune Dead Code" | TC-DEAD-01 |
| No magic strings | GEMINI.md | TC-SHAPE-01 (use constants in mapper) |
| No logic change on builder path | Out of Scope | TC-REGRESSION-01 |
| Wizard payload must now match builder for shared fields | Fix (fields were missing) | TC-WIZARD-01 |
| File size limit | GEMINI.md | TC-SIZE-01 (builder_page_logic loses ~80 lines) |
| Tests win over plans | GEMINI.md | TC-TDD-01 |

---

## Test Contracts
| ID | Exact Text | Why It Fails First |
|---|---|---|
| **TC-DEAD-01** | `builder_payload_mapper.dart` file does NOT exist on disk after Phase 1 | File still present |
| **TC-SHAPE-01** | Canonical mapper output for a group with weight=`0.5`, maxPoints=`10` contains `'weight': 0.5` and `'maxDeductionPoints': 10.0` | Field missing in map |
| **TC-REGRESSION-01** | `rtk flutter test test/features/templates/` passes with 0 failures after migration | Caller import broke or arg mismatch |
| **TC-WIZARD-01** | Canonical mapper called with `isEditMode: false` produces no `id` key on groups or criteria | `id` key present when it should not be |
| **TC-LOGIC-01** | Criterion with `inputType='text'` has NO `pointsWeight` key in output (BL-2 rule) | BL-2 guard not preserved |
| **TC-LOGIC-02** | Criterion with `isCcp=true` has `'isCcp': true` in output | CCP flag lost |
| **TC-LOGIC-03** | `isRequired=false` + `confirmCorrect=true` → `isRequired: true` in output | confirmCorrect override lost |
| **TC-SIZE-01** | `template_builder_page_logic.dart` line count drops below 320 lines after migration | Duplication not removed |
| **TC-TDD-01** | Unit tests for `buildGroupsPayload` and `buildCriterionPayload` exist in `test/features/templates/utils/template_payload_mapper_test.dart` | No test file |

---

## Test Fixture & Payloads
### Fixture: Minimal Template Tree for Unit Tests
```dart
// Section with one criterion — no sub-sections
final section = EditableGroup(title: 'Food Safety');
section.titleCtrl.text = 'Food Safety';
section.weightCtrl.text = '0.5';
section.id = 'grp-1';

final crit = EditableCriterion();
crit.labelCtrl.text = 'Temp check';
crit.inputType = 'pass_fail';
crit.pointsCtrl.text = '10';
crit.id = 'crit-1';
section.criteria.add(crit);
```

### Expected JSON shape (isEditMode: true)
```json
{
  "id": "grp-1",
  "title": "Food Safety",
  "weight": 0.5,
  "orderIndex": 0,
  "children": [],
  "criteria": [
    {
      "id": "crit-1",
      "label": "Temp check",
      "inputType": "pass_fail",
      "pointsWeight": 10.0,
      "isCcp": false,
      "isRisk": false,
      "orderIndex": 0
    }
  ]
}
```

### Expected JSON shape (isEditMode: false — wizard create)
Same as above but `"id"` key absent from both group and criterion.

---

## Tools & Commands
- **Skill**: None required (pure refactoring + unit test authoring).
- **Unit Test Command**: `rtk flutter test test/features/templates/utils/template_payload_mapper_test.dart`
- **Regression Test Command**: `rtk flutter test test/features/templates/`
- **Dead Code Confirmation**: `grep_search` for `builder_payload_mapper` after Phase 1.

---

## Proposed Changes
| Action | File | Description |
|---|---|---|
| **DEL** | `lib/features/templates/utils/builder_payload_mapper.dart` | Dead code — zero external callers |
| **NEW** | `lib/features/templates/utils/template_payload_mapper.dart` | Canonical mapper: `buildGroupsPayload()`, `buildCriterionPayload()`, `buildScoringLogicConfig()` |
| **NEW** | `test/features/templates/utils/template_payload_mapper_test.dart` | Unit tests for all 3 functions |
| **MOD** | `lib/features/templates/pages/template_builder_page_logic.dart` | Replace `_buildGroupsRecursive`, `_buildGroups`, `_buildScoringConfig` with calls to canonical mapper. Import new util. |
| **MOD** | `lib/features/templates/pages/wizard_payload_builder.dart` | Remove duplicated functions; re-export or delete file entirely. Only `buildScoringLogicConfig` call must be updated. |
| **MOD** | `lib/features/templates/pages/template_wizard_page.dart` | Update import from `wizard_payload_builder` → `template_payload_mapper`, pass `isEditMode: false`. |

---

## Concept Diagram
```text
BEFORE (3 implementations):

builder_payload_mapper.dart  ─── DEAD (never imported)
        │ buildGroupsPayload()     — full fields, no callers

wizard_payload_builder.dart  ─── imported by template_wizard_page.dart
        │ buildCriterion()         — MISSING: id
        │ buildGroupsRecursive()   — MISSING: id, weight, maxDeduct, metadata
        │ buildScoringLogicConfig()

template_builder_page_logic.dart ─── part-of template_builder_page.dart
        │ _buildGroupsRecursive()  — full fields (canonical shape)
        │ _buildScoringConfig()    — identical JSON to above


AFTER (1 canonical implementation):

utils/template_payload_mapper.dart  ─── canonical source of truth
        │ buildGroupsPayload(groups, confirmCorrect, isEditMode)
        │ buildCriterionPayload(c, index, confirmCorrect, isEditMode)
        │ buildScoringLogicConfig(...)

template_wizard_page.dart  ─── calls buildGroupsPayload(isEditMode: false)
template_builder_page_logic.dart  ─── calls buildGroupsPayload(isEditMode: true)
```

---

## Execution Slices

### Slice 1: Write Unit Tests for Canonical Mapper
- **Complexity**: Medium — must cover all BL rules (pointsWeight gate, isRequired override, CCP/Risk, isEditMode branch, scoring config).
- **Value Delivered**: Proves the contract before any migration. Acts as regression guard.
- **Entry State**: No `template_payload_mapper.dart` or its test exists yet. All template tests pass (87 tests, exit 0).
- **Exit State**: `test/features/templates/utils/template_payload_mapper_test.dart` exists and covers TC-SHAPE-01, TC-WIZARD-01, TC-LOGIC-01/02/03. Tests are **RED** because the mapper doesn't exist yet.
- **Scope**: New test file ONLY. No production code changes.
- **Acceptance Criteria**:
  1. Test file exists at `test/features/templates/utils/template_payload_mapper_test.dart`.
  2. Tests are RED (`dart compile` shows import error for non-existent mapper).
  3. All 9 test contracts above are represented in the test file.

**Pros**: Ensures we never break BL rules silently.  
**Cons**: Requires creating the test before the code (correct TDD approach).

---

### Slice 2: Create Canonical Mapper + Delete Dead Code
- **Complexity**: Low — migrating from existing code, not writing new logic.
- **Value Delivered**: Single source of truth. TC-DEAD-01 passes. Tests turn GREEN.
- **Entry State**: Slice 1 complete. Tests are RED.
- **Exit State**: `utils/template_payload_mapper.dart` exists. `builder_payload_mapper.dart` is deleted. Tests are GREEN. `wizard_payload_builder.dart` still exists (not yet migrated).
- **Scope**: New `template_payload_mapper.dart` + delete `builder_payload_mapper.dart`. Do NOT touch callers yet.
- **Acceptance Criteria**:
  1. `rtk flutter test test/features/templates/utils/template_payload_mapper_test.dart` → ✅ all green.
  2. `builder_payload_mapper.dart` file no longer exists.
  3. `template_builder_page_logic.dart` and `template_wizard_page.dart` UNCHANGED (callers migrate in Slice 3).

---

### Slice 3: Migrate Callers + Delete Wizard Payload Builder
- **Complexity**: Low — update two import sites and three call sites.
- **Value Delivered**: `wizard_payload_builder.dart` deleted. `template_builder_page_logic.dart` shrinks by ~80 lines (from 395 to ~315). TC-REGRESSION-01 and TC-SIZE-01 pass.
- **Entry State**: Slice 2 complete. Canonical mapper exists and is tested.
- **Exit State**: Both pages use `template_payload_mapper.dart`. `wizard_payload_builder.dart` deleted. All 87+ template tests pass.
- **Scope**: `template_builder_page_logic.dart`, `template_wizard_page.dart`, delete `wizard_payload_builder.dart`.
- **Acceptance Criteria**:
  1. `rtk flutter test test/features/templates/` passes with 0 failures.
  2. `wizard_payload_builder.dart` file no longer exists.
  3. `template_builder_page_logic.dart` is under 320 lines.
  4. No remaining references to `wizard_payload_builder` or `builder_payload_mapper`.

---

## Risk Assessment
- **Risk**: Medium. The save path for both the Template Builder and Template Wizard is touched. A mistake here silently sends wrong payloads to the backend.
- **Mitigation**: Unit tests in Slice 1 lock in the BL rules before any migration happens. Run full test suite after each slice.

---

<command_logs>
- `grep_search buildGroupsPayload in /lib` → only found in builder_payload_mapper.dart itself (dead code confirmed)
- `grep_search buildGroupsRecursive in /templates` → found in wizard_payload_builder.dart and template_builder_page_logic.dart
- `grep_search wizard_payload_builder in /lib` → only template_wizard_page.dart imports it
- `grep_search builder_payload_mapper in /lib` → zero results (dead code confirmed)
- `rtk flutter test test/features/templates/` → ✅ 87 tests, exit 0 (baseline)
- `view_file builder_payload_mapper.dart` → confirmed dead, full fields (88 lines)
- `view_file wizard_payload_builder.dart` → confirmed live, missing fields (99 lines)
- `view_file template_builder_page_logic.dart L1-150` → confirmed canonical shape with id/weight/metadata fields
</command_logs>

---

## Verification Plan
After each slice, run the following commands and verify all pass before proceeding:

**After Slice 1 (tests written, should be RED):**
```bash
rtk flutter test test/features/templates/utils/template_payload_mapper_test.dart
# Expected: FAIL (mapper file does not exist yet)
```

**After Slice 2 (mapper created):**
```bash
rtk flutter test test/features/templates/utils/template_payload_mapper_test.dart
# Expected: all tests GREEN
```

**After Slice 3 (callers migrated):**
```bash
rtk flutter test test/features/templates/
# Expected: all 87+ tests pass, exit 0
```

Additionally, confirm with `grep_search`:
- Zero references to `builder_payload_mapper` anywhere in `/lib`.
- Zero references to `wizard_payload_builder` anywhere in `/lib` after Slice 3.

---

## Handoff Block
Execute slices **ONE AT A TIME** in order. Slice 2 cannot start until Slice 1 tests are written. Slice 3 cannot start until Slice 2 tests are green.

- **Slice 1**: Write Unit Tests → RED (no production code yet). No build. Just tests.
- **Slice 2**: Build Phase (create `template_payload_mapper.dart`, delete `builder_payload_mapper.dart`) → Run tests → GREEN.
- **Slice 3**: Build Phase (migrate callers, delete `wizard_payload_builder.dart`) → Run full template suite → GREEN.

**Absolute Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260522_171800_tdup1_template_serialization_dedup.md`
