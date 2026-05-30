# Test Specification: Scoring Redesign — Slice 3: Flutter Core (Parser Translation)

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260530_082805_slice3_flutter_core_cdefadc1.md`

---

## 🗺️ TDD Test Mapping Matrix

This specification details the test contracts written to drive the parser translation layer of the Flutter offline-first client. All tests are registered under TDD Inner Loop verification.

### 1. ScoringInputMapper parseScoringMode Tests
These unit tests are located inside `test/features/audit/services/scoring_input_mapper_test.dart` under the `parseScoringMode (Slice 3 Redesign)` group.

| Test Case | Description | Input configJson Payload | Expected Return Value | Status |
|---|---|---|---|---|
| **TC-01** | `down` + `true` maps to `penalty` | `{"scoreDirection":"down","isWeighted":true}` | `ScoringMode.penalty` | 🟢 Passes (default) |
| **TC-02** | `down` + `false` maps to `checklist` | `{"scoreDirection":"down","isWeighted":false}` | `ScoringMode.checklist` | 🔴 Fails (actual: penalty) |
| **TC-03** | `up` + `false` maps to `accumulation` | `{"scoreDirection":"up","isWeighted":false}` | `ScoringMode.accumulation` | 🔴 Fails (actual: penalty) |
| **TC-04** | `none` + `false` maps to `survey` | `{"scoreDirection":"none","isWeighted":false}` | `ScoringMode.survey` | 🔴 Fails (actual: penalty) |
| **TC-05** | `null` config maps to default `penalty` | `null` | `ScoringMode.penalty` | 🟢 Passes (default) |
| **TC-05b** | Malformed JSON maps to default `penalty` | `"{ bad"` | `ScoringMode.penalty` | 🟢 Passes (default) |
| **TC-06** | Legacy `scoringMode` key maps to `accumulation` | `{"scoringMode":"accumulation"}` | `ScoringMode.accumulation` | 🟢 Passes (legacy) |
| **TC-06b** | Legacy `scoringMode` key maps to `checklist` | `{"scoringMode":"checklist"}` | `ScoringMode.checklist` | 🟢 Passes (legacy) |
| **TC-07** | `isWeighted` missing defaults to `false` -> `checklist` | `{"scoreDirection":"down"}` | `ScoringMode.checklist` | 🔴 Fails (actual: penalty) |

### 2. AuditSnapshotParser parseSnapshot Tests
These unit tests are located inside the new file `test/features/audit/utils/audit_snapshot_parser_test.dart`.

| Test Case | Description | Input snapshotJson payload (scoringLogicConfig section) | Expected scoringMode String | Status |
|---|---|---|---|---|
| **TC-08** | New JSON keys `none` -> `survey` display string | `{"scoreDirection":"none","isWeighted":false}` | `"survey"` | 🔴 Fails (actual: penalty) |
| **TC-08b** | New JSON keys `down` + `true` -> `penalty` display string | `{"scoreDirection":"down","isWeighted":true}` | `"penalty"` | 🟢 Passes (default) |
| **TC-08c** | New JSON keys `up` + `false` -> `accumulation` display string | `{"scoreDirection":"up","isWeighted":false}` | `"accumulation"` | 🔴 Fails (actual: penalty) |
| **TC-08d** | Legacy `scoringMode` key still parses `checklist` | `{"scoringMode":"checklist"}` | `"checklist"` | 🟢 Passes (legacy) |
| **—** | New JSON keys `down` + `false` -> `checklist` display string | `{"scoreDirection":"down","isWeighted":false}` | `"checklist"` | 🔴 Fails (actual: penalty) |

---

## 🛠️ Verification Run Commands

To verify that the builder's implementation satisfies all of the specifications above, execute the following commands in sequence:

```bash
# 1. Verify Mapper translation logic
rtk flutter test test/features/audit/services/scoring_input_mapper_test.dart

# 2. Verify Snapshot parsing display mapping logic
rtk flutter test test/features/audit/utils/audit_snapshot_parser_test.dart

# 3. Check for any regression in the core scoring engine
rtk flutter test test/scoring_engine_test.dart

# 4. Run the entire Flutter unit test suite to guarantee zero regression
rtk flutter test
```
