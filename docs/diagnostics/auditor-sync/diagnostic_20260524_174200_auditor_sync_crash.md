# Diagnostic Report: Auditor Delta Sync Crash

[Mobile App (auditor1)] --> (pullDeltas without storeId) --> [API Endpoint: GET /api/sync/submissions]
                                                                        |
                                                                        v
                                                            [ScopeGuard validation]
                                                                        |
                                                 (Failed: Requires storeId for non-admin/AM)
                                                                        |
                                                                        v
                                                              [400 Bad Request]

---

## 1. Root Cause Analysis

When an auditor logged into the Checkly application, the mobile sync engine initialized the automatic delta sync by calling `/api/sync/submissions` to retrieve modified submissions.
- Because an auditor has chain-wide scope and is not bound to a specific store (nor does the Flutter application specify one on startup), the query parameter `storeId` is sent as `null`.
- The backend's `SyncSubmissions.HandleAsync` endpoint enforced a strict validation rule:
  ```csharp
  if (!isAdmin && !isAreaManager && !storeId.HasValue)
      return TypedResults.BadRequest(...);
  ```
- Since an auditor is neither an admin nor an area manager, and has no `storeId` parameter, they hit this check and received a `400 Bad Request` exception, crashing the local SQLite sync cycle.

---

## 2. Corrective Actions Taken

We updated the server scoping policy and endpoint query to fully support unbounded keyset delta syncing for the `auditor` role while enforcing strict row-level ownership boundary guards.

### File Modifications

#### A. [SyncSubmissions.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Submissions/SyncSubmissions.cs)
- Added the `isAuditor` role resolver flag.
- Modified the **Scope Guard** to allow callers with the `auditor` role to bypass the `storeId` requirement:
  ```csharp
  if (!isAdmin && !isAreaManager && !isAuditor && !storeId.HasValue)
  ```
- Modified the **IDOR Guard** to skip store-level checks for auditors since auditors are chain-wide:
  ```csharp
  if (!isAdmin && !isAuditor && storeId.HasValue)
  ```
- Added ownership filtering logic in the query builder to limit an auditor's delta sync strictly to their own submissions:
  ```csharp
  if (isAuditor)
  {
      if (!Guid.TryParse(user.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var auditorUserId))
          return TypedResults.Forbid();

      query = query.Where(s => s.AuditorId == auditorUserId);
  }
  ```

#### B. [SyncSubmissionsEndpointTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/SyncSubmissionsEndpointTests.cs)
- Enhanced the `SeedSubmissionAsync` helper method to support an optional `auditorId` parameter.
- Replaced the outdated `SyncSubmissions_MissingTenantScope_Returns400` test case with two focused, high-coverage scenarios:
  1. `SyncSubmissions_MissingTenantScope_NonAuditorNonAreaManager_Returns400`: Asserts that other unscoped roles (like `store_manager` without a resolved store context) still receive a `400 Bad Request`.
  2. `SyncSubmissions_AuditorUnboundedSync_Allowed_ReturnsOnlyOwnSubmissions`: Asserts that an auditor can successfully sync unbounded without a `storeId`, but only retrieves records where `AuditorId` matches their authenticated user ID.

---

## 3. Verification Results

All tests have been run and verified locally:
1. **Endpoint Tests**: `dotnet test --filter SyncSubmissionsEndpointTests`
   - **Status**: **PASS** (13/13 tests)
2. **Flutter client-side suite**: `flutter test`
   - **Status**: **PASS** (662/662 tests)
