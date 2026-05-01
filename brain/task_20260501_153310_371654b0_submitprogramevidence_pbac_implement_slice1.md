# Task: SubmitProgramEvidence PBAC Slice 1
Workflow: /implement | Track: B2

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_150405_371654b0_submitprogramevidence_pbac.md`
- **ATDD Contract**: `C:\Users\HP\.gemini\antigravity\brain\371654b0-a620-4bc8-bb54-83d89ab07e62\test_contracts_20260501_151614_371654b0_submitprogramevidence_pbac_atdd.md.resolved`

## Upfront
- [x] Pre-Requisite: Implementation Plan (from /analyze-feature)
- [x] Pre-Requisite: Failing Tests (from /atdd or /tdd)

> [!NOTE]
> **AI Decision:** Skipped new test authoring in this session.
> **Why:** QA already supplied RED ATDD coverage, and the user explicitly constrained execution to Slice 1 plumbing only.

## Active Slice
- [x] Slice 1: PBAC Plumbing for Program Execution (Read Tests -> Code -> Verify)

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff -> Terminate session

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW] | C:\Users\HP\Documents\GitHub\Checkly\brain\walkthrough_submitprogramevidence_pbac_slice1.md | Result |
| [NEW] | C:\Users\HP\Documents\GitHub\Checkly\brain\executed_tests_submitprogramevidence_pbac_slice1.md | Test Log |

## Strict Implementation Constraints & Human Reminders
- Execute EXACTLY ONE slice from the approved implementation plan.
- Keep scope to PBAC plumbing only: endpoint guard, capability constant, startup/test seed rows, admin capability catalog, and any directly coupled count/constant tests.
- Do not rewrite `SubmitProgramEvidence.cs` business logic unless a failing test proves it is required.
- Do not widen this into a full Programs capability catalog cleanup.
- Immutable test rule: adapt code to the existing contract; do not loosen tests to fit the code.
