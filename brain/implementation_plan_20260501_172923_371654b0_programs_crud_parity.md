<latent_space_scratchpad>
Key decisions to make:
1. Archive = soft-delete (Status → 'cancelled'). Hard delete is dangerous because ProgramAssignments have FK to ChecklyProgram. The entity uses Restrict on delete (per audit report Phase 2 scan).
2. Update = mutable fields only: Title, Deadline, Category. TemplateId and StoreIds are immutable after creation — changing them would corrupt existing assignments.
3. A program with 'cancelled' status should block new SubmitEvidence calls (the SM endpoint should guard against this). BUT the audit says to not scope-creep. We will add a note only.
4. RowVersion (xmin) is already on ChecklyProgram — use it for optimistic concurrency on Update to prevent lost-updates.
5. New capability: programs:manage (covers both update + archive) — one capability, admin only. This is simpler than two separate capabilities for now.
6. ProgramEndpoints.cs is only 63 lines — no split needed.
7. Need 2 new handler files: UpdateProgram.cs, ArchiveProgram.cs — each under 100 lines.
8. Need 2 new DTOs: UpdateProgramRequest — in ProgramDtos.cs (currently 112 lines, safe to add to without splitting).
9. ATDD route is correct: this touches DB + Auth + existing business rules.
</latent_space_scratchpad>

# Implementation Plan: Programs CRUD Parity (Update + Archive)
Workflow: /analyze-feature | Track: B2

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\371654b0-a620-4bc8-bb54-83d89ab07e62\audit_infra_report_20260501_122611_371654b0-a620-4bc8-bb54-83d89ab07e62_programs_backend.md.resolved`

## Executive Summary & Out of Scope
Add two missing endpoints to the Programs module:
- `PUT /api/programs/{id}` — update mutable fields (`Title`, `Deadline`, `Category`) for an existing `active` program.
- `DELETE /api/programs/{id}` — soft-archive a program by setting `Status = 'cancelled'`.

Both are admin-only, gated by a new `programs:manage` PBAC capability.

**Out of scope:**
- No Flutter/mobile UI changes (backend-only fix).
- No hard-delete logic (FK constraint `Restrict` makes it dangerous).
- No cascade-status-update to child `ProgramAssignment` rows on archive (out of scope for this slice).
- No guard on `SubmitProgramEvidence` to block submissions against a `cancelled` program (separate slice).

## Logs & Audits
- `UpdateProgram`: Log `program_updated` via `AuditLogger.Log(...)` with before/after field deltas.
- `ArchiveProgram`: Log `program_archived` via `AuditLogger.Log(...)`.

## 4-State Matrix

| State | UpdateProgram | ArchiveProgram |
|---|---|---|
| **Success** | `200 OK` — returns updated `ProgramSummaryDto` | `204 No Content` |
| **Error** | `409 Conflict` if `RowVersion` mismatch | `404 Not Found` if program doesn't exist |
| **Empty** | `404 Not Found` if `programId` doesn't exist | `400 Bad Request` if already `cancelled` |
| **Loading** | EF Core optimistic lock via `xmin` prevents race | N/A — idempotent guard |

## Test Contracts

| ID | Scenario | Expected Status | Why it fails first |
|---|---|---|---|
| TC-U1 | Admin updates `Title` and `Deadline` on an active program | `200 OK`, body has new `title` | Handler not built yet |
| TC-U2 | Store manager calls `PUT /api/programs/{id}` | `403 Forbidden` | Capability not seeded for `store_manager` |
| TC-U3 | Admin updates a program that doesn't exist | `404 Not Found` | Handler not built yet |
| TC-U4 | Admin updates with a past `Deadline` | `400 Bad Request` | Validation guard not built yet |
| TC-A1 | Admin archives an active program | `204 No Content`, status becomes `cancelled` | Handler not built yet |
| TC-A2 | Store manager calls `DELETE /api/programs/{id}` | `403 Forbidden` | Capability not seeded for `store_manager` |
| TC-A3 | Admin archives a non-existent program | `404 Not Found` | Handler not built yet |
| TC-A4 | Admin archives an already-cancelled program | `400 Bad Request` | Idempotency guard not built yet |

## Test Fixture & Payloads

**Required**: Admin client (bootstrap admin). An existing active program with at least 1 store assignment.

**PUT Request Body** (`/api/programs/{id}`):
```json
{
  "title": "Updated Program Title",
  "deadline": "2027-01-01T00:00:00Z",
  "category": "Compliance v2"
}
```

**PUT Response** (`200 OK`):
```json
{
  "id": "...",
  "title": "Updated Program Title",
  "category": "Compliance v2",
  "deadline": "2027-01-01T00:00:00Z",
  "status": "active"
}
```

**DELETE Response**: `204 No Content` (no body)

## Tools & Commands
- **Skills**: `dotnet-scaffolding`, `ef-core`, `dotnet-rbac-authorization`
- **Testing**: `rtk dotnet test server/tests --filter Program_Slice6`

## Proposed Changes
- `[MOD]` `server/Common/Auth/AppCapabilities.cs` — add `public const string ProgramsManage = "programs:manage";`
- `[NEW]` `server/Features/Programs/UpdateProgram.cs` — `PUT /api/programs/{id}` handler
- `[NEW]` `server/Features/Programs/ArchiveProgram.cs` — `DELETE /api/programs/{id}` handler
- `[MOD]` `server/Features/Programs/ProgramDtos.cs` — add `UpdateProgramRequest` record
- `[MOD]` `server/Features/Programs/ProgramEndpoints.cs` — register `PUT` and `DELETE` routes
- `[MOD]` `server/Program.cs` — seed `programs:manage` for `admin` role
- `[MOD]` `server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs` — seed `programs:manage` for `admin`
- `[NEW]` `server/tests/Checkly.Api.Tests/Program_Slice6_Tests.cs` — ATDD acceptance tests

## Concept Diagram
```
[Admin]
  --> PUT /api/programs/{id}
      --> [UpdateProgram Handler]
          --> Guard: program exists? (404)
          --> Guard: deadline in future? (400)
          --> Update Title, Deadline, Category + UpdatedAt
          --> AuditLogger.Log("program_updated")
          --> 200 OK

  --> DELETE /api/programs/{id}
      --> [ArchiveProgram Handler]
          --> Guard: program exists? (404)
          --> Guard: not already cancelled? (400)
          --> Set Status = "cancelled" + UpdatedAt
          --> AuditLogger.Log("program_archived")
          --> 204 No Content

