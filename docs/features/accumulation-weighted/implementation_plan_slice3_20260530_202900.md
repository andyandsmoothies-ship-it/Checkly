<latent_space_scratchpad>
## What the Bug Looks Like Today

### Current `format()` logic for `accumulation` (lines 15–20):
```
if (scoringMode == 'accumulation') {
  if (rawEarned != null && rawMax != null && !shortForm) {
    return '${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} pts';  // BUG: pts as primary
  }
  return totalScore != null ? _fmtPct(totalScore) : '—';
}
```
→ Long form (header): "100 / 110 pts"  ← PRIMARY = POINTS (wrong)
→ Short form (list):  "80"             ← just a number, no % sign

### Target output (all 4 modes consistent):
```
Accumulation OFF (shortForm=false): "80% (100 / 110 raw pts)"  ← % is primary
Accumulation OFF (shortForm=true):  "80%"                      ← % with sign
Accumulation ON  (shortForm=false): "80% (100 / 110 raw pts)"  ← same
Accumulation ON  (shortForm=true):  "80%"                      ← same
```

### Penalty (isWeighted=true) current behavior — this is the TARGET pattern:
```
penalty + isWeighted=true + shortForm=false: "80% (100 / 110 raw pts)"
penalty + isWeighted=false + shortForm=false: "80%"  (no raw pts secondary)
penalty + shortForm=true: "80%"
```

### What needs to change in accumulation branch:
1. shortForm=true  → `_fmtPct(totalScore) + '%'` (add % sign for consistency)
   Wait — check _fmtPct: it returns the number WITHOUT a % sign. "80" not "80%"
   But penalty branch returns `_fmtPct(totalScore)` too, which is just "80"
   So the AuditCard shows "80" from penalty — it's styled separately.
   → Do NOT add % sign to _fmtPct output (matches penalty behavior)
   
2. shortForm=false → `'${_fmtPct(totalScore)}% (${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} raw pts)'`
   BUT only when rawEarned and rawMax are available.
   If not available (old data without raw points): `'${_fmtPct(totalScore)}%'`
   
3. For BOTH isWeighted=true AND isWeighted=false for accumulation:
   Epic doc R5: "ScoreFormatter shows percentage as primary for Accumulation (both OFF and ON)"
   Epic doc R6: "ScoreFormatter shows raw pts secondary for Accumulation (Switch ON)"
   So: Accumulation OFF (isWeighted=false) → only % in long form (no secondary raw pts)
       Accumulation ON  (isWeighted=true)  → % primary + raw pts secondary in long form

Actually let me re-read the epic target comparison more carefully:
```
📈 Accumulation (Switch OFF) → Primary: 80%  Secondary: (100 / 110 raw pts)
⚖️ Accumulation (Switch ON)  → Primary: 80%  Secondary: (100 / 110 raw pts)
```
Both show raw pts secondary! R6 says "raw pts secondary for Accumulation (Switch ON)"
but the visual shows BOTH have secondary. I'll trust the visual (line 157-158 of epic).

So: long form for accumulation ALWAYS shows raw pts if available (same as penalty weighted).

### _fmtPct output analysis
`_fmtPct(80.0)` → "80" (whole number, no decimal)
`_fmtPct(80.5)` → "80.5"
The % sign is appended by the format() string: `'${_fmtPct(totalScore)}%'`
Penalty branch (line 32): `'${_fmtPct(totalScore)}% (${_fmtPts(...)} / ${_fmtPts(...)} raw pts)'`
→ So "80% (100 / 110 raw pts)" — the % IS added by the caller.
In penalty's shortForm (line 34): `return _fmtPct(totalScore);` — returns "80" (no %)
This is correct — list callers just show "80" styled in a circle, no % needed.

### NEW accumulation branch:
```dart
if (scoringMode == 'accumulation') {
  if (totalScore == null) return '—';
  if (!shortForm && rawEarned != null && rawMax != null) {
    return '${_fmtPct(totalScore)}% (${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} raw pts)';
  }
  return _fmtPct(totalScore);  // shortForm OR no raw data → just "80"
}
```

