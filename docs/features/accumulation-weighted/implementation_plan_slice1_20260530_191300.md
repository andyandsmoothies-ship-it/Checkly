<latent_space_scratchpad>
## Key Facts Found in Code

### ScoringInput (scoring_input.dart)
- Has: sections, answers, progressiveRepeatPenalty, scoringMode, hasGlobalRisk
- MISSING: `isWeighted` field — this is the root cause.
- The mapper reads `config['isWeighted']` (line 130) but only uses it for 'down' direction.
  For 'up' direction it's silently dropped.

### ScoringInputMapper.parseScoringMode() — lines 132–138
- `scoreDirection == 'up'` → always returns `ScoringMode.accumulation` (no isWeighted check)
- `scoreDirection == 'down' + isWeighted` → returns `ScoringMode.penalty`
- Shape B requires: 'up' STAYS as `ScoringMode.accumulation` but we add `isWeighted` field
  to ScoringInput so the engine can branch inside the `accumulation` case.

### scoring_engine.dart — lines 94–107
- Dispatch switch: `case ScoringMode.accumulation:` routes to AccumulationCalculator.calculate()
- No isWeighted check here — we need to add it.

### PenaltyCalculator.calculate() — the exact pattern to mirror
- Line 23–27: Sums totalWeight from sections
- Line 27: `final isWeighted = totalWeight > 0;`
- Lines 29–163: if (isWeighted) → weighted path using section.weight
- Weighted math (lines 141–154):
  - Builds `sectionResults` list of (ratio, weight) tuples
  - `participatingWeight` = sum of all section weights
  - `finalScore` = Σ(ratio × weight / participatingWeight)
  - score = finalScore × 100

### WeightedAccumulationCalculator math
MIRRORS PenaltyCalculator weighted path BUT:
- Instead of `sectionAfter / sectionBefore` (penalty ratio), use `sectionEarned / sectionPossible`
- No deduction logic — sections EARN forward, not deduct backward
- CCP: zeroes out sectionEarned (same as AccumulationCalculator line 68-70)
- Risk: hasRiskFailure → totalScore = 0 (same as AccumulationCalculator line 88)
- If totalWeight == 0: fallback to AccumulationCalculator (same as PenaltyCalculator → ChecklistCalculator)

### Edge Cases to Test
1. Happy path: Section A (8/10 pts, weight=60), Section B (5/10 pts, weight=40)
   = (0.8×60 + 0.5×40) / (60+40) × 100 = (48+20)/100 × 100 = 68.0%
2. CCP triggered in section A: sectionEarned = 0, ratio = 0, weight STILL counts in denominator
   = (0×60 + 0.5×40)/100 × 100 = 20.0%
3. Risk failure: hasRiskFailure = true → totalScore = 0.0
4. Zero weights: WeightedAccumulationCalculator.totalWeight == 0 → AccumulationCalculator fallback
5. Single section perfect score: 1 section, all earned → 100%

### Files to Modify
1. [NEW] lib/_shared/services/weighted_accumulation_calculator.dart
2. [MOD] lib/_shared/services/scoring_input.dart — add `isWeighted` field
3. [MOD] lib/_shared/services/scoring_engine.dart — split accumulation dispatch arm
4. [MOD] lib/features/audit/services/scoring_input_mapper.dart — pass isWeighted for 'up'

### Test File
5. [NEW] test/unit/weighted_accumulation_calculator_test.dart

### File Line Count Check
- scoring_input.dart: 23 lines ✅
- scoring_engine.dart: 110 lines ✅
- scoring_input_mapper.dart: 227 lines (under 250 — no split needed) ✅
- accumulation_calculator.dart: 97 lines ✅
- penalty_calculator.dart: 166 lines ✅

All 5 files are within the 4-file rule for Slice 1 (4 prod files + 1 test file).
</latent_space_scratchpad>

# Implementation Plan — Slice 1: WeightedAccumulationCalculator (Flutter)

**Plan ID**: ACCUM-WEIGHTED-SLICE1  
**Created**: 2026-05-30  
**Conversation ID**: a684dd5f-1b02-4247-86c8-ad87256b90e1  
**Status**: READY FOR TDD

---

## Input Lineage

