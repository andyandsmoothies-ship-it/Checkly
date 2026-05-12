<latent_space_scratchpad>
## The Compilation Landmine

The biggest risk in Slice 1: when we delete ProgramEvidence entity + DbSet, two production handlers
will NOT COMPILE:
  1. GetProgramAssignments.cs (line 73): queries db.ProgramEvidence
  2. UploadProgramPhoto.cs (line 52): queries db.ProgramEvidence

And two test files will NOT COMPILE / will FAIL:
  1. SubmitProgramEvidence_PbacAuth_Tests.cs — all 4 tests call the old submit endpoint.
     After Slice 1, that endpoint returns 410 Gone.
     Tests that expected 200 will now fail because 410 is the correct new behavior.
     Tests that expected 403/404 are fine IF they hit the endpoint before the 410 check.
     But actually, if the endpoint now only returns 410, ALL tests need to be updated to
     assert 410 Gone. This is a problem — we'd be changing tests to make new code pass.
     RULE: "TESTS ALWAYS WIN over Markdown plans."
     
     BUT WAIT: The rule says "Never change a test and the main code in the same step."
     In Slice 1 we are changing the code. We can also update the tests to match the NEW
     behavior (endpoint returns 410). The key rule is we don't change a test just to make
     EXISTING code pass. Here we're changing the behavior itself, so updating tests is
     correct. The test goal changes from "SM can submit evidence" to "Old endpoint returns Gone."
     
     HOWEVER: The existing `SubmitProgramEvidence_WhenCallerHasCapability_Succeeds` test
     was written to prove PBAC works — that test's PURPOSE is valid but its MECHANISM
     (POST to old endpoint) is the part that changes. The correct approach: DELETE the entire
     file in Slice 1, because these tests validate a behavior that no longer exists.
     They will be re-written in Slice 2 (new submission PBAC tests).

  2. ProgramPhotoIntegrationTests.cs — seeds db.ProgramEvidence directly in setup.
     After ProgramEvidence DbSet is removed from AppDbContext, this file WON'T COMPILE.
     Solution: DELETE this test file entirely in Slice 1. The UploadProgramPhoto endpoint
     itself is also being stubbed to return 410. New photo tests will be written in Slice 2
     when the new submission-based photo upload endpoint is implemented.

## Handler Stubbing Strategy

The handlers that reference db.ProgramEvidence must be made compile-safe in Slice 1:

GetProgramAssignments.cs: Remove the db.ProgramEvidence query. For now, return Evidence = []
and add a TODO comment: "// Slice 2: Replace with LinkedSubmissionId, Status, Score."
This is correct Slice 1 behavior — no evidence is returned yet, but the endpoint compiles.

UploadProgramPhoto.cs: Return TypedResults.Problem(statusCode: 410, title: "Gone",
detail: "Program photo upload via this endpoint is deprecated. Use the submission photo endpoint.")
This is the drain guard per the epic plan.

SubmitProgramEvidence.cs: Return TypedResults.Problem(statusCode: 410, title: "Gone",
detail: "Use POST /api/submissions with programAssignmentId instead.")

## File Sizes Check

SubmitProgramEvidence.cs: 80 lines → OK to shrink (will become ~15 lines — just returns 410)
GetProgramAssignments.cs: 121 lines → OK to shrink (removing evidenceMap section ~30 lines)
UploadProgramPhoto.cs: 82 lines → OK to shrink to ~20 lines
ProgramDtos.cs: 127 lines → Will DELETE: EvidenceItemRequest, SubmitEvidenceRequest, ProgramEvidenceDto, ProgramAssignmentDetailDto.Evidence field
SubmitProgramEvidence_PbacAuth_Tests.cs: 301 lines → DELETE entirely
ProgramPhotoIntegrationTests.cs: 190 lines → DELETE entirely

## Migration Naming

Latest migration: 20260510032711_SeedPhase3CapabilitiesAndFixBugs
New migration must be: 20260511XXXXXX_BridgeProgramToSubmission

IMPORTANT: dotnet run is RUNNING. Must stop it, run migration, restart.
Server: c:\Users\HP\Documents\GitHub\Checkly\server

