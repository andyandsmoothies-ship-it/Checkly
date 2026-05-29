<latent_space_scratchpad>
Pattern Label: ADVISORY RULE ENGINE + REAL-TIME SIMULATOR
This is NOT a state machine. It is a stateless rule processor that reads
the in-memory template tree and outputs a severity-graded warning list.
The Live Score Simulator is a separate read-only "what-if" calculator
layered on top of the existing Flutter ScoringEngine.

Key findings from codebase inspection:
- ScoringHelpers.IsPureAudit() (server/Common/Scoring/ScoringHelpers.cs:26)
  already encodes the "mixed audit = null score" rule. The C# linter must
  call this same logic — no new math needed, just expose it in the linter.
- template_builder_page_validation.dart already has a blocking validation
  extension pattern (_validate() → ValidationErrors). The linter EXTENDS
  this pattern for advisory warnings — same architecture, different severity.
- SaveTemplateTree.cs returns TemplateTreeDto on save. We can piggyback
  lint warnings in a new optional field without breaking existing consumers.
- No new DB table is needed. Linter results are ephemeral, computed on
  every save call, returned in the API response and discarded.
- The Dart linter runs LOCALLY (debounced, 800ms) so no network round-trip
  per keystroke. The C# linter runs ON SAVE only.
- Live Score Simulator: purely in-memory Dart computation. Zero backend calls.
  It reuses Flutter's existing ScoringEngine (already in lib/features/audit/).
- RISK: The simulator needs to import audit-domain scoring logic into
  templates-domain — a cross-feature dependency. Solution: extract
  ScoringEngine into lib/_shared/services/ or pass it as a pure function.
  This is the ONLY architectural seam risk in the entire epic.
- Responsive layout: LayoutBuilder wrapping TemplateBuilderPage body.
  If width >= 800px → 3-column Row. If width < 800px → TabBarView with 3 tabs.

