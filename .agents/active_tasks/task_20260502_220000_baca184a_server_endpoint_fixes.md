# Task: Fix Server Endpoint Security & Quality Findings
Workflow: /implement | Track: B1 (audit report — no tests required upfront)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_infra_report_20260502_215050_70e13ccc_server_endpoints.md`

## Upfront
- [x] Pre-Requisite: Audit Report provided (from /audit-infra)
- [x] Pre-Requisite: All target files read before coding

> [!NOTE]
> **AI Decision:** Track B1 (no TDD phase)
> **Why:** All 7 fixes are pure mechanical corrections — deleting a debug line, adding `.Take()`, reordering saves, and extracting a helper. No new domain logic or complex permutations that require pre-written failing tests.

## Active Slice (Anti-Collapse: ONE file per turn)

- [x] Turn 1 — IS-2 + IS-3: `FinalizeSubmission.cs` (delete debug write; add Take(500))
- [x] Turn 2 — IS-4: `SubmissionEndpoints.cs` (add 3 capability/role gates)
- [x] Turn 3 — IS-5: `ReviewSubmission.cs` (merge double SaveChanges into one)
- [x] Turn 4 — IS-6: Create `server/Common/ImageValidation.cs` + update both Photos files
- [x] Turn 5 — IS-7: SKIPPED — `ProgramAssignment` has no `IsActive` field (schema migration needed)
- [x] Turn 6 — IS-8: `ResourceAccessGuard.cs` (replace two-query with AnyAsync)
- [x] Turn 7 — Build verify: `dotnet build --no-restore` → 0 errors, 0 warnings

## Wrap Up
- [x] Phase 2: Self-Review
- [x] Phase 3: Handoff -> Terminate session

## Artifacts
| Status | File Path | Type |
|---|---|---|
| [NEW] | .agents/active_tasks/walkthrough_20260502_220000_baca184a_server_endpoint_fixes.md | Result |
| [NEW] | docs/qa/gates/executed_tests_20260502_220000_baca184a_server_endpoint_fixes.md | Test Log |