Wait, shortForm=false but no rawEarned/rawMax: return `_fmtPct(totalScore)` just as "80"?
That's missing the % sign. In the header (shortForm=false, no raw data), we still want "80%".
Penalty branch line 34 does: `return _fmtPct(totalScore);` → "80" (no %)
But penalty shortForm is line 34 only when isWeighted is false...

Actually re-reading penalty:
```
if (!shortForm && isWeighted == true && rawEarned != null && rawMax != null) {
  return '${_fmtPct(totalScore)}% (${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} raw pts)';
}
return _fmtPct(totalScore);  // catches shortForm=true AND isWeighted=false long form
```
Penalty longForm+isWeighted=false returns "80" (no %). That's inconsistent but it's existing behavior.

For ACCUMULATION, we're fixing the display. Epic says % is primary.
For accumulation:
- shortForm=true: return `_fmtPct(totalScore)` → "80" (list badge, styled separately, no %)
- shortForm=false, rawEarned + rawMax available: return `'${_fmtPct(totalScore)}% (${...} / ${...} raw pts)'`
- shortForm=false, no raw data: return `'${_fmtPct(totalScore)}%'` → "80%"

This matches the epic target perfectly. Let me define the test cases.

## Test Matrix (8 cases per epic line 274)

| ID | scoringMode | isWeighted | shortForm | rawEarned | rawMax | totalScore | Expected |
|----|-------------|------------|-----------|-----------|--------|------------|----------|
| T1 | accumulation | false | false | 100 | 110 | 80 | "80% (100 / 110 raw pts)" |
| T2 | accumulation | true  | false | 100 | 110 | 80 | "80% (100 / 110 raw pts)" |
| T3 | accumulation | false | true  | 100 | 110 | 80 | "80" |
| T4 | accumulation | true  | true  | 100 | 110 | 80 | "80" |
| T5 | accumulation | false | false | null | null | 80 | "80%" |
| T6 | accumulation | false | false | null | null | null | "—" |
| T7 | accumulation | false | false | 50.5 | 110 | 45.9 | "45.9% (50.5 / 110 raw pts)" |
| T8 | accumulation | false | false | 100 | 100 | 100 | "100% (100 / 100 raw pts)" |

## Regression cases (penalty must be unchanged):
| T9  | penalty | true | false | 100 | 110 | 80 | "80% (100 / 110 raw pts)" |
| T10 | penalty | false | false | null | null | 80 | "80" |
| T11 | checklist | - | false | null | null | 80 | "80 / 100 pts" |
| T12 | survey | - | - | null | null | null | "—" |

## Files
- [MOD] lib/features/audit/utils/score_formatter.dart (45 lines → ~50 lines) ✅ under 250
- [NEW] test/unit/score_formatter_test.dart
No callers need to change — ScoreFormatter API is unchanged (same parameters).
</latent_space_scratchpad>

# Implementation Plan — Slice 3: ScoreFormatter Fix (% Primary for All Modes)

**Plan ID**: ACCUM-WEIGHTED-SLICE3
**Created**: 2026-05-30
**Conversation ID**: a684dd5f-1b02-4247-86c8-ad87256b90e1
**Status**: READY FOR TDD

---

## Input Lineage

