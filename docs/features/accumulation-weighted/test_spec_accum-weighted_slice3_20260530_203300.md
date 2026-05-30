# Test Specification: ScoreFormatter Fix (% Primary for All Modes)

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice3_20260530_202900.md`

## Specifications

A total of 12 test cases have been implemented inside `test/unit/score_formatter_test.dart` covering 8 accumulation test scenarios and 4 regression check scenarios.

### Accumulation Test Cases (Expected to fail on current main code):

* **TC-01: Accumulation OFF — Long Form with Raw Points**
  * Inputs: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:100, rawMax:110, totalScore:80`
  * Expected Output: `'80% (100 / 110 raw pts)'`

* **TC-02: Accumulation ON (Weighted) — Long Form with Raw Points**
  * Inputs: `scoringMode:'accumulation', isWeighted:true, shortForm:false, rawEarned:100, rawMax:110, totalScore:80`
  * Expected Output: `'80% (100 / 110 raw pts)'`

* **TC-03: Accumulation OFF — Short Form (List Badge)**
  * Inputs: `scoringMode:'accumulation', isWeighted:false, shortForm:true, rawEarned:100, rawMax:110, totalScore:80`
  * Expected Output: `'80'`

* **TC-04: Accumulation ON — Short Form (List Badge)**
  * Inputs: `scoringMode:'accumulation', isWeighted:true, shortForm:true, rawEarned:100, rawMax:110, totalScore:80`
  * Expected Output: `'80'`

* **TC-05: Accumulation — Long Form, No Raw Data Available**
  * Inputs: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:null, rawMax:null, totalScore:80`
  * Expected Output: `'80%'`

* **TC-06: Accumulation — Null Score → Dash**
  * Inputs: `scoringMode:'accumulation', totalScore:null`
  * Expected Output: `'—'`

* **TC-07: Accumulation — Decimal Score, Decimal Raw Points**
  * Inputs: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:50.5, rawMax:110, totalScore:45.9`
  * Expected Output: `'45.9% (50.5 / 110 raw pts)'`

* **TC-08: Accumulation — Perfect Score**
  * Inputs: `scoringMode:'accumulation', isWeighted:false, shortForm:false, rawEarned:100, rawMax:100, totalScore:100`
  * Expected Output: `'100% (100 / 100 raw pts)'`

### Regression Test Cases (Expected to pass on current main code):

* **TC-09: Penalty + Weighted + Long Form — Unchanged**
  * Expected Output: `'80% (100 / 110 raw pts)'`

* **TC-10: Penalty + Unweighted + Long Form — Unchanged**
  * Expected Output: `'80'`

* **TC-11: Checklist — Long Form Unchanged**
  * Expected Output: `'80 / 100 pts'`

* **TC-12: Survey — Always Dash**
  * Expected Output: `'—'`

## How to Run Tests

Run this command inside the project directory:

```bash
rtk flutter test test/unit/score_formatter_test.dart
```

## Decision Log

- **Decision 1**: Standardize `ScoreFormatter` so that any `accumulation` mode (weighted or unweighted) outputs the percentage as the primary value (e.g. `80%`), followed by the raw points formatted as `(earned / max raw pts)` in the long form.
- **Decision 2**: Keep the short form as raw percentage numbers (e.g. `80`) to ensure widget layout compatibility (badge widgets, heatmap tiles, etc.) does not overflow.
- **Decision 3**: Survey remains unchanged (always formatted as `—`), Checklist remains unchanged (always formatted as `earned / max pts`), and Penalty mode remains unchanged.

## Verification Handoff

Sentinel QA Engineer handed off the verified red unit tests to Builder. The tests fail exactly at the expected assertions due to the formatter not yet supporting the primary percentage behavior for accumulation modes.

<test_trace>
```text
00:00 +0 -1: ScoreFormatter — accumulation branch TC-01: Accumulation OFF — Long Form with Raw Points [E]
  Expected: '80% (100 / 110 raw pts)'
    Actual: '100 / 110 pts'
```
</test_trace>

<forensic_evidence>
```bash
rtk flutter test test/unit/score_formatter_test.dart
```
</forensic_evidence>

