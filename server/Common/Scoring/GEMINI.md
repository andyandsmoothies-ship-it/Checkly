# Scoring Module Gotchas

## ScoringVerifier.cs — CCP Section Must Be EXCLUDED, Not ZEROED

- **Problem:** When a CCP criterion has a fault, setting `sectionRatio = 0` but leaving the section's weight in `participatingWeight` produces a different weighted average than Flutter's engine. Flutter uses `continue` to skip the entire section from both numerator AND denominator.
- **Symptom:** `POST /submissions` returns 400 with "Score verification failed". Client sends `0`, server calculates a non-zero value.
- **Fix:** Use `if (ccpTriggered) continue;` before computing `sectionAfter`. This excludes the section from `sectionResults` entirely, so `participatingWeight` naturally excludes it.
- **Rule:** The server `ScoringVerifier` must be a STRICT mirror of Flutter's `ScoringEngine`. Any behavioral change in Flutter's penalty calculation MUST be ported to C# simultaneously. Use integration tests to enforce this.

## VerifyChecklist — Formula Is Raw Deduction From 100, NOT Ratio

- **Problem:** It's tempting to use `(totalPoints - totalDeductions) / totalPoints × 100` (a ratio) for checklist mode. This is mathematically different from `100 - totalDeductions` when deductions can exceed pointsWeight.
- **Canonical formula:** `max(0, 100 - Σ(faults × pointsWeight))` — raw deductions from 100, NO division.
- **Test spec source:** `scoring_engine_test.dart` V05 and V14 are the immutable truth. Do NOT change them.
- **Rule:** The server's `VerifyChecklist` must match this formula exactly. Any attempt to "normalize" with division by totalPoints will cause 400 errors on checklist-mode audits.

## Answer-Level RISK/CCP Override — Apply Before Verify()

- **Problem:** Auditors can manually flag any criterion as RISK or CCP at answer time. These flags lived only in Flutter's local `AuditAnswer` model and were never sent to the server. The server re-read only the criterion's template-level `IsRisk`/`IsCcp` flag, silently ignoring the auditor's override.
- **Fix:** `AnswerInput` now has `IsCcp = false` and `IsRisk = false`. `FinalizeSubmission` merges these into the in-memory `criteria` list before calling `scorer.Verify()`.
- **Rule:** Never read RISK/CCP exclusively from `Criterion.IsRisk` in the verifier if the caller has answer-level overrides. Always merge answer-level overrides onto the criteria before calling `Verify()`.

## Answer-Level Override Boundary Sync — BOTH Routes Must Be Patched

- **Problem:** The RISK/CCP override merge was applied to `FinalizeSubmission.cs` (PUT route) but NOT `CreateSubmission.cs` (POST route). Brand-new offline audits route to `POST /api/submissions`, so any auditor override on a fresh audit still triggered a 400.
- **Rule (STRICT):** Any scoring-verification logic change to `FinalizeSubmission.cs` MUST be simultaneously mirrored in `CreateSubmission.cs`. These two handlers share the same verification contract. Always grep for the other file when modifying either one.
- **Canary Search:** After any change to `scorer.Verify(` in one handler, run `grep_search "scorer.Verify("` across `server/Features/Submissions/` and verify ALL call sites received the same treatment.

## ScoringVerifier — Answer Override vs Template RISK (Two-Path Contract)

- **Gotcha 26 (SR): Answer-level RISK override must bypass `HasFaults`.**
  Template-level `IsRisk=true` only triggers RISK when the answer has a fault (`HasFaults` returns true).
  Answer-level override (`AnswerInput.IsRisk=true`) must trigger UNCONDITIONALLY — even when answer `Value` is 'conform'.
- **Root cause:** An auditor may escalate a 'conform' answer for offline compliance reasons. Flutter respects this (`isAnswerRisk` is checked before `_hasFault`). The server must match.
- **Implementation:** Pass `HashSet<Guid>? explicitRiskAnswerIds` to `Verify()`.
  RISK predicate: `(c.IsRisk || isExplicit) && (isExplicit || HasFaults(c, answers))`.
- **DO NOT simplify** back to `.Where(c => c.IsRisk).Any(c => HasFaults(...))` — this re-introduces the 400 bug (RT1 regression).
- **Rule (STRICT):** Callers (`CreateSubmission`, `FinalizeSubmission`) MUST extract `explicitRiskIds` from `request.Answers.Where(a => a.IsRisk)` and pass it to every `scorer.Verify()` call site.

## JSON Config Sync — ScoringLogicConfig Keys Must Be Explicitly Parsed AND Passed

- **Problem (April 2026):** `progressiveRepeat: true` was stored in the template's `ScoringLogicConfig` JSON. Flutter correctly read this and applied n²×rate deduction. The server read only `scoringMode` from the JSON and left `progressiveRepeatPenalty` at its C# default (`false`), applying n×rate. This caused a systematic score mismatch (client 80.0, server 91.43).
- **Root cause:** `ScoringVerifier.Verify()` optional parameters do **NOT** auto-read from the JSON blob. Each key must be explicitly parsed and passed.
- **Rule (STRICT):** Any new key added to `ScoringLogicConfig` MUST be parsed and forwarded in **BOTH** `CreateSubmission.cs` AND `FinalizeSubmission.cs`. Use the established `TryGetProperty` + `JsonValueKind.True` pattern:
  ```csharp
  if (configDoc.RootElement.TryGetProperty("progressiveRepeat", out var progElem) && progElem.ValueKind == JsonValueKind.True)
      progressiveRepeatPenalty = true;
  ```
- **Canary Search:** After adding any new config key, run `grep_search "TryGetProperty"` in `server/Features/Submissions/` and verify BOTH handlers are updated.
