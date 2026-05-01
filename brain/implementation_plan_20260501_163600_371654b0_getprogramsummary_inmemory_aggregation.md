<latent_space_scratchpad>
The current `GetProgramSummary.cs` endpoint fetches all assignment statuses into memory. If a program has thousands of assignments, this will allocate thousands of strings in memory just to count them. We need to replace `ToListAsync` with a database-side `GroupBy` operation. Since the `overdue` calculation is derived from the program's deadline and the `pending` status, we can still easily calculate `overdueCount` and `pendingCount` by checking `isProgramDeadlinePassed` against the `pending` count from the DB projection. The dictionary returned by EF Core might throw on null keys, but the schema ensures Status is not null. We can safely retrieve the counts.
</latent_space_scratchpad>

# Task: Fix In-Memory Aggregation in GetProgramSummary
Workflow: /analyze-feature | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\371654b0-a620-4bc8-bb54-83d89ab07e62\audit_infra_report_20260501_122611_371654b0-a620-4bc8-bb54-83d89ab07e62_programs_backend.md.resolved`

## Executive Summary & Out of Scope
Refactor `GetProgramSummary.cs` to execute a database-side `GroupBy` projection for assignment statuses, eliminating the in-memory array allocation and potential OOM risks for large programs.
- **Out of Scope**: No changes to the API response schema or mobile client code. No changes to the endpoint's routing or authorization.

## Logs & Audits
- N/A. No changes to audit logging required.

## 4-State Matrix
- **Success**: Returns `ProgramSummaryResponse` with correctly aggregated counts using the optimized DB query.
- **Error**: N/A.
- **Empty**: Returns zeroes if no assignments exist.
- **Loading**: Fast server-side DB aggregation.

## Test Contracts
- **ID**: `Summary_ReturnsAggregatedCounts`
- **State Matrix**: Success
- **Failure Reason**: The existing tests for `GetProgramSummary` must continue passing. The test must verify that `overdueCount`, `pendingCount`, `submittedCount`, etc., are still correctly aggregated. If the query optimization causes EF Core to fail or counts to be incorrect, the test will fail.

## Test Fixture & Payloads
- **Required**: An existing program with multiple assignments in various statuses (pending, submitted, needs_revision, verified).

## Tools & Commands
- **Testing**: `rtk dotnet test server/tests --filter GetProgramSummary`

## Proposed Changes
- `[MOD]` `server/Features/Programs/GetProgramSummary.cs`: Refactor the `statuses` fetch to use `.GroupBy(a => a.Status).Select(g => new { Status = g.Key, Count = g.Count() }).ToDictionaryAsync(x => x.Status, x => x.Count, ct)`. Compute the total and individual counts from the dictionary.

## Risk Assessment
- **Severity**: Low
- **Description**: Refactoring a query to DB-side aggregation is low risk since it just returns counts. The main risk is missing status counts if a dictionary key lookup fails on a status that has zero count. We mitigate this by using `GetValueOrDefault()`.

## Verification Plan
- Run the integration tests `server/Api.Tests/Features/Programs/GetProgramSummaryTests.cs` to ensure the summary counts are correct.
- Verify the SQL generated uses a `GROUP BY` clause.

## Concept Diagram
`[Client Request] --> [GetProgramSummary] --> [DB: GROUP BY Status COUNT(*)] --> [Map to pending/overdue/submitted variables] --> [HTTP 200]`

## Execution Slices
### Phase 1: Implement Server-Side Aggregation
- Refactor `GetProgramSummary.cs` to use `.GroupBy()` instead of `.ToListAsync()`. Ensure `overdueCount` logic works correctly with the returned dictionary.
- **Complexity**: Low - Basic EF Core query translation.
- **Pros & Cons**: 
  - *Pros*: O(1) memory usage regardless of assignment count.
  - *Cons*: Need to be careful with dictionary key lookups to avoid KeyNotFoundException (use `GetValueOrDefault`).

## Handoff Block
The plan is ready. The next agent will execute the implementation.
@[/implement] Execute build for Slice 1: c:\Users\HP\Documents\GitHub\Checkly\brain\implementation_plan_20260501_163600_371654b0_getprogramsummary_inmemory_aggregation.md