- **Source Epic**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\analysis_epic_20260530_172200.md`
- **Predecessor Plans**:
  - Slice 1: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice1_20260530_191300.md`
  - Slice 2: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice2_20260530_193000.md`

---

## Executive Summary & Out of Scope

**Goal**: Fix `ScoreFormatter.format()` so that `scoringMode == 'accumulation'` returns **percentage as the primary display** — matching the other 3 scoring modes. Currently, the long-form (header) returns `'100 / 110 pts'` instead of `'80%'`.

**In Scope**:
- Rewrite the `accumulation` branch inside `score_formatter.dart`.
- New unit test file: `test/unit/score_formatter_test.dart`.

**Out of Scope**:
- No changes to any caller (5 callers use the same parameters — the API contract is unchanged).
- No changes to `checklist`, `penalty`, or `survey` branches.
- No backend/C# changes.
- No widget/UI layout changes.

---

## System Context

| Constraint | Detail |
|---|---|
| Pure Dart utility | `ScoreFormatter` has zero Flutter/widget dependencies. Tests run without a widget tree — no `testWidgets`, just `test`. |
| Caller API unchanged | All 5 callers pass the same named parameters. The fix is internal to `format()`. No cascading changes. |
| Offline-first | `ScoreFormatter` is called with data already on-device. No network dependency. |

---

## Lifecycle Context (4-State Matrix)

| State | Behavior |
|---|---|
| **Success** | `totalScore != null` → formatted string with `%` as primary. |
| **Loading** | Not applicable — formatter is pure/sync. |
| **Empty** | `totalScore == null` → returns `'—'`. |
| **Error** | No error state. Null inputs safely return `'—'`. |

---

## Constraint Traceability

| Epic Constraint | Test Contract |
|---|---|
| R5: ScoreFormatter shows `%` as primary for Accumulation (both OFF and ON) | TC-01, TC-02, TC-03, TC-04 |
| R6: ScoreFormatter shows `raw pts` secondary for Accumulation (Switch ON) | TC-02 (isWeighted=true, long form) |
| R7: No penalty/checklist math changed | TC-09, TC-10, TC-11, TC-12 (regression) |
| Long form with rawEarned + rawMax → show secondary raw pts | TC-01, TC-02, TC-07, TC-08 |
| No rawEarned/rawMax available → show `%` only | TC-05 |
| `totalScore == null` → show `'—'` | TC-06 |
| Decimal scores formatted to 1 dp | TC-07 |

---

## Test Contracts

All tests are **pure unit tests** — no `testWidgets`, no widget tree.

### TC-01: Accumulation OFF — Long Form with Raw Points
**Input**: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:100, rawMax:110, totalScore:80`
**Expected**: `'80% (100 / 110 raw pts)'`
**Why it fails today**: current code returns `'100 / 110 pts'` (pts as primary).

### TC-02: Accumulation ON (Weighted) — Long Form with Raw Points
**Input**: `scoringMode:'accumulation', isWeighted:true, shortForm:false, rawEarned:100, rawMax:110, totalScore:80`
**Expected**: `'80% (100 / 110 raw pts)'`
**Why it fails today**: same as TC-01.

### TC-03: Accumulation OFF — Short Form (List Badge)
**Input**: `scoringMode:'accumulation', isWeighted:false, shortForm:true, rawEarned:100, rawMax:110, totalScore:80`
**Expected**: `'80'`
**Why it may pass today**: current short form returns `_fmtPct(totalScore)` = `'80'`. This case may already be correct — but must be asserted to prevent regression.

### TC-04: Accumulation ON — Short Form (List Badge)
**Input**: `scoringMode:'accumulation', isWeighted:true, shortForm:true, rawEarned:100, rawMax:110, totalScore:80`
**Expected**: `'80'`
**Why**: same as TC-03.

### TC-05: Accumulation — Long Form, No Raw Data Available
**Input**: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:null, rawMax:null, totalScore:80`
**Expected**: `'80%'`
**Why it fails today**: current code returns `_fmtPct(totalScore)` = `'80'` (no `%` sign added).

### TC-06: Accumulation — Null Score → Dash
**Input**: `scoringMode:'accumulation', totalScore:null`
**Expected**: `'—'`
**Why**: guard for missing data.

### TC-07: Accumulation — Decimal Score, Decimal Raw Points
**Input**: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:50.5, rawMax:110, totalScore:45.9`
**Expected**: `'45.9% (50.5 / 110 raw pts)'`
**Why**: verify `_fmtPts` and `_fmtPct` decimal handling is applied correctly to both values.

