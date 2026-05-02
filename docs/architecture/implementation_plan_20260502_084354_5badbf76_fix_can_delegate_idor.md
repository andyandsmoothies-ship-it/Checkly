# Task: Fix A-02 IDOR Vulnerability in CanDelegate
Workflow: /analyze-feature | Track: B1

## Risk Assessment
> [!WARNING]
> **RISK WARNING:** This is a High-Risk architectural change altering core authorization rules. Modifying `ResourceAccessGuard.CanDelegate` to an async method and requiring a `ResourceScope` introduces a breaking signature change for endpoints and tests. However, the ROI is extremely high because it patches a critical IDOR vulnerability where Area Managers could delegate work across unauthorized regions.

<latent_space_scratchpad>
- `ResourceAccessGuard.CanDelegate` needs to become `CanDelegateAsync(ClaimsPrincipal user, ResourceScope scope, AppDbContext db, CancellationToken ct)`.
- CreateSubmission and FinalizeSubmission need `await` and passing the `db` and a `new ResourceScope(StoreId: ...)`.
- `SubmissionDelegationAuthTests` AC-02 needs to assign the newly created `area_manager` to the store's `AreaId` via their Profile, so the DB relations match.
- `SubmissionAccessGuardUnitTests` needs `TestWebApplicationFactory` injected so we can pass a real `AppDbContext` into `CanAccessAsync` and `CanDelegateAsync` when testing `area_manager`, or we just delete the `area_manager` unit test and rely on the full ATDD integration test. Better to refactor the Unit test to an Integration test by adding `IClassFixture<TestWebApplicationFactory>`.
</latent_space_scratchpad>

## Input Lineage
- Source Input: `C:\Users\HP\.gemini\antigravity\brain\5badbf76-fcd9-4eb7-8566-2f6faa9d4396\audit_arch_report_20260501_235325_5badbf76_sync_engine.md`

## Executive Summary & Out of Scope
**Goal**: Patch the IDOR vulnerability in `CanDelegate` by ensuring that when an Area Manager delegates a submission, the target store actually belongs to their assigned Area.
**Out of Scope**: 
- We will not implement `StoreManager` delegation (they remain `false`).
- We will not refactor the entire `SubmissionAccessGuardUnitTests` to use Moq. We will inject the `TestWebApplicationFactory` DB or use integration tests to verify DB interactions.

## Logs & Audits
- Security denial events (e.g., 403 Forbidden) during delegation are standard ASP.NET Core outputs. No new custom audit logs are strictly required beyond the existing `AuditLogger.Log` on successful submission creation/finalization.

## 4-State Matrix
| State | UI / API Response |
|---|---|
| **Loading** | Frontend shows spinner while delegating (creating/finalizing submission). |
| **Empty** | N/A (Delegation involves an existing payload or draft). |
| **Error** | API returns `403 Forbidden`. Frontend interprets this as "Unauthorized to delegate for this store." |
| **Success** | API returns `201 Created` or `200 OK`. Target auditor assumes ownership of the submission. |

## Test Contracts

| ID | Exact Text | State Matrix | Why it fails first (RED) |
|---|---|---|---|
| AC-02 | `AreaManager_CanDelegateToOtherUser_Returns201` | Success | Currently uses a dead string "manager" role, and the AreaManager lacks an explicit `AreaId` relation with the store. The new strict Area checking will fail until we seed the DB correctly. |
| AC-03 | `Auditor_CannotDelegateToOtherUser_Returns403` | Error | Existing ATDD test already catches 403s but relies on the old synchronous signature. Needs refactoring. |
| UG-01 | `CanDelegate_AreaManager_ReturnsTrue_IfInArea` | Success | Unit test requires a real `AppDbContext` to execute `IsUserAreaAsync`. Passes `null` currently. |

## Test Fixture & Payloads
- **Seeded Area Manager**: Must have a `Profile.AreaId` seeded.
- **Seeded Store**: Must have `Store.AreaId` seeded matching the Area Manager.

## Tools & Commands
- **Skills**: `atdd-quality-gates`, `backend-architect`
- **Commands**: 
  - `cmd /c dotnet build server/Checkly.Api.sln`
  - `cmd /c dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "SubmissionDelegationAuthTests"`
  - `cmd /c dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "SubmissionAccessGuardUnitTests"`

## Proposed Changes
- `[MOD]` `server/Common/ResourceAccessGuard.cs`: Rename `CanDelegate` to `CanDelegateAsync`. Add parameters `ResourceScope scope, AppDbContext db, CancellationToken ct`. Call `IsUserAreaAsync` for `area_manager`.
- `[MOD]` `server/Features/Submissions/CreateSubmission.cs`: Await `CanDelegateAsync`.
- `[MOD]` `server/Features/Submissions/FinalizeSubmission.cs`: Await `CanDelegateAsync`.
- `[MOD]` `server/tests/Checkly.Api.Tests/SubmissionDelegationAuthTests.cs`: Seed `AreaId` correctly in AC-02.
- `[MOD]` `server/tests/Checkly.Api.Tests/SubmissionAccessGuardUnitTests.cs`: Convert to an integration test leveraging `TestWebApplicationFactory` to supply `AppDbContext` for the Area Manager DB-dependent role checks.

## Concept Diagram
```text
[Request: AssignToAuditorId = Y]
       |
       v
[ResourceAccessGuard.CanDelegateAsync]
       |
  Is Area Manager?
       |
  Check db.Profiles matching Store's AreaId
       |
   [Yes] --> 201 Created
   [No]  --> 403 Forbidden
```

## Execution Slices

### Execution Phase
**Complexity**: Low
**Reason**: We are changing an existing method signature and cascading the async/await pattern to its callers, alongside test fixture updates.
**Pros & Cons**: 
- *Pro*: Fixes a major security vulnerability (IDOR) with minimal code.
- *Con*: Requires tests to have properly seeded Area relationships, making test setup slightly more verbose.

## Verification Plan
1. Ensure the code compiles properly using `dotnet build`.
2. Run `SubmissionDelegationAuthTests` to ensure that AC-01 through AC-04 are passing.
3. Verify that `SubmissionAccessGuardUnitTests` runs locally without crashing on `NullReferenceException`.

<command_logs>
- `grep_search` for `CanDelegate` across `server/`
- `view_file` for `ResourceAccessGuard.cs`, `CreateSubmission.cs`, `FinalizeSubmission.cs`
- `view_file` for `TestWebApplicationFactory.cs` and related tests.
</command_logs>

## Handoff Block
> [!IMPORTANT]
> **Action:** Print the exact routing commands below for the user. Match each step to its correct route.
> 
> **Step-by-Step Rule:** Tell the user to run these commands **ONE AT A TIME**.
>
> **Route 3: Network/Auth/DB (Acceptance Tests First)**
> @[/atdd] Execute specs for Execution Phase: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260502_084354_5badbf76_fix_can_delegate_idor.md
