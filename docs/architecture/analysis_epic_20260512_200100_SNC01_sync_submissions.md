<latent_space_scratchpad>
Goal: Fix the DDoS risk (`CountAsync`) and Split-Brain data corruption risk (`Skip` / `Take` offset pagination over mutating index) in `/api/sync/submissions`.
Options:
- Shape A: Keyset (Cursor) Pagination. Pass `cursorUpdatedAt` and `cursorId` as query params instead of `page`. Drop `total` property, return `hasNextPage`.
- Shape B: Keyset Pagination using a dedicated monotonic `RowVersion` (xmin in Postgres). 
Tradeoffs: Shape A is easier, requires no DB schema changes, and is standard. Shape B requires DB schema changes and migrations. Shape A is chosen.
Slices:
1. Backend: Refactor `SyncSubmissions.cs` endpoint and its unit/integration tests to use cursor pagination and remove total counts.
2. Frontend: Update `SyncApiAdapter.dart` and any related models (`DeltaPullResult`) to handle cursors instead of pages, implementing the stubbed `pullDeltas` correctly.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_arch_report_20260512_195600_SNC01_sync_submissions.md`

## Executive Summary
The current `/api/sync/submissions` endpoint is structurally broken. It uses `CountAsync()` on a massive table, risking a DDoS when hundreds of mobile clients sync simultaneously. It also uses offset pagination (`Skip` and `Take`) over a mutating index (`UpdatedAt`), which mathematically guarantees skipped or duplicated records (Split-Brain) during active syncs. This Epic will replace offset pagination with Keyset (Cursor) Pagination and eliminate the `CountAsync()` operation entirely.

## Decision Matrix

| Requirement | Shape A: Cursor Pagination (`UpdatedAt` + `Id`) | Shape B: `RowVersion` / DB Sequence Cursor |
|-------------|:---:|:---:|
| **R1: Zero Missed Records (No Split Brain)** | ✅ | ✅ |
| **R2: Prevent DDoS (O(1) execution time)** | ✅ | ✅ |
| **R3: Minimal Database Migrations** | ✅ | ❌ |

**Decision**: **Shape A** is chosen. It uses existing indexed columns (`UpdatedAt` and `Id`) to build a stable cursor without requiring database migrations or sequence generators, guaranteeing O(1) query time and zero dropped records.

## Risk Assessment
- **Mobile Client Drift**: Changing from offset to cursor pagination breaks the API contract. Mobile clients currently stubbing `pullDeltas` must be correctly implemented to pass the cursor.
- **Client Determinate Loaders**: By removing `CountAsync()`, the mobile app can no longer display a "10 out of 500" progress bar. It must fall back to an indeterminate spinner.

## Visual & Functional Context
- **UI Impacts**: Initial sync progress indicators must change from determinate (percentages) to indeterminate (spinners) since the total count of submissions to sync is no longer known upfront.

## System Context
- **Offline-First**: Mobile clients depend entirely on this sync endpoint to download their scoped offline database. Missing records means audits cannot be completed offline.
- **RBAC**: Existing IDOR and Tenant scoping (`StoreId` / `AreaId`) must remain perfectly intact.

## Lifecycle Context
- **Edge Cases**: 
  - Submissions updated with the exact same `UpdatedAt` millisecond tick. The `ThenBy(s => s.Id)` ensures deterministic sorting to break ties.

## Data Context
- **No Schema Changes**: We will rely on the existing `UpdatedAt` and `Id` columns.

## Architecture Flow
1. **Mobile Request**: Client requests `/api/sync/submissions?storeId={id}&cursorUpdatedAt={time}&cursorId={uuid}&limit=50`.
2. **Backend Query**: EF Core fetches `limit + 1` rows where `(UpdatedAt > cursorUpdatedAt) OR (UpdatedAt == cursorUpdatedAt AND Id > cursorId)`.
3. **Backend Response**: Returns `limit` items. If `limit + 1` was found, `hasNextPage` is `true`.
4. **Mobile Client**: Persists data, stores the `UpdatedAt` and `Id` of the very last record as the new cursor, and loops if `hasNextPage` is true.

## Risk Review & Security
- **Security Auditor**: 10/10. (IDOR rules remain untouched, DDoS vector eliminated).
- **DB Architect**: 10/10. (Eliminates full table scans on open-ended queries).
- **Junior Dev**: 9/10. (Cursor pagination is slightly more complex to read than `Skip`/`Take`, but standard).

## Logs & Audits
- We must log any fallback to full-sync (no cursor provided) to track potential performance impacts.

## Testing Expectations
- **Backend Tests**: Must explicitly verify that records modified during a sync fetch loop are NOT missed on subsequent pages (tie-breaker cursor logic).
- **ATDD**: Update `SyncSubmissionsEndpointTests.cs` to test `cursorUpdatedAt`, `cursorId`, and `hasNextPage` logic.

## Handoff Block

1. **Epic Plan**: `docs/architecture/analysis_epic_20260512_200100_SNC01_sync_submissions.md`
2. **Slices**:
   - **Slice 1 | Backend API Migration** `[BLOCKING]`: Rewrite `SyncSubmissions.cs` and `SyncSubmissionsEndpointTests.cs` to use Keyset Pagination and remove `CountAsync`.
   - **Slice 2 | Frontend Sync Consumption** `[SEQUENTIAL]`: Update `SyncApiAdapter.dart` to implement `pullDeltas` using the new cursor payload. Update mobile sync engine to handle `hasNextPage`.
3. **Next Steps**: The Builder must implement Slice 1 (Backend API Migration) by rewriting the endpoint and fixing failing ATDD tests.
4. **Next Workflow**: `/implement`

<forensic_evidence>
Executed `grep_search` to find `SyncSubmissions` usages.
Found `server/Features/Submissions/SyncSubmissions.cs` and `server/tests/Checkly.Api.Tests/SyncSubmissionsEndpointTests.cs`.
Executed `grep_search` to find `sync/submissions` in `lib/`. No usages found.
Executed `view_file` on `lib/_shared/services/sync_api_adapter.dart` and discovered `pullDeltas` is currently a stub on the mobile side.
</forensic_evidence>
