<latent_space_scratchpad>
KEY FACTS FROM RECON:
- CreateSubmission.cs = 304 lines (MUST SPLIT first — rule: >250 lines)
- FinalizeSubmission.cs = 317 lines (needs state machine hook — adding ~15 lines is ok, stays <400)
- SubmissionEndpoints.cs POST / has .RequireCapability(SubmissionsCreate) at ROUTE level
- PBAC bypass must happen INSIDE the handler (cannot bypass at route level)
- programs:execute is already seeded for store_manager and area_manager in Program.cs + TestWebApplicationFactory.cs
- AssignmentSummaryDto has: Id, ProgramId, ProgramTitle, Category, Deadline, Status, CreatedAt
  → Must ADD TemplateId to this (7 Sync Steps — Slice 2)
- GetMyAssignments.cs = 68 lines — easy to update
- ProgramDtos.cs = 100 lines — easy to update
- Program_Slice2A_Tests.cs = 140 lines — TC1 and TC2 already pass. New tests to ADD here.
- Program_Slice3_Tests.cs = 70 lines — keep as-is (these test HQ admin view, not Slice 2)
- CreateSubmissionRequest has NO ProgramAssignmentId yet → Must ADD it
- Submission entity has ProgramAssignmentId (added in Slice 1) ✅

STATE MACHINE RULES (from epic):
  On CreateSubmission (draft):  ProgramAssignment.Status: pending/needs_revision → "in_progress"
  On FinalizeSubmission (complete): ProgramAssignment.Status → "submitted"
                                    Submission.ReviewStatus = "approved" (auto-approve)

PBAC BYPASS LOGIC (3-condition, must be atomic):
  IF request.ProgramAssignmentId != null:
    1. Load assignment WHERE id = request.ProgramAssignmentId (404 if missing)
    2. Assert assignment.StoreId == caller's profile.StoreId (403 if mismatch — IDOR)
    3. Assert assignment.TemplateId == request.TemplateId (400 if mismatch)
    4. IF all pass → skip SubmissionsCreate capability check
    5. Set Submission.ProgramAssignmentId = request.ProgramAssignmentId
    6. Auto-set ProgramAssignment.Status → "in_progress" (if status was pending/needs_revision)

  The caller MUST have programs:execute capability (that gate is checked at the Programs endpoint 
  level but NOT at submissions level). Wait — the submission endpoint has RequireCapability(SubmissionsCreate).
  We need to bypass this. But how?
  
  Option A: Remove RequireCapability from the route, check capability INSIDE the handler.
  Option B: Use a custom policy that allows programs:execute OR submissions:create.
  
  Option A is simpler and safer — move the capability check inside the handler.
  The handler already has auth guard code. Add: if request.ProgramAssignmentId != null → check programs:execute instead of submissions:create.
  
  BUT WAIT: RequireCapability is at the endpoint level. The handler runs AFTER the policy check.
  If the SM has programs:execute but NOT submissions:create, they will get 403 before the handler runs.
  
  Solution: Change route from RequireCapability(SubmissionsCreate) to just RequireAuthorization()
  and add manual PBAC check INSIDE the handler at the top.
  
  This is the correct approach per the epic. The security check must be:
  - IF ProgramAssignmentId is null → require submissions:create
  - IF ProgramAssignmentId is not null → require programs:execute + 3-condition IDOR
  
  This means the route-level RequireCapability must be REMOVED and moved inside the handler.

SPLIT STRATEGY for CreateSubmission.cs (304 lines):
  Extract "ProgramAssignment bridge" logic into a new file:
  ProgramAssignmentBridge.cs — a static helper with:
    - ValidateAndLinkAsync(request, callerProfile, db, ct) → returns (assignment, error)  
    - TransitionToInProgressAsync(assignment, db, ct)
  
  This keeps CreateSubmission.cs clean and under 250 lines after adding ~30 lines of bridge code.

FINALIZE HOOK:
  FinalizeSubmission.cs gets a post-success hook (after transaction commits):
    IF submission.ProgramAssignmentId has value:
      Load assignment, set Status = "submitted", set ReviewStatus = "approved"
      This runs OUTSIDE the main transaction (same pattern as notification dispatch)