- **Source Epic**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\analysis_epic_20260530_172200.md`
- **Predecessor Analysis**: Scoring Redesign Epic `analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`

---

## Executive Summary & Out of Scope

**Goal**: Implement the Flutter-side weighted accumulation calculator. This is the math engine for the new scoring mode. All other slices (C# mirror, ScoreFormatter, UI unlock, HeaderCard) depend on this slice being correct first.

**What changes**:
1. `ScoringInput` gains a new `isWeighted` field (defaults to `false` — zero blast radius on existing callers).
2. `ScoringInputMapper.parseScoringMode()` starts reading `isWeighted` for the `'up'` direction and passing it into `ScoringInput`.
3. `ScoringEngine.calculate()` splits the `accumulation` dispatch arm: if `input.isWeighted == true`, dispatch to new `WeightedAccumulationCalculator`; otherwise keep existing `AccumulationCalculator`.
4. New file `WeightedAccumulationCalculator` implements `Σ(sectionEarned/sectionPossible × weight/totalWeight) × 100`.

**Out of Scope (YAGNI)**:
- `ScoreFormatter` changes (Slice 3)
- Template Builder UI toggle unlock (Slice 4)
- `HeaderCard` info row (Slice 5)
- C# backend mirror `VerifyAccumulationWeighted` (Slice 2)
- No new `ScoringMode` enum values — Shape B (flag check, no enum change)

---

## System Context

| Constraint | Detail |
|---|---|
| Offline-First | Flutter calculates before server verifies. This calculator runs entirely on-device. |
| Sync | `isWeighted` is already stored in `scoringLogicConfig` JSON on the template. No schema change needed. |
| RBAC | No change. Calculator receives no user identity. |
| API Contract | Output `ScoringResult` shape is unchanged. Server (Slice 2) will mirror this math. |
| Static Class | `WeightedAccumulationCalculator` is a static class — no DI registration required. |
| Shape B | `ScoringMode` enum is unchanged. `isWeighted` flag on `ScoringInput` controls dispatch. |

---

## Lifecycle Context — 4-State Matrix

| State | Behavior |
|---|---|
| **Success** | `totalScore` is a `double` (0.0–100.0, rounded to 2dp) |
| **Loading** | N/A — pure synchronous calculation |
| **Error** | `hasGlobalRisk = true` → `totalScore = 0.0` forced by engine BEFORE calculator is called |
| **Empty / Suppressed** | Purity gate (engine) → `totalScore = null`. Zero weights → fallback to `AccumulationCalculator` |

---

## Constraint Traceability

| Constraint (from Epic) | Source | Test Contract ID |
|---|---|---|
| Weighted math: Σ(sectionEarned/sectionPossible × weight/totalWeight) × 100 | R1 | TC-01 |
| Unweighted accumulation math stays unchanged | R2 | TC-07 |
| isWeighted flag must be carried through ScoringInput | Risk 1 | TC-01 |
| Old accumulation templates (no isWeighted) default to false | Lifecycle | TC-07 |
| CCP zeroes sectionEarned, weight STILL counts in denominator | Epic Edge Case | TC-03 |
| Risk failure → totalScore = 0.0 | Epic Edge Case | TC-04 |
| Zero total section weights → fallback to AccumulationCalculator | PenaltyCalculator pattern | TC-05 |
| parseScoringMode('up') must now pass isWeighted | Risk 1 / Mapper line 134 | TC-06 |
| ScoringInput.isWeighted defaults to false — backward compat | Risk 1 mitigation | TC-07 |

---

## Test Contracts

### TC-01: Happy Path — Two sections, weighted score

**Description**: Section A earns 8/10 pts (weight=60), Section B earns 5/10 pts (weight=40).  
**Expected**: `(0.8 × 60 + 0.5 × 40) / 100 × 100 = 68.0%`  
**Why first**: This proves the core formula is correct before edge cases.

```
Fixture:
  sections: [
    { id: 'sec-a', weight: 60, criteria: [{ pts: 10, earned: 8 }] },
    { id: 'sec-b', weight: 40, criteria: [{ pts: 10, earned: 5 }] },
  ]
  answers: all correct for earned values
  isWeighted: true
Expected totalScore: 68.0
```

### TC-02: Perfect Score

**Description**: All criteria answered perfectly. Expected: 100.0.

```
Fixture:
  sections: [
    { weight: 70, criteria: [{ pts: 10, earned: 10 }] },
    { weight: 30, criteria: [{ pts: 10, earned: 10 }] },
  ]
  isWeighted: true
