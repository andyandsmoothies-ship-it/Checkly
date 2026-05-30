# Walkthrough: Scoring Redesign – Slice 3: Flutter Core (Parser Translation)

**Session ID**: `01b5a796-6aad-4e60-a969-cd94db61ee5a`
**Date**: `2026-05-30T08:35:00+07:00`

---

## Input Lineage

- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260530_082805_slice3_flutter_core_cdefadc1.md`

---

## Decision Log

### Proposed Design
The epic originally proposed renaming `ScoringMode` enum in Flutter and changing downstream widgets to use two separate enums (`scoreDirection` and `isWeighted`).

### Implemented Design (Internal Translation Pattern)
We kept `ScoringMode` enum completely unchanged inside the Flutter frontend core. The parser layer now dynamically translates incoming `scoreDirection` + `isWeighted` JSON configs into the internal legacy enum:
- `("none", any)` ➔ `ScoringMode.survey`
- `("up", any)` ➔ `ScoringMode.accumulation`
- `("down", true)` ➔ `ScoringMode.penalty`
- `("down", false)` ➔ `ScoringMode.checklist`

### Rationale
This completely isolates changes to **2 files** and avoids a massive 30+ file refactoring across the Template Builder UI and Audit presentation widgets. We get 100% server JSON compatibility with a blast radius of 0.

---

## Verification Handoff

Manual verification can be performed using standard target tests:
```bash
rtk flutter test test/features/audit/services/scoring_input_mapper_test.dart
rtk flutter test test/features/audit/utils/audit_snapshot_parser_test.dart
```

### Forensic Evidence

1. **PBAC UI verification check run successfully**:
   ```bash
   python .agents/scripts/verify_pbac_ui.py --advisory
   ```
2. **Global test suite execution**:
   ```bash
   rtk flutter test
   ```
   **Result**: 767/767 passed.

<forensic_evidence>
Tools used:
- replace_file_content to edit lib/features/audit/services/scoring_input_mapper.dart and lib/features/audit/utils/audit_snapshot_parser.dart
- run_command to run flutter tests
- verify_workflow.py to enforce the workflow hard gate
</forensic_evidence>

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/services/scoring_input_mapper_test.dart
00:00 +0: ScoringInputMapper.fromTemplate maps flat group into SectionInput
00:00 +1: ScoringInputMapper.fromTemplate maps group with child groups into SectionInput with subsections
00:00 +2: ScoringInputMapper.fromTemplate parses scoringMode and progressiveRepeat from scoringLogicConfig
00:00 +3: ScoringInputMapper.fromTemplate non_conform answer without numericValue defaults to 1 fault
00:00 +4: ScoringInputMapper.fromTemplate maps maxDeductionPoints from CriterionDto to CriterionInput
00:00 +5: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-01: down + weighted -> penalty
00:00 +6: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-02: down + unweighted -> checklist
00:00 +7: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-03: up -> accumulation
00:00 +8: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-04: none -> survey
00:00 +9: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-05: null input -> penalty default
00:00 +10: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-05b: malformed JSON -> penalty default
ScoringInputMapper: parse scoringMode: FormatException: Unexpected character (at character 3)
{ bad
  ^

00:00 +11: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-06: legacy scoringMode key still works (accumulation)
00:00 +12: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-06b: legacy scoringMode key still works (checklist)
00:00 +13: ScoringInputMapper.fromTemplate parseScoringMode (Slice 3 Redesign) TC-07: scoreDirection present, isWeighted missing -> defaults false -> checklist
00:00 +14: All tests passed!
</test_trace>

---

## Gotcha Protocol

No additions to `GEMINI.md` are required as we implemented the fallback compatibility perfectly.
