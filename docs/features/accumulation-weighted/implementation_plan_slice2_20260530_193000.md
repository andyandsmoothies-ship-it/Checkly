<latent_space_scratchpad>
## Key Facts From Code

### ScoringVerifier.cs — line 76
Current dispatch: `"up" => ScoringCalculators.VerifyAccumulation(...)`
No `isWeighted` check at all. This must split into two arms:
  `"up" when isWeighted => ScoringCalculators.VerifyAccumulationWeighted(...)`
  `"up"                 => ScoringCalculators.VerifyAccumulation(...)`

### ScoringCalculators.cs — VerifyAccumulation (lines 149–210)
Unweighted Accumulation pattern:
- Loops over rootGroups → computes sectionPossible + sectionEarned
- CCP → sectionEarned = 0 BUT weight still counts (via totalPossible)
- finalScore = totalEarned / totalPossible × 100
- Returns RawEarned + RawMax on result

### VerifyAccumulationWeighted math to implement
This is identical to VerifyPenalty weighted path EXCEPT:
- No deduction logic
- Instead: sectionEarned = Σ(positive earned points per criterion in section)
- sectionRatio = sectionEarned / sectionPossible
- CCP → sectionEarned = 0, weight STILL counts in participatingWeight (unlike old CCP bug that used continue)
- finalScore = Σ(sectionRatio × weight / participatingWeight) × 100
- Must use ScoringHelpers.GetCriteriaForGroup() (same as VerifyAccumulation) for criterion collection

### Critical Gotcha: CCP Denominator Rule
Epic doc line 198: "Section earned = 0, weight still counts in denominator"
In VerifyPenalty, the CCP path uses `sectionResults.Add((0m, section.Weight ?? 0)); continue;`
This keeps the weight in participatingWeight. We MUST mirror this exactly.

### ScoringHelpers.cs
GetCriteriaForGroup() at line 53 — recursive, grabs criteria from group + all children.
Use this in VerifyAccumulationWeighted (same as VerifyAccumulation line 162).

### Existing Test That Will Break
ScoringVerifierDispatchTests.cs line 143:
`Verify_With_Up_And_Weighted_True_Dispatches_To_VerifyAccumulation_Ignoring_Weighted`
This test was written to document the OLD gap (bug). After Slice 2, `"up" + isWeighted=true`
will route to VerifyAccumulationWeighted, not VerifyAccumulation. The test's assert
(`Assert.Null(result.IsWeighted)`) will still hold ONLY if we keep IsWeighted null on the new result.
But the test name says "Ignoring_Weighted" which is factually wrong after the fix.
→ We must UPDATE this test to assert the CORRECT new behavior (weighted path is taken).

### File Sizes
- ScoringVerifier.cs: 90 lines ✅
- ScoringCalculators.cs: 212 lines ✅ (adding ~50 lines → ~262. Over 250 limit but under 400. No split needed.)
- ScoringVerifierDispatchTests.cs: 171 lines ✅

### Test Fixture Math (same as Slice 1 Flutter fixture, for cross-verification)
Section A: weight=60, possible=10, earned=8 → ratio = 0.8
Section B: weight=40, possible=10, earned=5 → ratio = 0.5
participatingWeight = 100
finalScore = (0.8 × 60/100 + 0.5 × 40/100) × 100 = (0.48 + 0.20) × 100 = 68.0%

CCP fixture (Section A CCP-triggered):
Section A: ratio = 0.0, weight = 60 (stays in denominator)
Section B: ratio = 0.5, weight = 40
finalScore = (0.0 × 60/100 + 0.5 × 40/100) × 100 = 20.0%
</latent_space_scratchpad>

# Implementation Plan — Slice 2: VerifyAccumulationWeighted (C# Backend)

**Plan ID**: ACCUM-WEIGHTED-SLICE2
**Created**: 2026-05-30
**Conversation ID**: a684dd5f-1b02-4247-86c8-ad87256b90e1
**Status**: READY FOR TDD

---

## Input Lineage

- **Source Epic**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\analysis_epic_20260530_172200.md`
- **Predecessor Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice1_20260530_191300.md`

---

## Executive Summary & Out of Scope

**Goal**: Mirror the Flutter `WeightedAccumulationCalculator` (Slice 1) in C#. The server must produce the same score within ±0.01 tolerance when `scoreDirection == "up"` and `isWeighted == true`.

**Two changes only:**
1. Add `VerifyAccumulationWeighted()` method to `ScoringCalculators.cs`.
2. Split the `"up"` arm in `ScoringVerifier.cs` to route `"up" + isWeighted=true` to the new method.

