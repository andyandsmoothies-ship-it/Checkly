# Task: Investigate 'Opening Tasks' Subtitle on Action Plans
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: User Screenshot showing 'Opening Tasks' under the Action Plan title on the Action Plans tab.

## Root Cause
"Opening Tasks" is not hardcoded dummy text, nor is it a status. It is the **Template Section Name** (also known as the Group Title) that the failed task originally belonged to.

## Explicit Code Trace (Premises + Proof)
1. **The UI Layer**: In `lib/features/action_plans/widgets/action_plan_card.dart` (line 62), the subtitle field is bound to `plan.groupTitle`.
2. **The Data Layer**: In `server/Features/ActionPlans/CreateActionPlan.cs`, when a Store Manager creates an Action Plan from a failed audit, the system saves the `GroupTitle` of the failed criteria.
3. **The Origin**: In `lib/features/templates/models/wizard_starter_packs.dart` (line 34), we see that "Opening Tasks" is one of the default template sections provided for a "checklist" audit. 
   - Criteria inside that section include tasks like "Brief team on objectives".
   - When "Brief team on objectives" fails, it creates an action plan, and labels it with its parent section: "Opening Tasks".

## Proposed Scope-Limited Fix (Trade-offs)
**Current State**: The UI just prints "Opening Tasks" underneath the title. To a new user, this looks like a random phrase and lacks context.

**Option 1: Do nothing**
- *Pros*: Zero effort. Experienced users know it's the section name.
- *Cons*: Confuses new users.

**Option 2: Add Context Prefix in UI (Recommended)**
- *Fix*: In `action_plan_card.dart`, change `plan.groupTitle` to `'Section: ${plan.groupTitle}'` or `'Template Group: ${plan.groupTitle}'`.
- *Pros*: Instantly clarifies what the text means. Very low blast radius.
- *Cons*: Takes up slightly more horizontal space.

<forensic_evidence>
- `grep_search` "Action Plans"
- `list_dir` lib/features/action_plans/widgets
- `view_file` action_plan_card.dart
- `view_file` action_plan_dto.dart
- `grep_search` ActionPlanDto
- `view_file` ListActionPlans.cs
- `view_file` CreateActionPlan.cs
- `grep_search` "opening tasks"
- `view_file` wizard_starter_packs.dart
</forensic_evidence>

---

## Handoff Block
1. **Final Diagnostic Verdict**: "Opening Tasks" is the name of the section from the audit template where the failure occurred. The code is working correctly, but the UX is slightly ambiguous.
2. **Blast Radius**: Modifying the UI label string affects only the visual presentation on the Action Plan cards.
3. **AI Agent Mission Brief**: Update `action_plan_card.dart` to prepend "Section: " to the `groupTitle` text to improve user comprehension.
4. **Execution Queue**:
- [ ] @[/implement] docs/diagnostics/failure_report_20260509_132115_abc1_action_plan_subtitle.md