## What Stays in ProgramDtos.cs (7 Sync Steps — only DTO changes in Slice 1)

Keep these (they are NOT related to ProgramEvidence):
- CreateProgramRequest
- CreateProgramResponse  
- ProgramSummaryDto
- AssignmentSummaryDto (note: does NOT get templateId yet — that is Slice 2 per 7 sync steps)
- RejectRequest
- ProgramSummaryResponse
- UpdateProgramRequest

Delete these (they reference ProgramEvidence or old evidence endpoint):
- EvidenceItemRequest
- SubmitEvidenceRequest
- ProgramEvidenceDto
- The Evidence[] field from ProgramAssignmentDetailDto → replace with nullable LinkedSubmissionId, LinkedSubmissionStatus, LinkedSubmissionScore

## Migration Content (conceptual — EF Core will generate, but Builder knows what to expect)

UP:
  ALTER TABLE submissions ADD COLUMN program_assignment_id uuid NULL;
  ALTER TABLE submissions ADD CONSTRAINT fk_submissions_program_assignment 
    FOREIGN KEY (program_assignment_id) REFERENCES program_assignments(id) ON DELETE SET NULL;
  CREATE INDEX idx_submissions_program_assignment_id 
    ON submissions(program_assignment_id) WHERE program_assignment_id IS NOT NULL;
  DROP TABLE program_evidence;

DOWN (rollback):
  DROP INDEX idx_submissions_program_assignment_id;
  ALTER TABLE submissions DROP COLUMN program_assignment_id;
  CREATE TABLE program_evidence (...) -- EF Core generates this

EF Core C# needed to generate this migration:
  1. In Submission.cs: add `public Guid? ProgramAssignmentId { get; set; }` and `public ProgramAssignment? ProgramAssignment { get; set; }`
  2. In SubmissionConfiguration.cs: add HasIndex(x => x.ProgramAssignmentId).HasFilter("program_assignment_id IS NOT NULL"); and HasOne(x => x.ProgramAssignment).WithMany(a => a.Submissions).HasForeignKey(x => x.ProgramAssignmentId).OnDelete(DeleteBehavior.SetNull);
  3. In ProgramAssignment.cs: add `public ICollection<Submission> Submissions { get; set; } = [];`
  4. In AppDbContext.cs: DELETE the `public DbSet<ProgramEvidence> ProgramEvidence => Set<ProgramEvidence>();` line
  5. DELETE ProgramEvidenceConfiguration.cs entirely
  6. DELETE ProgramEvidence.cs entity entirely

EF Core will then generate migration that:
- Adds submissions.program_assignment_id column with FK
- Drops program_evidence table

## ProgramAssignment.cs current content
I need to check ProgramAssignment.cs to confirm current fields before adding Submissions nav prop.

## CRITICAL: ChecklyProgramConfiguration — does Program use Deadline?
Need to check if Deadline is in the existing ChecklyProgram config — it IS in GetMyAssignments
The existing Config already has it per earlier view. No changes there.
</latent_space_scratchpad>

# Implementation Plan: Slice 1 — Server DB Migration
**Program-Submission Bridge**

**ShortID**: b4c8d9e2
**Date**: 2026-05-11
**Scope**: Server only — no Flutter changes
**Epic**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md`

---

## Input Lineage

- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md`

---

## Executive Summary & Out of Scope

**What this slice does** — in plain English:

This slice does three things at once:
1. **Adds a bridge column**: Adds `program_assignment_id` (nullable) to the `submissions` table so that a Submission can be linked to a ProgramAssignment.
2. **Deletes the dead weight**: Removes the `program_evidence` table from the database AND all the C# code that writes to or reads from it.
3. **Installs the drain guard**: Changes the old `POST /assignments/{id}/submit` endpoint to return `410 Gone` so the Flutter outbox treats it as a fatal error and stops retrying instead of silently swallowing 404s.

```
BEFORE:
  submissions table          program_evidence table
  [id, template_id, ...]     [id, assignment_id, value, ...]
       (no link)                (dead-end, no scoring)

AFTER:
  submissions table          program_evidence table
  [id, template_id,          DELETED
   program_assignment_id FK]
```

