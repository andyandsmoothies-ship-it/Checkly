<latent_space_scratchpad>
## Latent Space Scratchpad

### Problem Framing
This is Slice 6: Visual Reskin for Audit & Programs screens. No backend logic is modified. No database modifications are made. No sync behaviors are changed.
However, we must be exceptionally careful about:
1. Retaining `ActionGuard` wrappers on any buttons/actions we modify to ensure that the hybrid entity-driven UI (HATEOAS) allowedActions permissions stay fully functional.
2. Confirming that all replaced widgets (e.g. standard Cards with `StrokeCard`, ElevateButtons with `BubblyButton`, CircularProgressIndicator with `QuestProgressBar` or progressIndicatorTheme overrides) exactly conform to the visual rules.
3. Keeping file sizes below 400 lines (GEMINI.md rule).
4. Providing detailed instructions for replacing core visual elements in all 10 affected pages.

Let's check the affected pages and their lengths:
- `lib/features/audit/pages/audit_form_page.dart` (381 lines) - Near the 400 line limit! We must be careful not to make this file longer. If refactoring it makes it exceed 400 lines, we should split it or pull sub-widgets into separate files (e.g. `lib/features/audit/widgets/audit_form_app_bar.dart` or `lib/features/audit/widgets/audit_score_hud.dart`).
- `lib/features/audit/pages/history_page.dart` (140 lines) - Safe.
- `lib/features/audit/pages/survey_results_page.dart` (103 lines) - Safe.
- `lib/features/programs/pages/program_list_page.dart` (140 lines) - Safe.
- `lib/features/programs/pages/program_dashboard_page.dart` (198 lines) - Safe.
- `lib/features/programs/pages/program_execution_page.dart` (209 lines) - Safe.
- `lib/features/programs/pages/area_campaign_list_page.dart` (140 lines) - Safe.
- `lib/features/programs/pages/program_assignment_list_page.dart` (86 lines) - Safe.
- `lib/features/programs/pages/program_create_wizard_page.dart` (251 lines) - Near 250 lines! If we touch this page, we should split it to follow the file length rules if it grows.
- `lib/features/programs/pages/program_store_selector_page.dart` (112 lines) - Safe.

Let's review the required reskins per screen:
1. `AuditFormPage`:
   - Replace traditional `Scaffold` background, use playful light theme tones.
   - Reskin question sections using `StrokeCard`.
   - Swap the default FloatingActionButton for `BubblyButton` or clean custom bottom action sheet.
   - Integrate `QuestProgressBar` for audit progress tracking.
2. `HistoryPage`:
   - Replace ListTiles with custom structured cards using `StrokeCard`.
   - Swap standard chips with `PillChip`.
   - Render user action buttons with `BubblyButton`.
3. `SurveyResultsPage`:
   - Swap default question score views with progress bars using `QuestProgressBar`.
   - Wrap items in `StrokeCard`.
4. `ProgramListPage`:
   - Change basic lists to gamified lists.
   - Use `StrokeCard` for each program.
   - Highlight current program completion percentage using `QuestProgressBar`.
5. `ProgramDashboardPage`:
   - Restyle KPI blocks using `StrokeCard` and bold numeric indicators.
   - Update campaign status rows with `PillChip`.
6. `ProgramExecutionPage`:
   - Replace standard alert box with a custom warning-themed `StrokeCard` or `BubblyDialog` for "Needs Revision".
   - Switch primary button ("Start Audit" / "Resume Audit") to a large, bold `BubblyButton`.
7. `AreaCampaignListPage`:
   - Refactor campaign lists using `StrokeCard` cards.
   - Use `QuestProgressBar` for tracking execution progress.
8. `ProgramAssignmentListPage`:
   - Replace ListTiles inside warnings with gamified warning cards using `StrokeCard` with `PillChip`.
9. `ProgramCreateWizardPage`:
   - Restyle steps. Step indicator dot animations: ensure they are rounded and colorful.
   - Bottom Action Bar: "Issue Campaign" button must be replaced with `BubblyButton`.
