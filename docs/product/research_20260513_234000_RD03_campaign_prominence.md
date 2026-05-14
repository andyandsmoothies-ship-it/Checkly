# Research: Elevating Campaign Creation Prominence

[ORIGIN_IDEA]: "I think the campaign creation and listing and preview, should not be as current, as it is a main feature like audit starting, while both using the same source are audit templates."

<latent_space_scratchpad>
**Reasoning & Tradeoffs:**
- **Status Quo Check**: I mapped the source code. Currently, the `ChecklyFab` handles "Start New Audit" (self-performed) and "Assign Task" (delegated single audit). Bulk Campaign creation is hidden deeply: `Home Dashboard` -> `Scroll down to KPI Panel` -> `Tap "Active Programs"` -> `Campaign List Page` -> `Tap FAB` -> `Create Wizard`.
- **E2E Conflict**: Both "Assign Task" and "Create Campaign" rely on `AppCapabilities.programsCreate` or `submissionsCreate`. They both use templates as their source. Hiding one while promoting the other creates an arbitrary hierarchy in the UX.
- **UI Constraints**: The bottom navigation (`ShellRoute` in `app_router.dart`) already has 6 tabs (`/home`, `/activity`, `/plans`, `/templates`, `/profile`, `/inbox`). Adding a 7th tab is a mobile UX anti-pattern. If we promote Campaigns to the bottom nav, we must replace an existing tab (likely `/templates`).
- **ATDD Implications**: If we modify `ChecklyFab`, we must ensure existing `find.text('Assign Task')` tests don't break. If we replace the `/templates` tab, tests expecting `find.byIcon(Icons.description)` on the bottom nav will break.
</latent_space_scratchpad>

## E2E Workflow Map: Status Quo vs. Elevated Target

### Status Quo (Fragmented Journeys)
1. **Start Single Audit**: `Home` -> `ChecklyFab` -> `Start New Audit` -> `Template Selector`
2. **Assign Single Audit**: `Home` -> `ChecklyFab` -> `Assign Task` -> `Schedule BottomSheet`
3. **Create Campaign**: `Home` -> `Scroll to Status Panel` -> `Tap "Active Programs"` -> `Campaign List` -> `FAB` -> `Campaign Wizard`

### Elevated Target (Unified Prominence)
The goal is to bring "Campaigns" out of the Admin Dashboard metrics panel and place it front-and-center, visually equal to single audits.

## Comparative Decision Matrix

### Option A: Strict Native Fit (The FAB & Dashboard Promotion)
- **Concept**: Add "Create Campaign" to the global `ChecklyFab` menu. Replace the generic "Active Programs" KPI row with a dedicated, top-level "Campaigns Hub" Action Card on the Admin Dashboard.
- **Pros**: Zero breaking changes to the bottom nav. Requires minimal routing changes. Very low risk to ATDD contracts.
- **Cons**: `ChecklyFab` gets slightly crowded with 3 options.
- **Effort**: Low (Track A)

### Option B: Pragmatic Balance (Bottom Nav Tab Swap)
- **Concept**: Replace the `/templates` tab in the bottom nav with a new `/campaigns` tab. The template builder and raw template list are moved into an "Admin Settings" menu. 
- **Pros**: Massive visibility boost. Campaigns become a first-class citizen alongside Activity and Plans.
- **Cons**: Breaks the mental model for store managers who use the Templates tab to browse ad-hoc forms. Breaks ATDD tests expecting the Templates tab.
- **Effort**: Medium (Track B)

### Option C: Enterprise Overhaul (Unified "Work Hub")
- **Concept**: The `/templates` tab becomes a unified "Start Hub". A user selects a template, then chooses the execution strategy: (1) Self-Perform, (2) Delegate Single, or (3) Mass Campaign.
- **Pros**: Perfectly aligns with your insight that "both use the same source are audit templates." 
- **Cons**: Requires deprecating the `ChecklyFab` entirely and rewriting the entire wizard architecture to be template-first instead of action-first.
- **Effort**: High (Track C)

## Blind Spots & Risks
1. **Role Gating Complexity**: The `ChecklyFab` currently checks `submissionsCreate` and `programsCreate`. Adding a third option requires careful logic so Store Managers don't accidentally see "Create Campaign".
2. **ATDD Test Fragility**: Options B and C will absolutely break existing ATDD testing contracts related to the bottom navigation bar and FAB interactions.
3. **Mobile Space Constraints**: Adding more options to the FAB popup could push it off-screen on smaller devices like the iPhone SE if we don't adjust the padding properly.

## Conflicts with Guidelines
- **Conflict**: Option B and C conflict with the `[GEMINI.md]` rule: "Refactoring internal code should not break tests". Modifying the fundamental navigation architecture (`ShellRoute`) will require extensive test rewrites.

---

## Handoff Block

**Final Verdict**: Viable. **Option A** is the safest, immediate win without breaking ATDD tests, but **Option C** is the most architecturally sound based on your feedback. Please select an option.

**Effort Sizing**: Track A (Low) / Track C (High).

**AI Agent Mission Brief**: 
You are awaiting the user's decision on how to elevate the Campaign feature's prominence. Once selected, you will modify `app_router.dart`, `checkly_fab.dart`, and `dashboard_page.dart` to implement the new access patterns.

**Next Workflow Command**:
`@/implement {docs/product/research_20260513_234000_RD03_campaign_prominence.md}`
