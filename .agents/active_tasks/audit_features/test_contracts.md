# Test Contracts: Infrastructure Audit Fixes

## TC-1: SearchUsers PBAC Gating
- **Test File**: `server/tests/Checkly.Api.Tests/Features/Users/SearchUsers_Authorization_Tests.cs`
- **Behavior**: Verifies that `/api/users` endpoint only allows `admin` and `area_manager` roles.
- **Fail Status**: RED (Currently fails because `store_manager` and `auditor` get 200 OK due to PBAC leak).

## TC-2: ListAreas ManagerName Regression Test
- **Test File**: `server/tests/Checkly.Api.Tests/Features/Areas/ListAreas_Tests.cs`
- **Behavior**: Ensures that `ManagerName` is correctly included when an area manager is assigned.
- **Fail Status**: GREEN (Currently passes. Written as a regression test to ensure that the upcoming DB projection refactor does not break the feature contract).

## TC-3: ProgramAssignment AssigneeId Index
- **Test File**: `server/tests/Checkly.Api.Tests/Common/Persistence/ProgramAssignmentConfiguration_Tests.cs`
- **Behavior**: Ensures the Entity Framework `AppDbContext` creates a database index on `AssigneeId` for the `ProgramAssignment` table to prevent sequence scans on fetch queries.
- **Fail Status**: RED (Currently fails because no explicit index exists on `AssigneeId`).
