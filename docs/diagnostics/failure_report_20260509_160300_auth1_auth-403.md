# Failure Report: AM User 403 on /programs/assignments/my

## Input Lineage
- **Source Input**: User Chat Log - HTTP GET `/api/programs/assignments/my` responded 403 for AM User.

## Root Cause
The `area_manager` role is not seeded with the PBAC capabilities `programs:assignments_my` and `programs:execute`. Currently, in `Program.cs` and `TestWebApplicationFactory.cs`, these capabilities are explicitly seeded *only* for the `store_manager` role. When an Area Manager attempts to view or execute an assigned audit program, the `RequireCapability(AppCapabilities.ProgramsAssignmentsMy)` middleware rejects the request with a 403 Forbidden.

## Explicit Code Trace (Premises + Proof)
1. **Endpoint Guard**: `server/Features/Programs/ProgramEndpoints.cs` maps `GET /api/programs/assignments/my` with `.RequireCapability(AppCapabilities.ProgramsAssignmentsMy)`.
2. **Missing Seed Data**: `server/Program.cs` (lines 348-356) and `server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs` (lines 135-136) only insert `programs:assignments_my` and `programs:execute` for the `'store_manager'` role.
3. **Execution Gap**: Because `area_manager` is not explicitly granted these capabilities during app startup or test factory initialization, PBAC fails-closed and denies access.

## Proposed Scope-Limited Fix

**Trade-offs / Pros & Cons:**
- *Pros*: Area Managers gain the ability to be assigned and execute audits directly without requiring a separate Store Manager account. Adheres to the PBAC capability model correctly.
- *Cons*: Area Managers will now see an execution flow for audits. Ensure Flutter UI handles their expanded capabilities gracefully.

**Fix Steps**:
1. Open `server/Program.cs` and locate the "Programs Module Slice 2A" capability seeding block.
2. Add rows for `area_manager` to receive `programs:assignments_my` and `programs:execute`.
3. Open `server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs` and add the exact same rows in the `EnsureDatabaseCreated` SQL seeding method.
4. Run integration tests to verify AM users no longer receive a 403 on execution paths.

## Handoff Block

**Verdict**: Missing PBAC role-capability associations for `area_manager`.
**Fix**: Seed `programs:assignments_my` and `programs:execute` for `area_manager` in `Program.cs` and `TestWebApplicationFactory.cs`.
**Blast Radius**: Low. Backend-only seeding update.
**AI Agent Mission Brief**: Implement the proposed scope-limited fix by adding the missing capability seeds for `area_manager` in the backend configuration, then run tests.

### Execution Queue
- [ ] @[/implement] docs/diagnostics/failure_report_20260509_160300_auth1_auth-403.md

<forensic_evidence>
- `grep_search` for `ProgramsAssignmentsMy`
- `view_file` on `ProgramEndpoints.cs`
- `view_file` on `AppCapabilities.cs`
- `grep_search` for `programs:assignments_my`
- `view_file` on `Program.cs`
- `view_file` on `TestWebApplicationFactory.cs`
</forensic_evidence>