10. `ProgramStoreSelectorPage`:
    - Refactor store checkboxes/tiles into a list of interactive cards using `StrokeCard`.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260521_202100_ds01_duolingo_reskin.md`

## Executive Summary & Out of Scope
This implementation plan covers **Slice 6 (Audit + Programs screens)** of the gamified Duolingo Reskin epic. It outlines the precise visual changes required to transform 10 core pages from the current Apothecary editorial layout into a playful, high-contrast, gamified experience.

### In Scope
- Refactoring the following 10 page files to fully adopt the Duolingo palette, Nunito font hierarchy, and new gamified primitives:
  - `lib/features/audit/pages/audit_form_page.dart`
  - `lib/features/audit/pages/history_page.dart`
  - `lib/features/audit/pages/survey_results_page.dart`
  - `lib/features/programs/pages/program_list_page.dart`
  - `lib/features/programs/pages/program_dashboard_page.dart`
  - `lib/features/programs/pages/program_execution_page.dart`
  - `lib/features/programs/pages/area_campaign_list_page.dart`
  - `lib/features/programs/pages/program_assignment_list_page.dart`
  - `lib/features/programs/pages/program_create_wizard_page.dart`
  - `lib/features/programs/pages/program_store_selector_page.dart`
- Preserving all `ActionGuard` wrappers, dynamic state streams, business logic, DB queries, and API calls.
- Adhering strictly to maximum file limits (<400 lines) by extracting sub-components if necessary.

### Out of Scope
- Any functional modifications to database schema, server DTOs, endpoint routes, offline synchronization, or business managers.
- Implementing dark-mode specific page overrides (app uses light theme primarily; dark theme is handled globally via global fallback settings).
- Modifying security permissions or roles.

## System Context
- **Runtime Environment**: Offline-first hybrid Flutter app running locally on a SQLite/Drift database, synchronized periodically with a PostgreSQL backend via REST endpoints.
- **RBAC / PBAC Rules**: Role-based routing and capability restrictions governed by backend AllowedActions arrays. Pages map actions (e.g., "issue_campaign", "complete_audit") strictly based on these permissions via standard `ActionGuard` widgets.
- **Observability**: Standard Flutter framework error logs using structured `ErrorDisplayService`. No new diagnostics logs are introduced in this UI slice.

## Lifecycle Context
All screens in Slice 6 support the full **4-State Matrix**:
1. **Loading State**: Circular progress indicator overridden globally via light theme `progressIndicatorTheme` (colored in vibrant Macaw Blue).
2. **Success State**: Playful content layout utilizing high-contrast typography, interactive `StrokeCard` containers, and solid `BubblyButton` triggers.
3. **Empty State**: Renders unified empty state banner featuring friendly, blame-free illustration headers and pastel backgrounds.
4. **Error State**: Consistent problem dialogs or inline error notices rendered in bold Cardinal Red (#FF4B4B) detailing clear, actionable troubleshooting tips.

## Constraint Traceability

| ID | Design Constraint | Mapping to Test Contract ID | Technical Verification Strategy |
|:---|:---|:---|:---|
| **C1** | Nunito bold font scaling | `TC-06-NUNITO` | Verify Nunito is imported and used in custom styles or fallback text styles. |
| **C2** | Flat Swan border on cards | `TC-06-STROKECARD` | Confirm standard `Card` classes are converted to `StrokeCard` with 2px Swan border. |
| **C3** | 3D tactile bubbly buttons | `TC-06-BUBBLYBUTTON` | Confirm `ElevatedButton` and `FilledButton` widgets are replaced by `BubblyButton`. |
| **C4** | Vibrant colorful progress bars | `TC-06-PROGRESSBAR` | Verify progress bars are refactored to use implicitly-animated `QuestProgressBar`. |
| **C5** | ActionGuard preservation | `TC-06-ACTIONGUARD` | Dry-run search to verify that no `ActionGuard` or allowed actions verification logic is removed. |
| **C6** | Strict file-size limit | `TC-06-FILESIZE` | Check file lengths of all updated page assets to guarantee they stay well under 400 lines. |

## Test Contracts

| ID | Test Contract Description | Expected State Matrix | Why it fails first |
|:---|:---|:---|:---|
| **TC-06-NUNITO** | Verify Nunito font is applied to all typography elements on screens | Success / Success | Defaults to Manrope style if the standard AppTheme integration is bypassed. |
| **TC-06-STROKECARD** | Verify cards use flat `StrokeCard` with no blurred drop-shadows | Success / Success | Renders legacy Material elevation and blurred borders if legacy components are left behind. |
| **TC-06-BUBBLYBUTTON** | Verify primary actions use `BubblyButton` widgets | Success / Success | Traditional Material buttons do not shift down by 4px on press and lack the solid bottom shadow. |
| **TC-06-PROGRESSBAR** | Verify progress displays utilize custom `QuestProgressBar` | Success / Loading | Legacy progress bars display static linear lines lacking gloss highlight detail. |
| **TC-06-ACTIONGUARD** | Verify visual elements within ActionGuard maintain identical permissions | Success / Success | Removing ActionGuard references allows unauthorised roles to trigger protected flows. |
| **TC-06-FILESIZE** | Ensure modified files do not exceed the strict 400-line constraint | Static Compilation | Standard compiler compiles but builds fail static style compliance sweeps if a file contains >400 lines. |

## Test Fixture & Payloads
- **Test Target**: Flutter Widget and Integration testing suite.
- **Fixture Requirements**:
  - `ProfileStoreAssignment` seeded for the current Store Manager.
  - Active campaigns / campaigns assigned to current store seeded inside the local database.
  - Pending audit forms available to test execution progression.

## Tools & Commands
- **Static Analysis check**: `rtk flutter analyze`
- **Unit & Widget testing**: `rtk flutter test`
- **Compliance sweep**: `python .agents/scripts/verify_workflow.py "{Absolute Path to tasktracker}"`

## Proposed Changes

### UI Component Routing & Truncation Matrix

| Component | Target File Path | Truncation Limit | Overflow Action | Required Next Route |
|:---|:---|:---|:---|:---|
| **Audit Form Header** | `lib/features/audit/pages/audit_form_page.dart` | Header Title: 1 Line | TextOverflow.ellipsis | `/audit` (self) |
| **History Card Item** | `lib/features/audit/pages/history_page.dart` | Title: 1 Line | TextOverflow.ellipsis | `/audit?submissionId=:id` |
| **Program Card Item** | `lib/features/programs/pages/program_list_page.dart` | Program Title: 1 Line | TextOverflow.ellipsis | `/programs/:id` |
| **KPI Title** | `lib/features/programs/pages/program_dashboard_page.dart` | Metric Label: 1 Line | TextOverflow.fade | `/programs` (dashboard) |
| **Execution Action** | `lib/features/programs/pages/program_execution_page.dart` | Action Label: 1 Line | TextOverflow.clip | `/audit?templateId=:id` |
| **Store Selector Item** | `lib/features/programs/pages/program_store_selector_page.dart`| Store Name: 1 Line | TextOverflow.ellipsis | Modal pop back to Wizard |

### Files Scheduled for Modification `[MOD]`

1. **`lib/features/audit/pages/audit_form_page.dart`**
   - Swap traditional custom AppBars with flat, clean navigation headers.
   - Refactor question sections into standard `StrokeCard` widgets.
   - Swap default linear indicators with the glossy `QuestProgressBar` widget.
   - Ensure file size remains below 400 lines (currently 381 lines). If it risks exceeding 400 lines, extract internal private widgets (like `_CriterionRow` or `_SectionHeader`) into clean sub-components in `lib/features/audit/widgets/`.

2. **`lib/features/audit/pages/history_page.dart`**
   - Refactor individual audit history listings to use interactive, bordered `StrokeCard` cards.
   - Apply `PillChip` for standard visual status badges.
   - Style action triggers with solid `BubblyButton` widgets.

3. **`lib/features/audit/pages/survey_results_page.dart`**
   - Convert question rating displays into beautiful gamified progress trackers using `QuestProgressBar`.
   - Group response distributions inside flat `StrokeCard` elements.

4. **`lib/features/programs/pages/program_list_page.dart`**
   - Redesign standard list items as high-contrast `StrokeCard` cards.
   - Track program deadlines and completion rates with custom `QuestProgressBar` and bold typography.

5. **`lib/features/programs/pages/program_dashboard_page.dart`**
   - Transform dashboard KPI scorecards to use flat white `StrokeCard` elements.
   - Style campaign progress tracks with `QuestProgressBar`.
   - Format status markers using `PillChip`.

6. **`lib/features/programs/pages/program_execution_page.dart`**
   - Swap the warning alert container with a beautiful pastel red `StrokeCard` decorated with deep Cardinal Red text border markers.
   - Re-architect the primary action buttons using prominent, large-scale `BubblyButton` widgets.

7. **`lib/features/programs/pages/area_campaign_list_page.dart`**
   - Style tabular campaign summaries inside modern `StrokeCard` grids.
   - Present program metrics using playful pastel background grids.

8. **`lib/features/programs/pages/program_assignment_list_page.dart`**
   - Upgrade action items to flat structured cards using `StrokeCard`.
   - Highlight urgent revision requirements using striking `PillChip` badges.

9. **`lib/features/programs/pages/program_create_wizard_page.dart`**
   - Refactor linear step indicators into bold bubbly colored dots.
   - Modernize the bottom action layout: swap generic `ElevatedButton` for interactive `BubblyButton`.
   - Maintain key identifier contracts (`key: const Key('issue_program_button')`).

10. **`lib/features/programs/pages/program_store_selector_page.dart`**
    - Refactor store checkbox rows into interactive, selectable `StrokeCard` boxes.

## Risk Assessment
The visual reskin is pure UI, but carries critical operational risks:
1. **ActionGuard Breakage**: Accidentally removing or modifying `ActionGuard` widgets can allow unauthorized users to perform critical actions (e.g. issuing a program, resuming/editing audits).
   - *Mitigation*: Meticulously verify all visual wrappers keep `ActionGuard` logic untouched.
2. **File Size Bounds**: `audit_form_page.dart` (381 lines) is very close to the 400-line hard ceiling. Refactoring it directly could push it past 400 lines and trigger validation failures.
   - *Mitigation*: Proactively extract inline visual helper widgets into separate files within `lib/features/audit/widgets/` to shrink parent files.
3. **UI Layout/Constraint Overflow**: Converting generic widgets to gamified primitives with thick 3D borders (e.g. 2px borders + bottom shadows on buttons and cards) can trigger layout overflows (yellow/black pixel bars).
   - *Mitigation*: Adjust layout padding/margins, use flexible layout widgets (`Flexible`, `Expanded`), and enforce single-line text truncations where needed.

## Verification Plan
We will execute standard automated and manual validation gates to ensure zero structural or visual regression:
1. **Static Analysis**: Run `rtk flutter analyze` on the workspace to verify there are 0 warnings or compiler issues.
2. **Automated Unit & Widget Tests**: Execute `rtk flutter test` to ensure existing widget trees, keys, and functional navigation structures remain fully intact.
3. **Visual Heuristic Auditing**: Conduct visual checks on all 10 pages using target simulated inputs (empty, loaded, success, error) to guarantee perfect aesthetic conformity to the Duolingo shape and color language.

## Concept Diagram

```
[User Navigate to Page]
          │
          ▼