GEMINI.md GOTCHA — Dual Writes:
  "Always write new snapshot fields in BOTH CreateSubmission AND FinalizeSubmission."
  ProgramAssignmentId is already set at Create time. At Finalize time, we DON'T re-set it
  (it's already on the submission). We only transition ProgramAssignment.Status.

GETMYASSIGNMENTS — TemplateId:
  Must add TemplateId to AssignmentSummaryDto.
  Source: a.Program.TemplateId (navigation: ProgramAssignment → Program → TemplateId)
  This is the 7 Sync Steps rule item 6: Flutter DTO.

AUDIT LOG (from epic):
  AuditLogger.Log(db, user, "program_submission_created", "Submission", submission.Id,
    $"SM created Program Submission for ProgramAssignment {assignment.Id}.",
    $"/api/submissions")
  Add this INSTEAD of or ALONGSIDE the existing "submission_started" log.
  Decision: Add AS WELL — the existing log stays (it's a different event type).
</latent_space_scratchpad>

# Implementation Plan: Slice 2 — Server API (PBAC Bypass + State Machine)
**Program-Submission Bridge**

**ShortID**: b4c8d9e2 | **Date**: 2026-05-11 | **Epic**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md`

---

## Input Lineage
- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md`
- **Slice 1 Walkthrough**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\program_submission_bridge\walkthrough_20260511_184628_b4c8d9e2_slice1_server_db.md`

---

## Executive Summary & Out of Scope

**What Slice 2 does:**

```
BEFORE:
  POST /api/submissions → RequireCapability(submissions:create)
  SM has programs:execute only → 403 Forbidden

AFTER:
  POST /api/submissions → RequireAuthorization() (authenticated only)
  IF request.ProgramAssignmentId == null → require submissions:create (existing path)
  IF request.ProgramAssignmentId != null → require programs:execute + 3-way IDOR (new path)
     ↓ on success
     Submission.ProgramAssignmentId = assignmentId
     ProgramAssignment.Status → "in_progress"
  PUT /api/submissions/{id}/finalize → (existing finalize flow)
     ↓ post-commit hook (if ProgramAssignmentId set)
     ProgramAssignment.Status → "submitted"
     Submission.ReviewStatus = "approved"
```

**Also in Slice 2:** `AssignmentSummaryDto` gains `TemplateId` (7 Sync Steps, Step 6).

**Out of Scope:**
- Flutter Drift tables, `activeSubmissionId`, `ProgramSyncModule` (Slice 3)
- `ProgramExecutionPage` → `AuditFormPage` route (Slice 4)
- E2E integration test (Slice 5)
- New photo upload endpoint for program submissions (not in epic scope for Slice 2)
- `GetProgramAssignments` linked-submission enrichment (future slice)
- `GetMyAssignments` pagination/filter changes (not requested)

---

## ⚠️ Risk Warning

**`CreateSubmission.cs` is 304 lines — above the 250-line file limit.** The Builder must extract the ProgramAssignment bridge logic into `ProgramAssignmentBridge.cs` BEFORE adding new code. This extraction is Phase A.

**Route-level capability gate change:** Removing `.RequireCapability(SubmissionsCreate)` from `SubmissionEndpoints.cs` and moving the check inside the handler is a security-critical operation. The Builder MUST ensure the manual check inside the handler covers both paths:
- No `ProgramAssignmentId` → check `submissions:create` explicitly
- With `ProgramAssignmentId` → check `programs:execute` + IDOR

---

## System Context

- **Environment**: Server-only (ASP.NET Core .NET 10, PostgreSQL)
- **RBAC**: `store_manager` has `programs:execute` (seeded in `Program.cs` line 353 and `TestWebApplicationFactory.cs` line 136). They do NOT have `submissions:create`.
- **Local rules (GEMINI.md Submissions)**: "Always write new snapshot fields in BOTH CreateSubmission AND FinalizeSubmission." → ProgramAssignmentId is set at create; at finalize we only transition the `ProgramAssignment.Status`, not re-set the FK.
- **Local rules (Persistence GEMINI.md)**: `NpgsqlRetryingExecutionStrategy` — all DB work inside `strategy.ExecuteAsync()`. The ProgramAssignment status update must run INSIDE the same `ExecuteAsync` closure as the submission save.
- **Commands use `rtk` prefix** (e.g., `rtk dotnet build`).

---

## Lifecycle Context

| State | Behavior |
|---|---|
| **SM creates draft (program path)** | `POST /submissions` with valid `ProgramAssignmentId` → 201 Created. `ProgramAssignment.Status = "in_progress"`. |
| **SM finalizes (program path)** | `PUT /submissions/{id}/finalize` → 200 OK. `ProgramAssignment.Status = "submitted"`. `Submission.ReviewStatus = "approved"`. |
| **IDOR attempt (wrong store)** | `POST /submissions` with `ProgramAssignmentId` for another store → 403 Forbidden. |
| **Template mismatch** | `POST /submissions` with `ProgramAssignmentId` but wrong `TemplateId` → 400 Bad Request. |
| **Missing assignment** | `POST /submissions` with non-existent `ProgramAssignmentId` → 404 Not Found. |
| **Normal audit (no ProgramAssignmentId)** | `POST /submissions` unchanged — requires `submissions:create` capability as before. |

---

## Test Contracts

| ID | Scenario | Given | When | Then | Why fails first |
|---|---|---|---|---|---|
| TC-S2-01 | SM with programs:execute creates draft for valid assignment | SM assigned to Store A, assignment belongs to Store A, templateId matches | POST /submissions with ProgramAssignmentId | 201 Created. `submission.ProgramAssignmentId` = assignmentId. `assignment.Status` = "in_progress" | Route gate blocks SM (no submissions:create) |
| TC-S2-02 | SM creates completed submission for assignment | Same setup, answers + clientScore provided | POST /submissions with status=completed | 201 Created. `assignment.Status` = "in_progress" (draft→finalize flow handles "submitted") | Gate blocks |
| TC-S2-03 | Finalize transitions assignment to submitted | TC-S2-01 draft exists | PUT /submissions/{id}/finalize | 200 OK. `assignment.Status` = "submitted". `submission.ReviewStatus` = "approved" | State machine hook not yet in FinalizeSubmission |
| TC-S2-04 | IDOR: SM from Store B cannot use Store A assignment | SM assigned to Store B | POST /submissions with Store A's assignmentId | 403 Forbidden | IDOR check not yet implemented |
| TC-S2-05 | Template mismatch returns 400 | Valid assignment for Store A, but wrong templateId in request | POST /submissions | 400 Bad Request, body has `error` field | Mismatch check not yet implemented |
| TC-S2-06 | Non-existent assignmentId returns 404 | Any | POST /submissions with random UUID as ProgramAssignmentId | 404 Not Found | Assignment lookup not yet implemented |
| TC-S2-07 | SM without programs:execute is rejected | SM with no capabilities | POST /submissions with ProgramAssignmentId | 403 Forbidden | No manual capability check yet |
| TC-S2-08 | Normal audit path unchanged | Auditor with submissions:create | POST /submissions without ProgramAssignmentId | 201 Created (existing behavior preserved) | Regression — must not break |
| TC-S2-09 | GetMyAssignments returns templateId field | SM has assignment | GET /api/programs/assignments/my | Response items contain non-null `templateId` | AssignmentSummaryDto lacks templateId |
| TC-S2-10 | Double-tap guard: second draft POST returns same submission | SM creates draft, then POSTs again with same IdempotencyKey | POST twice | Second call returns 200 (idempotency hit), not a new 201 | Idempotency key already works — TC proves regression safety |

---

## Test Fixture & Payloads

**Required state for TC-S2-01 through TC-S2-07:**
```
- Admin user (bootstrap)
- Template (type: "qc", isActive: true)
- Store A
- ChecklyProgram (templateId = Template.Id)
- ProgramAssignment (programId = Program.Id, storeId = StoreA.Id, status = "pending")
- SM user (role: store_manager) linked to Store A via Profile.StoreId
```

**Request body — TC-S2-01 (draft program submission):**
```json
POST /api/submissions
{
  "templateId": "{{templateId}}",
  "storeId": "{{storeAId}}",
  "programAssignmentId": "{{assignmentId}}",
  "status": "draft",
  "clientScore": null,
  "answers": null,
  "idempotencyKey": "prog-draft-{{assignmentId}}"
}
Expected: 201 Created
{
  "id": "{{newSubmissionId}}",
  "status": "draft",
  "templateId": "{{templateId}}"
}
```

**Request body — TC-S2-03 (finalize to trigger state machine):**
```json
PUT /api/submissions/{{submissionId}}/finalize
{
  "clientScore": 95.0,
  "sectionScores": "{}",
  "answers": [ ... ]
}
Expected: 200 OK
— ProgramAssignment.Status == "submitted" (verify via DB scope)
— Submission.ReviewStatus == "approved" (verify via DB scope)
```

---

## Tools & Commands

**Skills needed:**
- `ef-core` (for GEMINI.md transaction rules)
- `atdd-quality-gates` (test classification)

**Commands:**
```
rtk dotnet build server/Checkly.Api.csproj
rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj
```

---

## Proposed Changes

```
[NEW] server/Features/Submissions/ProgramAssignmentBridge.cs
      Static helper — validates IDOR + template match, transitions ProgramAssignment.Status

[MOD] server/Features/Submissions/CreateSubmission.cs
      - Remove direct PBAC capability gate assumption
      + Add manual capability check at top (submissions:create OR programs:execute path)
      + Call ProgramAssignmentBridge.ValidateAndLinkAsync() when ProgramAssignmentId is set
      + Set submission.ProgramAssignmentId in the Submission builder
      + Add program_submission_created audit log entry

[MOD] server/Features/Submissions/FinalizeSubmission.cs
      + Post-commit hook: IF submission.ProgramAssignmentId != null →
          load assignment, set Status = "submitted", set ReviewStatus = "approved", SaveChanges

[MOD] server/Features/Submissions/SubmissionEndpoints.cs
      - .RequireCapability(AppCapabilities.SubmissionsCreate) on POST /
      + .RequireAuthorization() (capability checked inside handler)

[MOD] server/Features/Submissions/Dtos.cs
      + Add Guid? ProgramAssignmentId to CreateSubmissionRequest

[MOD] server/Features/Programs/ProgramDtos.cs
      + Add Guid? TemplateId to AssignmentSummaryDto (7 Sync Steps)

[MOD] server/Features/Programs/GetMyAssignments.cs
      + Map a.Program!.TemplateId into AssignmentSummaryDto projection

[MOD] server/tests/Checkly.Api.Tests/Program_Slice2A_Tests.cs
      + Add TC-S2-01 through TC-S2-09 test methods
```

**Total files**: 7 MOD, 1 NEW = 8 files.

---

## Concept Diagram

```
[POST /api/submissions]
     |
     v
[Handler: CreateSubmission.HandleAsync]
     |
     +-- ProgramAssignmentId == null?
     |        |
     |        YES → Check submissions:create capability
     |                  → 403 if missing → normal audit path
     |        NO ↓
     +-- [ProgramAssignmentBridge.ValidateAndLinkAsync]
              |
              ├── Load ProgramAssignment by id → 404 if not found
              ├── Assert assignment.StoreId == caller profile.StoreId → 403 if mismatch
              ├── Assert assignment.TemplateId == request.TemplateId → 400 if mismatch
              └── Check programs:execute capability → 403 if missing
                       |
                       v
              [Build Submission entity]
              submission.ProgramAssignmentId = assignmentId
                       |
                       v
              [strategy.ExecuteAsync]
              ├── db.Submissions.Add(submission)
              ├── assignment.Status = "in_progress" (if pending/needs_revision)
              ├── AuditLogger.Log("program_submission_created")
              └── db.SaveChangesAsync()
                       |
                       v
              201 Created ✅

[PUT /api/submissions/{id}/finalize]
     |
     v
[FinalizeSubmission.HandleAsync — existing logic unchanged]
     |
     v
[After transaction.CommitAsync()]
     |
     +-- submission.ProgramAssignmentId == null?
              |
              YES → skip (normal audit path)
              NO ↓
     [Load ProgramAssignment]
     assignment.Status = "submitted"
     submission.ReviewStatus = "approved"
     db.SaveChangesAsync() ← outside main transaction (same pattern as notification)
     200 OK ✅
```

---

## Execution Phases

### Phase A — Extract ProgramAssignmentBridge (File Split)

**Complexity: Low.** No new logic — only extraction.

- **Summary**: Create `ProgramAssignmentBridge.cs` with a static `ValidateAndLinkAsync()` method. Extract the 3-condition IDOR validation logic into this file so `CreateSubmission.cs` stays under 250 lines when the new code is added.
- **Value**: `rtk dotnet build` passes. `CreateSubmission.cs` is ready to receive new code safely.
- **Entry state**: `CreateSubmission.cs` = 304 lines.
- **Exit state**: `ProgramAssignmentBridge.cs` exists with validation method. Build passes.
- **Scope**:
  - `[NEW]` `server/Features/Submissions/ProgramAssignmentBridge.cs` — contains `ValidateAndLinkAsync(Guid assignmentId, Guid templateId, Guid callerStoreId, AppDbContext db, CancellationToken ct)` returning a `Result` discriminated union (assignment or error `IResult`).
- **Acceptance Criteria**:
  - `ProgramAssignmentBridge.cs` exists on disk
  - Contains the 3-condition check: load assignment → IDOR → template match
  - Returns structured result type (not throws)
  - `rtk dotnet build` passes

### Phase B — CreateSubmission PBAC Bypass + DTO Update

**Complexity: Medium.** New conditional path inside an existing complex handler.

- **Summary**: Add `ProgramAssignmentId` to the request DTO. Move the capability check inside the handler. Call `ProgramAssignmentBridge.ValidateAndLinkAsync()`. Set `submission.ProgramAssignmentId` and write `assignment.Status = "in_progress"` inside the strategy closure. Remove route-level capability gate from `SubmissionEndpoints.cs`.
- **Value**: `POST /submissions` with a valid `ProgramAssignmentId` from an SM returns 201 Created and transitions assignment to `in_progress`.
- **Entry state**: Phase A complete. Build passes.
- **Exit state**: TC-S2-01, TC-S2-04, TC-S2-05, TC-S2-06, TC-S2-07, TC-S2-08 all pass.
- **Scope**:
  - `[MOD]` `Dtos.cs` — add `Guid? ProgramAssignmentId = null` to `CreateSubmissionRequest`
  - `[MOD]` `SubmissionEndpoints.cs` — change POST route from `RequireCapability(SubmissionsCreate)` to `RequireAuthorization()`
  - `[MOD]` `CreateSubmission.cs` — add manual capability split at top, call bridge, set FK on entity, write audit log, save assignment status inside `strategy.ExecuteAsync`
- **CRITICAL guard**: The `ProgramAssignment.Status` update MUST happen inside the same `strategy.ExecuteAsync()` closure as `db.SaveChangesAsync()` — per GEMINI.md Npgsql rule.
- **Acceptance Criteria**:

| ID | Check | How |
|---|---|---|
| B1 | SM (programs:execute) creates draft with valid assignmentId → 201 | Integration test TC-S2-01 |
| B2 | IDOR: wrong store → 403 | Integration test TC-S2-04 |
| B3 | Template mismatch → 400 | Integration test TC-S2-05 |
| B4 | Non-existent assignmentId → 404 | Integration test TC-S2-06 |
| B5 | SM without programs:execute → 403 | Integration test TC-S2-07 |
| B6 | Normal audit (no programAssignmentId) still works → 201 | Integration test TC-S2-08 |
| B7 | Assignment.Status in DB = "in_progress" after create | DB scope assertion in TC-S2-01 |

### Phase C — FinalizeSubmission State Machine Hook

**Complexity: Low.** Post-commit hook, same pattern as notification dispatch already in the file.

- **Summary**: After `transaction.CommitAsync()` in `FinalizeSubmission.HandleAsync`, add a conditional block: if `submission.ProgramAssignmentId` is not null, load the assignment, set `Status = "submitted"` and `submission.ReviewStatus = "approved"`, then `SaveChangesAsync()`. This runs outside the main transaction (same pattern as FCM dispatch on lines 289–312).
- **Value**: Completing a program submission automatically marks the assignment as done and bypasses AM review.
- **Entry state**: Phase B complete.
- **Exit state**: TC-S2-03 passes. `FinalizeSubmission.cs` ≤ 340 lines.
- **Scope**:
  - `[MOD]` `FinalizeSubmission.cs` — add ~15-line post-commit block
- **Acceptance Criteria**:

| ID | Check | How |
|---|---|---|
| C1 | Finalize sets assignment.Status = "submitted" | DB scope assertion in TC-S2-03 |
| C2 | Finalize sets submission.ReviewStatus = "approved" | DB scope assertion in TC-S2-03 |
| C3 | FinalizeSubmission.cs is ≤ 340 lines | `wc -l` or view_file |
| C4 | Normal finalize (no programAssignmentId) unchanged | Existing finalize tests still pass |

### Phase D — GetMyAssignments TemplateId (7 Sync Steps)

**Complexity: Low.** One-line projection change + one field add to DTO.

- **Summary**: Add `Guid? TemplateId` to `AssignmentSummaryDto`. Map `a.Program!.TemplateId` in the EF Core LINQ projection inside `GetMyAssignments.cs`. Existing tests in `Program_Slice2A_Tests.cs` do NOT assert `templateId` yet — add one assertion to TC1 to prove the field is populated.
- **Entry state**: Phase C complete.
- **Exit state**: TC-S2-09 passes. `GetMyAssignments` response contains `templateId`.
- **Scope**:
  - `[MOD]` `ProgramDtos.cs` — add `Guid? TemplateId` to `AssignmentSummaryDto`
  - `[MOD]` `GetMyAssignments.cs` — add `TemplateId = a.Program!.TemplateId` to `.Select()` projection
  - `[MOD]` `Program_Slice2A_Tests.cs` — add assertion `Assert.NotNull(item.GetProperty("templateId"))` in TC1

---

<command_logs>
- view_file: walkthrough_20260511_184628_b4c8d9e2_slice1_server_db.md — confirmed Slice 1 complete, 471 tests pass
- view_file: Program_Slice2A_Tests.cs — confirmed TC1/TC2 existing, helpers available, 140 lines
- view_file: Program_Slice3_Tests.cs — confirmed HQ scope (not Slice 2 target)
- view_file: UploadProgramPhoto.cs — confirmed 410 stub, 25 lines
- view_file: CreateSubmission.cs — 304 lines (over limit), confirmed no ProgramAssignmentId field
- view_file: FinalizeSubmission.cs — 317 lines, confirmed post-commit notification pattern at line 289
- view_file: SubmissionEndpoints.cs — confirmed RequireCapability(SubmissionsCreate) on POST /
- view_file: Dtos.cs — confirmed CreateSubmissionRequest lacks ProgramAssignmentId
- view_file: ProgramDtos.cs — confirmed AssignmentSummaryDto lacks TemplateId
- view_file: GetMyAssignments.cs — confirmed 68 lines, no TemplateId in projection
- view_file: GetProgramAssignments.cs — confirmed 95 lines, nulls for LinkedSubmission fields
- view_file: AppCapabilities.cs — confirmed ProgramsExecute = "programs:execute"
- view_file: Submission.cs — confirmed ProgramAssignmentId added in Slice 1 (line 12)
- view_file: ProgramAssignment.cs — confirmed Status values: pending/submitted/needs_revision/verified
- grep_search: programs:execute → seeded in Program.cs line 353 + TestWebApplicationFactory.cs line 136
- grep_search: RequireCapability in SubmissionEndpoints.cs → SubmissionsCreate on POST /
</command_logs>

---

## Handoff Block

> [!IMPORTANT]
> **Route: `/atdd` first** (Slice 2 uses Network + Auth + Database = high test risk).
> The existing `Program_Slice2A_Tests.cs` is the right home for TC-S2-01 through TC-S2-09.
>
> **Phases must run in order A → B → C → D.** Each phase must `rtk dotnet build` before proceeding.

```
@[/atdd] Execute specs for Slice 2 — Phase A through D:
C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_190931_b4c8d9e2_slice2_server_api.md
```

> [!WARNING]
> **Concurrency**: Do NOT start Slice 3 (Flutter) until `rtk dotnet test` passes for all Slice 2 phases.
