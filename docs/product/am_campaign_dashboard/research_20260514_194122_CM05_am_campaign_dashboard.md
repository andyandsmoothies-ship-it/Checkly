# Research: Area Manager Campaign Feature Design

[ORIGIN_IDEA]: "i am not decided yet. please @[/research]the design related to the campaign feature for the AM. we implemented some for the Admin and SM already. as the AM and auditor in this campaign feature, their roles are just like reporting than execution"

<latent_space_scratchpad>
**Reasoning & Tradeoffs:**
- **Status Quo Check**: Currently, `AdminActiveCampaignsWidget` handles active campaigns for Admins (Creators). `ActionRequiredWidget` handles campaign execution assignments for Store Managers (Executors). The Area Manager and Auditor share the "middle ground" but currently act as Executors in the backend (they have `programs:execute`).
- **Reporting Paradigm Shift**: The user states AMs/Auditors are for *reporting*, not execution. This means they need to see aggregate progress across multiple stores, rather than being assigned individual tasks. 
- **E2E Scope**: 
  - Backend: `server/Program.cs` needs to revoke `programs:execute` from AMs (optional but aligns with reporting), and grant `programs:list` (to see the campaigns) and `programs:assignments_list` (to view execution progress across stores). 
  - API: `ProgramApiService` might need an endpoint to fetch aggregate completion stats for a campaign scoped by Area. Currently, `/api/programs` returns active campaigns.
  - Frontend: `ManagerDashboardVariant` (for AMs) and `AuditorDashboardVariant` currently lack a reporting widget. `AdminActiveCampaignsWidget` could be renamed to `ActiveCampaignsWidget` and shared, but it primarily shows "total assigned", not "completion rate". A dedicated reporting widget might be better.
</latent_space_scratchpad>

## E2E Workflow Map: Area Manager Campaign Reporting

### Upstream Triggers (Backend PBAC)
1. Admin creates a Campaign (`programs:create`) and assigns it to multiple stores.
2. The Backend PBAC is updated to grant `programs:list` and `programs:assignments_list` to `area_manager` and `auditor` roles.

### Downstream Effects (Frontend UI)
1. Area Manager logs in and lands on `DashboardPage`.
2. `ManagerDashboardVariant` detects `programs:list` capability and renders a new or shared Campaign Widget.
3. Instead of seeing a "Start Audit" CTA, the widget emphasizes completion rates (e.g., "4/10 stores completed") for the campaigns active in their area.
4. Tapping a campaign drills down into a "Campaign Progress Report" showing which stores are lagging, allowing the AM to follow up.

## Impact Spectrum

### Option A: Strict Native Fit (Shared Widget)
- **Concept**: Rename `AdminActiveCampaignsWidget` to `ActiveCampaignsWidget`. Add it to `ManagerDashboardVariant` and `AuditorDashboardVariant`. Use PBAC to hide the `[ + New Campaign ]` button for non-admins.
- **Pros**: Fastest implementation. High code reuse. Immediately solves the empty dashboard gap.
- **Cons**: The widget currently displays generic data ("30 stores assigned") rather than actionable reporting data for AMs ("5 stores in your area completed it, 3 are overdue").
- **Effort**: Low (Track A). 

### Option B: Pragmatic Balance (Area Progress Widget)
- **Concept**: Create a distinct `CampaignProgressWidget` specifically for AMs and Auditors. This widget queries `/api/programs/assignments` scoped to their area, displaying progress bars for active campaigns instead of just listing them.
- **Pros**: Perfectly aligns with the "reporting" persona. Gives AMs immediate visual feedback on compliance across their stores.
- **Cons**: Requires a new backend DTO projection to aggregate assignment completion rates by campaign, and a new Flutter UI component with progress bars.
- **Effort**: Medium (Track B).

### Option C: Enterprise Overhaul (Full Analytics Drill-Down)
- **Concept**: Remove campaigns from the dashboard entirely for AMs. Instead, create a dedicated `/campaign-analytics` tab in the bottom navigation. This page offers heatmaps, store-by-store compliance tables, and automated push notification nudges.
- **Pros**: Maximum value for reporting personas. Extremely powerful enterprise feature.
- **Cons**: Massive scope creep. Over-engineers a problem that might just need simple visibility.
- **Effort**: High (Track C).

## Blind Spots & Risks
1. **Area Scoping (Data Leakage)**: If an AM is granted `programs:list`, the backend MUST strictly scope the returned campaigns to only those that apply to stores within their assigned `AreaId`. If not, an AM might see active campaigns for a different region they have no jurisdiction over.
2. **Payload Size vs. Aggregation**: Querying all assignments for a campaign on the client to calculate completion percentage is too expensive. The backend must provide pre-aggregated completion stats in the `ProgramDto` to keep the dashboard performant.
3. **Auditor Context**: Auditors often operate globally or across regions. Defining their "scope" for campaign reporting might be difficult if they aren't tied to a specific `AreaId`.

## Conflicts with Rules
- **Conflict**: The codebase relies on the term "Program" internally. Creating new widgets like `CampaignProgressWidget` will require strict adherence to naming conventions (file named `program_progress_widget.dart` but UI says "Campaign Progress").
- **Conflict**: Rule "Test Both Sides" — if we build Option B, we must write integration tests for the new backend projection BEFORE building the Flutter UI.

<forensic_evidence>
- `grep_search` on `ManagerDashboardVariant` to audit current status quo for AMs.
- `view_file` on `AppRole.dart` and `Program.cs` to verify backend PBAC seeds.
</forensic_evidence>

---

## Handoff Block

**Final Verdict**: Viable. **Option B (Area Progress Widget)** is the strongest architectural fit. Since the AM and Auditor are "reporting" roles, simply showing them the admin widget (Option A) is insufficient because they need to see *progress and completion rates*, not just the template name.

**Effort Sizing**: Track B (Medium). Concurrency Strategy: Sequential (Backend DTO/PBAC updates first, then Flutter UI implementation).

**AI Agent Mission Brief**: 
You are awaiting the user's decision on the AM Campaign Reporting Architecture. Once the user selects Option A, B, or C, implement the backend PBAC updates (`programs:list`, `programs:assignments_list`) and build the corresponding UI reporting widget for the Area Manager dashboard.

**Next Workflow Command**:
`@/implement {c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260514_194122_CM05_am_campaign_dashboard.md}`