Expected totalScore: 100.0
```

### TC-03: CCP Triggered — Section Zeroed but Weight Counts

**Description**: CCP triggered in Section A. Its earned = 0, but its weight (60) still participates in the denominator.  
**Expected**: `(0 × 60 + 0.5 × 40) / 100 × 100 = 20.0%`  
**Why critical**: If CCP section is excluded from denominator, score inflates falsely. Mirrors PenaltyCalculator CCP behavior.

```
Fixture:
  sections: [
    { id: 'sec-a', weight: 60, criteria: [{ pts: 10, isCcp: true }] },
    { id: 'sec-b', weight: 40, criteria: [{ pts: 10, earned: 5 }] },
  ]
  answers: sec-a criterion answered with fault (triggers CCP)
Expected totalScore: 20.0
```

### TC-04: Risk Failure — Total Score Forced to 0

**Description**: `hasRiskFailure = true` after engine risk check. Engine does NOT call calculator — already returns 0. This test verifies the engine's risk short-circuit correctly prevents calculator execution.

```
Fixture: same as TC-01 but a criterion has isRisk=true and is answered with a fault
Expected totalScore: 0.0, hasRiskFailure: true
```

### TC-05: Zero Section Weights — Falls Back to Unweighted Accumulation

**Description**: All section weights are 0. `WeightedAccumulationCalculator` must detect `totalWeight == 0` and fall back to `AccumulationCalculator`.  
**Expected**: Unweighted score = `(8+5)/(10+10) × 100 = 65.0%`

```
Fixture: same as TC-01 but all section weights are 0.0
  isWeighted: true (flag is true, but weights are missing → fallback)
Expected totalScore: 65.0
```

### TC-06: ScoringInputMapper — Passes isWeighted for 'up' direction

**Description**: `parseScoringMode()` with `{scoreDirection:'up', isWeighted:true}` must produce a `ScoringInput` where `isWeighted == true`.  
This verifies the mapper gap (Risk 1) is closed.

```
Input config JSON: '{"scoreDirection":"up","isWeighted":true}'
Expected ScoringInput.isWeighted: true
Expected ScoringInput.scoringMode: ScoringMode.accumulation
```

### TC-07: Backward Compat — Old Templates with No isWeighted Still Use Unweighted Accumulation

**Description**: Config `{scoreDirection:'up'}` (no isWeighted key) → `isWeighted` defaults to `false` → dispatches to `AccumulationCalculator`.  
**Expected**: Same result as current unweighted calculation.

```
Input config JSON: '{"scoreDirection":"up"}'
Expected ScoringInput.isWeighted: false
Expected dispatch: AccumulationCalculator (existing behavior, no regression)
```

---

## Test Fixture & Payloads

### Base Fixture (used by TC-01, TC-03, TC-05)

```dart
// Section A: weight=60, one criterion worth 10 pts
final sectionA = SectionInput(
  id: 'sec-a',
  weight: 60,
  criteria: [
    CriterionInput(id: 'c1', groupId: 'sec-a', pointsWeight: 10,
                   isCcp: false, isRisk: false, inputType: 'pass_fail'),
  ],
);
// Section B: weight=40, one criterion worth 10 pts
final sectionB = SectionInput(
  id: 'sec-b',
  weight: 40,
  criteria: [
    CriterionInput(id: 'c2', groupId: 'sec-b', pointsWeight: 10,
                   isCcp: false, isRisk: false, inputType: 'pass_fail'),
  ],
);
// Answers: c1 earns 8pts (value='pass', 0 faults) → not correct, adjusted:
// Actually for pass_fail: no faults = earns full pointsWeight.
// To earn 8/10, use scale type: numericValue=8.
// To earn 5/10: numericValue=5 on scale.
final answers = [
  AnswerInput(criteriaId: 'c1', numericValue: 8, value: null), // scale, earns 8
  AnswerInput(criteriaId: 'c2', numericValue: 5, value: null), // scale, earns 5
];
// Change inputType to 'scale' for partial credit testing.
```

> **Note to Builder**: For `pass_fail` binary criteria, `earned = pointsWeight` (pass) or `0` (fail). Use `scale` inputType with `numericValue` for partial credit tests (TC-01, TC-03).

---

## Tools & Commands

| Tool | Purpose |
|---|---|
| `tdd` skill | Builder MUST write tests first (RED), then implement (GREEN) |
| `flutter test test/unit/weighted_accumulation_calculator_test.dart` | Run the new unit tests |
| `flutter test test/scoring_engine_test.dart` | Regression gate — must still be green after changes |
| `flutter test` (full) | Final gate before handoff |

**No `rtk` prefix needed for Flutter test commands** (Flutter test runner).  
**Windows**: `cmd /c rtk flutter test test/unit/weighted_accumulation_calculator_test.dart`

---

## Proposed Changes

Build order: **Model → Mapper → Engine → New Calculator → Tests**

| Order | Action | File | Reason |
|---|---|---|---|
| 1 | [MOD] | `lib/_shared/services/scoring_input.dart` | Add `isWeighted` field (default: `false`) |
| 2 | [MOD] | `lib/features/audit/services/scoring_input_mapper.dart` | Pass `isWeighted` for `scoreDirection == 'up'` |
| 3 | [MOD] | `lib/_shared/services/scoring_engine.dart` | Split `accumulation` dispatch arm: `isWeighted ? WeightedAccumulationCalculator : AccumulationCalculator` |
| 4 | [NEW] | `lib/_shared/services/weighted_accumulation_calculator.dart` | New calculator: weighted accumulation math |
| 5 | [NEW] | `test/unit/weighted_accumulation_calculator_test.dart` | Unit tests: TC-01 through TC-07 |

---

## Concept Diagram

```
[ScoringInputMapper.fromTemplate()]
  reads scoringLogicConfig JSON
  scoreDirection='up' + isWeighted=true
         |
         v
