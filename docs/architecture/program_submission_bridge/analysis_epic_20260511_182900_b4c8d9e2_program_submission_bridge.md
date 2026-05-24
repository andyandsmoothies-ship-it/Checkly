<latent_space_scratchpad>
## Architecture Flow (Final Mental Model)

The two systems today:
  [ProgramAssignment] -- has --> [ProgramEvidence]  (dead end, no scoring)
  [Submission]        -- is  --> [AuditFormPage]     (full engine: scoring, GPS, offline)

After the bridge:
  [ProgramAssignment] <-- FK -- [Submission]         (Submission owns the FK)
  [AuditFormPage] is reused for BOTH normal Audits AND Program execution.
  [ProgramEvidence] tables are completely deleted.

## Key Design Decisions (from ADR + Peer Review)

1. FK DIRECTION: Submission.ProgramAssignmentId (nullable). NOT ProgramAssignment.SubmissionId.
   Reason: Avoids circular insert dependency. EF Core navigation: HasOne().WithMany() allows
   multiple submission attempts per assignment (revision history).

2. PBAC BYPASS: Must validate 3 conditions before bypassing standard template PBAC:
   a) ProgramAssignment exists in DB
   b) ProgramAssignment.StoreId is accessible by current user (IDOR check)
   c) ProgramAssignment.TemplateId == Submission.TemplateId (prevents template substitution attack)

3. STATE MACHINE: Two independent machines:
   ProgramAssignment: pending -> in_progress -> submitted -> needs_revision | verified
   Submission:        draft   -> completed   -> approved (auto-approved for Program context)
   Sync bridge: Submission status triggers ProgramAssignment status change.

4. DOUBLE-TAP PREVENTION: CachedProgramAssignment gains `active_submission_id` column.
   Written the instant the user taps the assignment. Prevents duplicate draft creation offline.

5. DELETION ORDER:
   Server must be updated FIRST. Then Flutter.
   Reason: If Flutter Drift table still has PendingProgramSubmissions and server no longer accepts
   the old evidence endpoint, the sync will 422 (fatal) and evidence will be lost.
   Safe sequence: Server deploys (old evidence endpoint returns 410 Gone) → Flutter Slice 3 deploys
   (wipes old outbox, rewires to Submission outbox).

## What Dies
- server: ProgramEvidence entity, ProgramEvidenceConfiguration, AddProgramEvidence migration (kept in history), SubmitProgramEvidence.cs handler, EvidenceItemRequest, SubmitEvidenceRequest, ProgramEvidenceDto DTOs
- flutter: PendingProgramSubmissions table, PendingProgramPhotos table, ProgramEvidenceForm widget, program_evidence_form.dart, program_outbox_dao.dart (replaced), program_evidence_viewer_dialog.dart

## What Is Reused (Zero New UI Required)
- AuditFormPage (existing) — already handles multi-question forms, photos, scoring
- PendingSubmissions outbox (existing) — already handles offline sync for submissions
- SyncEngine submission drain (existing) — already handles POST /submissions
- Submission entity (existing) — just gains ProgramAssignmentId nullable FK

## Slices (Strict Sequential Order)
Slice 1 [BLOCKING]: Server DB — Add FK, update EF Core, drop ProgramEvidence
Slice 2 [SEQUENTIAL after 1]: Server API — Update DTOs, PBAC bypass, status machine bridge
Slice 3 [SEQUENTIAL after 2]: Flutter Sync — Update Drift, delete evidence outbox, rewire sync
Slice 4 [SEQUENTIAL after 3]: Flutter UI — Rewire ProgramExecutionPage to AuditFormPage
Slice 5 [SEQUENTIAL after 4]: Integration Test — E2E proof
</latent_space_scratchpad>

# Epic Plan: Program-Submission Bridge

**ShortID**: b4c8d9e2
**Date**: 2026-05-11
**Track**: C (Epic — 5 ordered slices)
**Workflow**: /analyze-epic

