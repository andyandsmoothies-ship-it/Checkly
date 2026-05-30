<latent_space_scratchpad>
## Constraints Extracted from Epic

C1: 100% Hard Cut — drop `scoringMode` JSON key from `ScoringLogicConfig`. No backward-compat code.
C2: New JSON shape: `{"scoreDirection":"down","isWeighted":true,"progressiveRepeat":false}`
C3: ScoringVerifier.Verify() switch must route on `scoreDirection` ("up"/"down"/"none"), not old string.
C4: "down" + isWeighted=true  → VerifyPenalty (weighted)
C5: "down" + isWeighted=false → VerifyChecklist (raw deduction)
C6: "up"   + isWeighted=*     → VerifyAccumulation
C7: "none"                    → Survey (null score)
C8: TemplateLinter check: "isWeighted=true" → groups must sum to 100 (replaces "penalty" string check).
C9: BOTH CreateSubmission.cs AND FinalizeSubmission.cs must be updated (GEMINI.md: Any-Route-Both rule).
C10: Dtos.cs: replace ScoringMode? with ScoreDirection? + IsWeighted? in SubmissionDto and SubmissionDetailDto.
C11: ActionPlanService: "survey" guard must use scoreDirection == "none" (not scoringMode == "survey").
C12: GetAnalytics.cs: `scoringMode` query param → `scoreDirection` query param. "survey" filter → "none".
C13: ScoringCalculators.cs — math is UNCHANGED. Only the dispatcher changes in ScoringVerifier.cs.
C14: Existing ScoringConfigParser tests must PASS with new JSON shape (old tests will FAIL — that's expected RED first).

## Out of Scope
- Flutter enum/engine changes (Slice 3)
- Template Builder UI changes (Slice 4)
- Dashboard category tag filter (Slice 5)
- Database column dropping (future migration, not this slice)
- Snapshot jobs (BodReportCalculator, GetBodReport) — they filter `ScoringMode != "survey"`.
  These can use scoreDirection column directly from the DB (already backfilled in Slice 1).
  Therefore they are NOT touched here. They will be updated in Slice 5 (analytics).

## Architecture Pattern
Event-Driven Parser Replacement — Strategy Pattern dispatch.
Old: `scoringMode switch { "penalty" => ..., "checklist" => ..., "accumulation" => ..., "survey" => ... }`
New: `scoreDirection` + `isWeighted` two-dimensional dispatch table.

## Callers of ScoringConfigParser.Parse() — Full List
1. `CreateSubmission.cs:187` — verification path
2. `CreateSubmission.cs:252` — submission write path (called TWICE — both must change)
3. `FinalizeSubmission.cs:138` — verification + write path
4. `TemplateLinter.cs:48` — weight validation
These are the ONLY 4 callers. Each must be updated.

## Callers that read `ScoringMode` string on Submission entity
- `CreateSubmission.cs:319` — scoringMode passed to ActionPlanService
- `CreateSubmission.cs:351` — survey skip for SectionScoreExploder
- `FinalizeSubmission.cs:192-196` — survey null guards + ScoringMode write
- `FinalizeSubmission.cs:248` — scoringMode passed to ActionPlanService
- `FinalizeSubmission.cs:268` — survey skip for SectionScoreExploder
- `GetAnalytics.cs:22,139,140,152,159` — scoringMode query param + survey filters

## File Line Counts (from research)
- ScoringConfigParser.cs: 44 lines ✅
- ScoringVerifier.cs: 75 lines ✅
- ScoringCalculators.cs: 212 lines ✅ (unchanged)
- Dtos.cs: 98 lines ✅
- CreateSubmission.cs: 372 lines ⚠️ > 250 — file limit rule triggers
- FinalizeSubmission.cs: 331 lines ⚠️ > 250 — file limit rule triggers
- TemplateLinter.cs: 187 lines ✅
- GetAnalytics.cs: 268 lines ⚠️ > 250 — but we touch only 5 lines (lines 22,139,140,152,159)

## File Limit Decision
CreateSubmission.cs (372) and FinalizeSubmission.cs (331) exceed 250 lines.
HOWEVER: splitting these files would require extracting scoring logic into a dedicated ScoringHandler.cs.
This would be a separate refactor that could destabilize the transaction/execution-strategy wrappers.
Decision: Since this slice touches <= 6 lines per file (only the scoringMode string references),
and the files are already well-structured with clear sections, the risk of splitting EXCEEDS the benefit.
The plan must document this trade-off explicitly as a known exception.

## Two Failure Modes (GEMINI.md requirement)
1. Parser returns ("penalty", false) for new JSON → ScoringVerifier falls to `_` (penalty) default → wrong math for "up" (accumulation) templates. Score mismatch 400.
2. "isWeighted=false" JSON → ScoringVerifier routes to VerifyPenalty (weighted path) → inflated score since no weights exist. Score mismatch 400.
</latent_space_scratchpad>

# Implementation Plan: Scoring Redesign — Slice 2: Backend Parser + Scoring Engine

**Created**: 2026-05-29T23:16:23+07:00
**Author**: Antigravity AI
**Epic**: SCORING-REDESIGN
**Slice**: 2 of 5
**Status**: PLANNING

---

## Input Lineage

- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Slice 1 Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md`
- **Entry Dependency**: Slice 1 must be complete. `score_direction`, `is_weighted`, `category_tag` columns must exist in the DB.

---

## Executive Summary & Out of Scope

**Goal**: Replace the old 4-value `scoringMode` string system in the C# backend with the new two-field system (`scoreDirection` + `isWeighted`). This is a 100% Hard Cut — no backward-compatibility code is written.

```text
OLD flow:
  JSON blob {"scoringMode":"penalty"} 
    → ScoringConfigParser → (scoringMode="penalty")
    → ScoringVerifier switch("penalty") → VerifyPenalty

NEW flow:
  JSON blob {"scoreDirection":"down","isWeighted":true}
    → ScoringConfigParser → (scoreDirection="down", isWeighted=true)
    → ScoringVerifier dispatch(down+true) → VerifyPenalty (math UNCHANGED)
```

**Dispatch table** (replaces 4-arm switch):

| scoreDirection | isWeighted | → Calculator |
|---|---|---|
| `"down"` | `true`  | `VerifyPenalty` (weighted) |
| `"down"` | `false` | `VerifyChecklist` (raw deduction) |
| `"up"`   | any     | `VerifyAccumulation` |
| `"none"` | any     | Survey — null score |

**Out of Scope** (will NOT be built in this slice):
- Flutter enum / engine changes (Slice 3)
- Template Builder UI changes (Slice 4)
- Dashboard category tag filter (Slice 5)
- `BodReportCalculator.cs` and `GetBodReport.cs` analytics updates (Slice 5)
- Dropping `scoring_mode` DB column (future migration, after all slices pass)
- Any changes to `ScoringCalculators.cs` — the math functions are UNCHANGED

---

## System Context

| Constraint | Detail |
|---|---|
| Offline-first | Scoring runs on Flutter device. Server re-verifies. Math must match exactly. |
| Hard Cut API | App is unpublished. No clients send old `scoringMode` JSON key. Drop it completely. |
| GEMINI.md: Both-Routes Rule | Any change to `scorer.Verify()` call in one handler MUST be mirrored in the other. |
| GEMINI.md: JSON Config Sync | Any new JSON key in `ScoringLogicConfig` MUST be parsed AND forwarded in BOTH handlers. |
| File Limit Exception | `CreateSubmission.cs` (372L) and `FinalizeSubmission.cs` (331L) exceed 250L. Exception documented: changes are <= 6 lines each, splitting would destabilize transaction wrappers. |

---

## Lifecycle Context — 4-State Matrix

| State | Behavior |
|---|---|
| **Success** | `ScoringConfigParser.Parse()` reads new JSON, `ScoringVerifier.Verify()` dispatches correctly, score matches client, submission saved with `score_direction` written. |
| **Error** | `scoreDirection` missing from JSON → parser defaults to `"down"`. `isWeighted` missing → defaults to `false`. Fallback = Checklist. API returns 400 only if score actually mismatches. |
| **Empty** | Survey mode (`scoreDirection="none"`) → `TotalScore = null`, `IsWeighted = null`. |
| **Loading** | No loading state on backend. Synchronous parse + verify in handler. |

---

## Constraint Traceability

| # | Constraint | Test Contract |
|---|---|---|
| C1 | Hard Cut: no `scoringMode` key in JSON | TC-01: Parse new JSON → returns (down, true, false) |
| C2 | New JSON shape: `scoreDirection` + `isWeighted` | TC-01, TC-02, TC-03, TC-04 |
| C3 | ScoringVerifier routes on `scoreDirection` | TC-05, TC-06, TC-07, TC-08 |
| C4 | down+true → VerifyPenalty (weighted) | TC-05 |
| C5 | down+false → VerifyChecklist | TC-06 |
| C6 | up → VerifyAccumulation | TC-07 |
| C7 | none → Survey null | TC-08 |
| C8 | TemplateLinter: isWeighted=true → group sum=100 | TC-09 |
| C9 | BOTH Create + Finalize updated | TC-10 (integration round-trip) |
| C10 | Dtos replace ScoringMode? with ScoreDirection? + IsWeighted? | TC-11 |
| C11 | ActionPlanService guard uses scoreDirection="none" | TC-12 |
| C12 | GetAnalytics query param renamed `scoreDirection` | TC-13 |
| C13 | ScoringCalculators math unchanged | TC-05, TC-06, TC-07 (same numerical assertions) |
| C14 | Old parser tests go RED first | Pre-condition of RED gate |

---

## Test Contracts

### Unit Tests (ScoringConfigParserTests.cs — REPLACE existing)

| ID | Description | Input JSON | Expected Output |
|---|---|---|---|
| TC-01 | Parses new format: down+weighted | `{"scoreDirection":"down","isWeighted":true}` | `("down", true, false)` |
| TC-02 | Parses new format: down+unweighted | `{"scoreDirection":"down","isWeighted":false}` | `("down", false, false)` |
| TC-03 | Parses new format: up | `{"scoreDirection":"up","isWeighted":false}` | `("up", false, false)` |
| TC-04 | Parses new format: none (survey) | `{"scoreDirection":"none","isWeighted":false}` | `("none", false, false)` |
| TC-04b | Parses with progressiveRepeat | `{"scoreDirection":"down","isWeighted":true,"progressiveRepeat":true}` | `("down", true, true)` |
| TC-04c | Null input → default down+false | `null` | `("down", false, false)` |
| TC-04d | Malformed JSON → default down+false | `"{ invalid"` | `("down", false, false)` |
| TC-04e | Missing `isWeighted` → defaults false | `{"scoreDirection":"up"}` | `("up", false, false)` |
| TC-04f | Missing `scoreDirection` → defaults "down" | `{"isWeighted":true}` | `("down", true, false)` |

### Unit Tests (ScoringVerifierDispatchTests.cs — NEW file)

| ID | Description | Input | Expected |
|---|---|---|---|
| TC-05 | down+true → calls VerifyPenalty path (weighted) | scoreDirection="down", isWeighted=true, groups with weights | IsWeighted=true in result |
| TC-06 | down+false → calls VerifyChecklist path (raw) | scoreDirection="down", isWeighted=false, no group weights | IsWeighted=false in result |
| TC-07 | up → calls VerifyAccumulation | scoreDirection="up", isWeighted=false | RawEarned+RawMax populated |
| TC-08 | none → returns null score | scoreDirection="none" | ServerScore=null |

### Unit Tests (TemplateLinterTests.cs — MODIFY)

| ID | Description | Config JSON | Expected |
|---|---|---|---|
| TC-09 | isWeighted=true + groups sum != 100 → lint error | `{"scoreDirection":"down","isWeighted":true}` | "WeightedModeGroupSum" error |
| TC-09b | isWeighted=false → no group sum check | `{"scoreDirection":"down","isWeighted":false}` | No lint error |

### Integration Tests (ScoringDesignSlice2Tests.cs — NEW file)

| ID | Description | Fixture | Expected |
|---|---|---|---|
| TC-10 | POST /submissions with new JSON config creates submission with ScoreDirection | Template with `{"scoreDirection":"down","isWeighted":false}`, valid answers | HTTP 201, response has `scoreDirection="down"`, `isWeighted=false` |
| TC-11 | SubmissionDto contains ScoreDirection + IsWeighted (no ScoringMode) | Existing completed submission | JSON response has `scoreDirection` key, no `scoringMode` key |
| TC-12 | Survey submission (scoreDirection=none) returns null TotalScore | Template with `{"scoreDirection":"none"}` | HTTP 201, `totalScore=null` |
| TC-13 | GET /analytics?scoreDirection=none returns only survey submissions | 2 seeded submissions (1 none, 1 down) | Response counts match |

---

## Test Fixture & Payloads

### New ScoringLogicConfig JSON shapes (used by Flutter → server)

```json
// Weighted penalty (old: penalty)
{"scoreDirection":"down","isWeighted":true,"progressiveRepeat":false}

// Unweighted checklist (old: checklist)
{"scoreDirection":"down","isWeighted":false,"progressiveRepeat":false}

// Accumulation (old: accumulation)
{"scoreDirection":"up","isWeighted":false,"progressiveRepeat":false}

// Survey (old: survey)
{"scoreDirection":"none","isWeighted":false,"progressiveRepeat":false}
```

### SubmissionDto JSON response (after Slice 2)

```json
{
  "id": "...",
  "scoreDirection": "down",
  "isWeighted": true,
  "totalScore": 87.5
}
```

> ⚠️ `scoringMode` key REMOVED from both `SubmissionDto` and `SubmissionDetailDto`.

---

## Tools & Commands

- **Skills needed**: `tdd` skill (unit tests), `testing-strategy` skill (integration tests)
- **Build**: `rtk dotnet build server`
- **Unit tests only**: `rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~ScoringConfig|FullyQualifiedName~ScoringVerifier|FullyQualifiedName~TemplateLinter|FullyQualifiedName~ScoringDesignSlice2"`
- **All tests**: `rtk dotnet test server/tests/Checkly.Api.Tests`

---

## Proposed Changes

Build in this order (dependencies cascade downward):

| # | Action | File | Lines Changed | Notes |
|---|---|---|---|---|
| 1 | [MOD] | `server/Common/Scoring/ScoringConfigParser.cs` | ~15 | New return tuple: `(string ScoreDirection, bool IsWeighted, bool ProgressiveRepeat)`. Remove `scoringMode` key read. Add `scoreDirection` + `isWeighted` key reads. |
| 2 | [MOD] | `server/Common/Scoring/ScoringVerifier.cs` | ~10 | Change `Verify()` signature: replace `string scoringMode` param with `string scoreDirection` + `bool isWeighted`. Update dispatch switch. |
| 3 | [MOD] | `server/Features/Submissions/Dtos.cs` | ~6 | In `SubmissionDto` and `SubmissionDetailDto`: remove `string? ScoringMode`, add `string? ScoreDirection` and `bool? IsWeighted`. |
| 4 | [MOD] | `server/Features/Submissions/CreateSubmission.cs` | ~10 | Update 2× `ScoringConfigParser.Parse()` calls, update `scorer.Verify()` call, update submission write (`ScoringMode=` → `ScoreDirection=`), update survey guards, update `SubmissionDto` constructor. |
| 5 | [MOD] | `server/Features/Submissions/FinalizeSubmission.cs` | ~8 | Same as CreateSubmission — update Parse, Verify, write, survey guards, SubmissionDto constructor. |
| 6 | [MOD] | `server/Features/Templates/TemplateLinter.cs` | ~5 | Replace `scoringMode == "penalty"` check with `isWeighted == true`. |
| 7 | [MOD] | `server/Common/Services/ActionPlanService.cs` | ~2 | Replace `scoringMode == "survey"` guard with `scoreDirection == "none"`. |
| 8 | [MOD] | `server/Features/Analytics/GetAnalytics.cs` | ~5 | Rename query param `scoringMode` → `scoreDirection`. Replace "survey" literal with "none". |
| 9 | [MOD] | `server/tests/Checkly.Api.Tests/ScoringConfigParserTests.cs` | ~30 | Replace old 3 tests with 9 new tests (TC-01 → TC-04f). |
| 10 | [NEW] | `server/tests/Checkly.Api.Tests/ScoringVerifierDispatchTests.cs` | ~80 | TC-05 → TC-08: dispatch routing tests. |
| 11 | [NEW] | `server/tests/Checkly.Api.Tests/ScoringDesignSlice2Tests.cs` | ~100 | TC-10 → TC-13: integration tests. |

---

## Concept Diagram

```text
[ScoringLogicConfig JSON blob in DB/Snapshot]
  {"scoreDirection":"down","isWeighted":true,"progressiveRepeat":false}
              |
              v
  [ScoringConfigParser.Parse(json)]
    returns: (scoreDirection="down", isWeighted=true, progressiveRepeat=false)
              |
   +----------+----------+
   |                     |
   v                     v
[CreateSubmission]   [FinalizeSubmission]
  calls scorer.Verify(   calls scorer.Verify(
    scoreDirection,         scoreDirection,
    isWeighted, ...)        isWeighted, ...)
              |
              v
  [ScoringVerifier.Verify()]
    dispatch:
      "down" + true  → VerifyPenalty()    ← math UNCHANGED
      "down" + false → VerifyChecklist()  ← math UNCHANGED
      "up"           → VerifyAccumulation() ← math UNCHANGED
      "none"         → return null
              |
              v
  [Submission entity written]
    ScoreDirection = "down"
    IsWeighted = true   (already in DB from Slice 1)
    ScoringMode = preserved (not written anymore, stays from old data)
              |
              v
  [SubmissionDto returned]
    scoreDirection: "down"
    isWeighted: true
    (scoringMode: REMOVED)
```

---

## Execution Slices

### Slice A — Core Parser + Verifier Signature Change
**Complexity**: Low
**Entry State**: Slice 1 complete. `score_direction`/`is_weighted` columns exist in DB.
**Exit State**: `ScoringConfigParser.Parse()` returns new 3-tuple. `ScoringVerifier.Verify()` dispatches on `scoreDirection` + `isWeighted`. Tests for parser and dispatch pass GREEN.
**Scope**: 2 files (`ScoringConfigParser.cs`, `ScoringVerifier.cs`) + 2 test files.

**Acceptance Criteria**:
1. `ScoringConfigParser.Parse()` signature: `(string ScoreDirection, bool IsWeighted, bool ProgressiveRepeat)`
2. Reads `scoreDirection` key from JSON. Default: `"down"`.
3. Reads `isWeighted` key from JSON. Default: `false`.
4. Reads `progressiveRepeat` key unchanged.
5. `ScoringVerifier.Verify()` signature: `string scoreDirection = "down"`, `bool isWeighted = false` (replaces `string scoringMode = "penalty"`).
6. `"down"` + `isWeighted=true` → routes to `VerifyPenalty`.
7. `"down"` + `isWeighted=false` → routes to `VerifyChecklist`.
8. `"up"` → routes to `VerifyAccumulation`.
9. `"none"` → returns `VerificationResult` with `ServerScore = null`.
10. All TC-01 → TC-08 unit tests pass GREEN.
11. `rtk dotnet build server` passes with 0 errors.

> ⚠️ **After Slice A**: `CreateSubmission.cs` and `FinalizeSubmission.cs` will have **compile errors** because they still pass `scoringMode:` to `scorer.Verify()`. This is EXPECTED. Do not fix them until Slice B.

### Slice B — Callers + DTOs Update
**Complexity**: Medium
**Entry State**: Slice A complete. Parser + Verifier have new signatures. Code does NOT compile yet.
**Exit State**: All 4 callers of `ScoringConfigParser.Parse()` updated. Both submission handlers updated. DTOs updated. Code compiles and all TC-10 → TC-13 integration tests pass GREEN.
**Scope**: 5 files (`CreateSubmission.cs`, `FinalizeSubmission.cs`, `Dtos.cs`, `TemplateLinter.cs`, `ActionPlanService.cs`, `GetAnalytics.cs`).

**Acceptance Criteria**:
1. `Dtos.cs`: `SubmissionDto` has `ScoreDirection?` + `IsWeighted?` (no `ScoringMode`).
2. `Dtos.cs`: `SubmissionDetailDto` has `ScoreDirection?` + `IsWeighted?` (no `ScoringMode`).
3. `CreateSubmission.cs` line 187: calls `ScoringConfigParser.Parse()` → unpacks `(scoreDirection, isWeighted, progressiveRepeat)`.
4. `CreateSubmission.cs` line 225: `scorer.Verify(..., scoreDirection: scoreDirection, isWeighted: isWeighted, ...)`.
5. `CreateSubmission.cs` line 252: second `Parse()` call also updated.
6. `CreateSubmission.cs` survey guards: `submissionScoringMode == "survey"` → `scoreDirection == "none"`.
7. `CreateSubmission.cs` submission write: `ScoreDirection = scoreDirection` (NOT `ScoringMode = ...`).
8. `FinalizeSubmission.cs` — same 5 changes mirrored exactly.
9. `TemplateLinter.cs`: lints `isWeighted == true` → groups must sum to 100 (replaces `scoringMode == "penalty"`).
10. `ActionPlanService.cs`: `scoringMode == "survey"` → `scoreDirection == "none"`.
11. `GetAnalytics.cs`: query param `scoringMode` → `scoreDirection`. Literal `"survey"` → `"none"`.
12. All TC-09 → TC-13 tests pass GREEN.
13. `rtk dotnet build server` passes with 0 errors.
14. `rtk dotnet test server/tests/Checkly.Api.Tests` — all existing tests still pass.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Forgetting to update one of the 2 callers of Parse() in CreateSubmission.cs | HIGH | There are TWO Parse() calls on lines 187 and 252. Both must be updated. |
| ScoringVerifier.Verify() called from test code with old `scoringMode:` named param | MEDIUM | Run `grep_search "scoringMode:"` across entire `server/` to find all named-param usages before building. |
| Analytics "survey" filter now returns wrong data if not updated to "none" | HIGH | `GetAnalytics.cs` uses `s.ScoringMode != "survey"` which reads the **DB column**. After Slice 1, the `score_direction` column has "none" for surveys. But `ScoringMode` column still has "survey". So this filter still works via old column. However the new query param must change to avoid confusion. |
| ActionPlanService receives "none" but checks "survey" — action plans created for survey mode | MEDIUM | Update ActionPlanService guard in same Slice B. |

---

## Verification Plan

Run after Slice B is complete:

```bash
# 1. Build verification
rtk dotnet build server

# 2. Targeted unit + dispatch tests
rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~ScoringConfig"
rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~ScoringVerifier"

# 3. Integration tests
rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~ScoringDesignSlice2"

# 4. Full suite — no regressions
rtk dotnet test server/tests/Checkly.Api.Tests
```

**Canary Greps** (run BEFORE starting Slice B to catch missed usages):
```
grep_search: "scoringMode:" in server/ — find all named-param callers of scorer.Verify()
grep_search: "scoringMode ==" in server/Features/ — find remaining string comparisons
grep_search: "ScoringMode =" in server/Features/ — find entity write sites
```

<command_logs>
- list_dir: server/Common/Scoring → confirmed 5 files (Parser, Calculators, Verifier, Helpers, GEMINI.md)
- grep_search: scoringMode|ScoringMode in server/Common/Scoring → found all usages (ScoringConfigParser, ScoringVerifier)
- view_file: ScoringConfigParser.cs (44 lines) — confirmed old return tuple (ScoringMode, ProgressiveRepeat)
- view_file: ScoringVerifier.cs (75 lines) — confirmed switch on `scoringMode` string
- view_file: ScoringCalculators.cs (212 lines) — confirmed math is self-contained, no scoringMode refs
- grep_search: scoringMode|ScoringMode in server/Features → 40 hits across 8 files
- view_file: Dtos.cs (98 lines) — confirmed string? ScoringMode in both SubmissionDto + SubmissionDetailDto
- view_file: FinalizeSubmission.cs lines 130-210 — confirmed 5 scoringMode usages
- view_file: CreateSubmission.cs lines 180-280 + 280-372 — confirmed 2 Parse() calls, submission write
- view_file: TemplateLinter.cs lines 35-80 — confirmed scoringMode == "penalty" check
- view_file: ScoringConfigParserTests.cs (32 lines) — confirmed 3 existing tests (will go RED)
- grep_search: scoringMode in server/Common/Services → ActionPlanService.cs:32,37
- view_file: GetAnalytics.cs (268 lines) — confirmed scoringMode query param at lines 22,139,140,152,159
</command_logs>

---

## Handoff Block

**Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_231623_slice2_backend_parser_cdefadc1.md`

**Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\scoring_redesign\task_20260529_231623_slice2_backend_parser_cdefadc1.md`

### Action Sequence — Execute ONE slice at a time

1. **QA writes unit tests** (TC-01 → TC-08) in `ScoringConfigParserTests.cs` (replace) + new `ScoringVerifierDispatchTests.cs`. Run → confirm RED (compile fails because signatures not changed yet). **YIELD.**

2. **Builder: Slice A** — Update `ScoringConfigParser.cs` + `ScoringVerifier.cs`. Run unit tests → GREEN. Build will have compile errors on callers. **YIELD.**

3. **QA writes integration tests** (TC-09 → TC-13) in `ScoringDesignSlice2Tests.cs` (new). **YIELD.**

4. **Builder: Slice B** — Update all 6 caller files (`CreateSubmission.cs`, `FinalizeSubmission.cs`, `Dtos.cs`, `TemplateLinter.cs`, `ActionPlanService.cs`, `GetAnalytics.cs`). Run full `dotnet test` → GREEN. **YIELD.**

> ⚠️ **Do NOT begin Slice 3 (Flutter Enum)** until `dotnet test` passes GREEN for all tests above.

### Key Risk Reminder
> `CreateSubmission.cs` calls `ScoringConfigParser.Parse()` **TWICE** (lines 187 and 252). Both must be updated. The second call at line 252 feeds `ActionPlanService` and `SectionScoreExploder`.
