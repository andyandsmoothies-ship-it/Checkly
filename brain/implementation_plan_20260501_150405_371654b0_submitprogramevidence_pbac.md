<latent_space_scratchpad>
- The defect is architectural, not behavioral-only: the endpoint already returns the right 403 for admin, but for the wrong reason. A plan that only preserves existing role outcomes would miss the actual PBAC migration.
- Reusing `programs:assignments_my` would be the smaller diff, but it conflates read and mutation permissions. The codebase already separates action permissions (`action_plans:write`, `action_plans:verify`, `submissions:create`, `submissions:list`), so a dedicated `programs:execute` capability is the cleaner fit.
- The admin capability catalog is already incomplete for existing Programs capabilities (`programs:create`, `programs:list`, `programs:assignments_my`, `programs:assignments_list`, `programs:review`). That broader parity gap is real, but expanding this task to fix all Programs catalog omissions would be feature drift. Keep the scope to `programs:execute` only and document the broader gap as follow-up risk.
- `Program.cs` is a large shared startup file. Do not use this issue as an excuse to refactor startup seeding wholesale. Follow the existing seed-and-reload-cache pattern exactly.
</latent_space_scratchpad>

## Input Lineage
- `C:\Users\HP\.gemini\antigravity\brain\371654b0-a620-4bc8-bb54-83d89ab07e62\audit_infra_report_20260501_122611_371654b0-a620-4bc8-bb54-83d89ab07e62_programs_backend.md.resolved`

## Executive Summary & Out of Scope
Track: B2.

Goal: replace the hardcoded route guard on `POST /api/programs/assignments/{id}/submit` with the repo’s PBAC capability system so execution permission can be reassigned without recompiling the backend.

Recommended shape:
- Add `AppCapabilities.ProgramsExecute = "programs:execute"`.
- Guard `SubmitProgramEvidence` with `.RequireCapability(AppCapabilities.ProgramsExecute)` instead of `.RequireRole("store_manager")`.
- Seed `programs:execute` for `store_manager` in `Program.cs` and `TestWebApplicationFactory.cs`.
- Add `programs:execute` to the admin capability catalog so role-management UI can assign it.
- Prove PBAC behavior with tests that fail under role-based auth but pass under capability-based auth.

Why this shape wins:
- It matches the project’s permission model instead of leaving a role string special-case in Programs.
- It enables a future role such as `assistant_manager` to submit evidence if granted the capability.
- It preserves the existing IDOR/store-scoping checks inside `SubmitProgramEvidence` and changes only authorization shape.

Out of scope:
- No rewrite of handler business logic in `SubmitProgramEvidence.cs`.
- No Flutter route guards or widget gating for Programs execution in this slice.
- No broad cleanup of all missing Programs capabilities from the admin catalog.
- No replacement of the startup seed pattern with migrations or a new seed service.
- No changes to PBAC listener infrastructure, `CapabilityAuthorizationHandler`, or JWT structure.

> [!NOTE]
> **Blast Radius Warning**
> This issue modifies Auth and shared startup seeding. Files in `server/Common/Auth/`, `server/Program.cs`, and `server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs` are in scope. The plan stays narrow, but the Builder must verify PBAC behavior carefully before merge.

## Logs & Audits
- No new `AuditLogger` event is required. Successful submissions should continue logging `program_submitted`.
- Failed authorization remains a route-level `403` and should not create business audit rows.
- PBAC cache reload behavior remains the existing startup/test pattern: insert capability row, then `InitializeAsync(...)`.

## 4-State Matrix
| State | System Condition | Expected Behavior |
|---|---|---|
| Success | Caller holds `programs:execute` and is linked to the assignment’s store | Route allows request, handler runs, submission returns `200 OK` with existing payload. |
| Error | Caller lacks `programs:execute` | Route denies with `403 Forbidden` before handler mutation logic executes. |
| Empty | Caller has capability but no linked store or assignment is outside their store | Existing handler behavior remains: `404 NotFound` for missing store assignment scope. |
| Loading | Mobile sync or UI submit request is in flight | No contract change; only authorization decision source changes from role string to capability. |

## Risk Assessment
| Risk | Severity | Mitigation |
|---|---|---|
| False confidence if tests only prove `store_manager` still works | High | Add a capability-based success case for a non-allowlisted role token with `programs:execute`; this is the key red test against the old role guard. |
| Fail-closed PBAC in tests if factory seed is not updated | High | Update `TestWebApplicationFactory.cs` in the same slice and verify with focused integration tests. |
| Admin catalog drift if `programs:execute` is seeded but not exposed in `GetCapabilityCatalog` | Medium | Add catalog assertion in test coverage and update metadata + count. |
| Startup regression from editing `Program.cs` | Medium | Follow the existing insert + `pbacCache.InitializeAsync(app.Services)` sequence exactly; do not refactor surrounding startup code. |

