# Walkthrough: Fix A-02 IDOR Vulnerability in CanDelegate

## Input Lineage
- **Implementation Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260502_084354_5badbf76_fix_can_delegate_idor.md`
- **ATDD Contracts**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260502_084947_5c387618_fix_can_delegate_idor.md`
- **Task Tracker**: `c:\Users\HP\Documents\GitHub\Checkly\brain\task_20260502_090236_baca184a_fix_can_delegate_idor.md`

## Decision Log

| Decision | Proposed | Implemented | Reason |
|---|---|---|---|
| `CanDelegateAsync` method | Add to `ResourceAccessGuard.cs` | Done | Provides asynchronous area membership checking against DB. |
| Sync `CanDelegate` method | Keep for admin fast path? | Kept | Admin checking doesn't need DB. Existing fast-path unit tests remain valid. |
| `CreateSubmission.cs` | Await `CanDelegateAsync` | Done | Passed request `StoreId` in `ResourceScope`. |
| `FinalizeSubmission.cs` | Await `CanDelegateAsync` | Done | Passed `submission.StoreId` in `ResourceScope` since the entity is already loaded. |
| `SubmissionAccessGuardUnitTests.cs` | Update `NOTE` marked calls | Done | Updated the two AreaManager unit tests to use `CanDelegateAsync` with injected DB context. |

## Files Changed

| Action | File |
|---|---|
| [MOD] | `server/Common/ResourceAccessGuard.cs` |
| [MOD] | `server/Features/Submissions/CreateSubmission.cs` |
| [MOD] | `server/Features/Submissions/FinalizeSubmission.cs` |
| [MOD] | `server/tests/Checkly.Api.Tests/SubmissionAccessGuardUnitTests.cs` |

## Verification Handoff

For QA to verify:
1. Build compiles with zero errors and zero warnings.
2. The ATDD tests that were previously failing (AreaManager delegating outside their area) now successfully return `403 Forbidden` (and thus pass the test assertion).
3. The Unit tests that were previously failing (CanDelegate_AreaManager_ReturnsFalse_IfOutsideArea) now successfully return `false`.
4. Full test suite (474 tests) passes — no regressions.

<test_trace>
ok dotnet test: 474 tests passed, 0 warnings in 1 projects (113.4 s)
</test_trace>

<forensic_evidence>
Commands executed:
1. `dotnet build Checkly.Api.csproj` — 0 errors, 0 warnings
2. `dotnet test` (full suite) — 474/474 passed
</forensic_evidence>

## Gotcha Protocol
No new gotchas identified for this specific IDOR fix that aren't already captured by the general rules.
