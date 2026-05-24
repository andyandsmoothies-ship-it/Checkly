# Infrastructure Audit Fixes

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_infra_report_20260512_175717_srv_feat.md`

## Executive Summary & Out of Scope
This plan addresses the critical findings and warnings from the recent infrastructure audit report. The goal is to plug PBAC data leakage, optimize memory allocation for area queries, and prevent potential sequence scans on program assignments.

**Out of Scope (Already Implemented):**
- **Phase 4.5 (Mutation Telemetry Gap)**: The audit report stated that mutating endpoints lacked telemetry. However, manual verification confirms that `AuditLogger.Log` (which writes to the `SystemLog` table) is already implemented across `CreateStore`, `CreateProgram`, `CreateArea`, `UpdateSubmission`, etc. This finding is considered resolved and out of scope for this slice.

## System Context
- **APIs**: Minimal API Endpoints in ASP.NET Core (`SearchUsers.cs`, `ListAreas.cs`).
- **Database**: PostgreSQL (Entity Framework Core).
- **Security**: Strict PBAC requirement to prevent unbounded data leakage.

## Lifecycle Context
- **Success**: APIs return expected data with proper pagination and security scoping.
- **Error**: `SearchUsers` returns `403 Forbidden` if a non-admin/non-AM attempts to list users.

## Test Contracts

| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-1 | SearchUsers prevents unauthorized roles | Success (200) for admin/area_manager, Error (403) for store_manager/auditor | Endpoint currently lacks a Role check on the caller |
| TC-2 | ListAreas includes manager names | Success (200) with manager names mapped | Refactored EF Core query must correctly Left Join and select the manager's name |
| TC-3 | ProgramAssignment assignee index | Success | Index is not defined in Entity Framework Configuration |

## Test Fixture & Payloads
- **TC-1**: Requires authenticated API clients with `admin`, `area_manager`, and `store_manager` roles.
- **TC-2**: Requires seeded Areas with assigned `area_manager` profiles.

## Tools & Commands
- **Skills**: `ef-core`
- **Commands**: 
  - `dotnet test`
  - `rtk dotnet ef migrations add AddProgramAssignmentAssigneeIndex --project server/Common/Common.csproj --startup-project server/Api/Api.csproj`

## Proposed Changes

### [MOD] SearchUsers.cs (server/Features/Users/SearchUsers.cs)
Add PBAC check to ensure the caller has the right role to list users.

### [MOD] ListAreas.cs (server/Features/Areas/ListAreas.cs)
Remove the unbounded in-memory array allocation (`managersByArea`) and replace it with an inline EF Core subquery or LeftJoin inside the `Select` projection of `areaQuery`.

### [MOD] ProgramAssignmentConfiguration.cs (server/Common/Persistence/Configurations/ProgramAssignmentConfiguration.cs)
Add `e.HasIndex(x => x.AssigneeId);` to optimize query performance.

## Risk Assessment
- **Risk Level**: Low. The changes are straightforward and contained to specific query filters and index additions.
- **ROI**: High. Prevents PII leakage, unbounded memory allocations, and database sequence scans.

## Verification Plan

### Automated Tests
- Run `rtk dotnet test` to verify `ProfileStoreAssignmentTests` or `ListAreas` related tests if any exist.
- Run `rtk dotnet build` to ensure the changes compile correctly without errors.

### Manual Verification
- Execute `SearchUsers.cs` without the required capabilities to ensure a `403 Forbidden` response.
- Execute `ListAreas.cs` to ensure the output remains identical but the area manager is still loaded correctly.
- Review the EF Core migration script to ensure it creates the index as intended on `program_assignments` (`assignee_id`).

## Concept Diagram
`[User Search Request]` --> `[Role Check: Admin/AM?]` --> `(Yes) [Return Data]` / `(No) [403 Forbidden]`

## Execution Slices

### Execution Phase: Implement Infra Fixes
- **Plain English Summary**: Apply the 3 minor infrastructure patches across the codebase and generate the migration for the new database index.
- **Value Delivered**: Increased API security, lower RAM usage on large payloads, and faster DB queries.
- **Entry State Required**: The current codebase.
- **Exit State Guaranteed**: Clean security roles on `/api/users`, optimized memory footprint on `/api/areas`, and the new index migration script created.
- **Scope**: Modifying 3 backend files and generating 1 EF Core migration.
- **Acceptance Criteria**: TC-1, TC-2, TC-3 pass.
- **Complexity**: Low. Changes are very localized and straightforward.
- **Pros & Cons**: 
  - *Pros*: Plugs the leak and memory bounds the query.
  - *Cons*: Slight cost to generate a new DB migration for one index.

## Handoff Block
Once approved, the user should execute the following command to begin Test-Driven Development on the backend:

```text
@[/tdd] Execute tests for Execution Phase: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260512_181600_srv_feat_infra_audit_fixes.md
```
