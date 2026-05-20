# Walkthrough: SL-2 Phase B2 (Server API Layer)

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260519_075200_sl2_province_benchmark.md`

## Decision Log
- **GetAnalyticsInsightsResolver.cs Extraction (Proposed & Implemented)**: To avoid AI context collapse on the `GetAnalytics.cs` file (which would have exceeded 400 lines), I separated the insight aggregation and radar calculations into an isolated static resolver class.
- **Backward Compatibility (Proposed & Implemented)**: Rather than breaking existing mobile clients that send `?areaId=xxx`, I modified `GetAreaLeaderboard.cs` to resolve either `areaId` (legacy) or `province` (new slice 2 logic). If an areaId is provided, the API looks up the area to determine its province, then delegates back to the province logic.
- **Test Sandbox Collision Fix (Implemented)**: Tests were failing intermittently when setting up stores for identical province names due to a unique composite index. To guarantee test idempotency, I appended random `Guid.NewGuid()` suffixes to province names in tests.

## Verification Handoff
1. All Server API components for `GetAreaLeaderboard` and `GetAnalytics` use the newly resolved Province filtering mechanisms.
2. The UI developer can now confidently send `?province=Da Nang` instead of `?areaId=...` in their API clients (Phase B3).
3. The returned leaderboard DTO contains both `id` and `storeId` keys for graceful degradation of Flutter clients parsing JSON.

<test_trace>
Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:   537, Skipped:     7, Total:   544, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
Executed `rtk dotnet test server/tests/Checkly.Api.Tests`
</forensic_evidence>

## Gotcha Protocol
- **Gotcha Proposed**: In `server/GEMINI.md` -> Integration Test Sandbox Collisions on Stores. When creating new Store entities during integration tests, ensure that `AddressProvince` fields receive unique suffixes (e.g. `Province = $"HCM-{Guid.NewGuid()}"`) if testing grouped queries, to avoid duplicate state collisions on parallel test runners accessing the shared local Postgres schema.
