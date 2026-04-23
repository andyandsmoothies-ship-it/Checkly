# GEMINI.override.md — GlobalRisks Feature

## 1. Two Parallel Risk Systems — DO NOT MERGE

This codebase has TWO separate risk systems that MUST remain decoupled:

| System | Location | Purpose |
|---|---|---|
| **Old (Criterion-based)** | `Criterion.IsRisk`, `Answer.IsRisk` | Template-driven risk flags. Part of scoring. DO NOT touch. |
| **New (GlobalRisk-based)** | `GlobalRisk`, `SubmissionRisk` entities | Standalone, company-wide risk domain. Decoupled from scoring. |

**STRICTLY PROHIBITED:** Merging, linking, or cross-referencing the two systems.
**STRICTLY PROHIBITED:** Using `ScoringVerifier.cs` for GlobalRisk logic.
**STRICTLY PROHIBITED:** Adding GlobalRisks to the `SyncTemplates` response.

---

## 2. SubmissionRisk Unique Constraint — 409 Pattern

The `submission_risks` table has a DB-level unique index on `(submission_id, global_risk_id)`.

If you try to trigger the same risk twice on the same submission, EF throws `DbUpdateException` (Postgres error `23505`).

**The Slice 3 endpoint MUST catch this and return HTTP 409 Conflict:**
```csharp
catch (DbUpdateException ex) when (ex.InnerException?.Message.Contains("23505") == true)
{
    return TypedResults.Conflict("This risk has already been triggered for this submission.");
}
```

---

## 3. TriggeredById is a Store-Only FK (No Navigation Property)

`SubmissionRisk.TriggeredById` stores a `Guid?` pointing to `profiles.id`.

**PROHIBITED:** Adding a navigation property (`Profile TriggeredBy`) to `SubmissionRisk`.
**PROHIBITED:** Adding a `WithMany()` call to `ConfigureProfile` for this FK.

If the endpoint needs auditor profile data, join manually in the LINQ query.

---

## 4. Cascade Delete Rules

| FK | Behavior | Reason |
|---|---|---|
| `submission_risks.submission_id → submissions` | CASCADE | Risks belong to a submission. When submission is deleted, risks go too. |
| `submission_risks.global_risk_id → global_risks` | RESTRICT | Cannot delete a GlobalRisk that has been triggered in any submission. |

---

## 5. EF Change Tracker Gotcha — Restrict Delete Tests

When writing tests for the RESTRICT rule (cannot delete a GlobalRisk with triggered SubmissionRisks):
- **NEVER** call `db.GlobalRisks.Remove(risk)` in the same `db` scope where the `SubmissionRisk` was inserted.
- EF's client-side tracker throws `InvalidOperationException` before the DB constraint fires.
- **FIX:** Use a **separate `using var deleteScope`** to load and delete the `GlobalRisk` with a clean change tracker.

See `GlobalRiskEntityTests.SubmissionRisk_Restrict_WhenGlobalRiskDeleted` for the correct pattern.
