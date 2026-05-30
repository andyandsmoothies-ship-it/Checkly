---
ConversationID: f625c2e4-0fdd-4c33-9271-185cf5df427c
---
# Green Test Log: Weighted Accumulation scoring logic (Slice 3)

## Summary of Results

All unit tests inside `score_formatter_test.dart` are green and pass.

- **Total Tests Run**: 12 (TC-01 through TC-12)
- **Passed**: 12
- **Failed**: 0
- **Skipped**: 0

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
