# Failure Report: Catch Flops / Failure Modes Audit (Slice 2)
**Workflow**: /catch-flops | **Track**: C  
**Conversation ID**: `ac4575e5-39d8-4b20-a4a6-49ce53ce5264`  
**Date**: 2026-05-29T23:29:28Z  
**Source Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_231623_slice2_backend_parser_cdefadc1.md`

---

## Executive Summary

As the Red-Team SRE Failure Analyst, I have conducted a targeted audit of the **Slice 2: Backend Parser + Scoring Engine** implementation plan. This phase replaces the old 4-value `scoringMode` string with the new two-dimensional `scoreDirection` + `isWeighted` scoring logic.

While the strategy pattern design is exceptionally robust, the system faces several hidden "flops"—including silent query exclusions on PostgreSQL, logical validation collisions in the linter, and compiler errors due to named parameter mismatches in callers.

This report documents these issues, assesses their severity, and defines concrete mitigations to be incorporated directly into the implementation.

```text
       [Parser JSON] 
             │
             ▼
[TemplateLinter.cs] ── (Flop: Accumulation Weight Collision) ──► Block Template Save
             │
             ▼
[GetAnalytics.cs Query] ── (Flop: PG Null Inequality Exclusion) ──► Missing Analytics Data
```

---

## Discovered Flops & Failure Modes

### 1. 🔴 CRITICAL: PostgreSQL Null Inequality Silently Excludes Legacy Submissions in `GetAnalytics.cs`
* **Risk Domain**: Database Query & Data Integrity
* **Scenario**: In `GetAnalytics.cs`, we filter submissions by `scoringMode != "survey"`. When this query is updated to use the new `ScoreDirection` column, it will be written as `query.Where(s => s.ScoreDirection != "none")`.
* **The Flop**: In PostgreSQL, any inequality comparison like `score_direction != 'none'` evaluates to `NULL` (falsy) for rows where the `score_direction` column is `NULL`. This means that if any legacy submissions failed to backfill correctly in Slice 1, or if a sync bug inserts a null `score_direction`, those records will be **silently and permanently excluded** from all boardroom analytics and KPI calculations without throwing any error.
* **Mitigation**: You MUST write the EF Core query defensively using null-safe check wrappers:
  ```csharp
  query = query.Where(s => s.ScoreDirection == null || s.ScoreDirection != "none");
  ```
  This ensures that both legacy null records and non-survey records are captured correctly.

---

### 2. 🔴 CRITICAL: Logical Collision in `TemplateLinter.cs` Blocks Saving Accumulation Templates
* **Risk Domain**: Calculation & Logical Boundaries
* **Scenario**: In `TemplateLinter.cs`, the validation check for weighted mode ensures group weights sum to exactly 100%. The plan proposes updating:
  ```csharp
  if (scoringMode == "penalty")
  ```
  to:
  ```csharp
  if (isWeighted)
  ```
* **The Flop**: Accumulation templates (`scoreDirection == "up"`) accumulate raw points and do not utilize group weights. However, if a user saves an accumulation template that has `isWeighted: true` (which is technically invalid but could be set in early draft payloads or manual configurations), the linter will trigger the `"PenaltyModeGroupSum"` error and block saving. The user will be unable to save the template because the linter enforces a sum of 100% on weights that are completely ignored by the scoring engine.
* **Mitigation**: Restrict the weighted sum check strictly to downward-facing (deductive) templates:
  ```csharp
  if (isWeighted && string.Equals(scoreDirection, "down", StringComparison.OrdinalIgnoreCase))
  ```

---

### 3. 🟡 WARNING: Named Parameter Compilation Breakages in `ActionPlanService.cs` Callers
* **Risk Domain**: Code Compilation & API Contracts
* **Scenario**: The plan proposes modifying the `ActionPlanService.AutoCreateAsync` signature to replace `string? scoringMode = null` with `string? scoreDirection = null`.
* **The Flop**: Both `CreateSubmission.cs` and `FinalizeSubmission.cs` call `ActionPlanService.AutoCreateAsync` using explicit named arguments:
  ```csharp
  await ActionPlanService.AutoCreateAsync(
      ...,
      scoringMode: submissionScoringMode,
      ...);
  ```
  If the named parameter `scoringMode` is changed in the service signature but the callers are modified to pass positional values, or if we overlook renaming the named arguments in the callers, the backend will fail to compile with `CS1739: The best overload for 'AutoCreateAsync' does not have a parameter named 'scoringMode'`.
* **Mitigation**: Callers must explicitly rename the named argument:
  ```csharp
  await ActionPlanService.AutoCreateAsync(
      ...,
      scoreDirection: scoreDirection,
      ...);
  ```

---

### 4. 🟡 WARNING: Malformed JSON Parsing Defaults to Checklist and Masking Score Mismatches
* **Risk Domain**: Error Handling & Fallbacks
* **Scenario**: If a client sends a malformed `ScoringLogicConfig` JSON or completely null payload, `ScoringConfigParser.Parse()` will catch the `JsonException` and fall back to returning `("down", false, false)` (Checklist mode).
* **The Flop**: While returning a safe fallback prevents server crashes, defaulting to Checklist mode for a template that was originally designed as Weighted Penalty (`"down"`, `true`) will cause the server to calculate a raw percentage instead of a weighted percentage. This will result in an instant score mismatch error (HTTP 400), but the error reason printed in the logs will be highly confusing because the parser masked the true malformed JSON issue.
* **Mitigation**: Keep the fallback return `("down", false, false)` to guarantee SRE resilience (no server crashes), but ensure that `JsonException` logging is elevated to `Log.Error` (instead of `Warning`) so that API-level parsing failures are highly visible in development and production telemetry.

---

## Audit Handoff Block

* **Audit Verdict**: **Resilient with Minor Adjustments**
* **Failure Report Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\scoring_redesign\audit_failure_report_20260529_232928_scoring_redesign_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md`
* **Next Steps**:
  1. Incorporate the defensively wrapped `(s.ScoreDirection == null || s.ScoreDirection != "none")` in `GetAnalytics.cs`.
  2. Scope the `TemplateLinter` group-sum rule strictly to `isWeighted && scoreDirection == "down"`.
  3. Mirror named parameter updates in both `CreateSubmission.cs` and `FinalizeSubmission.cs`.