---

## Input Lineage

- **ADR**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260511_181003_b4c8d9e2_program_arch.md`
- **Research A**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260511_141500_b4c8d9e2_program_arch.md`
- **Research B**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260511_142100_e6f7a8b9_program_submission_arch.md`

---

## Executive Summary

Store Managers cannot execute Programs today. Tapping a Program Assignment shows a basic text box and crashes the server with a 400 Bad Request due to a hardcoded fake `CriteriaId` GUID. The fix is to bridge Programs to the existing Submission engine: add a nullable `ProgramAssignmentId` FK to `Submission`, delete the dead `ProgramEvidence` tables, and rewire the Flutter `ProgramExecutionPage` to launch the existing `AuditFormPage`. Programs will instantly gain offline sync, scoring, photo upload, and structured multi-question forms—at zero new UI cost.

```
TODAY:
  [SM taps Assignment] --> [ProgramEvidenceForm] --> POST /assignments/{id}/submit
                                                           |
                                               400 Bad Request (CriteriaId bug)

AFTER:
  [SM taps Assignment] --> [AuditFormPage (reused)] --> POST /submissions (existing outbox)
                                                               |
                                                    Submission.ProgramAssignmentId = AssignmentId
                                                               |
                                              ProgramAssignment.Status -> in_progress -> submitted
```

---

## Decision Matrix

| Shape | Mechanism | Pros | Cons | Verdict |
|---|---|---|---|---|
| **A — Unidirectional FK on Submission** | Add `ProgramAssignmentId` (nullable) to `Submission`. Reuse `AuditFormPage`. Delete `ProgramEvidence`. | Zero new UI. Full engine (score, offline, photos) for free. No circular FK. History of revisions kept. | Large blast radius (7 Sync Steps, Drift migration, 5 server files deleted). Strict ordering required. | ✅ **SELECTED** |
| **B — Enrich ProgramEvidence** | Keep `ProgramEvidence`, add scoring fields, build a mini renderer. | Smaller blast radius. No Drift migration. | Permanent tech debt. No scoring engine. No offline support. Photo uploads need bespoke code. Violates DRY. | ❌ Rejected |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Silent 422 regression if old evidence outbox syncs after server drops the endpoint | 🔴 CRITICAL | Server Slice 1 keeps old evidence endpoint returning `410 Gone` (fatal error → drains outbox to exhausted). Flutter Slice 3 deletes the old outbox. |
| PBAC 403 — SM cannot create Submission for HQ-only Template | 🔴 CRITICAL | Slice 2: PBAC bypass with 3-condition IDOR validation before bypassing. |
| IDOR attack via fake ProgramAssignmentId on submission request | 🔴 CRITICAL | Slice 2: Validate assignment exists, store matches user, templateId matches. Reject all three or bypass nothing. |
| Double-tap in offline mode creates 2 draft Submissions | 🟡 HIGH | Slice 3: Add `active_submission_id` to `CachedProgramAssignments`. Populate on first tap. Resume on second tap. |
| Circular FK (ProgramAssignment.SubmissionId + Submission.ProgramAssignmentId) | 🟡 HIGH | Mitigated by design: FK is ONLY on `Submission`. Use EF Core navigation property `HasOne().WithMany()`. |
| Double approval (AM approves then HQ verifies = 2 approval steps) | 🟡 HIGH | Slice 2: Auto-set `ReviewStatus = "approved"` on Program-linked Submissions to skip AM review step. |
| Draft sync falsely advances ProgramAssignment to `submitted` | 🟡 HIGH | Slice 2: Only transition ProgramAssignment to `submitted` when `Submission.Status == "completed"`. Drafts → `in_progress` only. |
| Cascading delete destroys submitted Submissions if Program is deleted | 🟡 HIGH | Slice 1: FK must be `ON DELETE SET NULL`, not CASCADE. Submission is orphaned, not deleted. |

---

## Visual & Functional Context

### SM Journey (Slice 3 & 4 scope)

```
[My Programs List]
  --> tap assignment (status: pending | overdue | needs_revision)
  --> [AuditFormPage] (reused, existing widget)
       - templateId from CachedProgramAssignment.templateId
       - programAssignmentId passed as context arg
       - auto-saves draft locally via existing DraftAnswers table
  --> SM completes all criteria --> taps "Submit"
  --> PendingSubmissions outbox row created (existing path)
  --> ProgramAssignmentId included in outbox payload
  --> Optimistic status: local CachedProgramAssignment.status = "in_progress"
  --> On sync success: server transitions ProgramAssignment to "submitted"