## Verification Plan
1. Write the PBAC authorization tests first and confirm at least one RED case against the current role-based guard.
2. Implement the capability constant, route guard, startup/test seeds, and catalog entry.
3. Run focused backend tests:
   - Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
   - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~SubmitProgramEvidence"`
4. Run focused PBAC/catalog regressions:
   - Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
   - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~GetCapabilityCatalog|FullyQualifiedName~AppCapabilities"`
5. Run the existing Slice 2A regression file to ensure the admin forbidden path and SM success path still hold:
   - Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
   - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~Program_Slice2A"`

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| BE-PBAC-EXEC-01 | `SubmitProgramEvidence_WhenNonStoreManagerRoleHasProgramsExecute_AndOwnStoreAssignment_ReturnsOk` | Success | Current route guard is `RequireRole("store_manager")`, so any non-store_manager token is rejected even if the capability row exists. |
| BE-PBAC-EXEC-02 | `SubmitProgramEvidence_WhenStoreManagerRoleLacksProgramsExecute_ReturnsForbidden` | Error | Current role-based guard ignores the capability table, so a `store_manager` token still reaches the handler. |
| BE-PBAC-EXEC-03 | `GetCapabilityCatalog_IncludesProgramsExecute_WithMetadata` | Success | `GetCapabilityCatalog.cs` currently has no `programs:execute` entry or metadata. |
| BE-PBAC-EXEC-04 | `AppCapabilities_Constants_HaveProgramsExecute` | Success | `AppCapabilities.cs` currently has no `ProgramsExecute` constant. |
| BE-PBAC-EXEC-05 | `SubmitProgramEvidence_WhenAdminStillLacksProgramsExecute_ReturnsForbidden` | Error | Regression guard to preserve current admin-denied behavior after moving off hardcoded roles. |

## Test Fixture & Payloads
Fixture requirements:
- `TestWebApplicationFactory` with PBAC cache initialized after capability inserts.
- One seeded store and one `ProgramAssignment` linked to that store.
- One real user/profile row linked to that store.
- For the non-store-manager PBAC test, forge a JWT with the same user id but a custom role string using `TokenService.GenerateToken(...)`, per `server/tests/GEMINI.md`.
- Insert `programs:execute` for the forged role in `role_capabilities`.

Request example:
```http
POST /api/programs/assignments/{assignmentId}/submit
Authorization: Bearer <jwt>
Content-Type: application/json
```

Payload example:
```json
{
  "evidenceItems": [
    {
      "criteriaId": "6af8dcd0-a516-4d76-88b6-d30917a0625e",
      "value": "Done",
      "photoLocalKey": "photo1.jpg"
    }
  ]
}
```

Expected success response:
```json
{
  "newStatus": "submitted"
}
```

Expected forbidden response:
```http
403 Forbidden
```

## Tools & Commands
Builder skills:
- `dotnet-rbac-authorization`
- `testing-strategy`

Focused commands:
- Workdir `C:\Users\HP\Documents\GitHub\Checkly\server`
  - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~SubmitProgramEvidence"`
  - `rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~GetCapabilityCatalog|FullyQualifiedName~AppCapabilities"`

## Proposed Changes
| Status | File Path | Change |
|---|---|---|
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\Common\Auth\AppCapabilities.cs` | Add `ProgramsExecute = "programs:execute"` as the canonical capability constant for program evidence submission. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\Features\Programs\ProgramEndpoints.cs` | Replace the hardcoded `RequireRole("store_manager")` guard with `.RequireCapability(AppCapabilities.ProgramsExecute)`. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\Program.cs` | Seed `programs:execute` for `store_manager` using the existing insert-and-reload-cache startup pattern. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\TestWebApplicationFactory.cs` | Re-seed `programs:execute` for `store_manager` in the test bootstrap PBAC rows so fail-closed tests behave like dev startup. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\Features\Admin\Roles\GetCapabilityCatalog.cs` | Add `programs:execute` to the static catalog and metadata so the admin role-management UI can assign it. |
| `[NEW]` | `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Programs\SubmitProgramEvidence_PbacAuth_Tests.cs` | New focused integration tests for capability-based auth, including forged-role success and missing-capability denial. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Auth\AppCapabilitiesTests.cs` | Extend constant assertions to include `ProgramsExecute`. |
| `[MOD]` | `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Admin\Roles\GetCapabilityCatalog_Count_Tests.cs` | Update expected count and assert `programs:execute` presence. |

## Concept Diagram
```text
[JWT Role Claim + PBAC Cache]
  -> [ProgramEndpoints.MapPost("/assignments/{id}/submit")]
  -> [RequireCapability(programs:execute)]
  -> [SubmitProgramEvidence.HandleAsync]
  -> [Profile.StoreId scope check]
  -> [Persist evidence + log program_submitted]
```

