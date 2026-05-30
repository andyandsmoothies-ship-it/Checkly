---
ConversationID: f625c2e4-0fdd-4c33-9271-185cf5df427c
---
# Walkthrough: Weighted Accumulation scoring logic (Slice 3)

## Input Lineage

- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice3_20260530_202900.md`
- **Failing Tests (TDD)**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\test_spec_accum-weighted_slice3_20260530_203300.md`

## Decision Log

### Proposed Design vs. Implemented Design
- **Proposed**: Rewrite the `accumulation` branch inside `ScoreFormatter.format()` so that it outputs percentage as the primary score and raw points as secondary in the long form.
- **Implemented**: 
  - If `totalScore` is null, returns `'—'`.
  - If `shortForm` is true, returns `_fmtPct(totalScore)`.
  - If `shortForm` is false and `rawEarned` and `rawMax` are available, returns `'${_fmtPct(totalScore)}% (${_fmtPts(rawEarned)} / ${_fmtPts(rawMax)} raw pts)'`.
  - If `shortForm` is false but raw details are missing, returns `'${_fmtPct(totalScore)}%'`.
  - Kept all checklist, survey, and penalty branches untouched to prevent regressions.

## Verification Handoff

### Steps for manual/automated QA
1. Run the new `ScoreFormatter` unit tests:
   ```cmd
   rtk flutter test test/unit/score_formatter_test.dart
   ```
2. Verify all 12 tests (TC-01 through TC-12) pass.

## Test Trace

<test_trace>
```text
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/unit/score_formatter_test.dart
00:00 +0: ScoreFormatter — accumulation branch TC-01: Accumulation OFF — Long Form with Raw Points
00:00 +1: ScoreFormatter — accumulation branch TC-02: Accumulation ON (Weighted) — Long Form with Raw Points
00:00 +2: ScoreFormatter — accumulation branch TC-03: Accumulation OFF — Short Form (List Badge)
00:00 +3: ScoreFormatter — accumulation branch TC-04: Accumulation ON — Short Form (List Badge)
00:00 +4: ScoreFormatter — accumulation branch TC-05: Accumulation — Long Form, No Raw Data Available
00:00 +5: ScoreFormatter — accumulation branch TC-06: Accumulation — Null Score → Dash
00:00 +6: ScoreFormatter — accumulation branch TC-07: Accumulation — Decimal Score, Decimal Raw Points
00:00 +7: ScoreFormatter — accumulation branch TC-08: Accumulation — Perfect Score
00:00 +8: ScoreFormatter — regression checks TC-09 (Regression): Penalty + Weighted + Long Form — Unchanged
00:00 +9: ScoreFormatter — regression checks TC-10 (Regression): Penalty + Unweighted + Long Form — Unchanged
00:00 +10: ScoreFormatter — regression checks TC-11 (Regression): Checklist — Long Form Unchanged
00:00 +11: ScoreFormatter — regression checks TC-12 (Regression): Survey — Always Dash
00:00 +12: All tests passed!
```
</test_trace>

## Forensic Evidence

<forensic_evidence>
```cmd
rtk flutter test test/unit/score_formatter_test.dart
```

Output:
```text
00:00 +12: All tests passed!
```
</forensic_evidence>

## Gotcha Protocol

There are no additions to `GEMINI.md` required, as this implementation updates a pure, self-contained Dart formatting utility and maintains strict regression compatibility.
