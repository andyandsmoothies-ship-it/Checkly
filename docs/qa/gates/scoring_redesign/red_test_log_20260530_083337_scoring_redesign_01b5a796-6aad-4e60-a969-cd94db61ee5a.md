# Red Test Log: Scoring Redesign — Slice 3: Flutter Core

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260530_082805_slice3_flutter_core_cdefadc1.md`
- **Failing Test Spec**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\scoring_redesign\test_spec_20260530_083337_scoring_redesign_01b5a796-6aad-4e60-a969-cd94db61ee5a.md`

---

## 🚦 TDD Inner Loop Validation: RED Stage

This log captures the test suite outputs run before implementing the parser translation layer. The tests fail strictly due to the lack of mapping logic for the new `scoreDirection` and `isWeighted` keys.

---

### 1. scoring_input_mapper_test.dart failures

Run: `rtk flutter test test/features/audit/services/scoring_input_mapper_test.dart`
Results: 4 failed out of 14 tests.

```text
00:00 +6 -1: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-02: down + unweighted -> checklist [E]
  Expected: ScoringMode:<ScoringMode.checklist>
    Actual: ScoringMode:<ScoringMode.penalty>
  
  package:matcher                                                    expect
  package:flutter_test/src/widget_tester.dart 473:18                 expect
  test\features\audit\services\scoring_input_mapper_test.dart 172:9  main.<fn>.<fn>.<fn>
  
00:00 +6 -1: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-03: up -> accumulation
00:00 +6 -2: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-03: up -> accumulation [E]
  Expected: ScoringMode:<ScoringMode.accumulation>
    Actual: ScoringMode:<ScoringMode.penalty>
  
  package:matcher                                                    expect
  package:flutter_test/src/widget_tester.dart 473:18                 expect
  test\features\audit\services\scoring_input_mapper_test.dart 177:9  main.<fn>.<fn>.<fn>
  
00:00 +6 -2: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-04: none -> survey
00:00 +6 -3: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-04: none -> survey [E]
  Expected: ScoringMode:<ScoringMode.survey>
    Actual: ScoringMode:<ScoringMode.penalty>
  
  package:matcher                                                    expect
  package:flutter_test/src/widget_tester.dart 473:18                 expect
  test\features\audit\services\scoring_input_mapper_test.dart 182:9  main.<fn>.<fn>.<fn>

00:00 +10 -3: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-07: scoreDirection present, isWeighted missing -> defaults false -> checklist
00:00 +10 -4: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-07: scoreDirection present, isWeighted missing -> defaults false -> checklist [E]
  Expected: ScoringMode:<ScoringMode.checklist>
    Actual: ScoringMode:<ScoringMode.penalty>
  
  package:matcher                                                    expect
  package:flutter_test/src/widget_tester.dart 473:18                 expect
  test\features\audit\services\scoring_input_mapper_test.dart 205:9  main.<fn>.<fn>.<fn>
```

---

### 2. audit_snapshot_parser_test.dart failures

Run: `rtk flutter test test/features/audit/utils/audit_snapshot_parser_test.dart`
Results: 3 failed out of 5 tests.

```text
00:00 +0 -1: AuditSnapshotParser.parseSnapshot (Slice 3 Redesign) TC-08: New JSON keys (none, false) -> survey string [E]
  Expected: 'survey'
    Actual: 'penalty'
     Which: is different.
            Expected: survey
              Actual: penalty
                      ^
             Differ at offset 0
  
  package:matcher                                                 expect
  package:flutter_test/src/widget_tester.dart 473:18              expect
  test\features\audit\utils\audit_snapshot_parser_test.dart 15:7  main.<fn>.<fn>

00:00 +1 -1: AuditSnapshotParser.parseSnapshot (Slice 3 Redesign) TC-08c: New up + false -> accumulation string
00:00 +1 -2: AuditSnapshotParser.parseSnapshot (Slice 3 Redesign) TC-08c: New up + false -> accumulation string [E]
  Expected: 'accumulation'
    Actual: 'penalty'
     Which: is different.
            Expected: accumulati ...
              Actual: penalty
                      ^
             Differ at offset 0
  
  package:matcher                                                 expect
  package:flutter_test/src/widget_tester.dart 473:18              expect
  test\features\audit\utils\audit_snapshot_parser_test.dart 37:7  main.<fn>.<fn>

00:00 +2 -2: AuditSnapshotParser.parseSnapshot (Slice 3 Redesign) New JSON keys (down, false) -> checklist string
00:00 +2 -3: AuditSnapshotParser.parseSnapshot (Slice 3 Redesign) New JSON keys (down, false) -> checklist string [E]
  Expected: 'checklist'
    Actual: 'penalty'
     Which: is different.
            Expected: checklist
              Actual: penalty
                      ^
             Differ at offset 0
  
  package:matcher                                                 expect
  package:flutter_test/src/widget_tester.dart 473:18              expect
  test\features\audit\utils\audit_snapshot_parser_test.dart 58:7  main.<fn>.<fn>
```

---

## 🔬 Interrogation Outcome

* **Verification Status**: `FAIL (Expected)`
* **Code Quality**: Clean compiles. Imports correct. Mocking boundaries respected.
* **Failure Target**: The tests fail precisely at the assertion of the new scoring translations since the implementation files (`scoring_input_mapper.dart` and `audit_snapshot_parser.dart`) have not yet been modified to parse the new key-value pairs.