## Execution Slices
### Slice 1 - PBAC Plumbing for Program Execution [BLOCKING]
Complexity: Medium. Reason: auth route guard + startup seeding + admin capability catalog all move together.

Structural blueprint:
- Add `ProgramsExecute` constant in `AppCapabilities.cs`.
- Change `SubmitProgramEvidence` route guard in `ProgramEndpoints.cs` to `RequireCapability(AppCapabilities.ProgramsExecute)`.
- Seed `programs:execute` for `store_manager` in `Program.cs`.
- Mirror that seed in `TestWebApplicationFactory.cs`.
- Add `programs:execute` to `GetCapabilityCatalog.Catalog` and `CapabilityMetadata`.

Pros & Cons:
- Pros: aligns Programs with the repo’s PBAC system; enables dynamic reassignment of execution permission; keeps business handler unchanged.
- Cons: touches shared auth/startup files; requires catalog count/test updates.
- Rejected alternative: reuse `ProgramsAssignmentsMy`.
  Why rejected: it couples read and mutation permission into one capability and breaks the project’s existing read/write separation pattern.

### Slice 2 - Proof That PBAC Replaced Roles [BLOCKING]
Complexity: Medium. Reason: requires integration tests that specifically distinguish role-based from capability-based behavior.

Structural blueprint:
- Add a dedicated test file for `SubmitProgramEvidence` PBAC auth.
- Use one failing test where a non-`store_manager` token with `programs:execute` must succeed.
- Use one failing test where a `store_manager` token without `programs:execute` must be forbidden.
- Update catalog and constant tests for the new capability.
- Keep existing admin-forbidden and SM-success behavior as regressions.

Pros & Cons:
- Pros: proves the real architectural change instead of only preserving old outcomes.
- Cons: test setup is slightly more complex because forged tokens are needed to bypass the registration allowlist.

## Strict Implementation Constraints & Human Reminders
- Do not widen this issue into a full Programs capability catalog cleanup. Add only `programs:execute`.
- Keep `SubmitProgramEvidence.cs` handler logic unchanged unless a test proves the route-level PBAC migration affects behavior.
- Follow the existing `Program.cs` seed pattern exactly: `INSERT ... ON CONFLICT DO NOTHING`, then `await pbacCache.InitializeAsync(app.Services)`.
- Use a new dedicated PBAC test file; do not append more auth scenarios to the 293-line `Program_Slice2A_Tests.cs`.
- The forged-role test must still use a real `Profile.StoreId` mapped by user id. Do not fake away the IDOR/store-scoping path.

<command_logs>
- `Get-Date -Format "yyyyMMdd_HHmmss"`
- `Get-Content -Raw .agents/skills/dotnet-rbac-authorization/SKILL.md`
- `Get-Content -Raw server\Features\Programs\ProgramEndpoints.cs`
- `Get-Content -Raw server\Features\Programs\SubmitProgramEvidence.cs`
- `Get-Content -Raw server\Common\Auth\AppCapabilities.cs`
- `Get-Content server\Program.cs`
- `Get-Content server\tests\Checkly.Api.Tests\TestWebApplicationFactory.cs`
- `Get-Content server\tests\Checkly.Api.Tests\Program_Slice2A_Tests.cs`
- `Get-Content server\Features\ActionPlans\UpdateActionPlan.cs`
- `Get-Content server\Features\Admin\Roles\GetCapabilityCatalog.cs`
- `Get-Content lib\_shared\constants\app_capabilities.dart`
- `Get-Content lib\_shared\router\app_router.dart`
- `Get-Content server\tests\Checkly.Api.Tests\Features\Auth\AppCapabilitiesTests.cs`
- `Get-Content server\tests\Checkly.Api.Tests\Features\Admin\Roles\GetCapabilityCatalog_Count_Tests.cs`
- `rg -n "RequireCapability|RequireRole|programs:execute|programs:assignments_my|GetCapabilityCatalog|CreateAuthenticatedClient|phantom|Forbidden" ...`
</command_logs>

## Handoff Block
Mission summary:
- Replace the hardcoded role guard on `SubmitProgramEvidence` with PBAC.
- Recommended choice is a new dedicated `programs:execute` capability, not reuse of `programs:assignments_my`.
- Keep the scope narrow: endpoint auth, seed plumbing, catalog exposure, and proof tests.

Run these one at a time:

Step 1:
`@[/atdd] Execute specs for Slice 1: C:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_150405_371654b0_submitprogramevidence_pbac.md`

Step 2:
`@[/implement] Execute build for Slice 1: C:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_150405_371654b0_submitprogramevidence_pbac.md`

Concurrency:
- Do not start implementation until the PBAC auth specs are locked.

Decision required before implementation:
- Approve the dedicated `programs:execute` capability.
- Alternative if you reject it: reuse `programs:assignments_my`, with the explicit downside that read and execute permissions become inseparable.

Plan ready for Builder to execute.
