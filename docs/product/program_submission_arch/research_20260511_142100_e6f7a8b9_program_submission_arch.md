# Research: Program-Submission Bridge Architecture (Delivery vs. Payload)

`[ORIGIN_IDEA]`: The business requires Programs to deliver various task types (Marketing Campaigns, Training/Rollouts, Blitz Audits) with complex features like photos, multi-question forms, and scoring. Currently, Programs are siloed and use a basic `ProgramEvidence` table, lacking the robust features of normal Audits (`Submissions`). The proposal is to use Programs as the "Delivery Mechanism" (Scheduler) carrying a `TemplateId`, and use `Submissions` as the "Payload/Execution". Store Managers will tap a Program Assignment and launch a normal Submission, allowing us to delete `ProgramEvidence` and gain all Submission features (offline mode, scoring, photos) for free, while retaining HQ Verification via `ProgramAssignment` statuses.

<latent_space_scratchpad>
- **Status Quo Audited:**
  - `ChecklyProgram` already holds `TemplateId`.
  - `ProgramAssignment` tracks Who, When, and HQ statuses (`Status`, `RejectionComment`, `VerifiedAt`).
  - `ProgramEvidence` is extremely basic (`AssignmentId`, `CriteriaId`, `Value`, `PhotoLocalKey`).
  - `Submission` is massive, feature-rich (GPS, TotalScore, SectionScores, Answers, ActionPlans).
- **E2E Flow:**
  - **HQ:** Creates `ChecklyProgram` with a `TemplateId` -> assigns to Stores (`ProgramAssignment`).
  - **Sync:** Flutter app receives `ProgramAssignment` and the `Template`.
  - **Execution:** User taps Assignment. Instead of the dumb `program_evidence_form.dart`, it routes to the `Submission` execution engine, passing `TemplateId` and `ProgramAssignmentId`.
  - **Completion:** The resulting `Submission` is linked to the `ProgramAssignment`. When Submission syncs up, `ProgramAssignment` transitions to `submitted`.
  - **HQ Verification:** HQ reviews the `Submission`. If rejected, `ProgramAssignment` becomes `needs_revision`. User edits the *same* Submission. If approved, `ProgramAssignment` becomes `verified`.
- **Architectural Implication:** 
  - `ProgramAssignment` needs a new nullable `SubmissionId`.
  - `ProgramEvidence` (Entity, EF config, DTOs, Flutter Drift tables) must be completely eradicated.
  - Sync handlers need to atomically link Submission creation with ProgramAssignment status updates.
</latent_space_scratchpad>

## E2E Workflow Map
1. **Upstream Trigger:** HQ Admin creates a `ChecklyProgram` (Scheduler) using an existing `Template` (Payload).
2. **Assignment:** Backend generates `ProgramAssignment`s for target stores.
3. **App Sync (lib/):** Store Manager receives `ProgramAssignment` via `ProgramSyncModule`.
4. **Execution (lib/):** User taps assignment. App launches standard `Submission` form.
5. **Payload Creation:** User completes form. App saves a `Submission` with a `ProgramAssignmentId` (or updates the Assignment with `SubmissionId`).
6. **Backend Sync (server/):** `Submission` is uploaded. Server marks `ProgramAssignment` as `submitted`.
7. **Downstream Effect:** HQ Admin reviews `Submission`. Updates `ProgramAssignment` status to `verified` or `needs_revision`.

## Comparative Decision Matrix

| Hypothesis | Source Checked | Rejected/Approved | Architectural Implication |
|---|---|---|---|
| A) Strict native fit: Link `Submission` 1:1 with `ProgramAssignment`. Delete `ProgramEvidence`. | Both `lib/` and `server/` | **Approved** | Cleanest approach. Reuses robust Submission engine. Requires a `SubmissionId` on `ProgramAssignment` and widespread cleanup of `ProgramEvidence` code. |
| B) Pragmatic balance: Keep `ProgramEvidence` for simple notes, add `Submission` for complex templates. | Both `lib/` and `server/` | Rejected | Introduces branching logic (Is it a simple or complex program?) violating the "Keep It Simple" rule. High cognitive debt. |
| C) Enterprise overhaul: Polymorphic `Task` system merging Programs and Audits. | Architecture docs | Rejected | Too speculative. "Good code solves today's problem simply, not tomorrow's problem prematurely." |

## Blind Spots & Constraints
1. **Payload Size / Sync Issues:** Full `Submissions` carry GPS coordinates, Action Plans, and robust scoring metadata. Syncing thousands of training quiz Submissions will increase JSON payload size and SQLite storage significantly compared to the tiny `ProgramEvidence` model.
2. **AppDbContext Cascading Deletes:** Deleting `ProgramEvidence` and creating a foreign key between `ProgramAssignment` and `Submission` introduces cascading delete risks. If an HQ Admin deletes a `Program`, should the executed `Submissions` be orphaned or deleted?
3. **Template Scoping & PBAC:** A Template used in a Training Program might have strict PBAC constraints. We must ensure the `SubmissionApiService` does not throw authorization errors when a Store Manager tries to submit a Template they wouldn't normally have access to create ad-hoc.

## Conflicts
- **Conflict with `GEMINI.md`:** "The 7 Sync Steps (for PBAC & Data Sync)". Completely deleting `ProgramEvidence` and rewiring `ProgramAssignment` across the Entity, DbContext, Server DTO, Sync Endpoint, and Flutter Drift tables simultaneously touches a 🔴 High Impact scope. This requires careful staging to avoid breaking the offline sync engine.

<forensic_evidence>
- `grep_search` in `server/` for `ProgramEvidence|ProgramAssignment`
- `grep_search` in `lib/` for `ProgramEvidence|ProgramAssignment`
- `grep_search` in `server/` for `Submission|Template`
- `view_file` on `Program.cs`, `ProgramAssignment.cs`, `ProgramEvidence.cs`, `Submission.cs`
- `view_file` on `backend-architect/SKILL.md`, `flutter-architecture/SKILL.md`
</forensic_evidence>

## Handoff Block

- **Final Verdict:** Viable & Recommended (Track A - Strict Native Fit).
- **Effort Sizing:** Track C (Epic). The eradication of `ProgramEvidence` and rewiring of the offline Sync engine requires a multi-slice approach. Concurrency Strategy: Sequential slices (DB/Server -> Flutter Sync -> UI).
- **AI Agent Mission Brief:** The Architect has approved replacing `ProgramEvidence` with `Submission`. The next agent must break this epic into 3-5 vertical slices, starting with database migrations and DTO rewiring, ending with UI integration.
- **Next Command:** User should run the following command to slice this epic into manageable tasks:
`/analyze-epic c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260511_142100_e6f7a8b9_program_submission_arch.md`
