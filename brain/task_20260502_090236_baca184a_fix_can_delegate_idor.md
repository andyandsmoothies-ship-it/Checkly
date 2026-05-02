# Task: Fix A-02 IDOR Vulnerability in CanDelegate
Workflow: /implement | Track: C (ATDD tests exist, executing GREEN phase)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260502_084354_5badbf76_fix_can_delegate_idor.md`
- **ATDD Contracts**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260502_084947_5c387618_fix_can_delegate_idor.md`
- **Test Files (RED)**: `server/tests/Checkly.Api.Tests/SubmissionDelegationAuthTests.cs`, `server/tests/Checkly.Api.Tests/SubmissionAccessGuardUnitTests.cs`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from /analyze-feature)
- [x] Pre-Requisite: Failing Tests (from /atdd) — 2 RED tests confirmed in contract

## Active Slice
- [x] Step 1: Add `CanDelegateAsync` to `ResourceAccessGuard.cs`
- [x] Step 2: Update `CreateSubmission.cs` — await `CanDelegateAsync`
- [x] Step 3: Update `FinalizeSubmission.cs` — await `CanDelegateAsync`
- [x] Step 4: Update `SubmissionAccessGuardUnitTests.cs` — wire NOTE-marked calls to `CanDelegateAsync`
- [x] Step 5: Build + Test

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/walkthrough_20260502_baca184a_fix_can_delegate_idor.md | Result |