**Out of Scope** (do NOT implement in this slice):
- PBAC bypass logic in `POST /api/submissions` (Slice 2)
- Auto-approve `ReviewStatus` when `ProgramAssignmentId` is set (Slice 2)
- `TemplateId` field on `AssignmentSummaryDto` (Slice 2 — 7 Sync Steps)
- State machine bridge (ProgramAssignment status transitions) (Slice 2)
- Flutter Drift tables, `ProgramSyncModule` rewire (Slice 3)
- `ProgramExecutionPage` → `AuditFormPage` redirect (Slice 4)
- The new `POST /api/photos/submissions/{photoLocalKey}` endpoint (Slice 2)

---

## ⚠️ Risk Warning

**Compilation Landmine — Two production files query `db.ProgramEvidence` and will fail to compile if the DbSet is removed without updating them.**

| File | Line | Current code | Slice 1 fix |
|---|---|---|---|
| `GetProgramAssignments.cs` | 73 | `db.ProgramEvidence.AsNoTracking()...` | Remove the evidence batch-load query; return `Evidence = []` stub |
| `UploadProgramPhoto.cs` | 52 | `db.ProgramEvidence.Include(...)...` | Replace entire handler body with `410 Gone` |

**Two test files also reference `db.ProgramEvidence` and will not compile after deletion.**

| File | Action | Reason |
|---|---|---|
| `SubmitProgramEvidence_PbacAuth_Tests.cs` | DELETE | Tests validate the old endpoint behavior (POST /assignments/{id}/submit). After Slice 1, that endpoint returns 410. These tests are replaced in Slice 2 by submission-based PBAC tests. |
| `ProgramPhotoIntegrationTests.cs` | DELETE | Fixture directly seeds `db.ProgramEvidence` rows which no longer exist. Photo upload tests will be re-written in Slice 2 against the new submission photo path. |

> [!NOTE] AI Decision: Deleting tests is correct here because the behavior they test (ProgramEvidence table writes) is intentionally deleted. Rule: "Fix the code to match the tests" only applies when tests are testing valid expected behavior. These tests test deprecated behavior.

---

## System Context

- **Environment**: Server-only (ASP.NET Core .NET 10, PostgreSQL via EF Core)
- **Migration path**: EF Core `dotnet ef migrations add` → auto-applied on server restart via `db.Database.Migrate()` in `Program.cs`
- **Critical local rule** (from `server/Common/Persistence/GEMINI.md`): After creating a migration, the server MUST be restarted to trigger auto-migrate. The Builder MUST emit a `> [!WARNING]` block.
- **Critical local rule** (from `GEMINI.md`): All terminal commands must use `rtk` prefix (e.g., `rtk dotnet build`).
- **Server is currently running** (`dotnet run` for 8h+). Migration generation requires the terminal — the user must stop the server first.
- **PBAC**: No PBAC capability changes in this slice.

---

## Lifecycle Context

This slice is pure server infrastructure — no UI states.

| State | Behavior |
|---|---|
| **Migration Applied** | `submissions.program_assignment_id` column exists. `program_evidence` table is gone. Server restarts successfully. |
| **Migration Pending** | Server crashes on startup if code references deleted table. Migration must run before restart. |
| **Rollback needed** | EF Core `dotnet ef migrations remove` reverts the migration file. A `Down()` method re-creates the `program_evidence` table. |
| **Old Flutter outbox syncs** | `POST /assignments/{id}/submit` returns `410 Gone`. Flutter outbox treats 410 as fatal → marks row as `exhausted`. No data loss, no infinite retry. |

---

## Test Contracts

