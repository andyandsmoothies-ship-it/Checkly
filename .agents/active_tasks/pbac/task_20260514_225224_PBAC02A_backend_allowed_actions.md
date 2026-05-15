# Task: PBAC02 — Phase A: Backend AllowedActions in Submission DTOs
Workflow: /implement | Track: B2 (Tests from QA exist, now implement)

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260514_223612_PBAC02_hybrid_entity_ui.md`
- **Test Contracts**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260514_224300_PBAC02_backend_allowed_actions.md`
- **Test File**: `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\SubmissionAllowedActionsTests.cs`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from /analyze-feature)
- [x] Pre-Requisite: Failing Tests (from /atdd — tests exist in SubmissionAllowedActionsTests.cs)

## Active Slice
- [x] Slice A1: SubmissionActions.cs — New static constants file
- [x] Slice A2: Dtos.cs — Add AllowedActions to both DTOs
- [x] Slice A3: GetSubmission.cs — Inject PbacDictionaryCache, compute AllowedActions in hand-mapping
- [x] Slice A4: ListSubmissions.cs — Evaluate role before query, inject in .Select()
- [x] Verify: rtk dotnet build then rtk dotnet test

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | server/Features/Submissions/SubmissionActions.cs | Constants |
| [MOD] | server/Features/Submissions/Dtos.cs | DTO update |
| [MOD] | server/Features/Submissions/GetSubmission.cs | Logic update |
| [MOD] | server/Features/Submissions/ListSubmissions.cs | Logic update |