Shapes evaluated:
  B1: Dart-only linter (no backend changes) → fails R4 (server-side contract)
  B2: Dual linter (Dart debounced + C# on save) → covers all requirements
  Winner: B2
</latent_space_scratchpad>

# Epic Analysis: Audit Template Flexibility — Smart Linter & Live Score Simulator

**Date**: 2026-05-29 | **ConversationID**: ac4575e5-39d8-4b20-a4a6-49ce53ce5264
**Track**: C | **Effort**: 3–4 dev days

---

## Input Lineage

- **Source**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260528_161500_template_flexibility_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`

---

## Executive Summary

The Audit Template Engine grants admins full structural freedom, which allows invalid configurations (e.g., mixed scored/unscored criteria, penalty mode with no weights) to reach the database and poison downstream Boardroom analytics (BOD).

**Approved Solution**: A **dual-layer Smart Linter** (Dart + C#) that inspects the template tree and emits two severity levels — blocking Errors and advisory Warnings — without restricting the admin's design freedom. A **Live Score Simulator** panel is added to the Admin Template Editor so admins can preview score behavior before publishing.

**Pattern**: Advisory Rule Engine + Real-Time Simulator. No new database tables. No new entities. Zero migration risk.

```
[Admin builds template tree in TemplateBuilderPage]
        │
        ├──► [Dart Linter — debounced 800ms] ──► [TemplateLinterPanel: shows Errors + Warnings]
        │                                                │
        │                                               └──► [LintWarningCard — click scrolls to offending item]
        │
        ├──► [Live Score Simulator Panel] ──► [Toggle pass/fail per question → live % score]
        │
        ▼ (Admin taps Save)
[PUT /api/templates/{id}/tree]
        │
        └──► [C# TemplateLinter.Run(tree)] ──► [LintResult appended to SaveTreeResponse]
                                                      │
                                                      └──► Blocking errors → HTTP 422 Unprocessable
                                                           Advisory warnings → HTTP 200 + warnings[]
```

---

## Decision Matrix

### Requirements

| ID | Requirement |
|----|-------------|
| R1 | Admin sees blocking errors (Publish disabled) for structurally invalid templates |
| R2 | Admin sees advisory warnings (Publish allowed with bypass checkbox) for risky configs |
| R3 | Linter warnings are admin-only — Auditor execution screens are completely clean |
| R4 | Backend independently validates on save (server is the source of truth) |
| R5 | Warnings do not add sync payload cost to field devices |
| R6 | Dart validation runs without network round-trips (no per-keystroke API calls) |
| R7 | Admin can simulate scoring before publishing |
| R8 | No new database tables or migrations |
| R9 | Works on both mobile and desktop layouts |

### Shapes

**Shape B1: Dart-Only Linter** — All linting runs purely in Flutter. No C# changes.
**Shape B2: Dual Linter (Dart + C#)** — Dart runs locally/debounced; C# validates on save.

### Fit Check

| Requirement | Shape B1 | Shape B2 |
|-------------|:--------:|:--------:|
| R1 — Blocking errors | ✅ | ✅ |
| R2 — Advisory warnings | ✅ | ✅ |
| R3 — Admin-only | ✅ | ✅ |
| R4 — Server-side trust | ❌ | ✅ |
| R5 — No sync payload cost | ✅ | ✅ (warnings not in sync endpoint) |
| R6 — No per-keystroke API calls | ✅ | ✅ |
| R7 — Score Simulator | ✅ | ✅ |
| R8 — No migrations | ✅ | ✅ |
| R9 — Responsive layout | ✅ | ✅ |

**Winner: Shape B2.** B1 fails R4 — a malicious or buggy client could bypass Dart-only linting and save an invalid tree to the database.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| ScoringEngine cross-feature import (audit → templates) | 🔴 High | Extract `ScoringEngine` pure calculation function to `lib/_shared/services/scoring/` before Slice 3 |
| Dart debounce timer causes `A Timer is still pending` in widget tests | 🟡 Medium | Cancel timer in `dispose()` (see GEMINI.md Gotcha: Async Timer pending) |
| Simulator shows wrong result if ScoringEngine is not an exact mirror of backend | 🟡 Medium | Verify against existing `ScoringVerifier` unit tests (already cover all 4 modes) |
| C# linter breaks existing valid templates retroactively | 🟡 Medium | Linter is advisory only for existing templates; blocking rules apply only to new saves |
| `TemplateLinterPanel` overflow on narrow screens | 🟢 Low | `ConstrainedBox(maxHeight: 180) + ListView` (specified in research doc) |

### SRE Architectural Flops (Pre-Implementation Review)

Before writing code, three critical architectural gaps ("flops") were identified and added as mandatory fixes:

1. **Duplicate ID Key Collision Crash in EF Core Tracking**
   - **Risk**: An admin payload with duplicate UUIDs (either groups or criteria) causes `db.Criteria.Add()` or `existingCriterionMap` tracking to crash with `System.InvalidOperationException` (500 Server Error) instead of returning a clean 422 validation response.
   - **Mitigation**: Add a blocking linter rule `DuplicateIdCheck` to reject duplicate IDs with `HTTP 422`.
2. **Deeply Nested Groups Calculation Failure (Depth > 2)**
   - **Risk**: Both C# `VerifyPenalty` and Dart `ScoringInputMapper` only support a 2-level hierarchy (Sections and Subsections). Nesting groups deeper than 2 levels causes silent calculation drift and intermediate properties to be ignored.
   - **Mitigation**: Add a blocking linter rule `MaxNestingDepthExceeded` to reject templates containing groups nested deeper than 2 levels.
3. **Integer Overflow in C# Progressive Repeat Penalty**
   - **Risk**: `answer.RepeatedFaults` is a 32-bit `int`. Computing `answer.RepeatedFaults * answer.RepeatedFaults` inside `ScoringHelpers.GetDeduction` causes integer overflow for fault counts above 46,340, yielding negative deductions (which boosts user scores).
   - **Mitigation**: Cast to `decimal` *before* multiplication: `(decimal)answer.RepeatedFaults * (decimal)answer.RepeatedFaults * impact`.

### SRE Architecture Audit Report Additions (Resilience & Security Check)

Following the Architecture Audit Report findings, three additional safety rules have been incorporated:

1. **IDOR Tenant Ownership Security**
   - **Risk**: An admin from Tenant A could modify the payload to PUT a template tree belonging to Tenant B, resulting in cross-tenant data corruption.
   - **Mitigation**: Backend PUT handler (`SaveTemplateTree.cs`) must authorize the request by verifying the logged-in user belongs to the tenant that owns the template.
2. **Poison Pill Payload Size Limit**
   - **Risk**: A massive template payload (e.g. 50,000 criteria) could trigger Out-Of-Memory (OOM) exceptions or CPU starvation during database tracking or linter validation.
   - **Mitigation**: Enforce a hard cap of maximum 500 criteria/nodes in the payload at the entrypoint before running database operations or linter logic.
3. **UI 422 Server Error Display Fallback**
   - **Risk**: If the C# and Dart linter rules drift, the frontend might permit a save but the backend will reject it with HTTP 422. The user will be stuck with a generic, unhelpful error toast.
   - **Mitigation**: Implement 422 response body binding in `TemplateLinterPanel` and `template_builder_page.dart` so backend linter failures are parsed and rendered directly to the user as clear red cards.

---

## Visual & Functional Context

### UI Screens Affected

| Screen | File | Change |
|--------|------|--------|
| Template Builder (Admin only) | `lib/features/templates/pages/template_builder_page.dart` | Add `TemplateLinterPanel` + `LiveScoreSimulator` panel |
| Template Builder Validation | `lib/features/templates/pages/template_builder_page_validation.dart` | Extend with advisory warning logic (separate from blocking errors) |

### New Widgets (Admin-Only)

| Widget | Path | Layout Risk |
|--------|------|-------------|
| `TemplateLinterPanel` | `lib/features/templates/pages/widgets/template_linter_panel.dart` | Max 180px, ConstrainedBox + ListView |
| `LintWarningCard` | `lib/features/templates/pages/widgets/lint_warning_card.dart` | Wrap label in `Expanded` — no overflow |
| `LiveScoreSimulator` | `lib/features/templates/pages/widgets/live_score_simulator.dart` | Right panel (desktop) / Tab 3 (mobile) |

### Responsive Layout

```
Desktop (width >= 800px):
[  Question Editor  ] | [ Linter Panel ] | [ Score Simulator ]
       flex: 3              flex: 2              flex: 2

Mobile (width < 800px):
TabBar: [ 📝 Design ] [ ⚠️ Issues ] [ 🧮 Simulator ]
```

### Traceability: Auditor View

- **Auditor's `AuditFormPage`**: Zero changes. Linter panel is gated behind an admin-only widget, never imported into audit screens.

---

## System Context

### RBAC / Capability Gate
- Linter panel is rendered only inside `TemplateBuilderPage`. This page is already gated by `templates:create` / `templates:update` capabilities (Admin only). No new PBAC rules needed.

### Offline / Sync
- Lint warnings are **NOT** added to `SyncTemplates.cs` endpoint. They are ephemeral, returned only on the `PUT /tree` save response.
- Sync payload to field devices remains unchanged.

### API Contract

**Existing**: `PUT /api/templates/{id}/tree` → `200 TemplateTreeDto`

**Modified response** (additive, backward-compatible):
```json
{
  "id": "...",
  "title": "...",
  "groups": [...],
  "lintResult": {
    "errors": [
      { "ruleId": "PenaltyModeGroupSum", "message": "Group weights must sum to 100%", "targetId": "group-uuid" }
    ],
    "warnings": [
      { "ruleId": "MixedAuditWarning", "message": "Mixed scored/unscored criteria — score will be NULL on dashboards", "targetId": null }
    ]
  }
}
```

**Blocking error behavior**: C# linter runs before `db.SaveChangesAsync()`. If any blocking error is found → return `HTTP 422` with `lintResult`. The tree is NOT saved.

---

## Lifecycle Context

### Edge Cases

| Case | Behavior |
|------|----------|
| Template is all survey questions (`inputType = 'text'`) | No `MixedAuditWarning` — purity gate not applicable to surveys |
| Admin publishes with advisory warnings (bypass checkbox checked) | `PUT /tree` succeeds, response includes `warnings[]` array, Flutter shows toast |
| Admin has existing invalid template (pre-linter) | C# linter returns warnings but does NOT block save — advisory-only for existing data |
| `progressiveRepeat` is ON but all criteria have `minusImpact = 0` | `ProgressiveZeroImpact` warning fires |
| `IsRisk = true` on a survey-mode template | `SilentRiskInSurvey` warning fires (risk never triggers in survey mode) |

### Rollback Plan
- All new code is additive. `lintResult` field is new and nullable — existing Flutter clients that do not know about it will ignore it safely.
- C# blocking validation can be disabled via a feature flag (appsettings) without a deployment.

---

## Data Context

**No new database tables. No migrations.**

| Entity | Change |
|--------|--------|
| `Template` | No change |
| `Group` | No change |
| `Criterion` | No change |
| `SaveTreeRequest` (DTO) | No change (input) |
| `TemplateTreeDto` (DTO) | Add optional `LintResult? LintResult` field to response |

New C# types (in-memory only, no DB mapping):

```csharp
public sealed record LintIssue(string RuleId, string Message, Guid? TargetId, string Severity);
public sealed record LintResult(List<LintIssue> Errors, List<LintIssue> Warnings);
```

New Dart types:
```dart
class LintIssue { final String ruleId; final String message; final String? targetId; final String severity; }
class TemplateLintResult { final List<LintIssue> errors; final List<LintIssue> warnings; }
```

---

## Architecture Flow

```
[Admin types in TemplateBuilderPage]
    │
    ├──► _onChange() → debounce timer 800ms
    │         └──► DartTemplateLinter.run(sections, scoringMode)
    │                   └──► setState({ lintResult })
    │                              └──► TemplateLinterPanel rebuilds
    │
    ├──► LiveScoreSimulator (stateful widget)
    │         └──► Reads _sections + simulator toggle state
    │                   └──► _SharedScoringEngine.calculate() → displays %
    │
    └──► _save() [admin taps Publish]
              │
              ├──► DartTemplateLinter.run() — if blocking errors → abort, scroll to error
              │
              └──► PUT /api/templates/{id}/tree [SaveTreeRequest]
                        │
                        ├──► TemplateLinter.Run(request) [C# — runs BEFORE SaveChangesAsync]
                        │         ├──► Blocking errors → return HTTP 422 LintResult
                        │         └──► Warnings → continue save
                        │
                        └──► db.SaveChangesAsync()
                                  └──► return HTTP 200 TemplateTreeDto + lintResult
                                            └──► Flutter shows advisory toast if warnings[]
```

---

## Risk Review & Security

**DB Architect (8/10)**: No schema changes. Advisory-only for existing templates prevents retroactive migration breakage. Concern: LintResult in response adds ~1–3KB per save call — acceptable.

**Security Auditor (9/10)**: Blocking linter runs server-side before commit. A malicious client cannot bypass it by spoofing the Dart-only check. Lint data is read-only and not persisted. No new attack surface.

**Junior Dev (8/10)**: The dual-linter pattern is easy to follow — the Dart linter is a plain static function, the C# linter is a plain static class. Complexity risk: the responsive layout (LayoutBuilder + TabBarView) may be confusing. Mitigated by building it in Slice 3 with a clear example.

All scores ≥ 7 — plan passes.

---

## Logs & Audits

- Existing `AuditLogger.Log(db, user, "template_tree_saved", ...)` in `SaveTemplateTree.cs` covers the save event.
- No new audit log entries needed. Lint warnings are ephemeral — they are not audit events.

---

## Testing Expectations

| Layer | Test Type | What to verify |
|-------|-----------|----------------|
| C# `TemplateLinter` | Unit (TDD) | Each rule fires correctly and independently |
| `SaveTemplateTree` + linter | Integration (ATDD) | `PUT /tree` with invalid tree returns HTTP 422 with correct `lintResult` |
| `DartTemplateLinter` | Widget/Unit | Each Dart rule fires, debounce cancels correctly |
| `TemplateLinterPanel` | Widget | Renders error cards, empty state = zero height |
| `LiveScoreSimulator` | Widget | Score % updates when toggle changes, RISK triggers to 0% |
| Responsive layout | Widget | LayoutBuilder renders 3-column above 800px, TabBarView below |

---

<command_logs>
- view_file: .agents/persona/scout_persona.md
- view_file: GEMINI.md, README.md
- view_file: server/Features/Templates/SaveTemplateTree.cs
- view_file: lib/features/templates/pages/template_builder_page.dart
- view_file: lib/features/templates/pages/template_builder_page_validation.dart
- view_file: lib/features/templates/pages/widgets/builder_validation_banner.dart
- view_file: server/Common/Scoring/ScoringHelpers.cs
- view_file: server/Common/Scoring/ScoringVerifier.cs
- view_file: server/Features/Templates/Dtos.cs
- view_file: lib/features/templates/models/template_dto.dart
- view_file: lib/features/templates/GEMINI.md
- grep_search: LintWarning (server/Features/Templates) — 0 results (no existing linter)
- grep_search: scoringMode/ScoringLogicConfig (server) — confirmed JSON blob pattern
- grep_search: survey|mixed.*audit (server/Common) — confirmed IsPureAudit() reuse point
- list_dir: lib/features/templates/ (full tree mapped)
</command_logs>

---

## Handoff Block

**Approved**: Shape B2 — Dual Linter (Dart debounced + C# on save) + Live Score Simulator.
**Epic Plan Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-flexibility\analysis_epic_20260529_104152_audit_template_flexibility_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md`

---

### Slices

**Slice 1: C# Backend Linter**
- **Plain English**: Build the server-side rule engine that checks the template tree when the Admin clicks Save. If a rule is violated badly (like empty groups or wrong weight totals), it blocks the save and returns an error. Lighter issues become advisory warnings in the response. Also enforces payload limits and tenant authorization checks.
- **Why this step now?** The server is the truth. We build the contract first so Slice 2 (Dart) has a real API to mirror, not a guess.
- **Scenario Focus**: Basic Scenario — Admin saves a template with one blocking error.
- **Value Delivered**: `PUT /tree` with a penalty template missing weights returns `HTTP 422` with a structured `lintResult` JSON. Large templates or unauthorized requests are rejected safely.
- **Entry State Required**: `SaveTemplateTree.cs` exists and passes all existing tests.
- **Exit State Guaranteed**: `TemplateLinter.Run()` fires before `SaveChangesAsync()`. All 6 blocking rules and 4 advisory rules pass unit tests. `TemplateTreeDto` response carries a `LintResult?` field. `ScoringHelpers.GetDeduction` casts `RepeatedFaults` to `decimal` *before* multiplication to eliminate the progressive repeat integer overflow flop. Payload size check and tenant authorization check are enforced in `SaveTemplateTree.cs`.
- **Architectural Scope**: `server/Features/Templates/TemplateLinter.cs` [NEW], `server/Features/Templates/SaveTemplateTree.cs` [MOD — add linter call, tenant ownership check, and 500-node check], `server/Features/Templates/Dtos.cs` [MOD — add LintResult field].
- **Acceptance Criteria**:
  - `PenaltyModeGroupSum`: weights summing to 95% → HTTP 422, `errors[0].ruleId = "PenaltyModeGroupSum"`
  - `EmptyStructureCheck`: template with 0 groups → HTTP 422
  - `DuplicateIdCheck` (Flop #1): two groups or criteria with duplicate Guid ID → HTTP 422, `errors[0].ruleId = "DuplicateIdCheck"`
  - `MaxNestingDepthExceeded` (Flop #2): a group nested 3 levels deep (Group -> Subsection -> Subsubsection) → HTTP 422, `errors[0].ruleId = "MaxNestingDepthExceeded"`
  - `EmptySectionName`: group with blank title → HTTP 422
  - `ProgressiveRepeatOverflow` (Flop #3): high repeated fault count does not overflow or yield negative deductions → Verify calculations are overflow-safe.
  - `PayloadSizeCap` (Audit Risk #2): template with > 500 total criteria/groups → HTTP 400 Bad Request
  - `TenantOwnerAuthorization` (Audit Risk #3): PUT tree requesting save on a template ID owned by another tenant → HTTP 403 Forbidden or 404 Not Found
  - `MixedAuditWarning`: pass_fail criterion (weight=10) beside text criterion → HTTP 200, `warnings[0].ruleId = "MixedAuditWarning"`
  - `SilentRiskInSurvey`: `isRisk=true` on survey template → HTTP 200, warning fires
  - `ProgressiveZeroImpact`: progressiveRepeat ON + minusImpact=0 → HTTP 200, warning fires
  - Existing valid template saves → HTTP 200, `lintResult.errors = []`

---

**Slice 2: Dart Linter + TemplateLinterPanel UI**
- **Plain English**: Mirror the server rules inside Flutter. The Admin sees warnings as they design the template — no network call, instant feedback. The `TemplateLinterPanel` widget shows red error cards and yellow warning cards inside the builder.
- **Why this step now?** Slice 1 defined the rule contract. Slice 2 implements that same contract in Dart so the Admin gets instant feedback without waiting for a Save round-trip.
- **Scenario Focus**: Basic Scenario — Admin sees a live `MixedAuditWarning` card appear while editing.
- **Value Delivered**: Admin sees `⚠️ Mixed Audit — score will be NULL` warning card in real-time while editing sections. The Publish button is disabled if any blocking error is active. Advisory warnings show a bypass checkbox.
- **Entry State Required**: Slice 1 complete. `LintResult` DTO exists in Flutter (`lib/features/templates/models/`).
- **Exit State Guaranteed**: `DartTemplateLinter.run()` fires on an 800ms debounce. All 6 blocking rules (including duplicate IDs and max nesting depth of 2) are verified. The frontend handles backend HTTP 422 responses and binds custom server-side errors into the linter panel. All linter results display in `TemplateLinterPanel`. Clicking a `LintWarningCard` scrolls to the offending item. Timer is cancelled in `dispose()`.
- **Architectural Scope**: `lib/features/templates/utils/dart_template_linter.dart` [NEW], `lib/features/templates/pages/widgets/template_linter_panel.dart` [NEW], `lib/features/templates/pages/widgets/lint_warning_card.dart` [NEW], `lib/features/templates/pages/template_builder_page.dart` [MOD — wire linter, catch HTTP 422 and map to LintResult + bypass checkbox], `lib/features/templates/pages/template_builder_page_validation.dart` [MOD — separate blocking/advisory severity].
- **Acceptance Criteria**:
  - `DartTemplateLinter` unit test: each of the 10 rules fires independently
  - Widget test: `TemplateLinterPanel` renders zero height when `lintResult` is empty
  - Widget test: `LintWarningCard` wraps text in `Expanded` (no overflow)
  - Widget test: Publish button is disabled when `errors.isNotEmpty`
  - Widget test: bypass checkbox appears when `warnings.isNotEmpty && errors.isEmpty`
  - Widget test: When save fails with HTTP 422 and a `LintResult` payload, `TemplateLinterPanel` displays the server's custom errors (Audit Risk #1).
  - Timer pending test: widget teardown does not throw "A Timer is still pending"
  - Auditor screens (`AuditFormPage`): zero widget tests find `TemplateLinterPanel`

---

**Slice 3: Live Score Simulator**
- **Plain English**: Add an interactive panel where the Admin can toggle questions to "Pass" or "Fail" and instantly see what the final score percentage would be. It also shows a big red alert if the RISK flag would trigger.
- **Why this step now?** Slice 2 gives the Admin warnings. Slice 3 gives them answers — they can fix issues and immediately preview the mathematical result before publishing.
- **Scenario Focus**: Basic Scenario — Admin toggles a question to "Fail" and sees the score drop from 100% to 85% in real-time.
- **Value Delivered**: Admin can interact with the `LiveScoreSimulator` panel, toggle each question, and see a live score %. RISK trigger shows `🔴 RISK: Score forced to 0%`.
- **Entry State Required**: Slice 2 complete. Responsive layout scaffold (`LayoutBuilder`) wired in `template_builder_page.dart`.
- **Exit State Guaranteed**: `LiveScoreSimulator` computes score using `_SharedScoringEngine` (extracted from `lib/features/audit/` or duplicated as a pure function in `lib/_shared/`). Widget tests confirm score calculation for all 4 modes (penalty, accumulation, checklist, survey).
- **Architectural Scope**: `lib/_shared/services/scoring/scoring_calculator.dart` [NEW — pure function extracted from audit ScoringEngine], `lib/features/templates/pages/widgets/live_score_simulator.dart` [NEW], `lib/features/templates/pages/template_builder_page.dart` [MOD — responsive LayoutBuilder + TabBarView].
- **Acceptance Criteria**:
  - Widget test: All criteria passing → simulator shows `100%`
  - Widget test: One `pass_fail` criterion failed (weight=10, total=100) → simulator shows `90%`
  - Widget test: Any `isRisk=true` criterion failed → `🔴 RISK: Score forced to 0%` visible
  - Widget test: Survey mode → simulator shows `Survey — no score`
  - Widget test: Mixed audit (purity gate fails) → simulator shows `Mixed — score will be NULL`
  - Widget test: `LayoutBuilder` at 900px width → 3-column Row rendered
  - Widget test: `LayoutBuilder` at 400px width → `TabBarView` with 3 tabs rendered

---

### Handoff Roadmap

Execute slices **ONE AT A TIME** in this order:

- **Slice 1** [Risk: Network/Database] → **Write Acceptance Tests first → then Build**
  - Scope: `server/` only. Zero Flutter changes.
- **Slice 2** [Risk: Internal Logic] → **Write Unit Tests first → then Build**
  - Scope: `lib/features/templates/` only. Zero server changes.
- **Slice 3** [Risk: Internal Logic + Visuals] → **Write Unit Tests first → then Build**
  - Scope: `lib/_shared/` + `lib/features/templates/` only.

Blocking order: Slice 1 → Slice 2 → Slice 3. Each slice is **[SEQUENTIAL]**.
