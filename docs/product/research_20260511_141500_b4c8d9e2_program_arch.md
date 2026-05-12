# Research: Program Architecture Pivot

[ORIGIN_IDEA]: The user identified that the Program Creation feature is functionally disconnected from the Store Manager's execution experience. Specifically, the HQ Admin defines a Program using an advanced "Template" (capable of training quizzes, POSM marketing checks, or audits), but the SM app only displays a basic Note/Photo input and crashes the backend because of hardcoded `CriteriaId` mismatched types. The goal is to architect a final solution that empowers real-world F&B scenarios (training, marketing rollouts, QC checks) using the existing template capabilities without breaking the system.

<latent_space_scratchpad>
Debate: We have `ChecklyProgram` -> `ProgramAssignment` -> `ProgramEvidence`. 
The `ProgramEvidence` entity maps to a `CriteriaId` but doesn't have scoring, GPS, or Action Plans. 
If we want a "Training Course" with points (per the user's idea), we MUST calculate a score. We already have the `Submission` entity which does this flawlessly.
Tradeoffs:
If we pivot and say `ProgramAssignment` is just a scheduler that points to a `Submission`, we get all the `TemplateTree` offline rendering and scoring for free.
However, Submissions have an approval workflow (`pending_approval` -> `approved`). Program Assignments *also* have an approval workflow (`submitted` -> `verified` or `needs_revision`).
We have a state machine collision. 
Resolution: The ProgramAssignment should "own" the high-level workflow. The underlying Submission should automatically inherit the Program's rules (e.g. maybe bypass the default Area Manager approval and go straight to the Program's HQ assigned approver).
</latent_space_scratchpad>

## E2E Workflow Map

**Triggers**: 
- HQ Admin creates a `ChecklyProgram` and selects a `TemplateId` (e.g., POSM Banner Task).
- System bulk-inserts `ProgramAssignment` rows for target stores.

**Status Quo Friction**:
- SM taps Assignment -> Opens `ProgramExecutionPage`.
- UI renders single generic Note/Photo field (Ignores `TemplateId`).
- SM submits -> Backend hits 400 Bad Request because `program_summary` is not a `Guid`.

**Proposed E2E Flow**:
1. HQ Admin creates `ChecklyProgram` with `TemplateId`.
2. SM taps Assignment -> App launches standard `AuditFormPage` (via deep link or argument injection), passing the `TemplateId`.
3. SM completes the dynamic form (Scored Quiz, POSM Photo task, etc).
4. SM submits -> App creates a `Submission` and syncs it.
5. Backend ties the `SubmissionId` to the `ProgramAssignment`. Assignment transitions to `submitted`.
6. HQ sees the rich scored submission in their Program Dashboard.

## Comparative Decision Matrix

| Option | Approach | Source Checked | Rejected/Approved | Architectural Implication |
|--------|----------|----------------|-------------------|---------------------------|
| **(A) Strict Native Fit (Operation Bridge)** | Deprecate `ProgramEvidence`. Add `SubmissionId` to `ProgramAssignment`. SM launches standard `AuditFormPage` to execute Programs. | `Submission.cs`, `ProgramAssignment.cs` | **Approved** | 100% reuse of existing offline template rendering and scoring. Kills dead code. |
| **(B) Pragmatic Balance (Expand Evidence)** | Keep `ProgramEvidence` separate. Add `Score` and `MaxScore` fields. Build a separate dynamic template renderer just for Programs in Flutter. | `ProgramEvidence.cs` | Rejected | Violates DRY. We would have to rebuild the entire `AuditFormPage` logic just for Programs. |
| **(C) Enterprise Textbook Overhaul (Unified Actionable)** | Refactor everything into a polymorphic `ActionTask` table. Audits, Action Plans, and Programs become polymorphic subtypes. | EF Core Inheritance docs | Rejected | Too high risk. Modifying `Submission` base tables destroys the current stable system. |

## Blind Spots & Risks (NFRs)
1. **Offline Sync Size**: Linking Submissions to Programs means the `GetMyAssignments` payload size will explode because the client must aggressively cache the entire `TemplateTree` for every assigned program to support offline execution.
2. **State Machine Collision**: `ProgramAssignment` has HQ approval statuses (`verified`, `needs_revision`), while `Submission` has its own (`pending_approval`, `approved`). Syncing these two overlapping state machines could cause infinite loops or deadlocks if the `ReviewStatus` gets out of sync.
3. **Data Retention**: Submissions are massive (many rows of `Answers`). Storing a full `Submission` for every minor POSM photo check will dramatically increase the database footprint in PostgreSQL compared to a single lightweight `ProgramEvidence` row.

## Rule Conflicts
1. **Conflict: The 7 Sync Steps (PBAC & Data Sync)**: This architecture pivot requires adding `SubmissionId` to `ProgramAssignment`. This triggers the entire 7-step sync requirement. We will have to update the Drift `CachedProgramAssignments` table, EF Core `AppDbContext`, and the DTOs, which is a major, high-impact slice.
2. **Conflict: Silent Test Failures**: If the state machines collide and we return a 400 because a Submission is locked, the tests might fail silently if we don't explicitly log the body in integration tests.

<forensic_evidence>
Searched and reviewed `server/Common/Persistence/Entities/Submission.cs`
Searched and reviewed `server/Common/Persistence/Entities/ProgramAssignment.cs`
Searched and reviewed `server/Common/Persistence/Entities/ProgramEvidence.cs`
</forensic_evidence>

## Handoff Block

- **Final Verdict**: **Viable - Option A (Strict Native Fit)**. We will bridge `ProgramAssignment` to `Submission` and delete `ProgramEvidence`.
- **Effort Sizing**: Track A (High Impact - Database Schema Migration + Flutter State Migration).
- **AI Agent Mission Brief**: Execute Option A: Add `SubmissionId` to `ProgramAssignment`, update the 7 Sync Steps, delete `ProgramEvidence` from the DB, and rewire `ProgramExecutionPage` in Flutter to launch `AuditFormPage` with the assignment context.
- **Next Step**: Run the implementation workflow. Use the command: `/implement file:///c:/Users/HP/Documents/GitHub/Checkly/docs/product/research_20260511_141500_b4c8d9e2_program_arch.md`
