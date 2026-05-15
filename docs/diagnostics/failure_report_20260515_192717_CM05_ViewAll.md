# Diagnostic Report: Area Manager View All Campaigns Click Bug

## Input Lineage
- Source Input: Clicking 'View all campaigns (4)' on Area Manager dashboard shows nothing. 
- Log shows `[19:26:31 INF] HTTP GET /api/notifications responded 200 in 4.8183 ms` which is unrelated background polling.

## Root Cause
The `CampaignProgressWidget` was implemented with a placeholder `onPressed` callback for the "View All Campaigns" button:
```dart
onPressed: () {},
```
Additionally, there is no dedicated page implemented yet for the Area Manager to view their full list of campaigns. The existing `ProgramListPage` is for HQ (`/programs`) and the existing `ProgramAssignmentListPage` is for Store Managers' pending tasks (`/programs/assignments`).

## Explicit Code Trace (Premises + Proof)
1. `CampaignProgressWidget.dart` line 85 contains `onPressed: () {},`. When tapped, nothing happens. The background inbox poller coincidentally logs a `/api/notifications` hit at the same time.
2. `ActionRequiredWidget.dart` (which handles Store Manager tasks) correctly navigates via `context.push('/programs/assignments')`. 
3. Scanning `app_router.dart` shows no route for Area Campaigns (e.g., `/programs/area-campaigns`). 

## Proposed Scope-Limited Fix
**Trade-offs / Pros & Cons:**
The fix involves three parts:
1. **Create `AreaCampaignListPage`**: A new page that uses `FutureBuilder` or state to fetch `ProgramApiService().getAreaCampaignProgress()` and display the list.
   - **Pros:** Proper deep-linkable page that guarantees fresh data via pull-to-refresh.
   - **Cons:** Slightly duplicates the card UI from `CampaignProgressWidget`, but standardizes the UI approach.
2. **Update `app_router.dart`**: Add `/programs/area-campaigns` mapped to this new page, with PBAC capabilities correctly set to allow Area Managers.
3. **Update `CampaignProgressWidget`**: Wire the `onPressed` to `context.push('/programs/area-campaigns')`.

<forensic_evidence>
- `grep_search` for `View All Campaigns` located the empty callback in `CampaignProgressWidget`.
- `view_file` on `app_router.dart` verified no existing route for Area Campaigns.
- Verified that `AreaCampaignListPage` does not exist on disk using the terminal.
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict:** The button is a stub. A dedicated page for viewing all Area Campaigns needs to be created and wired up.
2. **The Required Fix and Blast Radius:** Create `lib/features/programs/pages/area_campaign_list_page.dart`, register `/programs/area-campaigns` in `app_router.dart`, and hook up the `onPressed` in `CampaignProgressWidget`. The blast radius is limited to the Area Manager dashboard navigation flow.
3. **AI Agent Mission Brief:** The Area Manager's "View All Campaigns" button is a stub (`onPressed: () {}`). Create `AreaCampaignListPage`, wire it to `/programs/area-campaigns` in `app_router.dart`, and update `CampaignProgressWidget` to navigate to it.
4. **Execution Queue:**
   - [ ] @[/implement] docs/diagnostics/failure_report_20260515_192717_CM05_ViewAll.md