| ID | Scenario | Given | When | Then | Why it fails first |
|---|---|---|---|---|---|
| TC1 | Build succeeds after entity deletion | All ProgramEvidence C# references removed | `rtk dotnet build` | Exit code 0, 0 errors | ProgramEvidence DbSet, entity class, and configuration deleted |
| TC2 | Migration is syntactically valid | Migration file generated | `rtk dotnet ef migrations script` | SQL output contains `ADD COLUMN program_assignment_id` and `DROP TABLE program_evidence` | Migration hasn't been generated yet |
| TC3 | Server starts without crash | Migration applied, server restarted | Server startup log | No `42703 column does not exist` errors | Column doesn't exist in DB before migration |
| TC4 | Old evidence endpoint returns 410 | Server running | `POST /api/programs/assignments/{id}/submit` with any body | HTTP 410 Gone, body `{ "error": "Deprecated..." }` | Handler still returns 200 or 400 currently |
| TC5 | Old photo endpoint returns 410 | Server running | `POST /api/photos/programs/evidence/{key}` with any file | HTTP 410 Gone | Handler still queries db.ProgramEvidence |
| TC6 | `dotnet test` passes | All test changes applied | `rtk dotnet test` | All tests pass, including the new behavior | `SubmitProgramEvidence_PbacAuth_Tests` and `ProgramPhotoIntegrationTests` fail until they are deleted |
| TC7 | FK integrity: Program deletion sets null | Submission linked to ProgramAssignment, Program deleted | `DELETE FROM programs WHERE id = ?` | `submission.program_assignment_id` = NULL (not deleted) | FK uses RESTRICT or CASCADE currently (neither is correct) |
| TC8 | Null FK does not break existing submissions | Existing submissions (not linked to programs) | `GET /api/submissions?...` | All existing submissions return correctly, `program_assignment_id` = null | EF Core incorrectly marks column as required |

---

## Test Fixture & Payloads

**No new seed data required for Slice 1** — this is schema-only. Tests are deleted, not added.

**Smoke test after migration (run manually):**
```http
POST /api/programs/assignments/00000000-0000-0000-0000-000000000001/submit
Authorization: Bearer {sm_token}
Content-Type: application/json

{}

Expected response:
HTTP 410 Gone
{ "status": 410, "title": "Gone", "detail": "Use POST /api/submissions with programAssignmentId instead." }
```

---

## Tools & Commands

**Skills needed:**
- `ef-core` (EF Core migration pattern)
- `dotnet-scaffolding` (migration scaffold command)

**Commands** (Builder runs these in order):
```
# 1. Verify build after code changes (before migration)
rtk dotnet build server/Checkly.Api.csproj

# 2. Generate the migration (stop dotnet run first)
rtk dotnet ef migrations add BridgeProgramToSubmission --project server/Checkly.Api.csproj --startup-project server/Checkly.Api.csproj

# 3. Verify migration SQL is correct
rtk dotnet ef migrations script --idempotent --project server/Checkly.Api.csproj --startup-project server/Checkly.Api.csproj > .agents/tmp/migration_preview.sql

# 4. Run tests
rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj
```

---

## Proposed Changes

```
[MOD] server/Common/Persistence/Entities/Submission.cs
      + Add: ProgramAssignmentId (Guid? nullable)
      + Add: ProgramAssignment? navigation property

[MOD] server/Common/Persistence/Entities/ProgramAssignment.cs
      + Add: ICollection<Submission> Submissions navigation property

[MOD] server/Common/Persistence/AppDbContext.cs
      - Delete line 40: DbSet<ProgramEvidence>

[MOD] server/Common/Persistence/Configurations/SubmissionConfiguration.cs
      + Add: HasIndex(x => x.ProgramAssignmentId) with partial filter
      + Add: HasOne(ProgramAssignment).WithMany(a => a.Submissions).OnDelete(SetNull)

[DEL] server/Common/Persistence/Entities/ProgramEvidence.cs
[DEL] server/Common/Persistence/Configurations/ProgramEvidenceConfiguration.cs

[NEW] server/Common/Persistence/Migrations/20260511XXXXXX_BridgeProgramToSubmission.cs
      (generated by EF Core — adds FK column, drops program_evidence table)

[MOD] server/Features/Programs/SubmitProgramEvidence.cs
      Replace entire handler body with: return TypedResults.Problem(statusCode: 410, title: "Gone")
      Delete all using imports that reference ProgramEvidence

[MOD] server/Features/Programs/GetProgramAssignments.cs
      Remove lines 72–97 (evidence batch-load)
      Replace ProgramEvidenceDto[] Evidence with: Guid? LinkedSubmissionId (stub null)
      Update result projection to pass null for LinkedSubmissionId

[MOD] server/Features/Programs/ProgramDtos.cs
      [DEL] EvidenceItemRequest record
      [DEL] SubmitEvidenceRequest record
      [DEL] ProgramEvidenceDto record
      [MOD] ProgramAssignmentDetailDto: replace ProgramEvidenceDto[] Evidence
            with Guid? LinkedSubmissionId, string? LinkedSubmissionStatus, decimal? LinkedSubmissionScore

[MOD] server/Features/Photos/UploadProgramPhoto.cs
      Replace entire handler body with: return TypedResults.Problem(statusCode: 410, title: "Gone")
      Remove all ProgramEvidence db queries

[DEL] server/tests/Checkly.Api.Tests/Features/Programs/SubmitProgramEvidence_PbacAuth_Tests.cs
[DEL] server/tests/Checkly.Api.Tests/Features/Photos/ProgramPhotoIntegrationTests.cs
```

