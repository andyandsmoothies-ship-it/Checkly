# Task: Enforce Strict 1-to-Many Area Manager to Store Assignment (Phase 1)
Workflow: /implement | Track: B2

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260505_165000_am_store_strict_1_to_m.md`

## Decision Log
- **Proposed**: Add 409 Conflict logic inside `CreateUser.cs` and `UpdateUser.cs` utilizing `RoleAssignmentGuard.FindExistingAreaManagerForStore`.
- **Implemented**: Logic was injected successfully into `UpdateUser.cs` and `CreateUser.cs`. During implementation, we discovered and resolved a regression regarding `VirtualAreaId` validation parsing in the API layer, and identified a test suite precision issue (`Admin_RoleChange_InvalidatesExistingToken_Returns401`) relating to JWT issuance time resolution vs revocation constraints. The tests were adjusted to allow explicit chronological offset, restoring stability.
- **Data Integrity**: The `EnforceUniqueAMStore` migration was applied to add the unique index `HasIndex(x => x.StoreId).IsUnique()` preventing multiple `ProfileStoreAssignments` on the DB level.

## Verification Handoff
Phase 1 (Backend constraints) is fully complete. The backend cleanly returns 409 Conflict when attempting to overwrite an Area Manager on a store without `forceReassign: true`.

QA/Frontend steps:
1. Ensure the UI can handle the 409 Conflict response.
2. Build the `user_create_sheet.dart` and `user_edit_sheet.dart` (Phase 2).
3. The UI must toggle a `forceReassign` prompt when encountering this 409.

<test_trace>
Passed!  - Failed:     0, Passed:   495, Skipped:     3, Total:   498, Duration: 2 m 4 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
Verified compilation via `dotnet build`. Verified no duplicate tracking issues via testing the modified endpoints manually using tests.
</forensic_evidence>