┌──────────────────────────────────────┐
│  Scaffold Background (Polar/White)  │
│  AppBar (Flat Swan 2px Border)       │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  Layout Structure                    │
│  - Items: StrokeCard                 │
│  - Progress: QuestProgressBar        │
│  - Badges: PillChip                  │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│  Primary Interactive Layer           │
│  - Tap actions: BubblyButton         │
│  - Animation: 4px tactile vertical   │
│    translation upon touch            │
└──────────────────────────────────────┘
```

## Execution Slices

### Execution Phase: Refactor Pages for Audit & Programs Features (UI Only)
- **Plain English Summary**: Update all 10 core pages across the Audit and Programs features to replace old Apothecary visual elements with standard gamified Duolingo theme equivalents. Primary triggers become custom 3D `BubblyButton` buttons, standard layout cards become rounded, high-contrast `StrokeCard` containers, and progress charts adopt glossy `QuestProgressBar` visual indicators.
- **Value Delivered**: Delivers a fully-unified gamified UI experience across all campaign administration, audit compliance, progress tracking, and program execution workflows.
- **Complexity**: **Medium**. The logic remains untouched, but the visual elements spans 10 files, requiring meticulous attention to detail to ensure zero interface breakage.
- **Entry State Required**: Slice 1 through Slice 5 successfully built and verified.
- **Exit State Guaranteed**: All 10 affected pages are completely visually reskinned, compiled successfully, passing static analyzer sweeps with 0 warnings/errors.
- **Scope**:
  - `lib/features/audit/pages/audit_form_page.dart`
  - `lib/features/audit/pages/history_page.dart`
  - `lib/features/audit/pages/survey_results_page.dart`
  - `lib/features/programs/pages/program_list_page.dart`
  - `lib/features/programs/pages/program_dashboard_page.dart`
  - `lib/features/programs/pages/program_execution_page.dart`
  - `lib/features/programs/pages/area_campaign_list_page.dart`
  - `lib/features/programs/pages/program_assignment_list_page.dart`
  - `lib/features/programs/pages/program_create_wizard_page.dart`
  - `lib/features/programs/pages/program_store_selector_page.dart`
- **Acceptance Criteria**:
  - All primary interactive user triggers are refactored to use custom `BubblyButton` components.
  - Standard cards and list frames are replaced with high-contrast `StrokeCard` containers (2px Swan border, R: 16px).
  - dead code or unused style dependencies are completely pruned.
  - Every modified file size strictly complies with the <400-line constraint.
  - Visual permission controls wrapped in `ActionGuard` widgets are left fully intact.
  - Execution of `rtk flutter analyze` outputs 0 warnings or compile errors.

## Command Logs
- `list_dir lib/features/audit/pages` -> Analyzed pages in Audit feature.
- `list_dir lib/features/programs/pages` -> Analyzed pages in Programs feature.
- `view_file lib/features/audit/pages/audit_form_page.dart` -> Checked page length and structural layout constraints.
- `view_file lib/features/programs/pages/program_create_wizard_page.dart` -> Checked step structures and persistent actions.

## Handoff Block
- **Next Phase**: **Build Phase** for [Execution Phase].
- **Workflow Route**: Route 1 (Direct Build) since this slice comprises a pure, logic-free visual UI reskin.
- **Sequence of Actions**:
  - **Execution Phase**: Plan -> Build -> Manual Visual Verification -> Static analysis verification.
- **Plan File Absolute Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260521_143000_ds06_slice_6_screens.md`
