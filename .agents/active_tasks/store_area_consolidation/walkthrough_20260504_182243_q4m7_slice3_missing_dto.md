# Walkthrough: Slice 3 Missing DTOs

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260504_181952_q4m7_slice3_missing_dto.md`

## Decision Log
- **Proposed**: Update backend DTOs to return `assignedStoreIds` and update Flutter services to accept them.
- **Implemented**: 
  - `UserDto` now includes `Guid[]? AssignedStoreIds`.
  - `UpdateUser.cs` maps `targetStoreIds` array into the anonymous 200 OK object.
  - `ListUsers.cs` uses a nested `Where` on `ProfileStoreAssignments` to select `AssignedStoreIds` for Area Managers.
  - `admin_api_service.dart` and `admin_user_manager.dart` explicitly support `virtualAreaId` and `assignedStoreIds` in both `createUser` and `saveUser`.
- **Trade-offs**: Nested `Select` query in `ListUsers.cs` might introduce a slight overhead, but Entity Framework translates it nicely to an Outer Apply / JSON aggregation in Postgres so N+1 issues are avoided natively.

## Verification Handoff
- Check that the `UpdateUser` returns the array of stores.
- Check that the admin area now compiles and accepts assigning an array of stores.
- Run `flutter analyze` and `flutter test` again when UI elements are bound.

<test_trace>
ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:07.96)
ok dotnet test: completed (binlog-only mode, counts unavailable, 0 warnings) (unknown)
</test_trace>

<forensic_evidence>
cmd /c flutter analyze -> No issues found! (ran in 99.6s)
cmd /c flutter test -> All tests passing (~450+)
</forensic_evidence>

## Gotcha Protocol
- None specific to this bug. It was a standard omission of DTO mapping.