[store_manager] --> PUT or DELETE --> 403 Forbidden (no programs:manage capability)
```

## Execution Slices

### Slice A: Backend — Handlers, Routes, Capabilities (ATDD First)
1. Add `ProgramsManage` constant to `AppCapabilities.cs`.
2. Add `UpdateProgramRequest` DTO to `ProgramDtos.cs`.
3. Create `UpdateProgram.cs` handler.
4. Create `ArchiveProgram.cs` handler.
5. Register both routes in `ProgramEndpoints.cs` with `.RequireCapability(AppCapabilities.ProgramsManage)`.
6. Seed `programs:manage` for admin in `Program.cs` and `TestWebApplicationFactory.cs`.

- **Complexity**: Low — follows identical patterns used in `CreateProgram.cs`, `VerifyProgramAssignment.cs`.
- **Pros**: Closes the audit gap with minimal surface area. No DB migration needed (soft-delete uses existing `Status` column).
- **Cons**: None significant.

### Slice B: Tests — ATDD Integration Test File
Write `Program_Slice6_Tests.cs` covering all 8 test contracts above.

- **Complexity**: Low — same factory pattern as `Program_Slice1_Tests.cs`.

> **Order**: Run Slice A first (ATDD — tests go RED). Then Slice B builds the handlers (tests go GREEN).

## Risk Assessment
- **Severity**: Low
- **Optimistic concurrency risk**: The `RowVersion` (xmin) column on `ChecklyProgram` is already configured. The `UpdateProgram` handler must use EF Core's `DbUpdateConcurrencyException` catch to return a clean `409 Conflict` instead of a 500.
- **Archive while active assignments exist**: Allowed by design — assignments can remain in-flight. The guard only prevents double-archive.

## Verification Plan
- Run `rtk dotnet test server/tests --filter Program_Slice6` — all 8 TCs must pass GREEN.
- Run full suite `rtk dotnet test server/tests` — zero regressions (459 existing tests must still pass).

<command_logs>
- grep_search: "GetProgramSummary" -> Found server/Features/Programs/GetProgramSummary.cs
- list_dir: server/Features/Programs -> 10 files confirmed
- view_file: ProgramEndpoints.cs (63 lines)
- view_file: CreateProgram.cs (83 lines, pattern confirmed)
- view_file: ProgramDtos.cs (112 lines)
- grep_search: "ChecklyProgram" -> Found entity at server/Common/Persistence/Entities/Program.cs
- view_file: Program.cs (entity, 30 lines — fields confirmed)
- grep_search: "ProgramsCreate" -> AppCapabilities.cs line 40
- view_file: AppCapabilities.cs (52 lines, no programs:manage exists)
- grep_search: "programs:create" in Program.cs -> confirmed seed block lines 336-378
- view_file: Program.cs seed block lines 330-380
- view_file: TestWebApplicationFactory.cs (195 lines, seed at lines 111-121)
- view_file: Program_Slice1_Tests.cs (235 lines, test pattern confirmed)
</command_logs>

## Handoff Block
Two slices. Run in order — Slice B must wait for Slice A.

**Step 1 (ATDD — write tests first, they go RED):**
```
@[/atdd] Execute specs for Slice A: c:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_172923_371654b0_programs_crud_parity.md
```

**Step 2 (Build — implement handlers until tests go GREEN):**
```
@[/implement] Execute build for Slice B: c:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_172923_371654b0_programs_crud_parity.md
```
