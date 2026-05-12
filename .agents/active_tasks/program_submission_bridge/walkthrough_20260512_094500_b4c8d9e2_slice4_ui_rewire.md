# Slice 4: UI Rewire & Data Plumbing (Walkthrough)

## Epic: Program-Submission Bridge

### Goal
Connect the existing `ProgramExecutionPage` to the new `AuditEngine` pathway by triggering the unified form instead of a generic text input, passing forward the necessary Context IDs.

### Steps Completed
1. **Removed Legacy Submission Form**: 
   - Deleted `ProgramEvidenceForm` from the frontend completely.
   - Removed `submitEvidence` call logic from `ProgramExecutionPage`.
2. **Data Plumbing in `ProgramExecutionPage`**:
   - Re-written the main action to an `onPressed` handler that fetches the primary Store ID from the database and constructs a deep link into the Audit Engine.
   - Passed `templateId` and `programAssignmentId` via query parameters.
   - Used `activeSubmissionId` to route as a "Resume Audit" via `submissionId` query parameter when an existing draft is available for the current program assignment.
3. **Draft Identity & Resumption**:
   - `AuditManager` already determines draft keys using the `programAssignmentId`.
   - By successfully extracting `activeSubmissionId` from `ProgramAssignmentDto` (wired up from `CachedProgramAssignments`), the user is able to resume un-synced program audits.
4. **Validation and Verification**:
   - Executed `flutter analyze` ensuring code quality.
   - Re-ran the `.NET` test suite and Flutter widget/unit tests—all passing.
   - Refactored frontend test `program_execution_needs_revision_test.dart` to match updated `ProgramAssignmentDto` signatures.

### Next Steps
The UI is completely wired, and the full backend schema is functional. The epic should now be tested end-to-end to verify offline sync, submission creation, and dashboard updates.
