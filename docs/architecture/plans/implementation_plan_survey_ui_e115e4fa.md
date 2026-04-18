# Implementation Plan: Hide Points Weight UI for Survey Mode
**Date:** 2026-04-18 | **Conversation ID:** e115e4fa-b153-4727-b0a6-f68ef620d42a
**Source ADR:** `C:\Users\HP\.gemini\antigravity\brain\a2d83fa4-a43e-41ba-95b0-058e32c7eaa2\decision_record_math_ui_a2d83fa4.md.resolved`
**Track:** B1 (Direct Implement — Low Risk, single UI conditional, no new patterns)

---

<latent_space_scratchpad>
## Edge Case Reasoning

**The two-gate problem:**
The current Points Weight block has one gate: hide if `inputType ∈ {text, single_choice, multi_choice}`.
The bug: a legacy template with `inputType = pass_fail` but `scoringMode = survey` bypasses this gate and shows Points Weight.

**Fix strategy - two options:**
A) Prepend a top-level `if (scoringMode == 'survey') const SizedBox.shrink()` that short-circuits the entire block.
B) Add `|| scoringMode == 'survey'` to the first branch of the existing if-else chain.

Option A is cleaner and more readable. It communicates the intent at a glance: "Survey mode = no points, full stop." Option B embeds the mode check into input-type logic which violates single responsibility.

**Summary card badge (lines 505-508):**
The inline summary card also shows a `${points}pt` badge. It uses the same input-type guard. We MUST apply the same `scoringMode == 'survey'` guard here for visual consistency — otherwise the drawer hides Points Weight but the card summary still shows "10pt" badge.

**Comment update:**
The comment on line 345 currently reads:
`//  - single_choice / multi_choice: HIDDEN (survey-only, no scoring)`
This is now factually wrong — we're hiding in survey mode regardless of input type. Update the comment to reflect the new two-gate logic.

**Scope:**
- Both hunks are in the same file, so this is still ONE micro-slice.
- No model changes. No backend changes. No routing changes.
- `scoringMode` is already passed to `CriterionEditor` from `section_editor.dart` — no prop chain changes needed.

**Risk of touching summary badge:**
Minimal. The badge is cosmetic. If we DON'T add the guard there, a user in Survey mode sees "10pt" on the card but no Points Weight in the drawer. This is inconsistent and confusing. The fix is required.
</latent_space_scratchpad>

---

## Executive Summary & YAGNI

**Goal:** When `scoringMode == 'survey'`, hide the Points Weight input in the criterion drawer **and** suppress the `pt` badge on the criterion summary card — regardless of what `inputType` the criterion has.

**YAGNI — What is OUT OF SCOPE:**
- ❌ No changes to `EditableCriterion` model
- ❌ No changes to backend `ScoringVerifier.cs`
- ❌ No changes to any other widget (section_editor, template_builder_page, etc.)
- ❌ No data clearing / scrubbing logic (the ADR constrains this to UI-only)
- ❌ No changes to Checklist mode behavior — Points Weight stays visible

---

## Trade-Off Analysis

| Approach | Pros | Cons |
|---|---|---|
| **Option A (chosen): Top-level `if (scoringMode == 'survey')` guard** | Clean intent, readable, survives future input type additions | Slightly longer diff |
| **Option B: Add `\|\| scoringMode == 'survey'` to first branch** | Shorter diff | Mixes mode check into input-type logic, harder to reason about |

**Rationale:** Option A chosen. One clear statement — "Survey? No points. End of story." — is easier to audit and maintain than a multi-condition boolean buried in the middle of a chain.

---

## Risk Assessment

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| Checklist math broken | Low | Critical | Guard is strictly `== 'survey'` — checklist is untouched |
| Badge still visible after drawer fix | Low | Medium | Fix both hunks in same slice |
| `scoringMode` is null | Low | Low | Guard uses `scoringMode == 'survey'` — null evaluates false, so all other modes work correctly |

---

## NFR Constraints

| Dimension | Requirement |
|---|---|
| **Performance** | Trivial `String ==` comparison. Zero latency impact. |
| **Security** | No auth surface touched. No data transmitted. |
| **Observability** | No telemetry needed for a cosmetic guard. |

---

## 4-State Matrix

| State | Expected Behavior |
|---|---|
| **Survey mode, pass_fail input** | Points Weight HIDDEN in drawer. `pt` badge hidden on card. ✅ Bug is fixed. |
| **Survey mode, text/choice input** | Points Weight HIDDEN (already hidden by input type gate, now also by mode gate). No change. |
| **Checklist mode, pass_fail input** | Points Weight VISIBLE. Math intact. ✅ Constraint 1 respected. |
| **Penalty / Accumulation mode, pass_fail input** | Points Weight VISIBLE. No change. |

---

## Business Rules

1. **[MATH_SAFETY]** `scoringMode == 'checklist'` MUST always show Points Weight.
2. **[SURVEY_HIDE]** `scoringMode == 'survey'` MUST always hide Points Weight, regardless of `inputType`.
3. **[SCOPE]** Only `criterion_editor.dart` is modified.

---

## Proposed Changes

| Status | File | Change |
|--------|------|--------|
| [MOD] | `lib/features/templates/widgets/criterion_editor.dart` | **Hunk 1:** Add `if (scoringMode == 'survey') const SizedBox.shrink() else` wrapper around the existing Points Weight block (lines 342–375). Update comment. |
| [MOD] | `lib/features/templates/widgets/criterion_editor.dart` | **Hunk 2:** Add `&& scoringMode != 'survey'` to the summary card `pt` badge guard (lines 505–508). |

---

## Execution Slices

### Slice 1 [BLOCKING] — Single file, two hunks in `criterion_editor.dart`