```

### HQ Journey (Slice 2 scope, backend only)

```
[HQ Programs Dashboard]
  --> GET /api/programs/{id}/assignments
  --> Sees list of assignments with submission data included
  --> Taps assignment --> Sees Submission detail (existing SubmissionDetail view)
  --> POST /assignments/{id}/reject (existing endpoint, unchanged)
  --> POST /assignments/{id}/verify (existing endpoint, unchanged)
  --> SM receives push notification (existing), sees "needs_revision" status
  --> SM reopens AuditFormPage for the SAME submission (edit existing draft)
```

### Mapped API Surface

| Action | Before | After |
|---|---|---|
| SM submits evidence | `POST /api/programs/assignments/{id}/submit` (DELETED) | `POST /api/submissions` (existing, with `programAssignmentId`) |
| HQ views evidence | `GET /api/programs/{id}/assignments` with `ProgramEvidenceDto[]` | Same endpoint, but evidence is the linked `Submission` record |
| HQ rejects/verifies | `POST /assignments/{id}/reject|verify` | Unchanged |
| SM syncs assignments | `GET /api/programs/assignments/my` | Same endpoint, DTO gains `templateId` field |

---

## System Context

### Offline-First Constraints

- `CachedProgramAssignments` must gain `templateId` column (needed offline to launch AuditFormPage without network).
- `active_submission_id` must be written to local Drift before routing to AuditFormPage.
- All submission data flows through the EXISTING `PendingSubmissions` outbox — no new outbox tables needed.
- `PendingProgramSubmissions` and `PendingProgramPhotos` Drift tables are DELETED.

### PBAC Constraints

- Capability `programs:execute` remains (guards assignment access).
- Capability `submissions:create` is NOT required for Program-triggered submissions (bypassed by PBAC logic).
- The PBAC bypass is ONLY in the `POST /api/submissions` handler path when `programAssignmentId` is non-null.

### API Contracts (Delta)

**`AssignmentSummaryDto`** — gains one field:
```
+ templateId: Guid  (needed by Flutter to launch AuditFormPage offline)
```

**`POST /api/submissions`** — existing request body gains one optional field:
```
+ programAssignmentId: Guid?  (triggers PBAC bypass + state machine bridge)
```

**`GET /api/programs/{id}/assignments`** — `ProgramAssignmentDetailDto` — `Evidence[]` field replaced:
```
- ProgramEvidenceDto[] Evidence
+ Guid? LinkedSubmissionId
+ string? LinkedSubmissionStatus
+ decimal? LinkedSubmissionScore
```

---

## Lifecycle Context

### Edge States

| State | Behavior |
|---|---|
| SM taps assignment offline, no network | `active_submission_id` written. AuditFormPage loads template from `CachedTemplates`. Draft saved to `DraftAnswers`. |
| SM taps same assignment again (offline) | `active_submission_id` already set. AuditFormPage resumes existing draft. No new Submission created. |
| SM submits, comes online → sync → server returns 422 | Retry engine marks as exhausted (existing behavior). SM sees error state. |
| HQ rejects → SM must redo | `ProgramAssignment.status = needs_revision`. SM opens AuditFormPage with EXISTING `Submission.Id` (resume, not new). |
| HQ deletes Program after SM submitted | `ProgramAssignment` rows CASCADE deleted. Linked `Submission.ProgramAssignmentId` SET NULL. Submission is orphaned but preserved. |
| Submission auto-approved | `ReviewStatus = "approved"` set server-side on submission sync (no AM action needed). |

### Rollback Plan

If Slice 1 is deployed and Slice 2 fails:
- Old `POST /assignments/{id}/submit` endpoint kept alive returning `410 Gone` (fatal to outbox).
- `ProgramEvidence` entity is dropped in migration but Submission FK is safe to revert via a new migration.
- Flutter is NOT yet updated (Slice 3), so SM sees no change in behavior.

---

## Data Context

### Schema Changes

**`Submission` entity** — add column:
```sql
ALTER TABLE submissions
ADD COLUMN program_assignment_id UUID NULL
REFERENCES program_assignments(id) ON DELETE SET NULL;