**File count**: 5 MOD, 4 DEL, 1 NEW (migration). Total blast radius: ~12 files.

---

## Concept Diagram

```
[Builder executes code changes]
       |
       v
[DEL] ProgramEvidence.cs entity
[DEL] ProgramEvidenceConfiguration.cs
[MOD] AppDbContext.cs — remove DbSet<ProgramEvidence>
[MOD] Submission.cs — + ProgramAssignmentId Guid? nullable
[MOD] ProgramAssignment.cs — + Submissions nav prop
[MOD] SubmissionConfiguration.cs — + HasOne(ProgramAssignment) SetNull FK
       |
       v
[COMPILE CHECK] rtk dotnet build → 0 errors
       |
       v
[MOD] SubmitProgramEvidence.cs — returns 410 Gone
[MOD] GetProgramAssignments.cs — removes evidence query, stubs LinkedSubmissionId = null
[MOD] UploadProgramPhoto.cs — returns 410 Gone
[MOD] ProgramDtos.cs — delete evidence DTOs, update ProgramAssignmentDetailDto
[DEL] SubmitProgramEvidence_PbacAuth_Tests.cs
[DEL] ProgramPhotoIntegrationTests.cs
       |
       v
[COMPILE CHECK] rtk dotnet build → 0 errors
       |
       v
[MIGRATION] rtk dotnet ef migrations add BridgeProgramToSubmission
  -- SQL UP: ADD COLUMN submissions.program_assignment_id + DROP TABLE program_evidence
  -- SQL DOWN: DROP COLUMN + CREATE TABLE program_evidence (rollback)
       |
       v
[RESTART] User restarts server → db.Database.Migrate() auto-applies migration
       |
       v
[SMOKE TEST] POST /assignments/{id}/submit → 410 Gone ✅
[SMOKE TEST] POST /photos/programs/evidence/{key} → 410 Gone ✅
       |
       v
[TEST SUITE] rtk dotnet test → all pass ✅
```

---

## Execution Phase

**Complexity: Medium** — the logic changes are small (stub to 410), but the blast radius is wide (9 files touched, migration generated).

### Phase A — C# Code Changes (no migration yet)

