# Executed Tests — Slice 3 Admin API

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_173100_q4m7s3k1_slice3_admin_api.md`
- `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260504_173403_q4m7_slice3_admin_api.md`

## Commands
1. `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~UpdateUserVirtualAreaTests|FullyQualifiedName~CreateUserVirtualAreaTests"` (RED)
2. `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~UpdateUserVirtualAreaTests|FullyQualifiedName~CreateUserVirtualAreaTests"` (GREEN)
3. `rtk dotnet build c:\Users\HP\Documents\GitHub\Checkly\server\Checkly.Api.csproj --no-restore`
4. `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj` (global)

## Results Summary
- RED: 7 failed, 1 passed (expected at start of implementation).
- GREEN (slice tests): 8 passed, 0 failed.
- Cheap verify build: 0 errors, 0 warnings.
- Global regression run: 484 passed, 0 failed.

<test_trace>
[RED]
Failed!  - Failed:     7, Passed:     1, Skipped:     0, Total:     8
- TC_3_1...CreatesAssignmentsForAllActiveStoresInArea: Expected 2, Actual 0
- TC_3_2...UpsertsDirectAssignments...: Expected 2, Actual 1
- TC_3_3...OccupiedLegacyArea_DoesNotReturn409: got 409 Conflict
- TC_3_4...MixedPayloadUnion...: Expected 2, Actual 0
- TC_3_5...InvalidAssignedStoreIds_Returns400: Expected 400, Actual 200
- TC_3_7...CreateUser...NoLongerFailsS10...: got 409 Conflict
- TC_3_8...ClearsAllAssignments: Expected 0, Actual 1

[GREEN - targeted]
ok dotnet test: 8 tests passed, 1 warnings in 1 projects (9.4 s)

[BUILD]
ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:01.93)

[GLOBAL]
ok dotnet test: 484 tests passed, 0 warnings in 1 projects (119.4 s)
</test_trace>

<forensic_evidence>
- Read failing ATDD test files: `UpdateUserVirtualAreaTests.cs`, `CreateUserVirtualAreaTests.cs`.
- Modified only Slice-3-relevant production files:
  - `server/Features/Admin/UpdateUser.cs`
  - `server/Features/Admin/CreateUser.cs`
- Re-ran same ATDD tests to GREEN.
- Ran global regression suite to prove no cross-slice breakage.
- Checked lint diagnostics on modified files: no linter errors.
- Verified no orphaned placeholder stubs in active admin test folder.
</forensic_evidence>
