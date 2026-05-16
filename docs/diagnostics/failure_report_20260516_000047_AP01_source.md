# Diagnostic Failure Report: AP01 Source Label Backend Missing

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\AP01_source\walkthrough_20260515_235259_AP01_source.md`
- **Initial Verification Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md`

## Root Cause
Orchestration failure / Skipped Phase. Phase A (Backend API & Database) of the AP01 implementation plan was never executed by the Builder. The user requested verification on Phase B (Frontend UI), but the backend tests (which were written in the TDD Red Phase) are still failing because the backend implementation was never done.

## Explicit Code Trace (Premises + Proof)
**Premise**: The backend tests are failing with `KeyNotFoundException` on `sourceTitle`.
**Proof**: 
- `dotnet test` output shows 3 failures:
  1. `CreateActionPlan_WithCampaign_SetsCampaignSource`
  2. `CreateActionPlan_WithAudit_SetsAuditSource`
  3. `GetActionPlan_WithNullSourceTitle_ReturnsNullField`
- A `grep_search` for `SourceTitle` in `server/` yielded 0 results outside of the test files. 
- The `ActionPlan.cs` entity and `ActionPlanDto` record in the backend lack the `SourceTitle` field.

## Proposed Scope-Limited Fix
The Builder (Forge) must implement Phase A from `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md`.

**Trade-offs / Pros & Cons**:
- **Pros**: Completes the end-to-end slice and turns the ATDD tests green.
- **Cons**: Requires another handoff loop. No immediate downsides as the backend changes are localized and tested.

<forensic_evidence>
- `list_dir` checked `.agents/active_tasks/AP01_source`
- `view_file` read `action_plan_dto.dart` and `action_plan_card.dart`
- `grep_search` for `SourceTitle` in `server/`
- `rtk dotnet test` executed on `server/Tests/Checkly.Api.Tests`
- `rtk flutter test` executed on `lib/` (Passed: 501, Failed: 0)
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict & Persistent path**: The backend Phase A was skipped. Tests fail correctly because the code does not exist yet. Path: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260516_000047_AP01_source.md`
2. **The required fix and its blast radius**: Implement Phase A (Add `SourceTitle` column, API return logic). Blast radius is limited to the Action Plan module.
3. **AI Agent Mission Brief**: Implement Phase A of the AP01 feature to satisfy the existing failing tests.
4. **Execution Queue**:
- [ ] @[/implement] C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md