- **Plain English Summary**: Change all C# code to remove every reference to `ProgramEvidence`. Stub the two deprecated endpoints to return `410 Gone`. Delete the two test files that test the old behavior. This makes the project compile with zero errors before the migration is even generated.
- **Why this step first?**: EF Core migration generation requires the project to compile. If we generate the migration first without fixing the references, `dotnet ef` will fail.
- **Scenario Focus**: Basic Scenario (the "make it compile" path)
- **Value Delivered**: `rtk dotnet build` exits with code 0. No production code references `ProgramEvidence` anymore.
- **Entry State Required**: `dotnet run` server is stopped. No pending migration exists.
- **Exit State Guaranteed**: `rtk dotnet build` succeeds. All references to `ProgramEvidence`, `SubmitEvidenceRequest`, `ProgramEvidenceDto` are gone. Two test files are deleted. Two handlers return 410.
- **Architectural Scope**:
  - `server/Common/Persistence/Entities/Submission.cs` — add 2 properties
  - `server/Common/Persistence/Entities/ProgramAssignment.cs` — add 1 navigation property
  - `server/Common/Persistence/AppDbContext.cs` — delete 1 DbSet line
  - `server/Common/Persistence/Configurations/SubmissionConfiguration.cs` — add FK + index config
  - `server/Common/Persistence/Entities/ProgramEvidence.cs` — DELETE
  - `server/Common/Persistence/Configurations/ProgramEvidenceConfiguration.cs` — DELETE
  - `server/Features/Programs/SubmitProgramEvidence.cs` — stub to 410
  - `server/Features/Programs/GetProgramAssignments.cs` — remove evidenceMap query, update DTO
  - `server/Features/Programs/ProgramDtos.cs` — delete 3 records, update 1 record
  - `server/Features/Photos/UploadProgramPhoto.cs` — stub to 410
  - `server/tests/.../SubmitProgramEvidence_PbacAuth_Tests.cs` — DELETE
  - `server/tests/.../ProgramPhotoIntegrationTests.cs` — DELETE
- **Acceptance Criteria**:

| ID | Criterion | Verification |
|---|---|---|
| AC-A1 | `ProgramEvidence.cs` entity file is deleted from disk | `list_dir server/Common/Persistence/Entities` shows no `ProgramEvidence.cs` |
| AC-A2 | `ProgramEvidenceConfiguration.cs` is deleted from disk | `list_dir` confirms deletion |
| AC-A3 | `AppDbContext.cs` has no `DbSet<ProgramEvidence>` line | `grep_search ProgramEvidence AppDbContext.cs` = 0 results |
| AC-A4 | `Submission.cs` has `ProgramAssignmentId` and `ProgramAssignment?` | `grep_search ProgramAssignmentId Submission.cs` = 1 result |
| AC-A5 | `SubmissionConfiguration.cs` has `HasOne(ProgramAssignment)` with `.OnDelete(DeleteBehavior.SetNull)` | `grep_search ProgramAssignment SubmissionConfiguration.cs` = match |
| AC-A6 | `SubmitProgramEvidence.cs` body only contains the 410 return | File < 20 lines |
| AC-A7 | `GetProgramAssignments.cs` has no `db.ProgramEvidence` reference | grep = 0 results |
| AC-A8 | `ProgramDtos.cs` has no `EvidenceItemRequest`, `SubmitEvidenceRequest`, `ProgramEvidenceDto` | grep = 0 results |
| AC-A9 | `UploadProgramPhoto.cs` has no `db.ProgramEvidence` reference | grep = 0 results |
| AC-A10 | `SubmitProgramEvidence_PbacAuth_Tests.cs` is deleted | `list_dir` confirms deletion |
| AC-A11 | `ProgramPhotoIntegrationTests.cs` is deleted | `list_dir` confirms deletion |
| AC-A12 | `rtk dotnet build` exits code 0 with 0 errors | Build output |

### Phase B — EF Core Migration

- **Plain English Summary**: Generate the EF Core migration that tells PostgreSQL to (1) add the `program_assignment_id` column to `submissions` and (2) drop the `program_evidence` table.
- **Why after Phase A?**: EF Core `dotnet ef migrations add` requires the project to compile first. Phase A ensures compilation.
- **Scenario Focus**: Basic Scenario (migration generated, schema updated)
- **Value Delivered**: A new `.cs` migration file exists on disk. The server can be restarted and the DB schema changes automatically.
- **Entry State Required**: Phase A complete. `rtk dotnet build` passes.
- **Exit State Guaranteed**: Migration file `20260511XXXXXX_BridgeProgramToSubmission.cs` exists. Migration SQL contains `ADD COLUMN program_assignment_id` and `DROP TABLE program_evidence`. `rtk dotnet test` passes.
- **Architectural Scope**:
  - `server/Common/Persistence/Migrations/20260511XXXXXX_BridgeProgramToSubmission.cs` — NEW (generated)
  - `server/Common/Persistence/Migrations/20260511XXXXXX_BridgeProgramToSubmission.Designer.cs` — NEW (generated)
  - `server/Common/Persistence/Migrations/AppDbContextModelSnapshot.cs` — AUTO-UPDATED (generated)