**Out of Scope:**
- No Flutter changes.
- No database migration.
- No API contract change (isWeighted already flows through `ScoringConfigParser`).
- No changes to `VerifyAccumulation()` (unweighted path stays unchanged).
- No changes to `VerifyPenalty()` or `VerifyChecklist()`.

---

## System Context

| Constraint | Detail |
|---|---|
| `isWeighted` already parsed | `ScoringConfigParser.Parse()` reads `isWeighted` from JSON and returns it. Both `CreateSubmission.cs` and `FinalizeSubmission.cs` pass it to `Verify()`. No new parsing needed. |
| Tolerance | `|clientScore - serverScore| ≤ 0.01` |
| CCP Rule | CCP-triggered section: earned = 0, BUT weight stays in the denominator (participatingWeight). Do NOT use `continue` on the section — add `(0m, weight)` to sectionResults. |
| No progressive repeat | Weighted Accumulation has no deduction logic. `progressiveRepeatPenalty` parameter is not used in this calculator. |

---

## Lifecycle Context (4-State Matrix)

| State | Behavior |
|---|---|
| **Success** | `VerifyAccumulationWeighted()` returns `IsValid: true`, `ServerScore` within ±0.01 of client. |
| **Score Mismatch** | `IsValid: false`, `ServerScore` shows server's calculated value. Submission is rejected with HTTP 400. |
| **Risk Triggered** | Handled upstream in `ScoringVerifier.Verify()` before dispatch. Not a concern inside the calculator. |
| **Zero Weights (Purity Fallback)** | If `totalWeight == 0`, the new calculator must fall back to `VerifyAccumulation()` — same as how `VerifyPenalty()` falls back to `VerifyChecklist()`. |

---

## Constraint Traceability

| Epic Constraint | Test Contract |
|---|---|
| R1: Weighted Accumulation math: score = Σ(sectionEarned/sectionPossible × weight) × 100 | TC-01 (happy path) |
| R2: Unweighted Accumulation math stays unchanged | TC-05 (regression: unweighted still works) |
| R4: Backend dispatch routes "up" + isWeighted=true to new weighted calculator | TC-01, TC-06 (dispatch) |
| R7: No existing penalty or checklist math is changed | TC-05 (regression) |
| Epic R8: same fixture, tolerance ≤ 0.01 (Slice 1 mirror) | TC-01, TC-02, TC-03 |
| CCP zeroes section earned, weight stays in denominator | TC-02 |
| Risk failure → total = 0 (upstream) | TC-04 (handled by existing verifier) |
| Zero weights → fall back to unweighted accumulation | TC-05b (zero-weight fallback) |

---

## Test Contracts

### TC-01: Happy Path — Two Sections, Weighted Score
**Given**: Two root groups: Section A (weight=60, possible=10, earned=8) and Section B (weight=40, possible=10, earned=5).
**When**: `Verify("up", isWeighted:true, clientScore:68.0)`
**Then**: `result.IsValid == true`, `result.ServerScore == 68.0`
**Math**: `(0.8 × 60 + 0.5 × 40) / 100 × 100 = 68.0`

### TC-02: CCP Triggered — Section Zeroed, Weight Stays in Denominator
**Given**: Section A (weight=60, possible=10, earned=8, **CCP criterion faulted**), Section B (weight=40, possible=10, earned=5).
**When**: `Verify("up", isWeighted:true, clientScore:20.0)`
**Then**: `result.IsValid == true`, `result.ServerScore == 20.0`
**Math**: `(0.0 × 60 + 0.5 × 40) / 100 × 100 = 20.0`
**Critical**: Section A ratio is 0, but weight 60 stays in participatingWeight (denominator = 100, not 40).

### TC-03: Perfect Score — All Sections Earn 100%
**Given**: Two sections, both earn 100% of possible points, weights sum to 100.
**When**: `Verify("up", isWeighted:true, clientScore:100.0)`
**Then**: `result.IsValid == true`, `result.ServerScore == 100.0`

### TC-04: Dispatch Gate — "up" + isWeighted=true Routes to Weighted Calculator
**Given**: Section A (weight=60, possible=10), all answers correct.
**When**: `Verify("up", isWeighted:true, clientScore:100.0)`
**Then**: Result matches weighted calculation (not the flat unweighted formula). Implicitly verified by TC-01.
> This also serves as the **replacement test** for the old `Verify_With_Up_And_Weighted_True_Dispatches_To_VerifyAccumulation_Ignoring_Weighted` test (which must be renamed and rewritten to assert the NEW correct behavior).

