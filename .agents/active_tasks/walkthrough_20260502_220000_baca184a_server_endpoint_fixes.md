# Walkthrough: Server Endpoint Security & Quality Fixes

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_infra_report_20260502_215050_70e13ccc_server_endpoints.md`

## Decision Log

| Finding | Proposed | Implemented | Notes |
|---------|----------|-------------|-------|
| IS-2 (Debug File Write) | Delete `File.AppendAllText` line | Deleted + replaced with `Log.Warning(...)` via Serilog | Added `using Serilog;` directive |
| IS-3 (Unbounded Query) | Add `.Take(500)` | Applied | Single-line addition |
| IS-4 (Missing Capabilities) | Add `RequireCapability` on 3 routes | Applied, but used `SubmissionsList` (not `SubmissionsRead` — that constant does not exist) | `VoidSubmission` uses `.RequireAuthorization("AdminOnly")` per existing named policy |
| IS-5 (Double SaveChanges) | Stage audit log before single save | Applied — audit log now staged before the single `SaveChangesAsync` | Eliminates silent audit log loss window |
| IS-6 (Duplicated Validator) | Extract `ImageValidation.cs` | Applied — `server/Common/ImageValidation.cs` created; both `UploadPhoto.cs` and `UploadProgramPhoto.cs` updated | Zero behavior change |
| IS-7 (No IsActive Check) | Add `!assignment.IsActive` | **SKIPPED — entity has no `IsActive` field** | `ProgramAssignment` entity has no such column. Requires schema migration. Needs product decision. |
| IS-8 (Two DB Round-trips) | Replace with `AnyAsync` | Applied | Stores query reduced from 2 queries to 1 |

## Verification Handoff

Manual QA steps:
1. **IS-2**: Call `PUT /api/submissions/{id}/finalize` with a score mismatch. Confirm no file is written to `.agents/tmp/`. Check Serilog output for `FinalizeSubmission 400: Score mismatch` warning.
2. **IS-4**: Call `GET /api/submissions/{id}` with a token that has no `submissions:list` capability. Expect **403 Forbidden** (previously would have reached handler body).
3. **IS-4**: Call `POST /api/submissions/{id}/void` with a non-admin token. Expect **403 Forbidden**.
4. **IS-5**: Review a submission. Verify a single `system_logs` audit entry is created — and that it is created even when a push notification fails.
5. **IS-6**: Upload a non-image file to both `POST /api/photos/{submissionId}` and `POST /api/photos/programs/evidence/{key}`. Expect **415 Unsupported Media Type** from both.
6. **IS-8**: No behavioral change — area_manager access to stores should still work identically.

## IS-7 Escalation
The audit suggested `if (assignment is null || !assignment.IsActive)` in `GetProgramPhoto.cs`. However, `ProgramAssignment` entity has no `IsActive` column. Options:
- **Option A**: Add `IsActive bool` column to `ProgramAssignment` entity + migration. 
- **Option B**: Gate on `Status == "verified"` (only verified assignments are active).
- **Option C**: Leave as-is (current behavior: any assignment, regardless of status, serves the photo).

Recommend discussing with the team before implementing.

<test_trace>
cmd /c "rtk dotnet build --no-restore -v q"

[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:05.95)
</test_trace>

<forensic_evidence>
- Build 1 (after IS-2 + IS-3): 0 errors, 0 warnings ✅
- Build 2 (final, all fixes): 0 errors, 0 warnings ✅
- IS-7 reverted — entity has no IsActive field (compile error: CS1061)
- IS-4 VoidSubmission: RequireRole() is not available on RouteHandlerBuilder; used RequireAuthorization("AdminOnly") per existing named policy in Program.cs
</forensic_evidence>

## Gotcha Protocol

Proposed additions to `server/GEMINI.md`:

> **Gotcha: RequireRole() does not exist on RouteHandlerBuilder in Minimal APIs**
> - **Fix**: Use `.RequireAuthorization("PolicyName")` with a named policy registered in `Program.cs`. The named policies (AdminOnly, AuditorAccess, StoreManagerAccess, AreaManagerAccess) already exist.