**Hunk 1 — The drawer Points Weight block (lines 342–376)**

Replace this:
```dart
                // Points weight:
                //  - pass_fail / numeric: editable text field
                //  - scale: read-only (auto-synced from highest option value)
                //  - single_choice / multi_choice: HIDDEN (survey-only, no scoring)
                if (criterion.inputType == 'single_choice' ||
                    criterion.inputType == 'multi_choice' ||
                    criterion.inputType == 'text')
                  const SizedBox.shrink() // No points weight for survey inputs
                else if (criterion.inputType == 'scale')
                  ListTile(
                    ...
                  )
                else
                  TextFormField(
                    ...
                  ),
```

With this:
```dart
                // Points weight visibility rules:
                //  - survey mode:  ALWAYS HIDDEN (null score — no math applies)
                //  - pass_fail / numeric: editable text field
                //  - scale: read-only (auto-synced from highest option value)
                //  - single_choice / multi_choice / text: HIDDEN (unscored input types)
                if (scoringMode == 'survey')
                  const SizedBox.shrink() // Survey mode: no scoring concept exists
                else if (criterion.inputType == 'single_choice' ||
                    criterion.inputType == 'multi_choice' ||
                    criterion.inputType == 'text')
                  const SizedBox.shrink() // No points weight for unscored input types
                else if (criterion.inputType == 'scale')
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Points Weight'),
                    trailing: Text(
                      criterion.pointsCtrl.text.isEmpty
                          ? '0'
                          : criterion.pointsCtrl.text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Theme.of(ctx).textTheme.titleMedium?.fontSize,
                      ),
                    ),
                    subtitle: const Text('Auto-set from highest scale option'),
                  )
                else
                  TextFormField(
                    controller: criterion.pointsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Points Weight',
                      helperText: 'Max score to award or multiplier for faults',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                  ),
```

**Hunk 2 — The summary card `pt` badge (lines 505–508)**

Replace this:
```dart
                            if (criterion.pointsCtrl.text.isNotEmpty &&
                                criterion.inputType != 'text' &&
                                criterion.inputType != 'single_choice' &&
                                criterion.inputType != 'multi_choice') ...[
```

With this:
```dart
                            if (criterion.pointsCtrl.text.isNotEmpty &&
                                scoringMode != 'survey' &&
                                criterion.inputType != 'text' &&
                                criterion.inputType != 'single_choice' &&
                                criterion.inputType != 'multi_choice') ...[
```

---

## Tactical Rollback Plan

This change is a pure UI conditional. Rollback = revert the two hunks in `criterion_editor.dart`. No DB migrations. No data loss. No API changes.

---

## Verification Plan

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | `flutter analyze` in project root | Zero new warnings or errors |
| 2 | Open Template Builder → set mode to **Survey** → open any criterion drawer | Points Weight field is GONE, regardless of input type |
| 3 | Change mode to **Checklist** → open any criterion drawer | Points Weight field is VISIBLE |
| 4 | Change mode to **Penalty** → open any criterion drawer | Points Weight field is VISIBLE |
| 5 | In **Survey** mode, check criterion summary card | `pt` badge is NOT shown on card |
| 6 | In **Checklist** mode, check criterion summary card | `pt` badge IS shown as before |

---

<forensic_evidence>
## Forensic Evidence (Research Commands Run)

```
view_file: criterion_editor.dart (full file, 615 lines)
grep_search: "scoringMode" in lib/ → 40+ hits confirming prop is already passed
grep_search: "CriterionEditor" in lib/ → 3 hits, only called from section_editor.dart
view_file: criterion_editor.dart lines 342–376 (Points Weight block)
view_file: criterion_editor.dart lines 500–520 (summary card badge)
```

**Key Facts Confirmed:**
- `scoringMode` is already a prop on `CriterionEditor` (line 10, 21) — no prop chain changes needed
- `CriterionEditor` is called in exactly 2 places in `section_editor.dart`, both already passing `scoringMode: scoringMode`
- The bug root cause (from ADR) is confirmed: line 346 checks only `inputType`, not `scoringMode`
- Summary card badge (lines 505–508) also has the same gap — must fix both hunks
</forensic_evidence>

---

## Strict Implementation Constraints (Carry-Forward)

> [!CAUTION]
> **Constraint 1 (MATH_SAFETY):** You are STRICTLY PROHIBITED from hiding Points Weight when `scoringMode == 'checklist'`. Only `'survey'` triggers the hide.

> [!IMPORTANT]
> **Constraint 2 (SCOPE):** Touch only `criterion_editor.dart`. Do NOT touch `section_editor.dart`, `template_builder_page.dart`, `EditableCriterion`, or any backend file.

> [!NOTE]
> **Gotcha:** `scoringMode` is `String?` (nullable). The guard `scoringMode == 'survey'` safely returns `false` when null. No null-check needed.

---

## Handoff Block

**AI Agent Mission Brief:**
Open `lib/features/templates/widgets/criterion_editor.dart`. Apply two hunks: (1) prepend `if (scoringMode == 'survey') const SizedBox.shrink() else` before the existing Points Weight input-type chain at ~line 346, and (2) add `&& scoringMode != 'survey'` to the summary card `pt` badge condition at ~line 505. Run `flutter analyze` to verify. Do NOT touch any other file.

**Next Command (Builder):**
```
@[/implement] Execute based on this exact plan:
C:\Users\HP\.gemini\antigravity\brain\e115e4fa-b153-4727-b0a6-f68ef620d42a\implementation_plan_survey_ui_e115e4fa.md
```

**Concurrency:** This is a single [BLOCKING] slice. No parallel dispatch needed.
**Track:** B1 — Switch to Forge Builder to execute.
