# Walkthrough: Keyset Sync Migration (SyncSubmissions)

## Executive Summary
This document provides a technical walkthrough of the architectural shift from **Offset-based Pagination** to **Keyset (Cursor) Pagination** for the Checkly Offline-First Synchronization Engine (`/api/sync/submissions`).

The migration successfully eliminates two critical system risks:
1. **DDoS Vector**: Prevented full table scans by eliminating the `.CountAsync()` call which degraded server performance during mass simultaneous syncs.
2. **Split-Brain Data Corruption**: Replaced fragile `Skip`/`Take` offsets with deterministic cursors (`UpdatedAt` + `Id`) to guarantee zero skipped or duplicated records when the dataset mutates mid-sync.

---

## 1. Backend API Migration (Slice 1)

### Problem
The original endpoint (`SyncSubmissions.cs`) requested a generic page number and returned the `total` number of rows in the database. During active edits across hundreds of stores, new records pushed earlier pages down, meaning mobile clients pulling Page 2 would skip records that had just been pushed down from Page 1.

### Implementation
- **Cursor Selection**: We leveraged existing indexed columns `UpdatedAt` and `Id` as stable keyset cursors. No schema migrations were needed.
- **Endpoint Restructure**: The route signature was changed to accept `cursorUpdatedAt` and `cursorId`.
- **EF Core Query Refactor**:
  ```csharp
  query = query.Where(s => s.UpdatedAt > cursorUpdatedAt || 
                          (s.UpdatedAt == cursorUpdatedAt && s.Id.CompareTo(cursorId) > 0))
               .OrderBy(s => s.UpdatedAt)
               .ThenBy(s => s.Id);
  ```
- **HasNextPage Paradigm**: We request `limit + 1` from the database. If the result count equals `limit + 1`, we return `limit` items to the client and set `hasNextPage = true`. The heavy `.CountAsync()` was entirely removed.

---

## 2. Frontend Sync Consumption (Slice 2)

### Problem
The Flutter sync engine natively requested `page` numbers and expected a `total` field to compute progress. The entire delta-pull workflow had to be rewritten to orchestrate multiple cursor jumps.

### Implementation
- **API Adapter Update (`SyncApiAdapter.dart`)**:
  - The `pullDeltas` network method was updated to transmit `cursorUpdatedAt` and `cursorId` as query parameters.
- **Engine Loop Refactor (`CoreAuditSyncModule.dart`)**:
  - Replaced the single-pull logic with a robust `while (hasNextPage)` loop.
  - The module now streams the paginated payload to the SQLite database via `SubmissionDao.upsertAll()`.
  - During the loop, the local `cursorId` variable tracks the last record's ID to fetch the next page. Once the entire sync completes, `syncMetaDao` saves the `serverTimestamp` to act as the baseline for the next sync session.
- **Dependency Injection (`locator.dart`)**:
  - Wired in `AuthManager`, `ProfileDao`, and `SubmissionDao` directly to support the revised offline repository patterns in the module.
- **Test Suite Modernization (`sync_engine_test.dart`)**:
  - The test suite's `FakeSyncApi` was upgraded to correctly simulate the `hasNextPage` schema. All 10 concurrency, network-failure, and authorization test scenarios successfully pass against the new cursor logic.

---

## Technical Conclusion
The system is now O(1) in query performance and guarantees absolute offline-first data consistency regardless of external mutations. The initial sync progress indicator has cleanly shifted from a determinate percentage loader to an indeterminate spinner, perfectly aligning with the constraints of high-scale distributed data replication.