### TC-05: Regression — Unweighted Accumulation Unchanged
**Given**: Same two-section fixture as TC-01, but `isWeighted: false`.
**When**: `Verify("up", isWeighted:false, clientScore:65.0)`
**Then**: `result.IsValid == true`, server uses flat `totalEarned / totalPossible × 100 = (8+5)/(10+10) × 100 = 65.0`. RawEarned and RawMax are populated.
**Purpose**: Prove the old `VerifyAccumulation()` path is untouched.

### TC-05b: Zero Weights Fallback — Falls Back to Unweighted Accumulation
**Given**: Section A (weight=null, possible=10, earned=8), Section B (weight=null, possible=10, earned=5). `isWeighted: true`.
**When**: `Verify("up", isWeighted:true, clientScore:65.0)`
**Then**: `result.IsValid == true`, result equals unweighted flat formula (65.0). `totalWeight == 0` triggers fallback to `VerifyAccumulation`.

### TC-06: Tolerance Boundary — Client Within ±0.01 Is Valid
**Given**: Same TC-01 fixture (server score = 68.0).
**When**: `Verify("up", isWeighted:true, clientScore:68.005)` — within tolerance.
**Then**: `result.IsValid == true`

### TC-07: Tolerance Boundary — Client Exceeds ±0.01 Is Invalid
**Given**: Same TC-01 fixture (server score = 68.0).
**When**: `Verify("up", isWeighted:true, clientScore:68.02)` — exceeds tolerance.
**Then**: `result.IsValid == false`, `result.ServerScore == 68.0`

---

## Test Fixture & Payloads

All tests are **pure unit tests** — no database, no HTTP, no WebApplicationFactory needed.

```csharp
// Standard fixture builder
private ScoringVerifier _verifier = new();

private static (List<Group> groups, List<Answer> answers, List<Criterion> criteria)
    BuildTwoSectionFixture(bool sectionACcp = false)
{
    var secAId = Guid.NewGuid();
    var secBId = Guid.NewGuid();
    var critA = new Criterion { Id = Guid.NewGuid(), GroupId = secAId, PointsWeight = 10, IsCcp = sectionACcp };
    var critB = new Criterion { Id = Guid.NewGuid(), GroupId = secBId, PointsWeight = 10 };
    var groups = new List<Group>
    {
        new() { Id = secAId, ParentId = null, Weight = 60 },
        new() { Id = secBId, ParentId = null, Weight = 40 }
    };
    var answers = new List<Answer>
    {
        // Section A: earns 8/10 — numeric style, 0 faults, numericValue=8 for scale
        // For pass_fail: all conform except 0 faults → earns full 10/10 points
        // Use scale inputType to get partial credit (numericValue = earned)
        new() { CriteriaId = critA.Id, NumericValue = 8 },   // earned = 8
        new() { CriteriaId = critB.Id, NumericValue = 5 }    // earned = 5
    };
    return (groups, answers, new List<Criterion> { critA, critB });
}
```

> **Note**: In `VerifyAccumulation`, the `scale` inputType check on lines 177–181 uses `NumericValue` directly as earned points. The fixture must use scale-compatible criterion types to get partial credit values 8 and 5.

---

## Tools & Commands

- **Skill**: `testing-strategy` (xUnit v3 patterns — pure unit, no factory needed)
- **Test command**: `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~WeightedAccumulation" --no-build`
- **Full regression**: `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --no-build`

---

## Proposed Changes

| # | Action | File | Note |
|---|---|---|---|
| 1 | [MOD] | `server/Common/Scoring/ScoringVerifier.cs` | Split `"up"` arm: add `"up" when isWeighted` before existing `"up"` case |
| 2 | [MOD] | `server/Common/Scoring/ScoringCalculators.cs` | Add `VerifyAccumulationWeighted()` method (~50 lines) |
| 3 | [MOD] | `server/tests/Checkly.Api.Tests/ScoringVerifierDispatchTests.cs` | Update/rename test at line 143 to assert new correct behavior |
| 4 | [NEW] | `server/tests/Checkly.Api.Tests/WeightedAccumulationVerifierTests.cs` | New test class for TC-01 through TC-07 |

---

## Concept Diagram

```text
ScoringVerifier.Verify("up", isWeighted=true)
        |
        v
   [2-D dispatch switch]
        |
        +---> "up" when isWeighted=true
        |           |
        |           v
        |   ScoringCalculators.VerifyAccumulationWeighted()
        |           |
        |           +---> totalWeight == 0?
        |           |          YES → fallback to VerifyAccumulation()
        |           |          NO  → weighted section loop
        |           |
        |           v
        |   for each rootGroup (section):
        |     collect criteria via GetCriteriaForGroup()
        |     ccpTriggered? → sectionResults.Add((0m, weight)); continue
        |     else → sectionEarned = Σ(earned per criterion)
        |            sectionRatio = sectionEarned / sectionPossible
        |            sectionResults.Add((sectionRatio, weight))
        |           |
        |           v
        |   participatingWeight = sectionResults.Sum(w)
        |   finalScore = Σ(ratio × weight / participatingWeight) × 100
        |           |
        |           v
        |   return VerificationResult(IsValid, ServerScore, IsWeighted=true)
        |
        +---> "up" (no isWeighted guard)
                    |
                    v
            ScoringCalculators.VerifyAccumulation()  ← unchanged
```