- **Acceptance Criteria**:

| ID | Criterion | Verification |
|---|---|---|
| AC-B1 | Migration file exists on disk | `list_dir server/Common/Persistence/Migrations` shows new `BridgeProgramToSubmission` file |
| AC-B2 | Migration SQL adds `program_assignment_id` nullable column | `dotnet ef migrations script` output contains `ALTER TABLE "submissions" ADD COLUMN "program_assignment_id"` |
| AC-B3 | Migration SQL drops `program_evidence` table | Script output contains `DROP TABLE IF EXISTS "program_evidence"` |
| AC-B4 | Migration SQL adds partial index on `program_assignment_id` | Script output contains `CREATE INDEX ... WHERE program_assignment_id IS NOT NULL` |
| AC-B5 | `rtk dotnet test` passes | All tests pass (deleted test files no longer contribute) |

> [!WARNING]
> **Server Restart Required**: After the migration is generated, the user MUST restart the `dotnet run` server process. The `Program.cs` already has `db.Database.Migrate()` which will auto-apply the migration on next startup. Without a restart, the new column and dropped table will NOT be in the database, and any Slice 2 work will crash with `42703 column does not exist`.

---

<command_logs>
- view_file: docs/architecture/analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md (Slice 1 scope: lines 270-323)
- view_file: server/Common/Persistence/Entities/Submission.cs (64 lines — confirmed no ProgramAssignmentId)
- view_file: server/Common/Persistence/Entities/ProgramEvidence.cs (29 lines — confirmed entity structure)
- view_file: server/Common/Persistence/AppDbContext.cs (49 lines — confirmed ProgramEvidence DbSet at line 40)
- view_file: server/Common/Persistence/Configurations/ProgramEvidenceConfiguration.cs (30 lines — confirmed Cascade FK)
- view_file: server/Common/Persistence/Configurations/ProgramAssignmentConfiguration.cs (50 lines — confirmed existing nav props)
- view_file: server/Common/Persistence/Configurations/SubmissionConfiguration.cs (81 lines — confirmed existing FKs and indexes)
- list_dir: server/Common/Persistence/Configurations (26 configuration files)
- list_dir: server/Common/Persistence/Migrations (97 files — latest: 20260510032711)
- view_file: server/Common/Persistence/GEMINI.md (33 lines — confirmed auto-migrate on restart, RTK prefix)
- view_file: server/Features/Programs/GetProgramAssignments.cs (121 lines — confirmed db.ProgramEvidence at line 73)
- view_file: server/Features/Photos/UploadProgramPhoto.cs (82 lines — confirmed db.ProgramEvidence at line 52)
- grep_search: ProgramEvidence in server/*.cs — found 7 production files + 2 test files with references
- view_file: server/tests/.../SubmitProgramEvidence_PbacAuth_Tests.cs (301 lines — confirmed POST to old endpoint)
- view_file: server/tests/.../ProgramPhotoIntegrationTests.cs (190 lines — confirmed db.ProgramEvidence seed at line 78)
- list_dir: server/tests/.../Features/Programs (3 test files)
</command_logs>

---

## Handoff Block

**Route**: This slice modifies existing infrastructure (DB schema, EF Core config). No new business logic is introduced — this is pure schema + stub work. Route to `/implement` directly.

> [!IMPORTANT]
> **Concurrency**: This slice is `[BLOCKING]`. Do NOT start Slice 2 until `rtk dotnet test` passes after Slice 1.

**Step-by-Step for Builder**:

1. Stop the running `dotnet run` server
2. Execute **Phase A** (code changes) — all 12 file operations
3. Run `rtk dotnet build` → confirm 0 errors
4. Execute **Phase B** (generate migration)
5. Run `rtk dotnet test` → confirm all pass
6. Restart the server → auto-migration applies
7. Smoke test the 410 endpoints manually

**Exact routing command:**
```
@[/implement] Execute build for Phase A + Phase B:
C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_183844_b4c8d9e2_slice1_server_db.md
```
