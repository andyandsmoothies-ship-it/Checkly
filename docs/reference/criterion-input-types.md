# Template Criterion Input Types — Reference Table

> **Purpose**: Single source of truth for all 7 criterion input types.  
> Prevents future implementers from re-introducing scoring bugs by being unaware of the scored/unscored split.  
> **Last Updated**: 2026-03-27 (P3 of Cascading Constraint Model cleanup)

---

## The 7 Input Types

| Input Type | Category | Points Field Shown | CCP/Risk Toggles | Special Editor | Notes |
|------------|----------|--------------------|------------------|----------------|-------|
| `pass_fail` | ✅ **Scored** | Editable number | ✅ Shown | None | Binary: pass or fail |
| `numeric` | ✅ **Scored** | Editable number | ✅ Shown | None | Free numeric entry |
| `fault_count` | ✅ **Scored** | Editable number | ✅ Shown | None | Count of observed faults |
| `scale` | ✅ **Scored** | Auto-synced (read-only) | ✅ Shown | Scale Options editor | Points = highest option's value |
| `text` | ❌ **Unscored** | Hidden | ❌ Hidden | None | Data collection only |
| `single_choice` | ❌ **Unscored** | Hidden | ❌ Hidden | Choice Options editor (≥ 2 options required) | Data collection only |
| `multi_choice` | ❌ **Unscored** | Hidden | ❌ Hidden | Choice Options editor (≥ 2 options required) | Data collection only |

---

## Critical Rules (Gotcha #11)

> [!IMPORTANT]
> Every location in the codebase that checks `pointsWeight` or renders scoring UI **MUST** first check `inputType`. The unscored types (`text`, `single_choice`, `multi_choice`) must be explicitly excluded.

This pattern appears in **5 enforced locations**:

| Location | File | Guard |
|----------|------|-------|
| Wizard payload builder | `template_wizard_page.dart` — `_buildCriterion()` | `!isChoiceType && inputType != 'text'` |
| Builder payload builder | `template_builder_page.dart` — `_buildGroupsRecursive()` | `inputType != 'text' && inputType != 'single_choice' && inputType != 'multi_choice'` |
| Criterion editor — Points Weight field | `criterion_editor.dart` — drawer | `inputType != 'text' && inputType != 'single_choice' && inputType != 'multi_choice'` |
| Criterion editor — CCP/Risk toggles | `criterion_editor.dart` — drawer | Same 3-way exclusion |
| Test helper | `wizard_payload_test.dart` — `buildGroupsRecursive()` | Mirrored from wizard |

---

## Scale Type Special Behaviour

When `inputType == 'scale'`:
- The **Points Weight** field becomes **read-only** and auto-displays the highest `point` value from `scaleOptions`.
- When the user switches **to** `scale`, the `pointsCtrl` is immediately synced to `max(option.points)` (implemented in `criterion_editor.dart` InputType callback).  
- `metadata` field stores: `{"scaleOptions": [{"label": "...", "points": 10}, ...]}`

---

## Choice Types Special Behaviour

When `inputType == 'single_choice'` or `'multi_choice'`:
- A **Choice Options editor** appears, requiring ≥ 2 options (enforced by `_validateCriteriaList` in `template_wizard_page.dart`).
- `metadata` field stores: `{"options": ["Option A", "Option B", ...]}`
- These types are **intentionally excluded** from scoring. Adding variable-weight choice scoring would require a metadata schema change. (Tracked as Blind Spot #3 in research.)

---

## The Cascading Constraint Model

The scoring engine processes the template tree recursively. Input type choices at the criterion level cascade upward:

```
Criterion (inputType + isCcp + isRisk)
    └─> Sub-Section score (maxPoints - deductions, capped)
            └─> Section score (if ANY criterion has isCcp=true AND fails → section = 0%)
                    └─> Final score (if ANY criterion has isRisk=true AND fails → audit = 0%)
```

See `scoring_engine.md` (Scoring Engine KI) for the full recursive algorithm.
