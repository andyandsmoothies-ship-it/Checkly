# Task: Deepen Resource Authorization — ResourceScope Refactor
Workflow: /implement | Track: B2 (tests existed, now implementing GREEN)

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_234500_380021a1_deepen_resource_authorization.md`
- **TDD Results**: `c:\Users\HP\Documents\GitHub\Checkly\brain\executed_tests_20260502_061017_5c387618_tdd_step5.md`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from /analyze-feature)
- [x] Pre-Requisite: Failing Tests (from /tdd) — alias `ResourceAccessGuard` was RED (CS0234)

## Active Slice
- [x] Slice 1: Create `ResourceScope.cs` value object
- [x] Slice 2: Create `ResourceAccessGuard.cs` (renamed + new signature)
- [x] Slice 3: Delete `SubmissionAccessGuard.cs`
- [x] Slice 4: Update 13 call sites across 11 files
- [x] Slice 5: Build verify — 0 errors, 0 warnings
- [x] Slice 6: Unit tests GREEN — 9/9 passed
- [x] Slice 7: Full regression — 472/472 passed

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | `server/Common/ResourceScope.cs` | Source |
| [NEW] | `server/Common/ResourceAccessGuard.cs` | Source |
| [DEL] | `server/Common/SubmissionAccessGuard.cs` | Removed |
| [MOD] | `server/Features/Submissions/GetSubmission.cs` | Call site |
| [MOD] | `server/Features/Submissions/ReviewSubmission.cs` | Call site |
| [MOD] | `server/Features/Submissions/SyncSubmissions.cs` | Call site |
| [MOD] | `server/Features/Submissions/FinalizeSubmission.cs` | Call site (CanDelegate only) |
| [MOD] | `server/Features/Submissions/CreateSubmission.cs` | Call site (CanDelegate only) |
| [MOD] | `server/Features/Photos/UploadPhoto.cs` | Call site |
| [MOD] | `server/Features/Photos/UploadProgramPhoto.cs` | Call site |
| [MOD] | `server/Features/Photos/GetPhoto.cs` | Call site |
| [MOD] | `server/Features/Photos/GetProgramPhoto.cs` | Call site |
| [MOD] | `server/Features/ActionPlans/UpdateActionPlan.cs` | Call site |
| [MOD] | `server/Features/GlobalRisks/ListSubmissionRisks.cs` | Call site |
| [MOD] | `server/Features/GlobalRisks/TriggerSubmissionRisk.cs` | Call site |
| [MOD] | `server/Features/GlobalRisks/RemoveSubmissionRisk.cs` | Call site |
| [NEW] | `brain/walkthrough_20260502_deepen_resource_authorization.md` | Result |
