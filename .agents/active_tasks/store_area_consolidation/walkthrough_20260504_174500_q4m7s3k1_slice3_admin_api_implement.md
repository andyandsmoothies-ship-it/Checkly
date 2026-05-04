## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_173100_q4m7s3k1_slice3_admin_api.md`
- `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260504_173403_q4m7_slice3_admin_api.md`

## Decision Log
- Proposed: Add `virtualAreaId` and `assignedStoreIds` support in admin update path, remove S10 conflict behavior, and add CreateUser parity.
- Implemented:
  1. `UpdateUser.Request` now accepts `virtualAreaId` and `assignedStoreIds`.
  2. Removed S10 conflict enforcement block from `UpdateUser`.
  3. Added direct assignment write logic for area managers:
     - virtual area resolves to all active store IDs in that area,
     - explicit `assignedStoreIds` unions with virtual-area results,
     - invalid explicit store IDs return 400 with `"One or more assigned stores do not exist"`,
     - resulting set is synchronized to `ProfileStoreAssignments` (remove extras + add missing),
     - explicit empty `assignedStoreIds` with no virtual area clears assignments.
  4. Kept `Profile.AreaId` assignment behavior for legacy compatibility (`areaId` or `virtualAreaId` path).
  5. Removed S10 conflict enforcement from `CreateUser` so AM creation no longer blocks on occupied area.

## Verification Handoff
1. Re-run targeted slice tests:
   - `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~UpdateUserVirtualAreaTests|FullyQualifiedName~CreateUserVirtualAreaTests"`
2. Re-run full regression:
   - `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj`
3. Confirm API behavior manually (optional):
   - Update an auditor to area manager with `virtualAreaId`.
   - Verify rows in `profile_store_assignments`.

<test_trace>
[RED]
Failed!  - Failed:     7, Passed:     1, Skipped:     0, Total:     8
- CreateUser TC_3_7 failed with 409 Area already has an area manager assigned
- UpdateUser TC_3_1/2/4/8 failed assignment count assertions
- UpdateUser TC_3_3 failed with 409 legacy S10 conflict
- UpdateUser TC_3_5 failed expected 400 (got 200)

[GREEN - targeted]
ok dotnet test: 8 tests passed, 1 warnings in 1 projects (9.4 s)

[CHEAP VERIFY]
ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:01.93)

[GLOBAL]
ok dotnet test: 484 tests passed, 0 warnings in 1 projects (119.4 s)
</test_trace>

<forensic_evidence>
- Commands executed:
  - `rtk dotnet test ... --filter "FullyQualifiedName~UpdateUserVirtualAreaTests|FullyQualifiedName~CreateUserVirtualAreaTests"` (RED then GREEN)
  - `rtk dotnet build c:\Users\HP\Documents\GitHub\Checkly\server\Checkly.Api.csproj --no-restore`
  - `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj` (global)
  - `rg "fail\('Implement|TODO|throw new NotImplementedException"` under `server/tests/Checkly.Api.Tests/Features/Admin` (no matches)
- Modified files:
  - `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Admin\UpdateUser.cs`
  - `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Admin\CreateUser.cs`
</forensic_evidence>

## Gotcha Protocol
- Proposed `server/GEMINI.md` addition:
  - "For area_manager assignment mutations, `ProfileStoreAssignments` is the source of truth. `Profile.AreaId` is legacy compatibility only; never enforce uniqueness (S10) via `AreaId`."
