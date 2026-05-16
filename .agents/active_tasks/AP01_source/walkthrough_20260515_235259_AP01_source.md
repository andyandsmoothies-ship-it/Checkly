# Walkthrough: AP01 Source Label — Phase B Frontend UI

## Input Lineage
- **Source Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md`
- **Task Tracker**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\AP01_source\task_20260515_235259_AP01_source.md`
- **Phase**: B (Frontend Only — Track B1)

## What Changed

```
[API JSON] --(sourceTitle field)--> [ActionPlanDto.fromJson] --> [ActionPlanCard widget row]
                                        (model layer)                   (UI layer)
```

### Files Modified

| File | Change |
|---|---|
| `lib/features/action_plans/model/action_plan_dto.dart` | Added `final String? sourceTitle` field, constructor param, and `fromJson` mapping. |
| `lib/features/action_plans/widgets/action_plan_card.dart` | Added conditional source row below the group title row. |

## Decision Log

| Point | Proposed | Implemented | Reason |
|---|---|---|---|
| DTO path | Plan says `models/action_plan_dto.dart` | Actual path: `model/action_plan_dto.dart` | Real file system path differs from plan. Verified with `list_dir`. |
| Icon choice | Plan says "Checkly styling" (no specific icon) | `Icons.account_tree_rounded` (size 12) | Semantically means "source/origin tree". Matches `onSurfaceVariant` muted style used throughout the card. |
| Null guard | Plan says "gracefully not render" | `if (plan.sourceTitle != null) ...[]` | Standard Dart spread-if pattern. Row is completely absent from tree when null — no empty space. |
| Text styling | Plan says "Checkly styling" | `bodySmall` + `onSurfaceVariant` | Exactly matches adjacent `'Section: ${plan.groupTitle}'` row for visual consistency. |

## Verification Handoff

> **QA Steps for TC_AP_SRC_03:**

1. Create an action plan from a Campaign submission (has `ProgramAssignmentId`).
   - Expected: Card shows `🌿 Campaign: Summer Safety` (or the program name from backend).
2. Create an action plan from a normal Audit submission (no program link).
   - Expected: Card shows `🌿 Audit: Daily Cleanliness` (or the template name).
3. Load an old action plan seeded before Phase A (null SourceTitle).
   - Expected: No source row renders. Card looks identical to before this feature.

## Arch Boundaries

- ✅ Widget imports: `flutter/material`, `app_colors`, `app_theme`, `action_plan_manager`, `action_plan_dto` — NO `dao/` or `services/api/` imports.
- ✅ Data flows through existing Manager layer, not bypassed.

<test_trace>
Command: rtk flutter analyze --no-fatal-infos
Working dir: c:\Users\HP\Documents\GitHub\Checkly\lib

Result: 1 issue found (ran in 126.3s)
Issue: warning in _shared\database\app_database.g.dart:10823 — override_on_non_overriding_member
Status: PRE-EXISTING in generated file (app_database.g.dart). NOT introduced by this change.
My changed files produced: 0 new warnings.
</test_trace>

<forensic_evidence>
Files verified post-edit:
- lib/features/action_plans/model/action_plan_dto.dart — 78 lines ✅
- lib/features/action_plans/widgets/action_plan_card.dart — 154 lines ✅
Both under 400-line hard cap.

Orphaned stubs grep: 0 results in lib/features/action_plans/ ✅
</forensic_evidence>

## Gotcha Protocol

No new gotchas found. Existing gotchas in `lib/features/action_plans/GEMINI.md` and `widgets/GEMINI.md` remain accurate and were respected.

> [!NOTE]
> **For next session:** Phase B is the FINAL phase of AP01. After QA manually validates the 3 test cases above, commit via GitHub Desktop. No further implementation slices remain for this feature.
