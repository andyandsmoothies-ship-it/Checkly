# Executed Tests: SubmitProgramEvidence PBAC Slice 1

## Environment Notes
- Workdir: `C:\Users\HP\Documents\GitHub\Checkly\server`
- `dotnet` required `DOTNET_CLI_HOME` redirected into the workspace because the sandbox default home path was not writable.
- `dotnet test` in this environment emitted only the MSBuild phase for `--no-build --no-restore`; `dotnet vstest` was used to get concrete test execution results.

## Commands And Results
1. `dotnet build --no-restore`
   - Result: PASS earlier in session for `Checkly.Api`
   - Output summary: `0 Warning(s)`, `0 Error(s)`

2. `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName=Checkly.Api.Tests.Features.Auth.AppCapabilitiesTests.AppCapabilities_Constants_HaveCorrectValues"`
   - Result: PASS
   - Summary: `Passed! - Failed: 0, Passed: 1, Skipped: 0, Total: 1`

3. `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~SubmitProgramEvidence|FullyQualifiedName~GetCapabilityCatalog|FullyQualifiedName~AppCapabilities"`
   - Result: FAIL
   - Summary: `Failed! - Failed: 7, Passed: 1, Skipped: 0, Total: 8`
   - Primary failure modes:
     - `3D000: database "checkly_test" does not exist`
     - `42P07: relation "AspNetRoles" already exists`

4. `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~Program_Slice2A"`
   - Result: FAIL
   - Summary: `Failed! - Failed: 3, Passed: 4, Skipped: 0, Total: 7`
   - Primary failure modes:
     - `42704: index "IX_stores_area_code" does not exist`
     - `42704: index "IX_areas_code" does not exist`
     - `42P07: relation "AspNetRoles" already exists`

5. `dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --no-build --no-restore -v normal`
   - Result: INCONCLUSIVE
   - Output only showed the MSBuild phase:
```text
Build started 5/1/2026 3:41:13 PM.

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.40
```

<test_trace>
Global test command:
`dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --no-build --no-restore -v normal`

Raw output:
```text
Build started 5/1/2026 3:41:13 PM.

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.40
```
</test_trace>

## Orphaned Stub Check
- `rg -n "fail\\(" server\tests\Checkly.Api.Tests`
- Result: no matches

## Scope Check
- Modified backend files:
  - `C:\Users\HP\Documents\GitHub\Checkly\server\Common\Auth\AppCapabilities.cs`
  - `C:\Users\HP\Documents\GitHub\Checkly\server\Features\Programs\ProgramEndpoints.cs`
  - `C:\Users\HP\Documents\GitHub\Checkly\server\Program.cs`
  - `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\TestWebApplicationFactory.cs`
  - `C:\Users\HP\Documents\GitHub\Checkly\server\Features\Admin\Roles\GetCapabilityCatalog.cs`
  - `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Auth\AppCapabilitiesTests.cs`
  - `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Admin\Roles\GetCapabilityCatalog_Count_Tests.cs`

<forensic_evidence>
Executed commands:
- `dotnet build --no-restore`
- `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName=Checkly.Api.Tests.Features.Auth.AppCapabilitiesTests.AppCapabilities_Constants_HaveCorrectValues"`
- `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~SubmitProgramEvidence|FullyQualifiedName~GetCapabilityCatalog|FullyQualifiedName~AppCapabilities"`
- `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~Program_Slice2A"`
- `rg -n "fail\\(" server\tests\Checkly.Api.Tests`
- `git diff --name-only -- [touched files]`

Observed evidence:
- AppCapabilities constant test passed on the compiled test assembly.
- Focused integration execution failed due local PostgreSQL/test-migration state, not an assertion mismatch in the new capability string.
- No orphaned `fail(...)` stubs remain in `server\tests\Checkly.Api.Tests`.
</forensic_evidence>
