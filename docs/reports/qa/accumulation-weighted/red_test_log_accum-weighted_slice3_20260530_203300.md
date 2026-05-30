---
ConversationID: f2960312-360f-408a-92a4-699802f89d10
---
# Red Test Log: ScoreFormatter Fix (% Primary for All Modes) (Slice 3)

## Summary of Results

Newly introduced test cases in `score_formatter_test.dart` fail as expected because the `ScoreFormatter` is not yet modified to format Accumulation modes with primary percentages.

- **Total Tests Run**: 12
- **Passed**: 7 (regression tests and short-form/null formats)
- **Failed**: 5 (TC-01, TC-02, TC-05, TC-07, TC-08)
- **Skipped**: 0

## Test Trace

<test_trace>
```text
00:00 +0 -1: ScoreFormatter — accumulation branch TC-01: Accumulation OFF — Long Form with Raw Points [E]
  Expected: '80% (100 / 110 raw pts)'
    Actual: '100 / 110 pts'
     Which: is different.
            Expected: 80% (100 / ...
              Actual: 100 / 110  ...
                      ^
             Differ at offset 0
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\unit\score_formatter_test.dart 18:7            main.<fn>.<fn>
  
00:00 +0 -2: ScoreFormatter — accumulation branch TC-02: Accumulation ON (Weighted) — Long Form with Raw Points [E]
  Expected: '80% (100 / 110 raw pts)'
    Actual: '100 / 110 pts'
     Which: is different.
            Expected: 80% (100 / ...
              Actual: 100 / 110  ...
                      ^
             Differ at offset 0
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\unit\score_formatter_test.dart 33:7            main.<fn>.<fn>

00:00 +2 -3: ScoreFormatter — accumulation branch TC-05: Accumulation — Long Form, No Raw Data Available [E]
  Expected: '80%'
    Actual: '80'
     Which: is different. Both strings start the same, but the actual value is missing the following trailing characters: %
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\unit\score_formatter_test.dart 78:7            main.<fn>.<fn>

00:00 +3 -4: ScoreFormatter — accumulation branch TC-07: Accumulation — Decimal Score, Decimal Raw Points [E]
  Expected: '45.9% (50.5 / 110 raw pts)'
    Actual: '50.5 / 110 pts'
     Which: is different.
            Expected: 45.9% (50.5 / 110 ...
              Actual: 50.5 / 110 ...
                      ^
             Differ at offset 0
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\unit\score_formatter_test.dart 104:7           main.<fn>.<fn>
  
00:00 +3 -5: ScoreFormatter — accumulation branch TC-08: Accumulation — Perfect Score [E]
  Expected: '100% (100 / 100 raw pts)'
    Actual: '100 / 100 pts'
     Which: is different.
            Expected: 100% (100 / 100 ...
              Actual: 100 / 100 pts ...
                         ^
             Differ at offset 3
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\unit\score_formatter_test.dart 119:7           main.<fn>.<fn>
```
</test_trace>

## Forensic Evidence

<forensic_evidence>
```bash
rtk flutter test test/unit/score_formatter_test.dart
```

Output:
```text
00:00 +7 -5: Some tests failed.
```
</forensic_evidence>
