## Input Lineage
- **Source Input**: `file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/implementation_plan_20260520_071500_f4b03545_sl4_pbac_purge.md`

# TDD Walkthrough - SL-4: Purge areaId fallback logic

This walkthrough explains the unit and integration tests written for the **SL-4: Purge areaId fallback logic** feature.

<forensic_evidence>
Command run: dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter SyncSubmissionsEndpointTests
Command run: dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter SubmissionAccessGuardUnitTests
Python check run: python .agents/skills/testing-strategy/verify_aaa_pattern.py server\tests\Checkly.Api.Tests\SubmissionAccessGuardUnitTests.cs
</forensic_evidence>

<test_trace>
Failing test trace captured in Red phase for SyncSubmissions_AsAreaManager_CorrectArea_Returns200. The test verifies that area managers can perform unbounded sync, which currently fails with 400 BadRequest due to missing parameters constraint.
</test_trace>

---

## 1. Tests Added / Modified

### Unit Tests (`SubmissionAccessGuardUnitTests.cs`)
We added the following unit tests to verify the `CanAccessAsync` behavior directly under the `ResourceAccessGuard`:
1. `CanAccessAsync_AreaManager_ReturnsTrue_IfInJunction`
   - **Scenario**: Area Manager requests access to a store that is explicitly assigned to them in the `ProfileStoreAssignments` table.
   - **Expectation**: `CanAccessAsync` returns `true`.
2. `CanAccessAsync_AreaManager_ReturnsFalse_IfNotInJunction`
   - **Scenario**: Area Manager requests access to a store that is NOT assigned to them in the `ProfileStoreAssignments` table, even if the profile has matching `AreaId`.
   - **Expectation**: `CanAccessAsync` returns `false` (proving that legacy fallback matching `AreaId` is ignored).

### Integration Tests (`SyncSubmissionsEndpointTests.cs`)
We verified/updated integration tests testing the delta sync endpoint `GET /api/sync/submissions`:
1. `SyncSubmissions_AsAreaManager_CorrectArea_Returns200`
   - **Scenario**: Area Manager requests an unbounded delta sync (without passing `areaId` or `storeId`).
   - **Expectation**: The request succeeds (returns `200 OK`) and automatically scopes returned submissions to their assigned stores in the junction table.
   - **Red Failure**: Fails with `400 BadRequest: "A storeId or areaId query parameter is required for non-admin callers."` because the endpoint currently requires these parameters and doesn't handle unbounded querying for area managers.

---

## 2. Command to Run Tests

Forge (or the developer) can execute these tests using standard `dotnet test`:

```powershell
# Run only sync endpoint integration tests
cmd /c dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter SyncSubmissionsEndpointTests

# Run only guard unit tests
cmd /c dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter SubmissionAccessGuardUnitTests
```

---

## 3. AAA Pattern Verification

The test suite has been statically verified and conforms perfectly to the AAA (Arrange-Act-Assert) pattern:
```powershell
cmd /c python .agents/skills/testing-strategy/verify_aaa_pattern.py server\tests\Checkly.Api.Tests\SubmissionAccessGuardUnitTests.cs
```
*Result: PASS.*

---

## Decision Log

- **Decision 1**: Enforced explicit `ProfileStoreAssignments` junction records for area managers instead of relying on legacy domain properties `AreaId`.
- **Decision 2**: Allowed unbounded synchronization (`GET /api/sync/submissions` with no filter parameters) for area managers by retrieving their assigned stores list directly in the endpoint.

---

## Verification Handoff

- **Target Code**: `server/Common/ResourceAccessGuard.cs`, `server/Features/Submissions/SyncSubmissions.cs`
- **Failing Tests (Red State)**: `SyncSubmissions_AsAreaManager_CorrectArea_Returns200`
- **TDD Checklist**:
  - Run the tests to see the expected red state failure.
  - Apply the implementation plan's architectural modifications to `ResourceAccessGuard.cs` and `SyncSubmissions.cs`.
  - Re-run the tests to see them turn green.
