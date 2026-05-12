# ADR: Program Architecture — Thunderdome Decision

**ShortID**: b4c8d9e2  
**Date**: 2026-05-11  
**Status**: ACCEPTED  
**Author**: Scout (Architect Agent)

---

## Input Lineage

- **Research A**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260511_141500_b4c8d9e2_program_arch.md`
- **Research B**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260511_142100_e6f7a8b9_program_submission_arch.md`

---

## [ORIGIN_IDEA] (Immutable — do not alter)

> The Program Creation feature is functionally disconnected from the Store Manager's execution experience. The HQ Admin defines a Program using an advanced Template (capable of training quizzes, POSM marketing checks, or audits), but the SM app only displays a basic Note/Photo input and crashes the backend (400 Bad Request) due to a hardcoded `CriteriaId` type mismatch. The goal is to architect a final solution that empowers real-world F&B scenarios (training, marketing rollouts, QC checks) using the existing template capabilities without breaking the system.

```
[HQ Admin] --(creates)--> [ChecklyProgram + TemplateId]
                                    |
                        (bulk insert ProgramAssignments)
                                    |
                [Store Manager] --(taps)--> [ProgramAssignment]
                                    |
                       (TODAY: crashes with 400 Bad Request)
                                    |
                       (GOAL: launches AuditFormPage with TemplateId)
                                    |
                           [Submission created]
                                    |
                 [ProgramAssignment.SubmissionId = Submission.Id]
                                    |
                       [HQ reviews Submission --> verified/needs_revision]
```

---

<latent_space_scratchpad>
## Internal Debate

**Q: Are R1 and R2 really competing, or are they duplicates?**
At first glance, both research artifacts arrive at the same verdict (Option A: bridge ProgramAssignment to Submission, delete ProgramEvidence). However, they are NOT identical artifacts — they differ critically in:

1. **Migration order** — R2 explicitly models a sequential staging approach (DB/Server → Flutter Sync → UI). R1 treats it as a flat task list with no ordering constraint.
2. **Effort sizing** — R1 calls it Track A (High Impact). R2 calls it Track C (Epic, multi-slice). R2 is correct. A schema migration, 7 Sync Steps, and UI rewire is not a single-session task.
3. **PBAC 403 risk** — R2 names it. R1 does not. Neither proposes a fix. This is the single most dangerous unresolved issue.
4. **Cascading delete risk** — R2 identifies the FK orphan risk (if HQ deletes a Program, what happens to linked Submissions?). R1 does not.
5. **State machine collision** — R1 correctly identifies the dual approval workflow (ProgramAssignment statuses vs. Submission statuses) and proposes a resolution (ProgramAssignment owns the high-level workflow). R2 simply describes the flow without addressing the conflict resolution.

**Q: Which is the better base artifact for handoff?**
R2 is the better base because:
- It is more honest about effort (Epic, multi-slice).
- It models the staging order (DB/Server first, then Flutter, then UI).
- It explicitly enumerates the cascading delete risk.

However, R1 contributes one unique, important insight that R2 lacks: the proposed resolution for the state machine collision (ProgramAssignment as the high-level owner, Submission as a subordinate payload). This must be merged into the final ADR.

**Q: Is the PBAC 403 a blocker or a constraint?**
It is a BLOCKER. If SMs cannot submit against a Template they don't have ad-hoc rights to, every Program execution fails on day one. The Builder MUST implement a "Program-scoped bypass" — the simplest approach is to check if the `SubmissionApiService` call is triggered in a Program context (`ProgramAssignmentId` is non-null) and short-circuit the standard PBAC Template ownership check. This bypasses ad-hoc restrictions while preserving Template security for normal audits.