---

## Execution Slice

### Slice 2 — VerifyAccumulationWeighted (C# Backend)

**Summary**: Add `VerifyAccumulationWeighted()` to `ScoringCalculators.cs`. Split `"up"` dispatch arm in `ScoringVerifier.cs`. Update the stale dispatch test.

**Value**: Weighted accumulation submissions pass server verification — no more HTTP 400 mismatch.

**Entry State Required**: Slice 1 (Flutter) is **green**. The math contract (TC-01 fixture at 68.0%) is established and tested in Dart. This slice only mirrors that math in C#.

**Exit State Guaranteed**: `dotnet test` — all 7 new contracts pass. All existing scoring tests still green.

**Complexity**: Medium — pure math, no IO, mirrors an existing pattern exactly.

---

### Acceptance Criteria

- [ ] TC-01: `"up" + isWeighted=true` → server score = 68.0 (matches Flutter TC-01)
- [ ] TC-02: CCP section → server score = 20.0 (weight stays in denominator)
- [ ] TC-03: Perfect score → 100.0
- [ ] TC-05: `"up" + isWeighted=false` → unweighted formula, unchanged
- [ ] TC-05b: Zero weights + isWeighted=true → falls back to unweighted
- [ ] TC-06: Within tolerance (68.005) → IsValid = true
- [ ] TC-07: Outside tolerance (68.02) → IsValid = false
- [ ] Old dispatch test renamed and updated to assert new weighted routing
- [ ] Full dotnet test regression suite still green (no regressions)

---

## ⚠️ Critical Gotchas

1. **CCP Denominator (Do NOT use `continue`)**: When CCP triggers, add `(0m, section.Weight ?? 0)` to `sectionResults` and THEN `continue`. Never skip the `Add` call — skipping removes the weight from `participatingWeight`, inflating the score. This matches the current `VerifyPenalty` fix already in place.

2. **Stale Dispatch Test**: `ScoringVerifierDispatchTests.cs` line 143 (`Verify_With_Up_And_Weighted_True_Dispatches_To_VerifyAccumulation_Ignoring_Weighted`) was written to document the pre-fix gap. After Slice 2, `"up" + isWeighted=true` will NOT go to `VerifyAccumulation`. This test must be renamed and rewritten in the same step as the code change — it is a test of the OLD broken behavior.

3. **Header Update**: Update the `ScoringVerifier.cs` summary comment (lines 9–13) to reflect the new dispatch matrix: `"up" + weighted → AccumulationWeighted`.

<command_logs>
- view_file: ScoringVerifier.cs — confirmed dispatch at line 76, `"up"` has no isWeighted check
- view_file: ScoringCalculators.cs — confirmed VerifyAccumulation math (lines 149–210), VerifyPenalty weighted pattern (lines 12–118)
- view_file: ScoringHelpers.cs — confirmed GetCriteriaForGroup(), IsPureAudit(), BuildFailedSet()
- view_file: ScoringConfigParser.cs — confirmed isWeighted is already parsed and returned for "up" direction
- view_file: ScoringVerifierDispatchTests.cs — confirmed stale test at line 143 that must be updated
- list_dir: server/tests/Checkly.Api.Tests — confirmed no WeightedAccumulationVerifierTests.cs exists yet
- view_file: server/Common/Scoring/GEMINI.md — confirmed CCP denominator rule and two-route contract
</command_logs>

---

## Handoff Block

**Plan Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\accumulation-weighted\implementation_plan_slice2_20260530_193000.md`

**Route**: **Route 2 — Unit Tests First** (pure math, no IO, known pattern)

**Action Sequence** (execute ONE step at a time):

1. **Slice 2: Write Unit Tests (RED)** → Create `WeightedAccumulationVerifierTests.cs` with TC-01 through TC-07. Update `ScoringVerifierDispatchTests.cs` line 143 to rename/rewrite stale test. Run `dotnet test` → expect RED (VerifyAccumulationWeighted does not exist yet).
2. **Slice 2: Build (GREEN)** → Add `VerifyAccumulationWeighted()` to `ScoringCalculators.cs`. Split `"up"` arm in `ScoringVerifier.cs`. Run `dotnet test` → expect GREEN.
