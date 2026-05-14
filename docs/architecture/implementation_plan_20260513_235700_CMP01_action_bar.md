<latent_space_scratchpad>
- Template Details Page uses a `Scaffold` with a `bottomNavigationBar`. We will replace the single "START AUDIT" button with a Row containing three actions.
- Action 1: "Start Audit" (requires `submissionsCreate`)
- Action 2: "Assign Task" (requires `submissionsCreate`)
- Action 3: "Create Campaign" (requires `programsCreate`)
- `TemplateCard` context menu needs `Quick Start` removed.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260513_234747_SYN01_campaigns.md`

## Executive Summary & Out of Scope
This plan implements Option 2 from the SYN01 decision record. We will unify execution strategies by surfacing "Start Now", "Assign", and "Create Campaign" inside the `TemplateDetailsPage` bottom action bar, and remove the redundant "Quick Start" option from `TemplateCard`.

**Out of Scope**:
- Modifying `ShellRoute` bottom navigation.
- Modifying the global `ChecklyFab`.
- Backend API changes.

## Risk Assessment
**Risk Level**: Low.
**Blast Radius**: Isolated to frontend `TemplateDetailsPage` and `TemplateCard` UI components. 
**ROI**: High. Surfacing campaigns explicitly improves UX heuristics significantly. No core architectural logic or state management changes are required.

## System Context
- **UI Environment**: Flutter PWA and Mobile.
- **PBAC**: 
  - "Start" and "Assign" buttons gated by `AppCapabilities.submissionsCreate`.
  - "Create Campaign" button explicitly gated by `AppCapabilities.programsCreate`. Buttons must be entirely omitted from layout if unauthorized, not just disabled.

## Lifecycle Context
- **Success**: The bottom action bar successfully renders the allowed subset of the 3 execution buttons.
- **Empty/Error/Loading**: The action bar inherits the page's existing state handling (which already accommodates these states gracefully).

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-01 | unauthorized_campaign_omission | If user lacks `programsCreate`, the "Create Campaign" button is absent from the DOM. | No PBAC wrapper currently exists for campaigns on this screen. |
| TC-02 | quick_start_removed | `TemplateCard` popup menu no longer contains the "start" option. | The menu currently conditionally renders the "start" option. |

## Test Fixture & Payloads
- **UI Testing Context Only**: No backend fixtures needed. Tests require a standard mock `PolicyManager` returning configured capabilities.

## Tools & Commands
- **Skills**: `flutter-api`, `ui-ux-designer`
- **Commands**: 
  - `rtk flutter test`

## Proposed Changes
#### [MOD] `lib/features/templates/pages/template_detail_page.dart`
- Replace the existing `bottomNavigationBar` single button with a `Row` or `Wrap` of buttons.
- Add "Assign" button.
- Add "Create Campaign" button wrapped in `PermissionGuard(capability: AppCapabilities.programsCreate)`.

#### [MOD] `lib/features/templates/widgets/template_card.dart`
- Remove the `start` PopupMenuItem and its associated case in the `onSelected` switch.

## Concept Diagram
`[Template Details View] --> [Bottom Action Bar] --> [Start | Assign | Campaign]`

## Execution Phase
- **Plain English Summary**: Update the UI layout of the `TemplateDetailsPage` and `TemplateCard` to centralize execution paths.
- **Value Delivered**: Consolidates template execution into a single, prominent location, satisfying UX heuristics without breaking existing tests.
- **Entry State**: Single "START AUDIT" button exists; "Quick Start" context menu option exists.
- **Exit State**: 3 buttons in the action bar (PBAC-gated); context menu streamlined.
- **Scope**: Frontend UI modification.
- **Acceptance Criteria**: Action bar displays correctly based on PBAC. The 3 buttons are rendered as an equal-weight action group. `TemplateCard` no longer shows "Quick Start".
- **Complexity**: Low. UI-only widget modifications.
- **Pros/Cons**: 
  - *Pro*: Zero backend risk, highly visible to users.
  - *Con*: Action bar might be slightly crowded on narrow mobile screens (will mitigate with `Wrap` or icon-only variants if needed, or equal flex spacing).

## Verification Plan
1. Launch the app and log in.
2. Verify "Start Audit", "Assign Task", and "Create Campaign" options appear in `TemplateDetailsPage`'s bottom action bar.
3. Validate PBAC logic: log in as an auditor (lacking `programsCreate` capability), open `TemplateDetailsPage`, and ensure "Create Campaign" is omitted completely from the UI.
4. Check `TemplateCard` to confirm "Quick Start" is gone.
5. Run `rtk flutter test` to verify no existing ATDD tests break.

<command_logs>
- `list_dir` for `lib/features/templates/pages`
- `view_file` for `template_card.dart`
- `view_file` for `template_detail_page.dart`
- `grep_search` for `programsCreate` in `app_capabilities.dart`
</command_logs>

## Handoff Block
Next step is to execute the UI implementation.
> **Route 2: Visuals/Simple (Direct Build)**
> @[/implement] Execute build for [Execution Phase]: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260513_235700_CMP01_action_bar.md`
