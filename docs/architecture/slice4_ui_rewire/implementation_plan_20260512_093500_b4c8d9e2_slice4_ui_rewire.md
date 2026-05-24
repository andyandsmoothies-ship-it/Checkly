<latent_space_scratchpad>
- Goal: Rewire `ProgramExecutionPage` to trigger `AuditFormPage`.
- Needs to pass `templateId` and `programAssignmentId`.
- Replace legacy submission form with a simple Start/Resume Audit button.
- Extract `activeSubmissionId` to resume drafts.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md`

## Executive Summary & Out of Scope
**Summary**: This slice finalizes the integration of the unified Audit Engine with the Program module. By passing `programAssignmentId` and `templateId` directly from `ProgramExecutionPage` to the `AuditFormPage`, the system allows users to execute assignments using the dynamic form and offline-sync infrastructure.
**Out of Scope**: No modifications to the backend synchronization logic or the core `AuditManager` schema beyond what has been completed in Slices 1-3. We will not rebuild the UI of the Audit form itself.

## Risk Assessment
- **Risk Level**: Low
- **Tradeoffs**: Store managers will click once to enter the audit form rather than seeing it directly inline. The risk is extremely low since no backend or core offline code changes.
- **Blast Radius**: `ProgramExecutionPage` widget state and `AppRouter`.

## System Context
- **Environment**: Offline-first Flutter app with local SQLite storage.
- **Dependencies**: `ProgramManager`, `AppRouter`, `AuditFormPage`.
- **Permissions**: Requires the `programs:execute` capability natively, handled by router guards.

## Lifecycle Context
- **Loading**: Assignment details fetch via Drift caching.
- **Success**: The assignment is displayed. Clicking 'Start Audit' pushes to the `/audit` route, carrying necessary IDs.
- **Empty/Error**: Assignment missing triggers error placeholder. "Needs Revision" shows a specific banner.

## Test Contracts
| ID | Expected Behavior | State Matrix | Why it fails first |
|---|---|---|---|
| TC-UI-1 | `ProgramExecutionPage` successfully parses `activeSubmissionId` to determine "Start" vs "Resume" labels | Success | UI lacks conditionals to read `activeSubmissionId`. |
| TC-UI-2 | Route string correctly constructs query parameters | Success | Missing `&submissionId=` syntax logic when resuming. |

## Verification Plan
1. **Automated Testing**:
   - Re-run `test/features/programs/program_execution_needs_revision_test.dart`
   - Global `flutter test` pipeline run.
   - Global `dotnet test` pipeline run to ensure backend API stability.
2. **Visual Inspection**:
   - Ensure the new "Start Audit" and "Resume Audit" button fits beautifully in the `ProgramExecutionPage` form.

## Test Fixture & Payloads
- **State Requirement**: Seeded SQLite database with a `PendingSubmission` and matching `CachedProgramAssignment`.

## Tools & Commands
- `flutter test`
- `flutter analyze`

## Proposed Changes
- `[MOD]` `lib/features/programs/pages/program_execution_page.dart`
- `[MOD]` `lib/features/programs/model/program_assignment_dto.dart` (Add missing fields)
- `[MOD]` `test/features/programs/program_execution_needs_revision_test.dart` (Fix test drift)
- `[DEL]` `lib/features/programs/pages/widgets/program_evidence_form.dart`

## Concept Diagram
`[ProgramExecutionPage]` --> `[User clicks Start]` --> `[AppRouter (/audit?templateId=...&programAssignmentId=...)]` --> `[AuditFormPage]`

## Execution Slices
**Phase A: UI Component Rewire**
- **Plain English Summary**: We will modify the assignment execution page to drop the legacy note input form and replace it with a button that launches the new Audit infrastructure.
- **Value Delivered**: Unlocks offline syncing and dynamic questionnaires for F&B rollouts and campaigns.
- **Entry State**: Legacy `ProgramEvidenceForm` displayed.
- **Exit State**: Clean UI with a single CTA routing to `/audit`.
- **Scope**: `ProgramExecutionPage` and removed `ProgramEvidenceForm`.
- **Acceptance Criteria**: Form is removed. Button successfully routes to `AuditFormPage`. 
- **Complexity**: Low. Strictly deleting legacy widgets and updating a navigation callback.
- **Pros & Cons**: 
  - *Pro*: Drastic reduction in custom UI logic.
  - *Con*: Store managers will have an extra click compared to inline input, but gain offline safety.

<command_logs>
- `cmd /c flutter analyze`
- `cmd /c flutter test`
</command_logs>

## Handoff Block
> **Route 2: Visuals/Simple (Direct Build)**
> @[/implement] Execute build for Slice 4: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260512_093500_b4c8d9e2_slice4_ui_rewire.md
