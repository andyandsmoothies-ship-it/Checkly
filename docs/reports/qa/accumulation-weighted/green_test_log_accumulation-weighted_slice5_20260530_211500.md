# Green Test Log - Weighted Accumulation Slice 5

## Metadata
- **ConversationID**: `f625c2e4-0fdd-4c33-9271-185cf5df427c`
- **Timestamp**: `2026-05-30T21:15:00`
- **Scope**: Slice 5 HeaderCard Info Row Validation

---

## 1. Commands Executed

### Target Widget Test Run
```cmd
rtk flutter test test/features/audit/widgets/header_card_test.dart
```

---

## 2. Test Execution Outputs

### Target Widget Test Console Output
```text
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/widgets/header_card_test.dart
00:00 +0: HeaderCard Widget Tests Renders info row when isWeighted is true
00:00 +1: HeaderCard Widget Tests Hides info row when isWeighted is false
00:00 +2: HeaderCard Widget Tests Hides info row when isWeighted is null
00:00 +3: All tests passed!

Exit code: 0
```

---

## 3. Analysis Compliancy
- [x] Zero mock failures.
- [x] Zero network calls during tests (isolated mock setup).
- [x] Correct widgets injected and queried using mocktail helpers.