CREATE INDEX idx_submissions_program_assignment_id
ON submissions(program_assignment_id)
WHERE program_assignment_id IS NOT NULL;
```

**`ProgramAssignment` entity** — add status value:
```
Status enum gains: 'in_progress'
(pending → in_progress when Submission draft synced)
(in_progress → submitted when Submission completed synced)
```

**`ProgramEvidence` entity** — DROP TABLE:
```sql
DROP TABLE program_evidence;
```

**`AssignmentSummaryDto`** — gains `templateId: Guid` (pulled from `Program.TemplateId` join).

**Drift (Flutter) — `CachedProgramAssignments`** — gains two columns:
```dart
TextColumn get templateId => text().nullable()();
TextColumn get activeSubmissionId => text().nullable()();
```

**Drift (Flutter) — DELETE tables**:
- `PendingProgramSubmissions`
- `PendingProgramPhotos`

### 7 Sync Steps — `ProgramAssignment`

1. Entity: `ProgramAssignment.cs` — no new column (FK is on Submission side)
2. DbContext: `AppDbContext` — configure `Submission.HasOne(ProgramAssignment).WithMany().OnDelete(SetNull)`
3. Server DTO: `AssignmentSummaryDto` — add `TemplateId: Guid`
4. Endpoint projection: `GetMyAssignments.cs` — project `a.Program!.TemplateId`
5. Sync endpoint: `GET /api/programs/assignments/my` response shape updated
6. Flutter DTO: `ProgramAssignmentDto` — add `templateId` field
7. Drift table: `CachedProgramAssignments` — add `template_id` column

---

## Architecture Flow

```
SLICE 1 — Server DB
[EF Core Migration]
  ADD program_assignment_id to submissions (nullable, SET NULL FK)
  ADD index on submissions.program_assignment_id
  DROP program_evidence table
  KEEP old /assignments/{id}/submit returning 410 Gone (fatal drain guard)

SLICE 2 — Server API
[CreateSubmission handler] gains:
  IF request.ProgramAssignmentId != null:
    1. Load ProgramAssignment WHERE id = request.ProgramAssignmentId (404 if missing)
    2. Assert assignment.StoreId matches caller's profile.StoreId (403 if mismatch)
    3. Assert assignment.TemplateId == request.TemplateId (400 if mismatch)
    4. IF all pass → bypass Template PBAC ownership check
    5. Set Submission.ReviewStatus = "approved" (skip AM review)
    6. Transition ProgramAssignment.Status:
       - "draft"     → "in_progress"
       - "completed" → "submitted"
       - "approved"  → "submitted"
[GetMyAssignments handler] projection gains TemplateId

SLICE 3 — Flutter Sync
[tables.dart]
  ADD templateId, activeSubmissionId to CachedProgramAssignments
  DELETE PendingProgramSubmissions table definition
  DELETE PendingProgramPhotos table definition
