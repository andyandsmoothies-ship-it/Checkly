# Research: Campaign (Program) UX/UI Redesign

[ORIGIN_IDEA]: "I need a comprehensive re design the UI/UX and the user journey of the whole feature campaign please @[/research]"

<latent_space_scratchpad>
**Reasoning & Tradeoffs:**
- **Status Quo**: The current campaign pages (`ProgramListPage`, `ProgramCreateWizardPage`, `ProgramDashboardPage`) use default Material widgets. They are highly functional but visually sparse and generic. Error states block the entire screen (e.g., in `ProgramDashboardPage` when `_error` is non-null, it wipes out the whole dashboard). The wizard is a modal-like structure but requires navigating away for store picking.
- **Visual Clutter & Hierarchy**: Just like the dashboard previously, the Program Dashboard lists each assignment in an identical `Container` bounding box. There is no clear distinction between overdue, pending, or submitted assignments without reading small text pills.
- **User Journey**: The creator journey in `ProgramCreateWizardPage` feels fragmented because of the persistent bottom action bar that becomes active only at the end, and nested navigation for template/store picking.
- **Consistency**: The naming convention refers to "Programs" in code and URLs (`/programs`), but the user domain vocabulary refers to "Campaigns". This mismatch causes cognitive dissonance (Conflict).
- **Offline Strategy**: Currently, the dashboard and list pages are marked online-only (`ProgramApiService`), meaning Area/Store Managers who go offline can't even see the read-only dashboard. Sync is handled on `ProgramAssignments` via Drift, but the high-level reporting is live.
</latent_space_scratchpad>

## E2E Workflow Map

1. **Campaign Creation (Admin/Platform)**
   - **Trigger**: Fab on `/programs` -> `/programs/new`
   - **UI**: `ProgramCreateWizardPage` (4 steps: Info, Template, Stores, Review).
   - **Backend**: `POST /api/programs`
   - **Friction**: The persistent "Issue Program" button feels disconnected from the linear flow. Template picking is a BottomSheet, Store picking pushes a new route. This fragmented navigation disrupts the wizard illusion.

2. **Campaign Dashboard (Area Manager/Admin)**
   - **Trigger**: Tap on program list -> `/programs/review/:id`
   - **UI**: `ProgramDashboardPage` with `ProgramKpiCard`, `ProgramSegmentedBarChart`, and filter chips.
   - **Backend**: `GET /api/programs/{id}/summary` & `GET /api/programs/{id}/assignments`
   - **Friction**: The full-screen error state blocks caching/retries gracefully. The assignment list lacks pagination and visual hierarchy for urgent (Overdue) vs. benign (Verified) statuses.

3. **Campaign Execution (Store Manager)**
   - **Trigger**: Dashboard banner -> `/programs/:assignmentId`
   - **UI**: `ProgramExecutionPage` -> `ProgramOutboxDao` (Drift).
   - **Friction**: Covered in earlier fixes, but the transition from Dashboard to Execution needs to feel cohesive with the new capped container approach.

## Comparative Decision Matrix

| Option | Approach | Architecture Implication | Verdict |
|---|---|---|---|
| **A. Strict Native Fit (Pragmatic Polish)** | Retain the current page structures but upgrade the widgets. Move from `ListTile` to custom bounded cards, refine typography, and implement soft-retry error boundaries instead of full-screen errors. | Zero backend changes. Medium UI effort. High safety. | **Approved** |
| **B. Pragmatic Balance (Offline-First Dashboard)** | Implement offline caching for `ProgramDashboardPage` and `ProgramListPage` so they remain usable without network, mirroring the execution layer's offline capabilities. | High Flutter effort. Requires new Drift tables (`CachedProgramSummaries`) and SyncApi extensions. | **Rejected** (Scope creep for a pure UX/UI redesign) |
| **C. Enterprise Overhaul (Campaign Workspace)** | Consolidate the List, Dashboard, and Wizard into a single "Campaign Workspace" with dual-pane layout for desktop/tablet, and seamless wizard transitions. | Massive refactoring of router and all `Program*` pages. High risk of breaking TC-04/05 ATDD contracts. | **Rejected** |

## Blind Spots
1. **Network Payload Size**: If a campaign is assigned to 2,000 stores, `GET /api/programs/{id}/assignments` will choke the mobile UI thread because there is no pagination in `_load()`.
2. **Offline Interactivity**: If a user is offline, the floating action button to create a program will fail ungracefully, as it relies on live HTTP calls.
3. **Template Syncing**: `_templateManager.loadTemplates()` is non-blocking in the wizard, but if it takes too long, the user opens an empty bottom sheet.

## Rules Conflicts
1. **Gotcha: Terminology Map**: User called it "Campaign" but the codebase enforces "Program". We MUST NOT rename the code files or database entities to Campaign. We must only adjust the visible UI strings (Business Language).
2. **Testing is Architecture**: The wizard's persistent "Issue Program" button exists specifically to satisfy `find.byKey(Key('issue_program_button'))` from any step. Redesigning this wizard to a standard Stepper might break the ATDD contract if the button isn't immediately resolvable in the widget tree.

<forensic_evidence>
- `view_file` on `ProgramCreateWizardPage.dart`
- `view_file` on `ProgramDashboardPage.dart`
- `view_file` on `ProgramListPage.dart`
</forensic_evidence>

## Handoff Block

**Final Verdict**: Viable. Proceed with **Option A (Strict Native Fit)**.

**Effort Sizing**: Track A (Medium effort, constrained to UI layer).

**AI Agent Mission Brief**: 
You are to execute a UI/UX polish on the `programs` feature folder. Upgrade `ProgramListPage`, `ProgramDashboardPage`, and `ProgramCreateWizardPage` to use modern, visually rich components (replacing generic `ListTiles`), implement soft-retry error states (removing full-screen blockers), and update the business language in the UI from "Program" to "Campaign" without renaming actual files or classes.

**Next Workflow Command**:
`@/implement {docs/product/research_20260513_140500_RD02_campaign_redesign.md}`
