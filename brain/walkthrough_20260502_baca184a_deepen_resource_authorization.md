# Walkthrough: Deepen Resource Authorization — ResourceScope Refactor

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_234500_380021a1_deepen_resource_authorization.md`
- **TDD Spec**: `c:\Users\HP\Documents\GitHub\Checkly\brain\executed_tests_20260502_061017_5c387618_tdd_step5.md`
- **Task Tracker**: `c:\Users\HP\Documents\GitHub\Checkly\brain\task_20260502_061613_baca184a_deepen_resource_authorization.md`

## Decision Log

| Decision | Proposed | Implemented | Reason |
|---|---|---|---|
| Value object location | `Common/ResourceScope.cs` | Same | Correct layer — shared utility |
| Class rename | `SubmissionAccessGuard` → `ResourceAccessGuard` | Done | Removes submission-specific semantic from a generic guard |
| `CanAccessAsync` signature | `(user, storeId, areaId, auditorId, db, ct)` → `(user, scope, db, ct)` | Done | Eliminated param confusion; `auditorId` → `OwnerId` in scope |
| `CanDelegate` signature | No change | Unchanged | Plan specified — no change |
| Private helpers | No change | Unchanged | Internal; pass `scope.StoreId`, `scope.AreaId` inline |
| Old file | Delete after new compiles | Deleted | Prevents dual-definition confusion |
| `SyncSubmissions` | `storeId + areaId, auditorId: null` | `new ResourceScope(StoreId: storeId, AreaId: areaId)` | Scope-only check, no owner |
| `UploadProgramPhoto` / `GetProgramPhoto` | `storeId, auditorId: null` | `new ResourceScope(StoreId: ...)` | Program photos have no submission owner |
| `server/GEMINI.md` | Stale `SubmissionAccessGuard` reference | Updated to `ResourceAccessGuard` | Boy Scout Rule |

## Files Changed

| Action | File |
|---|---|
| [NEW] | `server/Common/ResourceScope.cs` |
| [NEW] | `server/Common/ResourceAccessGuard.cs` |
| [DEL] | `server/Common/SubmissionAccessGuard.cs` |
| [MOD] | `server/Features/Submissions/GetSubmission.cs` |
| [MOD] | `server/Features/Submissions/ReviewSubmission.cs` |
| [MOD] | `server/Features/Submissions/SyncSubmissions.cs` |
| [MOD] | `server/Features/Submissions/FinalizeSubmission.cs` |
| [MOD] | `server/Features/Submissions/CreateSubmission.cs` |
| [MOD] | `server/Features/Photos/UploadPhoto.cs` |
| [MOD] | `server/Features/Photos/UploadProgramPhoto.cs` |
| [MOD] | `server/Features/Photos/GetPhoto.cs` |
| [MOD] | `server/Features/Photos/GetProgramPhoto.cs` |
| [MOD] | `server/Features/ActionPlans/UpdateActionPlan.cs` |
| [MOD] | `server/Features/GlobalRisks/ListSubmissionRisks.cs` |
| [MOD] | `server/Features/GlobalRisks/TriggerSubmissionRisk.cs` |
| [MOD] | `server/Features/GlobalRisks/RemoveSubmissionRisk.cs` |
| [MOD] | `server/GEMINI.md` |

## Verification Handoff

For QA to verify:
1. Build compiles with zero errors and zero warnings.
2. All 9 `SubmissionAccessGuardUnitTests` pass (the alias now resolves to `ResourceAccessGuard`).
3. Full test suite (472 tests) passes — no regressions.
4. No reference to `SubmissionAccessGuard` remains in `server/` (grep to confirm).

**Grep check command:**
```
grep -r "SubmissionAccessGuard" server/ --include="*.cs"
```
Expected result: **no output** (zero matches).

## Gotcha Protocol

> **Proposed GEMINI.md update (server/GEMINI.md)** — Already applied during this session.
>
> Old entry: `- **SubmissionAccessGuard**: Reusable permission guard.`
> New entry: `- **ResourceAccessGuard**: Reusable IDOR guard. Use \`new ResourceScope(StoreId: ..., OwnerId: ..., AreaId: ...)\` to scope access.`

---

<test_trace>
Targeted run (SubmissionAccessGuardUnitTests):
  ok dotnet test: 9 tests passed, 0 warnings in 1 projects (3.3 s)

Full suite regression:
  ok dotnet test: 472 tests passed, 0 warnings in 1 projects (138.5 s)

Build:
  ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:12.59)
</test_trace>

<forensic_evidence>
Commands executed:
1. `dotnet build Checkly.Api.csproj` — 0 errors, 0 warnings
2. `dotnet test --filter SubmissionAccessGuardUnitTests` — 9/9 passed
3. `dotnet test` (full suite) — 472/472 passed
</forensic_evidence>