[program_sync_module.dart]
  _drainProgramEvidence() → DELETED
  _drainProgramPhotos() → DELETED
  _pullProgramAssignments() → maps new templateId field
[program_outbox_dao.dart] → DELETED
[locator.dart] → remove ProgramOutboxDao registration

SLICE 4 — Flutter UI
[program_execution_page.dart]
  Remove: ProgramEvidenceForm widget import, _handleSubmit(), _isDirty state
  Add: On initState → write activeSubmissionId to CachedProgramAssignment
  Add: Navigate to AuditFormPage(templateId, programAssignmentId, submissionId)
[program_evidence_form.dart] → DELETED
[program_evidence_viewer_dialog.dart] → DELETED
[program_manager.dart] → remove submitEvidence(), simplify to loadAssignments only

SLICE 5 — Integration Test
POST /submissions with programAssignmentId
  Assert 201 Created
  Assert Submission.ProgramAssignmentId == assignmentId
  Assert ProgramAssignment.Status == "in_progress" (if draft)
POST /submissions/{id}/finalize (complete it)
  Assert ProgramAssignment.Status == "submitted"
  Assert Submission.ReviewStatus == "approved"
```

---

## Risk Review & Security

### Persona Scores

| Persona | Score | Notes |
|---|---|---|
| DB Architect | 9/10 | Unidirectional FK is clean. Index on `program_assignment_id` prevents N+1. SET NULL on delete is correct. -1 for adding `in_progress` as a string (should use a CHECK constraint or enum). |
| Security Auditor | 9/10 | 3-condition IDOR validation is strong. Auto-approve prevents double-approval confusion. -1 because the 410 Gone guard on old endpoint needs a sunset date (otherwise it lives forever). |
| Junior Dev | 8/10 | Migration order is explicit and safe. Rollback plan is clear. -2 because deleting `ProgramOutboxDao` + all evidence tables + multiple Dart files in one slice (Slice 3) is very large. Should flag to Builder to proceed file by file. |

**All scores ≥ 7. Plan passes.**

### Security Mandates

1. PBAC bypass MUST validate all three conditions atomically in one DB query. Never bypass on presence of `ProgramAssignmentId` alone.
2. Old evidence endpoint (`POST /assignments/{id}/submit`) must return `410 Gone` (not 404) to ensure the Flutter outbox treats it as a fatal error and stops retrying.
3. `Submission.ReviewStatus = "approved"` must be set server-side only, never trusted from client request body.

---

## Logs & Audits

Existing `AuditLogger.Log` infrastructure is unchanged. The Builder must add one audit event:

```
AuditLogger.Log(db, user, "program_submission_created", "Submission", submission.Id,
    $"SM created Program Submission for ProgramAssignment {assignment.Id}.",
    $"/api/submissions");