[ScoringInput] {scoringMode: accumulation, isWeighted: true}
         |
         v
[ScoringEngine.calculate()]
  switch(scoringMode):
    case accumulation:
      if (input.isWeighted)
         |
         +--> [NEW] WeightedAccumulationCalculator.calculate()
              for each section:
                ratio = sectionEarned / sectionPossible
                result += ratio * (weight / totalWeight)
              finalScore = result * 100
         |
      else
         +--> [EXISTING] AccumulationCalculator.calculate()
              (no change)
         |
         v
[ScoringResult] { totalScore: 68.0, sectionScores: {...} }
```

---

## Execution Slices (Micro-Specs)

### Slice 1 — Unified Weighted Accumulation Engine

**Summary**: Implement the new `WeightedAccumulationCalculator` and wire the `isWeighted` flag from the mapper through the engine dispatch.
**Scenario Focus**: Basic Scenario + Core Math Edge Cases.
**Value**: Flutter can seamlessly calculate weighted accumulation offline based on template config.
**Entry State**: `isWeighted` flag is ignored for 'up' scoring. Engine lacks weighted accumulation dispatch.
**Exit State**: Engine correctly routes to the new calculator and mathematically computes all test contracts.
**Architectural Scope**: Flutter Domain (Model, Mapper, Engine, Calculator).

**Acceptance Criteria**:
- TC-01: `68.0%` for the two-section fixture
- TC-02: `100.0%` for perfect score
- TC-03: `20.0%` for CCP-triggered section (zeroed but weight counts)
- TC-04: `0.0` + `hasRiskFailure: true` for risk failure
- TC-05: Fallback to `AccumulationCalculator` when all weights = 0
- TC-06: Mapper passes `isWeighted: true` when config has `{scoreDirection:'up', isWeighted:true}`
- TC-07: Mapper defaults `isWeighted: false` (no regression)

---

## Handoff Block

**Absolute Plan Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice1_20260530_191300.md`

**Route**: Route 2 — Unit Tests First (internal logic math, medium testing risk)

**Execution sequence**:

```
Slice 1 (Unified):
  1. [QA]      Write all unit tests (TC-01 through TC-07) in the new test file → verify RED
  2. [Builder] Implement ScoringInput, Mapper, Engine Dispatch, and WeightedAccumulationCalculator
  3. [Verify]  Run `flutter test` → ALL GREEN
```

**Do NOT start Slice 2 (C# backend) until ALL tests in Slice 1 are GREEN.**

---

<command_logs>
- view_file: accumulation_calculator.dart (97 lines) — confirmed unweighted math
- view_file: scoring_engine.dart (110 lines) — confirmed dispatch at lines 94–107
- view_file: penalty_calculator.dart (166 lines) — confirmed weighted math pattern to mirror
- view_file: scoring_input.dart (23 lines) — confirmed MISSING isWeighted field (root cause)
- view_file: scoring_input_mapper.dart (227 lines) — confirmed isWeighted dropped for 'up' at line 134
- view_file: section_input.dart (20 lines) — confirmed weight field exists on SectionInput
- view_file: scoring_mode.dart (3 lines) — confirmed Shape B: no enum change needed
- view_file: scoring_engine_test.dart (156 lines) — confirmed test pattern and fixture structure
- list_dir: test/ — confirmed test/unit/ exists as home for new test file
- grep_search: test/ for AccumulationCalculator — no existing test file (new file needed)
</command_logs>