**Q: Should we do this as one big epic or 3-5 vertical slices?**
5 vertical slices (R2's recommendation). Each slice must be independently deployable and testable:
- Slice 1: Server — DB migration (add `SubmissionId` to `ProgramAssignment`, remove `ProgramEvidence` FK), update EF Core, new Submission FK endpoint.
- Slice 2: Server — Update Sync endpoint, DTOs, and PBAC bypass for Program-triggered Submissions.
- Slice 3: Flutter — Update Drift tables (`CachedProgramAssignments` gains `submissionId`), delete `ProgramEvidence` Drift table, update ProgramSyncModule.
- Slice 4: Flutter — Rewire `ProgramExecutionPage` to route to `AuditFormPage` with TemplateId + ProgramAssignmentId args.
- Slice 5: Flutter + Server — Integration test validating full E2E: SM taps assignment → Submission created → ProgramAssignment transitions to `submitted`.
</latent_space_scratchpad>

---

## Normalized Summary of Options

Both research artifacts evaluated the same three architectural options:

| Option | Description | R1 Verdict | R2 Verdict |
|---|---|---|---|
| **A — Strict Native Fit** | Add `SubmissionId` to `ProgramAssignment`. Delete `ProgramEvidence`. Launch `AuditFormPage` from Program context. | ✅ Approved | ✅ Approved |
| **B — Pragmatic Balance** | Keep `ProgramEvidence`, add Score fields, build a separate dynamic renderer for Programs. | ❌ Rejected — violates DRY | ❌ Rejected — cognitive debt |
| **C — Enterprise Overhaul** | Polymorphic `ActionTask` table merging all Audits/Programs. | ❌ Rejected — speculative abstraction | ❌ Rejected — premature |

---

## Red Team Attack Vectors

### Attack on R1 (`b4c8d9e2` — "Operation Bridge")

**Catastrophic Scenario: Silent Data Loss via Unordered Migration**

R1 proposes deleting `ProgramEvidence` in the same slice as adding `SubmissionId`. If the Builder executes the DB migration (drops `ProgramEvidence`) before the Flutter Drift table is updated, the offline sync engine will still try to write evidence rows to a table that no longer exists in the backend DTO contract. Result: Store Managers complete Program tasks. The app saves to the stale Drift model. The sync fails silently with a 422 Unprocessable Entity. HQ sees zero completions. The original 400 crash becomes a 0-completions-forever regression.

**Root Cause**: R1 does not define a safe migration order. It presents the changes as a flat list, not as ordered, independently deployable slices.

**Safety Gap**: R1 also does not model the cascading delete risk. If an HQ Admin deletes a `ChecklyProgram` after Store Managers have submitted evidence, and the FK is set to `CASCADE`, all evidence `Submissions` for that Program are permanently deleted. This is a data destruction scenario with no recovery path.

### Attack on R2 (`e6f7a8b9` — "Delivery vs. Payload")

**Catastrophic Scenario: 403 Forbidden on Every Single Program Execution**

R2 correctly identifies the PBAC authorization gap as a constraint but **does not propose a fix**. The scenario: A Store Manager taps a Program Assignment. The app calls `SubmissionApiService` to create a `Submission` against the HQ-managed Template. The PBAC middleware checks if the SM has a capability to create Submissions for that Template. Because the Template was created exclusively by HQ for Program use, the SM's capability list does not include it. The endpoint returns 403 Forbidden.

Every single Store Manager, on every single Program execution attempt, will receive a permission denied error. This is not a blind spot — it is an **unresolved production blocker** being handed off disguised as a "constraint."

R2 names the risk correctly but fails at the most basic architect's responsibility: propose a mitigation. The Builder would receive this handoff and have no design to follow.

---

## Pugh Decision Matrix

**Baseline**: R1 (`b4c8d9e2`) = 0

| NFR Criterion | Weight | R1 Score | R1 Weighted | R2 Score | R2 Weighted |
|---|:---:|:---:|:---:|:---:|:---:|
| **Origin Idea Alignment** (fixes SM crash, enables rich Forms) | ×3 | 0 | 0 | 0 | 0 |
| **Offline Sync Safety** (defines safe migration order) | ×2 | 0 | 0 | +1 | +2 |
| **PBAC 403 Gap** (names the risk AND proposes a fix) | ×2 | -1 | -2 | -1 | -2 |
| **Dead Code Eradication** (`ProgramEvidence` full deletion plan) | ×1 | 0 | 0 | +1 | +1 |
| **Cascading Delete Risk** (FK orphan scenario analyzed) | ×1 | -1 | -1 | 0 | 0 |
| **State Machine Collision** (dual approval workflow resolved) | ×1 | +1 | +1 | 0 | 0 |
| **Effort Sizing Realism** (Epic = multi-slice, not single task) | ×1 | -1 | -1 | +1 | +1 |
| **Blast Radius Awareness** | ×1 | 0 | 0 | +1 | +1 |
| **TOTALS** | — | — | **-3** | — | **+3** |

**Mathematical Winner: R2 (`e6f7a8b9`)** with a net advantage of +6 points over R1.

---

## Final Verdict

**ACCEPTED: Option A — Strict Native Fit (R2 as the base, R1 state machine resolution merged in, plus Peer Review Security & Architecture Enhancements)**

> Programs = Delivery Mechanism (Scheduler). Submissions = Payload/Execution.

### Architecture Decision

```
[ProgramAssignment]
  + Status: pending | in_progress | submitted | needs_revision | verified
  (NO new column here. Handled via Navigation Property to Submission.)

[Submission]
  + ProgramAssignmentId (nullable FK -> ProgramAssignment.Id)
  (gains all existing scoring, GPS, ActionPlans for free)

[ProgramEvidence] --> DELETED entirely (Entity, EF config, DTOs, Drift table)

State Machine Resolution (from R1 & Peer Review):
  ProgramAssignment owns the HIGH-LEVEL workflow:
    pending -> in_progress (when Submission is synced as "draft")
    in_progress -> submitted (when Submission is synced as "completed" | "pending_approval")
    submitted -> needs_revision | verified (HQ action)
  Submission owns the LOW-LEVEL execution data:
    draft -> completed -> approved (Auto-approved)
  The ProgramAssignment status is the AUTHORITATIVE status for the HQ dashboard.
  "Double Approval" Prevention: Program-linked Submissions must be Auto-Approved at the Area Manager level (set ReviewStatus = "approved" instantly) to avoid double-approval confusion between AMs and HQ.

PBAC Bypass (MANDATORY — mitigating IDOR Vulnerability):
  IF Submission.ProgramAssignmentId IS NOT NULL:
    Explicitly validate:
      1. ProgramAssignment actually exists.
      2. ProgramAssignment.StoreId is accessible by current User.
      3. ProgramAssignment.TemplateId exactly matches Submission.TemplateId.
    IF all three are true THEN bypass Template ownership PBAC check.
  ELSE:
    Standard PBAC Template check applies.
```

### Mandatory Constraints for Builder

1. **Migration order is STRICT**: Server (DB + DTOs + Sync endpoint + PBAC bypass) MUST be deployed and verified BEFORE Flutter Drift tables are modified. Never delete `ProgramEvidence` from both layers in one slice.
2. **PBAC IDOR Prevention is a BLOCKER**: The Builder MUST implement the secure 3-step Program-context PBAC bypass on `SubmissionApiService` before shipping Slice 2.
3. **Unidirectional FK (No Circular Dependencies)**: Place the FK ONLY on the `Submission` table (`ProgramAssignmentId`). DO NOT add `SubmissionId` to `ProgramAssignment`. Use EF Core navigation properties (`HasOne().WithMany()`) to link them.
4. **Offline Double-Tap Prevention**: In Flutter's Drift DB, the `CachedProgramAssignment` must store `active_submission_id` locally the millisecond the user taps it to prevent generating duplicate drafts when offline.
5. **7 Sync Steps are MANDATORY**: Modifying `ProgramAssignment` schema triggers the full 7-step sync requirement: Entity → DbContext → Server DTO → Endpoint projections → Sync endpoint → Flutter DTO → Flutter Drift table.
6. **Integration test is MANDATORY in Slice 5**: A test must prove the full E2E: SM taps Assignment → Submission created with `ProgramAssignmentId` → ProgramAssignment transitions to `submitted` (only when completed) → Assert 200 and status match.

---

## Executive Business Summary

**What this means in plain English for the Product Owner:**

Right now, Store Managers cannot use Programs at all. When they tap a Program task, the app shows a basic text box (no photos, no scoring, no structured questions), and when they submit it, the server crashes. This means all the effort HQ puts into designing Training courses, POSM checklists, and Blitz audits via Programs is completely wasted — it never reaches the field.

**What we are building:** We are going to reuse the system that already works perfectly (the Audit form and submission engine) to also power Programs. HQ will continue creating Programs with a Template (as they do today). But instead of crashing, Store Managers will now see the full, rich Template form — the same one they already use for audits. Their responses will be scored, tracked, and sent to HQ for approval. HQ will see a proper reviewed submission instead of a blank cell.

**Business benefits:**
- Programs become a real operational tool overnight — no new UI to build, reuses existing proven code.
- Training programs with scoring, POSM checks with photos, Blitz audits — all work with the same single feature.
- HQ gets rich, scored data for every Program, enabling analytics.

**Operational tradeoffs:**
- This is a multi-week, multi-slice effort (Epic track). Expect 4-5 builder sessions.
- During migration, a short freeze on Program execution features is expected (2-3 days) until both server and app are updated together.

**Maintenance cost:**
- Positive long-term. We are deleting the old `ProgramEvidence` table (dead code) and replacing it with the battle-tested Submission engine. Less code, less maintenance.

**UX impact:**
- Store Managers see a proper form instead of a crash. Net positive.
- HQ Admins see scored, structured Program results on their dashboard. Net positive.

---

## Handoff Block

### Final Verdict
**Option A — Strict Native Fit.** Bridge `Submission` back to `ProgramAssignment` via a nullable `ProgramAssignmentId` FK. Delete `ProgramEvidence` completely. Rewire Flutter `ProgramExecutionPage` to launch `AuditFormPage`. Implement secure IDOR-safe PBAC bypass.

### Strict Constraints (Builder must not ignore)
1. **Deployment order is SERIAL**: Server slices first, Flutter slices second. No exceptions.
2. **PBAC IDOR Prevention**: Must securely validate the assignment in Slice 2 before bypassing.
3. **Unidirectional FK**: FK only exists on `Submission`. No circular dependency.
4. **Double Approval Prevention**: Auto-approve Program submissions.
5. **7 Sync Steps apply**: Update Entity → DbContext → Server DTO → Endpoint → Sync endpoint → Flutter DTO → Drift table.
6. **State machine**: Syncing drafts transitions ProgramAssignment to `in_progress`, not `submitted`.

### Execution Slices (Proposed)
- **Slice 1 (Server — DB)**: Add `ProgramAssignmentId` to `Submission` (nullable, SET NULL FK). Drop `ProgramEvidence` table. Implement Navigation Property on `ProgramAssignment`. EF Core migration.
- **Slice 2 (Server — API)**: Update DTOs. Update Sync endpoint. Implement SECURE PBAC bypass for Program-context Submissions. Auto-transition `ProgramAssignment.Status` to `in_progress` (if draft) or `submitted` (if completed/pending_approval). Auto-approve Program Submissions to bypass Area Manager review.
- **Slice 3 (Flutter — Sync)**: Update `CachedProgramAssignments` Drift table (add `active_submission_id` for local draft resumption). Delete `ProgramEvidence` Drift table. Update `ProgramSyncModule`.
- **Slice 4 (Flutter — UI)**: Rewire `ProgramExecutionPage` to launch `AuditFormPage` with `templateId` + `programAssignmentId` args. Add double-tap prevention using `active_submission_id`. Remove all `ProgramEvidence` form UI code.
- **Slice 5 (Integration Test)**: Write full E2E integration test: SM taps Assignment → Submission synced as complete → ProgramAssignment = `submitted` → Assert 200.

### Requirements Alignment Check
> [!WARNING]
> This architectural decision **alters the business execution flow** for Programs. If a `requirements.md` document exists for the Program Creation feature, it MUST be updated to reflect: (1) ProgramEvidence is no longer the output entity; Submission is. (2) The SM execution UX is now `AuditFormPage`, not a custom Program form. (3) HQ verification now reviews a full Submission record, not a ProgramEvidence summary row. The Product Owner must approve this scope change before implementation begins.

### AI Agent Mission Brief
The Architect has accepted Option A: Programs will reuse the Submission engine as the execution payload. The next agent must break this Epic into 5 ordered vertical slices starting with a unidirectional DB migration, implement a secure IDOR-safe PBAC bypass, handle draft states vs submitted states correctly, and end with a full E2E integration test. Migration order is STRICT — server first, Flutter second.

### Next Command
```
/analyze-epic C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260511_181003_b4c8d9e2_program_arch.md
```
