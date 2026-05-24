# Research: Unified Start Hub for Campaigns and Audits

[ORIGIN_IDEA]: "I think the campaign creation and listing and preview, should not be as current, as it is a main feature like audit starting, while both using the same source are audit templates. please @[/research]. do not override any current research"

<latent_space_scratchpad>
**Reasoning & Tradeoffs:**
- **Status Quo Check**: Currently, there are two distinct entry points. Starting a single audit happens via the `ChecklyFab` (which pulls up a `TemplateSelector`). Creating a Campaign (Program) happens by navigating deep into the Admin Dashboard -> Active Programs -> Campaign List -> FAB. This arbitrarily demotes Campaigns to a secondary feature, even though they represent bulk execution of the *exact same* underlying `Template` entity.
- **E2E Scope**: In the backend (`server/Common/Persistence/Entities`), `Template.cs` is the parent entity. Both `Submission.cs` (Single Audit) and `Program.cs` (Campaign) use `Template.cs` as their blueprint. The current Flutter UI completely divorces these concepts by putting them in different UX silos.
- **Unified Hub Concept**: Since they share the exact same source (Audit Templates), the mental model should be: **Select the Template first**, then choose the **Execution Strategy**:
  1. Self-Perform (Start Audit Now)
  2. Delegate Single (Assign Task)
  3. Mass Execution (Create Campaign)
- **Impact**: This fundamentally rewrites the "Start" mental model. The current `/templates` tab is primarily a builder/management screen for Admins, and a lookup screen for Auditors. We need to evolve the `/templates` tab into a unified "Execution Hub".
</latent_space_scratchpad>

## E2E Workflow Map: Status Quo vs. Unified Hub Target

### Status Quo (Action-First, Fragmented)
1. **Single Audit**: `ChecklyFab` -> Choose Action ("Start Audit") -> Pick Template -> Execute.
2. **Campaign**: `Admin Dashboard` -> Active Programs -> Campaigns List -> Pick Action ("Create Campaign") -> Pick Template -> Pick Stores -> Execute.
*Result: Users must decide *how* they want to work before picking *what* they are working on. Campaigns are hidden.*

### Elevated Target (Template-First Unified Hub)
1. **Unified Hub**: User opens the `/templates` tab (or taps a central "Start" action).
2. **Template Selection**: User browses or searches the centralized Template Library.
3. **Execution Strategy Menu**: Upon tapping a Template, the user is presented with a strategy choice based on their PBAC role:
   - *Start Now* (Single Audit)
   - *Assign Task* (Delegate to 1 store/user)
   - *Create Campaign* (Mass assign to N stores)
*Result: Campaigns are elevated to a first-class citizen, immediately visible alongside standard audits, perfectly matching the underlying backend architecture.*

## Comparative Decision Matrix

### Option A: Strict Native Fit (Template Details Action Bar)
- **Concept**: Keep the current `/templates` tab exactly as it is. However, when you tap a `TemplateCard`, instead of just previewing it, you open a `TemplateDetailsPage` with a prominent, equal-weight action bar: [Start Now] | [Assign] | [Create Campaign].
- **Pros**: Very safe. Does not break the `ChecklyFab` or existing bottom navigation. Respects current ATDD tests that rely on `TemplateListPage`. 
- **Cons**: Still requires users to know they can launch a campaign from the Templates tab, which might not be immediately obvious if they are used to the `ChecklyFab`.
- **Effort**: Low (Track A). Requires modifying `TemplateCard` tap behavior and adding an action bar to the preview.

### Option B: Pragmatic Balance (The Global "Start" Hub)
- **Concept**: Deprecate the current `ChecklyFab` popup menu. Instead, the FAB opens a full-screen `ExecutionHubPage`. This page lists all templates. When you tap a template, a BottomSheet slides up with the 3 execution strategies (Start, Assign, Campaign).
- **Pros**: Consolidates all creation logic into a single, highly visible flow. Elevates campaigns to equal footing immediately.
- **Cons**: Deprecating the `ChecklyFab` menu will break multiple ATDD UI tests that explicitly look for `find.text('Start New Audit')` on the home screen.
- **Effort**: Medium (Track B). 

### Option C: Enterprise Overhaul (Dual-Mode Execution Architecture)
- **Concept**: Split the app into "Play" and "Build" modes. The `ChecklyFab` becomes a "Start Work" button that opens the unified execution hub (Template -> Strategy -> Execute). The current `/templates` tab is moved to an "Admin Settings" area solely for *building* and *editing* templates.
- **Pros**: Perfectly separates the "Creator" persona from the "Executor" persona. 
- **Cons**: Massive refactor of the `ShellRoute` bottom navigation. High risk of confusing existing users who expect templates to be on the main navbar.
- **Effort**: High (Track C).

## Blind Spots & Risks
1. **PBAC Role Gating**: Store Managers do not have `programsCreate` capability. If we unify the hub, we must dynamically render the "Create Campaign" button only for Admins/Area Managers. If we don't handle this perfectly, Store Managers will see disabled buttons or encounter unauthorized errors.
2. **List Previews**: The user also requested unifying "Campaign listing and preview". If we unify creation around Templates, we must decide if the *Active Campaigns List* also lives in this new Hub, or if it remains in the Admin Dashboard. Mixing active campaigns with raw templates in the same list could cause severe visual clutter.
3. **Template Sync Latency**: The unified hub assumes templates are instantly available. If the device is offline, `_templateManager.loadTemplates()` must rely on Drift caching, otherwise the entire "Start Hub" fails.

## Conflicts with Guidelines
- **Conflict**: Option B and C strictly violate the rule `Refactoring internal code should not break tests` without significant effort, as they fundamentally alter the `ChecklyFab` navigation contract which ATDD tests depend on.
- **Conflict**: The codebase uses the term "Program" (e.g., `programsCreate`, `ProgramApiService`), but the UI requires "Campaign". The unified hub UI must strictly map `Program` backend logic to `Campaign` UI text without renaming the C# or Dart files.

<forensic_evidence>
- `view_file` on `TemplateListPage.dart` to verify template listing logic.
- `view_file` on `ProgramDashboardPage.dart` to verify campaign listing and preview logic.
</forensic_evidence>

---

## Handoff Block

**Final Verdict**: Viable. **Option B** is the most cohesive "unified hub" approach that perfectly treats single audits and mass campaigns as equal execution strategies stemming from a single template source, though it requires updating ATDD tests. **Option A** is a safer, incremental step. Please select an option.

**Effort Sizing**: Track A (Low) / Track B (Medium). Concurrency Strategy: Sequential (UI layout first, PBAC gating second).

**AI Agent Mission Brief**: 
You are awaiting the user's decision on the Unified Start Hub architecture. Once the user selects Option A, B, or C, you will refactor the template execution flow so that Campaigns and Audits are launched from the same source component.

**Next Workflow Command**:
`@/implement {c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260514_000000_CM04_unified_hub.md}`
