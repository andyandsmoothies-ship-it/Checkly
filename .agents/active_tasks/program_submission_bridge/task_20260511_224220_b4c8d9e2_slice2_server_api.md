# Task: Slice 2 — Server API (PBAC Bypass + State Machine)
Workflow: /implement | Track: B2

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_190931_b4c8d9e2_slice2_server_api.md`
- **Tests**: `server/tests/Checkly.Api.Tests/Program_Slice2A_Tests.cs`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from Feature Analysis)
- [x] Pre-Requisite: Failing Tests (from /atdd) — 10 RED tests in Program_Slice2A_Tests.cs

## Active Slice
- [x] Phase A: ProgramAssignmentBridge.cs (NEW file)
- [x] Phase B: Dtos.cs + SubmissionEndpoints.cs (DTO + route gate)
- [x] Phase C: CreateSubmission.cs (bridge integration)
- [x] Phase D: FinalizeSubmission.cs (post-commit hook)
- [x] Phase E: ProgramDtos.cs + GetMyAssignments.cs (TemplateId)

## Wrap Up
- [x] Phase F: Run full test suite (rtk dotnet test)
- [x] Phase G: Self-Review
- [x] Phase H: Handoff → Terminate session

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/program_submission_bridge/walkthrough_20260511_224220_b4c8d9e2_slice2_server_api.md | Result |
| [NEW] | docs/qa/gates/program_submission_bridge/executed_tests_20260511_224220_b4c8d9e2_slice2_server_api.md | Test Log |