### TC-08: Accumulation — Perfect Score
**Input**: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:100, rawMax:100, totalScore:100`
**Expected**: `'100% (100 / 100 raw pts)'`
**Why**: whole numbers render without decimals.

### TC-09 (Regression): Penalty + Weighted + Long Form — Unchanged
**Input**: `scoringMode:'penalty', isWeighted:true, shortForm:false, rawEarned:100, rawMax:110, totalScore:80`
**Expected**: `'80% (100 / 110 raw pts)'`
**Why**: prove the penalty branch is not touched.

### TC-10 (Regression): Penalty + Unweighted + Long Form — Unchanged
**Input**: `scoringMode:'penalty', isWeighted:false, shortForm:false, rawEarned:null, rawMax:null, totalScore:80`
**Expected**: `'80'`
**Why**: existing penalty unweighted behavior preserved.

### TC-11 (Regression): Checklist — Long Form Unchanged
**Input**: `scoringMode:'checklist', shortForm:false, totalScore:80`
**Expected**: `'80 / 100 pts'`
**Why**: checklist format must not change.

### TC-12 (Regression): Survey — Always Dash
**Input**: `scoringMode:'survey'`
**Expected**: `'—'`
**Why**: survey short-circuit must not be broken.

---

## Test Fixture & Payloads

No fixture setup needed — all inputs are primitive values passed directly to `ScoreFormatter.format()`.

```dart
// Example test shape — pure Dart, no testWidgets
import 'package:flutter_test/flutter_test.dart';
import 'package:checkly/features/audit/utils/score_formatter.dart';

void main() {
  group('ScoreFormatter — accumulation branch', () {
    test('TC-01: long form, raw data → % primary', () {
      final result = ScoreFormatter.format(
        scoringMode: 'accumulation',
        isWeighted: false,
        shortForm: false,
        rawEarned: 100,
        rawMax: 110,
        totalScore: 80,
      );
      expect(result, '80% (100 / 110 raw pts)');
    });
    // ... TC-02 through TC-08
  });

  group('ScoreFormatter — regression', () {
    // TC-09 through TC-12
  });
}
```

---

## Tools & Commands

- **No skill required** — this is a pure Dart utility file.
- **Test command**: `cmd /c rtk flutter test test/unit/score_formatter_test.dart`
- **Full regression**: `cmd /c rtk flutter test`

---

## Proposed Changes

| # | Action | File | Note |
|---|---|---|---|
| 1 | [NEW] | `test/unit/score_formatter_test.dart` | 12 test cases (TC-01 to TC-12) |
| 2 | [MOD] | `lib/features/audit/utils/score_formatter.dart` | Rewrite accumulation branch (~6 lines) |

**No other files change.** Callers (`header_card.dart`, `audit_card.dart`, `submission_row.dart`, `review_card.dart`, `audit_review_sheet.dart`, `audit_approval_page.dart`) pass the same parameters — API is unchanged.

---

## Concept Diagram

```text
ScoreFormatter.format(scoringMode, rawEarned, rawMax, totalScore, isWeighted, shortForm)
        |
        +---[survey]          → '—'
        |
        +---[accumulation]    (THIS IS THE FIX)
        |       |
        |       +-- totalScore == null       → '—'
        |       |
        |       +-- !shortForm + rawEarned + rawMax available
        |       |       → '${_fmtPct(totalScore)}% (${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} raw pts)'
        |       |
        |       +-- !shortForm + no rawEarned/rawMax
        |       |       → '${_fmtPct(totalScore)}%'
        |       |
        |       +-- shortForm = true
        |               → _fmtPct(totalScore)     (e.g. '80' — used in circular badge, styled)
        |
        +---[checklist]       → '${_fmtPts(totalScore)} / 100 pts'   (unchanged)
        |
        +---[penalty/other]   → penalty branch logic                  (unchanged)

CALLERS:
  AuditCard        shortForm=true  → '80'
  SubmissionRow    shortForm=true  → '80'
  ReviewCard       shortForm=true  → '80'
  HeaderCard       shortForm=false → '80% (100 / 110 raw pts)'   ← FIXED
  AuditApprovalPage shortForm=false→ '80% (100 / 110 raw pts)'   ← FIXED