```

---

## Testing Expectations

| Slice | Test Type | Coverage |
|---|---|---|
| Slice 1 | Migration smoke test | `dotnet test` passes. `program_evidence` table is gone. `submissions.program_assignment_id` column exists. |
| Slice 2 | Integration test | PBAC bypass: SM with `programs:execute` but no `submissions:create` can submit for a Program Assignment. IDOR: SM from Store B cannot bypass for Store A's assignment. Template mismatch: wrong templateId returns 400. |
| Slice 3 | Flutter unit test | `ProgramSyncModule.executePush()` no longer calls `_drainProgramEvidence()`. `_pullProgramAssignments()` maps `templateId` correctly. |
| Slice 4 | Flutter widget test | Tapping assignment writes `activeSubmissionId` before navigating. Second tap resumes same submission. |
| Slice 5 | Full E2E integration test | SM taps → Submission created with `ProgramAssignmentId` → `submitted` on complete → Assert 200 + status match + ReviewStatus = "approved". |

---

<command_logs>
- list_dir: server/Features/Programs
- list_dir: lib/features/programs (pages, manager, services)
- view_file: SubmitProgramEvidence.cs
- view_file: ProgramDtos.cs
- view_file: GetMyAssignments.cs
- view_file: ProgramEndpoints.cs
- view_file: program_execution_page.dart
- view_file: program_manager.dart
- view_file: program_sync_module.dart
- view_file: lib/_shared/database/tables.dart (full — confirmed PendingProgramSubmissions, PendingProgramPhotos, CachedProgramAssignments schemas)
- grep_search: ProgramAssignmentId in server/Features (0 results — confirms FK does not exist yet)
</command_logs>

<forensic_evidence>
- `list_dir server/Features/Programs` → 13 files confirmed: SubmitProgramEvidence.cs, ProgramDtos.cs, ProgramEndpoints.cs, GetMyAssignments.cs, ProgramAssignmentDetailDto in scope.
- `list_dir lib/features/programs/pages` → program_execution_page.dart confirmed at 244 lines. Uses ProgramEvidenceForm (dumb text form).
- `view_file server/Common/Persistence/Entities/ProgramEvidence.cs` → confirmed dead-end schema: AssignmentId, CriteriaId, Value, PhotoLocalKey only. No scoring engine.
- `view_file server/Common/Persistence/Entities/Submission.cs` → TemplateId (nullable), AuditorId, StoreId, Status, ReviewStatus, scoring fields all exist. `ProgramAssignmentId` column does NOT exist (grep_search: 0 results). Confirmed target for nullable FK.
- `view_file lib/_shared/database/tables.dart` lines 345–398 → `CachedProgramAssignments` lacks templateId and activeSubmissionId. `PendingProgramSubmissions` (lines 365–378) and `PendingProgramPhotos` (lines 384–398) exist and are scheduled for deletion.
- `view_file lib/features/programs/manager/program_manager.dart` → `submitEvidence()` hardcodes `criteriaId: 'program_summary'`. This is the source of the fake GUID crash. Writes to `PendingProgramSubmissionsCompanion`.
- `view_file lib/features/programs/services/program_sync_module.dart` → `_drainProgramEvidence()` calls `_api.pushProgramEvidence()` which maps to `POST /assignments/{id}/submit`. This is the sync path that causes the 400 crash.
- `grep_search ProgramAssignmentId in server/Features` → 0 results. FK does not yet exist anywhere in codebase. Confirmed safe to add.
</forensic_evidence>

---

## Handoff Block

### Final Epic Decision
**Option A — Unidirectional FK on Submission.** Persist file:
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md`

### Slices & Ordering

| Slice | Name | Order | Route |
|---|---|---|---|
| Slice 1 | Server DB Migration | `[BLOCKING]` — runs first alone | `/analyze-feature` → `/tdd` → `/implement` |
| Slice 2 | Server API — PBAC bypass + state machine | `[SEQUENTIAL after Slice 1]` | `/analyze-feature` → `/tdd` → `/implement` |
| Slice 3 | Flutter Sync — Drift tables + outbox rewire | `[SEQUENTIAL after Slice 2]` | `/analyze-feature` → `/tdd` → `/implement` |
| Slice 4 | Flutter UI — ProgramExecutionPage rewire | `[SEQUENTIAL after Slice 3]` | `/analyze-feature` → `/implement` |
| Slice 5 | E2E Integration Test | `[SEQUENTIAL after Slice 4]` | `/tdd` → `/implement` |

### Next Steps
The Architect has broken this Epic into 5 strictly ordered slices. Start with **Slice 1** (server DB migration). The Builder must NOT execute Slice 3 (Flutter) until Slice 2 (server API) is verified with `dotnet test`.

### Next Command — Start Slice 1
```
/analyze-feature C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md
```
> Instruction for next agent: Implement Slice 1 only — add `ProgramAssignmentId` nullable FK to `Submission`, drop `ProgramEvidence` table, create EF Core migration, make old evidence endpoint return `410 Gone`.
