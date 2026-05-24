# ADR: Synthesizing Campaign Prominence vs Unified Hub

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260514_000000_CM04_unified_hub.md`
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260513_234000_RD03_campaign_prominence.md`

[ORIGIN_IDEA]: "I think the campaign creation and listing and preview, should not be as current, as it is a main feature like audit starting, while both using the same source are audit templates. please @[/research]. do not override any current research"

<latent_space_scratchpad>
Both research artifacts identified the same core UX problem: single audits and bulk campaigns are both executions of a "Template", yet the UI completely divorces them. CM04 proposes moving the starting point entirely to the Templates tab or a new Hub. RD03 proposes forcing Campaigns into the ChecklyFab or replacing a bottom tab.
The unified hub (Option 3) sounds elegant on paper but introduces catastrophic offline risk if the hub fails to load. The ChecklyFab addition (Option 1) is a band-aid that clutters the UI. The bottom tab swap (Option 4) breaks PBAC access for Store Managers. The Template Details Action Bar (Option 2) is a pragmatic compromise that solves the semantic issue (templates are the source) without breaking the bottom nav or FAB tests.
</latent_space_scratchpad>

## 1. Normalized Options

- **Option 1: The Promoted FAB (RD03 - Option A)**: Add "Create Campaign" to the existing `ChecklyFab` alongside "Start Audit". 
- **Option 2: The Template Details Action Bar (CM04 - Option A)**: Leave the FAB alone. When tapping a template in the existing `/templates` tab, show 3 equal-weight buttons: [Start Now], [Assign], [Create Campaign].
- **Option 3: The Template-First Execution Hub (CM04 Option B / RD03 Option C)**: The `ChecklyFab` opens a full-screen `ExecutionHubPage` where users select a Template *first*, then choose the execution strategy.
- **Option 4: Bottom Nav Tab Swap (RD03 Option B)**: Replace the `/templates` tab with a `/campaigns` tab.

## 2. Hostile Interrogation (Red Teaming)

- **Option 1 (Promoted FAB) Attack**: Store Manager logs in. A brief offline status delays PBAC capability syncing. The FAB incorrectly shows "Create Campaign". The manager taps it, resulting in a 403 Forbidden API crash and a total UI freeze on the main dashboard.
- **Option 2 (Template Details Action Bar) Attack**: O(N) tap fatigue. Admins want to mass-assign 5 campaigns. They must navigate to `/templates`, scroll, tap, load details, tap "Create Campaign" 5 separate times. Management of active campaigns becomes orphaned from creation.
- **Option 3 (Template-First Execution Hub) Attack**: Offline drift catastrophe. `_templateManager.loadTemplates()` fails on a weak connection. Because the *entire* execution flow now depends on this single unified hub loading the full template list first, users cannot perform simple ad-hoc offline audits. The app becomes a brick in low-connectivity retail zones.
- **Option 4 (Bottom Nav Tab Swap) Attack**: Store Managers use the `/templates` tab purely as a reference library for operational standards. Replacing it with `/campaigns` forces them to go to "Admin Settings" to find forms, but PBAC blocks them from settings. They are locked out of reading SOPs.

## 3. Pugh Decision Matrix

| Criteria | Option 1 (Promoted FAB) [Baseline] | Option 2 (Template Action Bar) | Option 3 (Unified Execution Hub) | Option 4 (Tab Swap) |
|---|---|---|---|---|
| Origin Idea Alignment | 0 | +1 | +1 | -1 |
| Offline Resilience | 0 | 0 | -1 | 0 |
| UX Speed (Time-to-Start) | 0 | -1 | -1 | +1 |
| Blast Radius (ATDD Breakage) | 0 | 0 | -1 | -1 |
| PBAC Safety | 0 | +1 | -1 | -1 |
| **Total** | **0** | **+1** | **-3** | **-2** |

## 4. Executive Business Summary
The goal was to make Campaigns a "main feature" on par with starting single audits, recognizing that both are just different ways to execute a Template. 
While overhauling the entire app into a "Template-First Hub" sounds appealing, it introduces massive risks for offline users who just need to quickly start an audit when the internet drops. 

The mathematical winner is the **Template Details Action Bar**. This means we will keep the current navigation, but when you view a Template, you will see three equal-weight actions: Start Single Audit, Assign Task, and Create Campaign. This perfectly ties the actions to their source (the Template) without breaking existing tests or risking offline reliability.

---

## Handoff Block

**Final Verdict**: Option 2 (Template Details Action Bar) is the winner.

**Strict Constraints**:
1. Do not modify the `ShellRoute` bottom navigation.
2. The `ChecklyFab` remains untouched to preserve ATDD tests.
3. The "Create Campaign" button in the Template Details view MUST be completely omitted from the layout (not just disabled) for users without the `programsCreate` capability to prevent 403 crashes and UI confusion.
4. Remove the redundant "Quick Start" option from `TemplateCard`'s 3-dot context menu. All execution must strictly flow through the new `TemplateDetailsPage` action bar to reinforce the unified mental model.

**Execution Slices**:
- **Phase A (Action Bar UI)**: Modify `TemplateDetailsPage` to include the 3 execution buttons ([Start Now] | [Assign] | [Create Campaign]). These must be placed in a Persistent Bottom Action Bar or a prominent sticky header so they are always visible and not buried at the bottom of long template previews.
- **Phase B (PBAC Gating)**: Implement PBAC gating (`PolicyManager.can(AppCapabilities.programsCreate)`) on the action bar, ensuring unauthorized roles don't see the campaign option.
- **Phase C (Admin Dashboard Hub)**: Add an "Active Campaigns" section to the Admin Dashboard. Crucially, place a massive, primary `[ + New Campaign ]` button directly on this widget (which opens a "Select a Template" flow). This widget must also act as a direct portal to `ProgramListPage` and `ProgramDashboardPage`, treating campaign "listing" and "previewing" as first-class destinations.

**Requirements Alignment Check**:
*Warning*: This decision fundamentally alters the user flow defined in any prior `requirements.md` regarding campaign creation. The User flow must be updated to reflect that creation originates from the `/templates` tab or the new Admin Dashboard portal.

**AI Agent Mission Brief**: 
You will implement the "Template Details Action Bar" architecture with a prominent Dashboard portal. Update the Template view UI to surface the 3 execution strategies in a sticky header/bottom bar (omitting campaigns if lacking PBAC), remove the Quick Start context menu, and add a massive `[ + New Campaign ]` portal to the Admin Dashboard to elevate listing and creation.

**Next Workflow Command**:
`@[/implement] {c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260513_234747_SYN01_campaigns.md}`