```

---

## Execution Slice

### Slice 3 — ScoreFormatter Fix

**Summary**: Rewrite the 6-line `accumulation` branch in `score_formatter.dart`. Write 12 unit tests first.

**Value**: All 4 scoring modes show `%` as the primary display in audit headers and preview sheets. Users can directly compare Accumulation and Penalty audits side by side.

**Entry State Required**: Slice 1 (Flutter) and Slice 2 (C#) are green. This slice has no dependency on those — it's purely a display fix — but the epic sequences it after Slice 2 so the formatter can cover the new weighted accumulation output too.

**Exit State Guaranteed**: `score_formatter_test.dart` — all 12 cases pass. Full `flutter test` regression still green.

**Complexity**: Low — single file, pure function, no DI, no widget tree.

---

### Acceptance Criteria

- [ ] TC-01: `accumulation + longForm + rawData` → `'80% (100 / 110 raw pts)'`
- [ ] TC-02: `accumulation + isWeighted=true + longForm + rawData` → `'80% (100 / 110 raw pts)'`
- [ ] TC-03: `accumulation + shortForm` → `'80'`
- [ ] TC-04: `accumulation + isWeighted=true + shortForm` → `'80'`
- [ ] TC-05: `accumulation + longForm + no rawData` → `'80%'`
- [ ] TC-06: `accumulation + totalScore=null` → `'—'`
- [ ] TC-07: Decimal score + decimal raw pts → correctly formatted
- [ ] TC-08: Perfect score → `'100% (100 / 100 raw pts)'`
- [ ] TC-09: Penalty regression — unchanged
- [ ] TC-10: Penalty unweighted regression — unchanged
- [ ] TC-11: Checklist regression — unchanged
- [ ] TC-12: Survey regression — unchanged
- [ ] Full `flutter test` regression: no new failures

---

## ⚠️ Key Gotchas

1. **`_fmtPct` does NOT append `%`**: `_fmtPct(80.0)` returns `'80'`, not `'80%'`. The `%` sign must be appended explicitly in the format string: `'${_fmtPct(totalScore)}%'`.

2. **Short form = list badge**: Callers like `AuditCard` and `ReviewCard` use `shortForm: true`. They show the score in a styled circle — no `%` sign needed there. The short form must return just `_fmtPct(totalScore)` (e.g., `'80'`). Do NOT add `%` in short form.

3. **TC-03 and TC-04 may already pass**: The current code for `shortForm` in accumulation already falls through to `_fmtPct(totalScore)`. Write the tests anyway — they serve as regression guards.

4. **`isWeighted` flag does not change the display format for accumulation**: Both `isWeighted=true` and `isWeighted=false` show raw pts secondary in long form when available. The `isWeighted` flag only adds the ℹ️ info row in `HeaderCard` (Slice 5). `ScoreFormatter` itself treats them identically.

<command_logs>
- view_file: score_formatter.dart — confirmed bug at lines 15–20 (pts as primary for accumulation)
- grep_search: ScoreFormatter usages — found 5 call sites
- view_file: header_card.dart — confirmed shortForm=false (default) call
- view_file: audit_card.dart — confirmed shortForm=true call
- view_file: submission_row.dart — confirmed shortForm=true call
- view_file: review_card.dart — confirmed shortForm=true call
- list_dir: test/unit — confirmed no score_formatter_test.dart exists yet
- view_file: scoring_engine_test.dart — confirmed test pattern (pure Dart, no widget tree)
- view_file: analysis_epic_20260530_172200.md — confirmed R5, R6 requirements and visual target
</command_logs>

---

## Handoff Block

**Plan Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice3_20260530_202900.md`

**Route**: **Route 2 — Unit Tests First** (pure math/display logic, known pattern)

**Action Sequence** (execute ONE step at a time):

1. **Write Unit Tests (RED)** → Create `test/unit/score_formatter_test.dart` with TC-01 through TC-12. Run `flutter test test/unit/score_formatter_test.dart` → expect RED on TC-01, TC-02, TC-05.
2. **Build (GREEN)** → Rewrite the `accumulation` branch in `score_formatter.dart`. Run `flutter test test/unit/score_formatter_test.dart` → expect all 12 GREEN.
3. **Full Regression** → Run `flutter test` → confirm zero regressions.
