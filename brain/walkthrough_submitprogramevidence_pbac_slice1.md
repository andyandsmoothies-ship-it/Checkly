## Input Lineage
- Implementation plan: `C:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_150405_371654b0_submitprogramevidence_pbac.md`
- ATDD contract: `C:\Users\HP\.gemini\antigravity\brain\371654b0-a620-4bc8-bb54-83d89ab07e62\test_contracts_20260501_151614_371654b0_submitprogramevidence_pbac_atdd.md.resolved`
- Task tracker: `C:\Users\HP\Documents\GitHub\Checkly\brain\task_20260501_153310_371654b0_submitprogramevidence_pbac_implement_slice1.md`

## Decision Log
- Proposed: introduce a dedicated `programs:execute` capability instead of reusing `programs:assignments_my`.
- Implemented: added `AppCapabilities.ProgramsExecute`, swapped the submit endpoint to `.RequireCapability(AppCapabilities.ProgramsExecute)`, seeded `programs:execute` for `store_manager` in startup and test bootstrap, and exposed the capability through the admin catalog.
- Scope held: `SubmitProgramEvidence.cs` business logic was left untouched. No Flutter/UI capability constants or route guards were changed in this slice.
- Structural adjustment: `server\Program.cs` was kept at the workflow limit by merging the store-manager seed rows into one insert block and one cache reload.
- Known follow-up risk: the admin capability catalog still omits other existing Programs capabilities (`programs:create`, `programs:list`, `programs:assignments_my`, `programs:assignments_list`, `programs:review`). This slice intentionally added only `programs:execute`.

## Verification Handoff
1. Re-run backend build from `C:\Users\HP\Documents\GitHub\Checkly\server` once NuGet/networked restore is available or package assets are stable.
2. Ensure the local PostgreSQL test database `checkly_test` exists and is clean before running integration suites.
3. Run:
   - `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName=Checkly.Api.Tests.Features.Auth.AppCapabilitiesTests.AppCapabilities_Constants_HaveCorrectValues"`
   - `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~SubmitProgramEvidence|FullyQualifiedName~GetCapabilityCatalog|FullyQualifiedName~AppCapabilities"`
   - `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~Program_Slice2A"`
4. Expect the pure constant test to pass immediately. Integration failures currently point at local DB/test-runner setup, not the new PBAC strings/route guard.

<test_trace>
Command:
`dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --no-build --no-restore -v normal`

Raw terminal output:
```text
Build started 5/1/2026 3:41:13 PM.

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:00.40
```
</test_trace>

<forensic_evidence>
Commands run:
- `dotnet build --no-restore`
- `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName=Checkly.Api.Tests.Features.Auth.AppCapabilitiesTests.AppCapabilities_Constants_HaveCorrectValues"`
- `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~SubmitProgramEvidence|FullyQualifiedName~GetCapabilityCatalog|FullyQualifiedName~AppCapabilities"`
- `dotnet vstest tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll /TestCaseFilter:"FullyQualifiedName~Program_Slice2A"`
- `rg -n "fail\\(" server\tests\Checkly.Api.Tests`
- `git diff --name-only -- [touched files]`

Observed results:
- One earlier `dotnet build --no-restore` run succeeded for `Checkly.Api`.
- `AppCapabilities_Constants_HaveCorrectValues` passed against the built test assembly.
- Focused integration execution failed for infrastructure reasons:
  - `3D000: database "checkly_test" does not exist`
  - `42P07: relation "AspNetRoles" already exists`
  - `42704: index "IX_stores_area_code" does not exist`
  - `42704: index "IX_areas_code" does not exist`
- No orphaned `fail(...)` stubs were found in `server\tests\Checkly.Api.Tests`.

Slice evidence in code:
- `server\Common\Auth\AppCapabilities.cs` contains `ProgramsExecute = "programs:execute"`.
- `server\Features\Programs\ProgramEndpoints.cs` now guards submit with `RequireCapability(AppCapabilities.ProgramsExecute)`.
- `server\Program.cs` and `server\tests\Checkly.Api.Tests\TestWebApplicationFactory.cs` both seed `programs:execute` for `store_manager`.
- `server\Features\Admin\Roles\GetCapabilityCatalog.cs` now exposes `programs:execute` and metadata.
</forensic_evidence>

## Gotcha Protocol
- Existing `server\tests\GEMINI.md` already documents PBAC cache cold-start and parallel DB race conditions.
- Proposed addition: note that local integration runs also fail when `checkly_test` has not been created at all, and that `dotnet vstest` may give clearer execution evidence than `dotnet test --no-build --no-restore` in this environment when the latter only emits the MSBuild phase.

## Strict Implementation Constraints & Human Reminders
- This walkthrough covers only Slice 1 PBAC plumbing.
- Do not treat the remaining integration failures as proof that Slice 1 logic is wrong; they currently point to local test DB state and migration drift.
- Slice 2 proof tests still need a clean DB-backed run to formally certify the PBAC migration end-to-end.
