# Implementation Plan - SL-4: Purge areaId fallback logic from ResourceAccessGuard and SyncSubmissions

Purge the legacy `AreaId` fallback authorization and sync logic from the backend. Transition security checks and mobile sync scoping to use the multi-store junction table (`ProfileStoreAssignment`) exclusively.

## User Review Required
- **Security Scope Change**: The `area_manager` role's access control will be decoupled from a single `AreaId` column and now strictly validates against explicit assignments in `ProfileStoreAssignment`.
- **API Change**: The `areaId` query parameter on `GET /api/sync/submissions` is deprecated. Non-admin area managers querying without a specific `storeId` will have their results automatically scoped to all their assigned stores.

## Open Questions
- None.

## Proposed Changes

### Core Security & Authorization

#### [MODIFY] [ResourceAccessGuard.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/ResourceAccessGuard.cs)
- Simplify `IsUserAreaAsync(Guid userId, Guid? storeId, Guid? areaId, AppDbContext db, CancellationToken ct)` to `IsUserAreaAsync(Guid userId, Guid? storeId, AppDbContext db, CancellationToken ct)`.
- Completely remove the legacy `areaId.HasValue` fallback checking block which counted assigned stores.
- Update callers `CanAccessAsync` and `CanDelegateAsync` to no longer pass `scope.AreaId` when calling `IsUserAreaAsync`.

```csharp
private static async Task<bool> IsUserAreaAsync(Guid userId, Guid? storeId, AppDbContext db, CancellationToken ct)
{
    if (storeId is null) return false;

    return await db.ProfileStoreAssignments
        .AnyAsync(a => a.ProfileId == userId && a.StoreId == storeId.Value, ct);
}
```

---

### Mobile Keyset Synchronization

#### [MODIFY] [SyncSubmissions.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Submissions/SyncSubmissions.cs)
- Deprecate/ignore the `areaId` parameter. It will remain in the API signature to prevent contract breaks but will not be used in query filtering or authorization.
- **Rule 1 (Scope Guard)**: Non-admins must provide `storeId` or be resolved.
  - If a `store_manager` does not pass `storeId`, resolve `storeId = profile.StoreId`.
  - If an `area_manager` does not pass `storeId`, allow unbounded sync (do not reject with `400 Bad Request`).
  - All other non-admin roles must pass `storeId`.
- **Rule 2 (IDOR Guard)**:
  - If `storeId` is provided, call `ResourceAccessGuard.CanAccessAsync` with a `ResourceScope(StoreId: storeId)`.
- **Submission Filtering**:
  - If `storeId` has a value, filter by `s.StoreId == storeId.Value`.
  - Else if user is an `area_manager`, filter submissions strictly by their assigned stores fetched from `db.ProfileStoreAssignments`:
    ```csharp
    var assignedStoreIds = await db.ProfileStoreAssignments
        .Where(a => a.ProfileId == userId)
        .Select(a => a.StoreId)
        .ToListAsync(ct);
    query = query.Where(s => s.StoreId.HasValue && assignedStoreIds.Contains(s.StoreId.Value));
    ```

---

### Automated Integration Tests

#### [MODIFY] [SyncSubmissionsEndpointTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/SyncSubmissionsEndpointTests.cs)
- Update `SyncSubmissions_AsAreaManager_CorrectArea_Returns200`:
  - Request unbounded sync `GET /api/sync/submissions` (without `areaId`).
  - Verify that the sync succeeds and returns submissions for their assigned stores.
- Update `SyncSubmissions_AsAreaManager_MissingOneStoreInJunction_Returns403`:
  - Request explicit sync for the unassigned `storeId2` using `GET /api/sync/submissions?storeId={storeId2}`.
  - Verify that the sync is rejected with `403 Forbidden`.

#### [MODIFY] [SubmissionAccessGuardUnitTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/SubmissionAccessGuardUnitTests.cs)
- Update tests to pass `ResourceScope(StoreId: storeId)` instead of passing `AreaId` parameter.

## Risk Assessment
- **Volatility**: High. Modifying `ResourceAccessGuard` and `SyncSubmissions` directly impacts security and data sync layers.
- **Rollback**: Standard source control rollback.

## Verification Plan

### Automated Tests
- Run xUnit tests using `rtk dotnet test` command:
  ```powershell
  cmd /c rtk dotnet test --filter SyncSubmissionsEndpointTests
  cmd /c rtk dotnet test --filter SubmissionAccessGuardUnitTests
  ```

### Manual Verification
- Verify that standard endpoints compile, build, and tests execute and pass cleanly.
