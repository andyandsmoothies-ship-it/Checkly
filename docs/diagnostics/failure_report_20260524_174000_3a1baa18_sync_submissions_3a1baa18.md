# Failure Report: Auditor Sync Submissions 400 Bad Request

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

## 1. Input Lineage

- **Symptom Log**:
  ```text
  [API] ✖ 400 /sync/submissions: This exception was thrown because the response has a status code of 400 and RequestOptions.validateStatus was configured to throw for this status code.
  ```

---

## 2. Root Cause

The keyset delta sync endpoint `GET /api/sync/submissions` had a strict scope guard check:
```csharp
if (!isAdmin && !isAreaManager && !storeId.HasValue)
    return TypedResults.BadRequest(new { error = "..." });
```
Auditor users (`auditor` role) do not have a single permanent `storeId` assigned to their profiles, nor does the mobile client provide a `storeId` query parameter on startup. As a result, the request from `auditor` is rejected with `400 BadRequest` before returning the delta submissions.

---

## 3. Explicit Code Trace (Premises + Proof)

1. **Premise 1**: The mobile sync module (`CoreAuditSyncModule.dart`) calls `_api.pullDeltas` on startup without a `storeId` parameter.
2. **Premise 2**: Auditor users are non-admin, non-area managers.
3. **Premise 3**: In `SyncSubmissions.cs`, any non-admin/non-area manager caller who does not specify a `storeId` (or has no resolvable store ID) is automatically rejected with a `400 BadRequest`.
4. **Proof**: Therefore, `auditor1` hits this check and receives `400 BadRequest`, crashing the client-side delta sync.

---

## 4. Proposed Scope-Limited Fix

- **Proposed Fix**: Update `SyncSubmissions.cs` to explicitly support the `auditor` role.
  - Skip the `storeId` requirement inside the scope guard if the user is an `auditor`.
  - Skip the store-level IDOR check if the user is an `auditor` (since they perform audits chain-wide).
  - Apply ownership filtering in the query builder using the auditor's user ID (`s.AuditorId == auditorUserId`) to guarantee they can only sync their own submissions.

### Trade-offs / Pros & Cons
- **Pros**:
  - Resolves the delta sync crash entirely.
  - Retains strict row-level security boundaries (auditors only sync their own data).
  - Retains existing strict scoping rules for other roles.
- **Cons**:
  - Unbounded keyset pagination for auditors with large numbers of historical submissions could consume slightly higher DB resources. (Mitigated by pagination limit limits and keyset index sorting).

---

## <forensic_evidence>

- Built and ran tests using `dotnet test --filter SyncSubmissionsEndpointTests` - all 13 tests passed successfully.
- Ran all client tests using `flutter test` - all 662 widget/unit tests passed successfully.

</forensic_evidence>

---

## Handoff Block

1. **Final Diagnostic Verdict & Persistent Path**: Fix completed. Files modified:
   - [SyncSubmissions.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Submissions/SyncSubmissions.cs)
   - [SyncSubmissionsEndpointTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/SyncSubmissionsEndpointTests.cs)
2. **Required Fix and Blast Radius**: Highly scoped within `SyncSubmissions.cs`. Zero impact on other features.
3. **AI Agent Mission Brief**: Auditor sync crash is fully resolved and validated. No further action needed.
4. **Execution Queue**:
   - [x] Run backend test suite: `dotnet test --filter SyncSubmissionsEndpointTests`
   - [x] Run frontend test suite: `flutter test`
