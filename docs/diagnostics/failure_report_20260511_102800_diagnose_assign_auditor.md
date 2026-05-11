# Diagnostic Report: Admin Cannot Assign Task (No Auditors Found)
**Date:** 2026-05-11
**Track:** B1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\admin\task_20260511_102800_diagnose_assign_auditor.md`

## Root Cause
A hardcoded capability string mismatch exists between the frontend and the backend. 
During the UI Capabilities (PBAC) Epic, the frontend was designed to filter the auditor dropdown by requesting users with the capability `'submissions:execute'`. However, the backend database actually seeds and enforces this capability under the standard CRUD name `'submissions:create'`. Because no users possess the non-existent `'submissions:execute'` capability, the backend correctly returns an empty list, resulting in the "No results found" UI state.

## Explicit Code Trace (Premises + Proof)
1. **Frontend Request Path:** In `lib/features/admin/manager/admin_audit_manager.dart` (Line 74), the manager calls `_adminApi.searchUsersByCapability('submissions:execute')`.
2. **Frontend Test Enforcement:** The unit test `test/features/admin/manager/admin_audit_manager_pbac_test.dart` explicitly mocks and expects `'submissions:execute'` because of a stale acceptance criteria (`TC-PBAC-04`).
3. **Backend Source of Truth:** `server/Program.cs` and `server/Common/Auth/AppCapabilities.cs` strictly define and seed the capability as `public const string SubmissionsCreate = "submissions:create";`. It is mapped to the `admin`, `auditor`, and `area_manager` roles. 

Because the frontend asks the backend for an unrecognized capability string, the SQL query (`db.RoleCapabilities.Where(rc => rc.Capability == "submissions:execute")`) yields 0 users.

## Proposed Scope-Limited Fix
We need to sync the frontend with the backend's source of truth.
1. Change `'submissions:execute'` to `'submissions:create'` in `lib/features/admin/manager/admin_audit_manager.dart`.
2. Update the mocks and assertions in `test/features/admin/manager/admin_audit_manager_pbac_test.dart` to expect `'submissions:create'`.

**Trade-offs / Pros & Cons:**
- **Pros:** Immediately restores the ability to assign tasks. It aligns the UI perfectly with the backend's real database schema, adhering to standard CRUD naming conventions. Very low risk (1 line of production code change).
- **Cons:** Technically diverges from the original written Phase A `TC-PBAC-04` spec, but the spec was outdated relative to the implemented backend schema.

<forensic_evidence>
- `grep_search` for `Select Auditor` and `Assign Task` to locate `ScheduleAuditForm`.
- `view_file` on `schedule_audit_form.dart` to identify `_manager.scheduleData!.allAuditors`.
- `view_file` on `admin_audit_manager.dart` confirming `searchUsersByCapability('submissions:execute')`.
- `grep_search` on `.cs` backend files confirming `submissions:create` is the true seeded capability.
- Identified `test/features/admin/manager/admin_audit_manager_pbac_test.dart` aggressively locking down the stale `'submissions:execute'` string.
</forensic_evidence>

## Handoff Block
> **Final Diagnostic Verdict:** The frontend requests `'submissions:execute'`, but the backend expects `'submissions:create'`.
> **Required Fix & Blast Radius:** Change the hardcoded string in `admin_audit_manager.dart` and `admin_audit_manager_pbac_test.dart`. Blast radius is extremely narrow and perfectly bounded by existing tests.
> **AI Agent Mission Brief:** The frontend has a string mismatch for a PBAC capability. Change `submissions:execute` to `submissions:create` in `AdminAuditManager` and its corresponding test file to match the backend.

**Execution Queue:**
- [ ] @[/implement] docs/diagnostics/failure_report_20260511_102800_diagnose_assign_auditor.md
