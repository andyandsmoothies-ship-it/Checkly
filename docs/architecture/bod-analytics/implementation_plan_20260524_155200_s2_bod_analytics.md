<latent_space_scratchpad>
This is the implementation plan for Slice 2 — API Gateway.
The goal is to implement the C# backend minimal API endpoints for BOD report retrieval and manual triggering, secured via PBAC capability "analytics:bod" (gated for 'admin').

Let's double-check all edge cases:
- GET /api/analytics/bod must retrieve the most recent complete (or partially failed) snapshot. If no snapshot is generated, return 404 with standard message.
- POST /api/analytics/bod/refresh must trigger the nightly computation. To do this securely without double computation or database hammering, it will rate-limit to 1 per 15 minutes by tracking in-memory `_lastManualRun` inside `BodReportWorker`.
- To share worker state cleanly in .NET, the `BodReportWorker` should be registered as a Singleton, and `IHostedService` registration should resolve from it:
  ```csharp
  builder.Services.AddSingleton<BodReportWorker>();
  builder.Services.AddHostedService<BodReportWorker>(sp => sp.GetRequiredService<BodReportWorker>());
  ```
  Wait! Let's verify if `BodReportWorker` registration in `Program.cs` needs to be updated. Yes, that is a modified file.
- If refresh is rate-limited, return HTTP 429 and JSON body `{ "status": "rate_limited", "retryAfter": "15 min" }`.
- If another refresh is already running, return HTTP 409 Conflict or 400 Bad Request with "Another refresh job is already in progress.". Let's use 400 Bad Request `{ "error": "Another refresh job is already in progress." }` to keep it clean.
- Gating: Gated by `AppCapabilities.AnalyticsBod` capability. In C# this translates to `.RequireCapability(AppCapabilities.AnalyticsBod)` which enforces the role check based on seeded PBAC roles.
- Tests will prove:
  - Admin (possessing `analytics:bod` capability) can retrieve the report (HTTP 200).
  - Admin can trigger refresh successfully (HTTP 200).
  - Calling refresh a second time within 15 minutes returns HTTP 429.
  - Non-admin role (e.g. area_manager/auditor) receives HTTP 403 Forbidden for both endpoints.
  - Empty database returns HTTP 404.
</latent_space_scratchpad>

## Input Lineage
- **Epic Plan**: `file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/bod-analytics/analysis_epic_20260524_142100_bod_analytics.md`

## Executive Summary & Out of Scope
This implementation plan outlines the steps to build and secure the API endpoints for the Board of Directors (BOD) Analytics.
- **In Scope**:
  - GET `/api/analytics/bod`: Securely retrieves and deserializes the latest completed/partially failed `BodReportSnapshot`.
  - POST `/api/analytics/bod/refresh`: Gated behind admin capability, triggers manual snapshot recalculation with a 15-minute rate limit.
  - Refactoring hosted service registration in `Program.cs` so `BodReportWorker` state (specifically the last manual refresh timestamp) can be shared and resolved from the API endpoint handler.
  - Comprehensive integration tests using `TestWebApplicationFactory`.
- **Out of Scope**:
  - Flutter frontend changes (this is Slice 3).
  - Modifying the underlying calculation queries (built in Slice 1).

## System Context
- **Offline/Online**: This feature is purely online-only. Both endpoints fail immediately if the connection to the PostgreSQL database is unavailable.
- **RBAC/PBAC**: Access is strictly gated by the PBAC capability `analytics:bod` (`AppCapabilities.AnalyticsBod`), which default-seeds only for the `admin` role. Non-admin users (e.g., area managers, auditors) receive `403 Forbidden`.
- **Concurrency & Lock Guard**: The manual refresh endpoint leverages `DistributedLockManager` to lock the key `"Checkly.BodReportWorker"` in a PostgreSQL advisory lock, preventing race conditions or concurrent recalculation runs.

## Lifecycle Context
- **Empty State**: When no snapshot exists in the database, `GET /api/analytics/bod` returns `404 Not Found` with a helpful payload: `{ "error": "No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM." }`.
- **Success State**: When a completed snapshot exists, returns `200 OK` with full KPI, leaderboards, weakness, aging, and auditor metrics.
- **PartiallyFailed State**: If a snapshot was generated with partial query failures, returns `200 OK` alongside a warning status flag (`Status = PartiallyFailed`).
- **Rate-Limited State**: Tapping refresh within 15 minutes of the last run returns `429 Too Many Requests` with a descriptive JSON payload: `{ "status": "rate_limited", "retryAfter": "15 min" }`.

## Constraint Traceability

| Constraint | Source Document / Rule | Test Contract ID |
|---|---|---|
| Admin-only authorization check | `GET` and `POST` require `analytics:bod` | TC-SL2-01, TC-SL2-02 |
| Endpoint returns 404 when no snapshot exists | Empty DB scenario | TC-SL2-03 |
| Snapshot status Complete/PartiallyFailed returned | DTO requirements | TC-SL2-04 |
| Rate-limiting 1 refresh every 15 minutes | In-memory `_lastManualRun` constraint | TC-SL2-05 |
| Concurrent refresh lock protection | Lock manager requirement | TC-SL2-06 |

## Test Contracts

| ID | Description | State Matrix / Inputs | Why it fails first |
|---|---|---|---|
| **TC-SL2-01** | Admin role can successfully fetch latest snapshot | Requires Admin Client, 1 Seeded snapshot | 404 Not Found (endpoint not registered) |
| **TC-SL2-02** | Non-admin user gets 403 Forbidden on fetch/refresh | Requires Area Manager Client | 404 or 200 instead of 403 |
| **TC-SL2-03** | Fetch returns 404 when database has no snapshots | Requires Admin Client, empty snapshot table | 500 or Empty instead of 404 |
| **TC-SL2-04** | Fetch deserializes and returns full nested KPIs | Requires Admin Client, 1 Seeded payload | Malformed JSON or 500 error |
| **TC-SL2-05** | Refresh returns 429 when triggered twice within 15 mins | Requires Admin Client, consecutive triggers | Returns 200 on second trigger |
| **TC-SL2-06** | Refresh respects DistributedLock concurrent checks | Requires Admin Client, concurrent trigger execution | Lock violation or deadlock |

## Test Fixture & Payloads
Seeded state in `TestWebApplicationFactory`:
- Bootstrap Admin (`bootstrap@admin.test` / `Bootstrap123!@` / Role `admin`)
- `analytics:bod` capability default-seeded for `admin`.

### GET `/api/analytics/bod`
**Request Headers**:
```http
Authorization: Bearer <Admin_Token>
```
**Response Payload (200 OK)**:
```json
{
  "date": "2026-05-24",
  "computedAt": "2026-05-24T02:15:00Z",
  "status": "Complete",
  "kpis": {
    "totalAudits": 45,
    "avgScore": 84.5,
    "avgScoreDelta": 2.1,
    "completionRate": 92.5,
    "completionRateDelta": -1.2,
    "openAPs": 12,
    "overdueAPs": 3,
    "activeStores": 8,
    "totalAuditors": 4
  },
  "trend": [
    {
      "month": "2026-01",
      "avgScore": 80.0,
      "auditCount": 35
    }
  ],
  "topStores": [
    {
      "storeName": "Store A",
      "province": "Danang",
      "avgScore": 92.0,
      "auditCount": 12,
      "rank": 1
    }
  ],
  "bottomStores": [
    {
      "storeName": "Store B",
      "province": "Danang",
      "avgScore": 75.0,
      "auditCount": 8,
      "rank": 8
    }
  ],
  "weaknesses": [
    {
      "categoryName": "Cleanliness",
      "failCount": 18,
      "totalChecks": 120,
      "failRate": 15.0
    }
  ],
  "actionPlanAging": [
    {
      "bucket": "0-7 days",
      "count": 5
    }
  ],
  "auditorProductivity": [
    {
      "auditorName": "John Doe",
      "auditCount": 15,
      "avgScore": 86.0
    }
  ]
}
```

### POST `/api/analytics/bod/refresh`
**Response Payload (200 OK)**:
```json
{
  "status": "triggered",
  "computedAt": "2026-05-24T08:30:00.123456Z"
}
```
**Response Payload (429 Too Many Requests)**:
```json
{
  "status": "rate_limited",
  "retryAfter": "15 min"
}
```

## Tools & Commands
- **Testing framework**: xUnit, WebApplicationFactory, Npgsql.
- **Verification Command**:
  ```bash
  rtk dotnet test --filter "Checkly.Api.Tests.Features.Analytics.BodAnalyticsEndpointTests"
  ```

## Proposed Changes

| File | Status | Description |
|---|---|---|
| `server/Features/Analytics/GetBodReport.cs` | **[NEW]** | Handles the GET endpoint, fetching the latest snapshot. |
| `server/Features/Analytics/RefreshBodReport.cs` | **[NEW]** | Handles the POST manual trigger endpoint. |
| `server/Features/Analytics/AnalyticsEndpoints.cs` | **[MOD]** | Maps GET `/bod` and POST `/bod/refresh` routes. |
| `server/Program.cs` | **[MOD]** | Configures `BodReportWorker` as a Shared Singleton DI service. |
| `server/Features/Analytics/BodReportWorker.cs` | **[MOD]** | Implements the shared rate-limiting, lock acquisition, and calculation trigger logic. |
| `server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsEndpointTests.cs` | **[NEW]** | Integration tests confirming all Slice 2 acceptance criteria. |

## Concept Diagram

```
                ┌───────────────────────────────────┐
                │        Client / Flutter App       │
                └─────────────────┬─────────────────┘
                                  │
      GET /api/analytics/bod      │      POST /api/analytics/bod/refresh
     ┌────────────────────────────┼────────────────────────────┐
     │                            │                            │
     ▼                            ▼                            ▼
┌──────────────────┐    ┌──────────────────┐    ┌─────────────────────────────────┐
│ Analytics Router │    │  Auth Policy Check│    │        Analytics Router         │
│  (GetBodReport)  │    │ (analytics:bod)  │    │       (RefreshBodReport)        │
└────────┬─────────┘    └──────────────────┘    └────────────────┬────────────────┘
         │                                                       │
         ▼                                                       ▼
┌──────────────────┐                                    ┌──────────────────┐
│ AppDbContext     │                                    │ BodReportWorker  │
│  (Read Snapshot) │                                    │ (Rate Limit /    │
└──────────────────┘                                    │ Lock Guard)      │
                                                        └────────┬─────────┘
                                                                 │
                                                                 ▼
                                                        ┌──────────────────┐
                                                        │ BodReportWorker  │
                                                        │ (Trigger Compute)│
                                                        └──────────────────┘
```

## Risk Assessment
The following security and performance risks are carefully analyzed and mitigated:
- **Rate-Limiting**: To prevent API hammers/DDoS, `_lastManualRun` is tracked in the Singleton hosted service memory and rejects requests within 15 minutes of the last run.
- **Concurrent Execution Lock**: Using postgres advisory lock `Checkly.BodReportWorker` avoids race conditions where two admins double-trigger the worker concurrently.
- **PBAC Isolation**: Custom capability `analytics:bod` is restricted solely to the `admin` role, preventing unauthorized access from lower-privilege users.

## Verification Plan
We will verify Slice 2 implementation by writing and executing integration tests:
- **TC-SL2-01**: Admin role can successfully fetch latest snapshot (200 OK).
- **TC-SL2-02**: Non-admin user gets 403 Forbidden on fetch/refresh.
- **TC-SL2-03**: Fetch returns 404 when database has no snapshots.
- **TC-SL2-04**: Fetch deserializes and returns full nested KPIs correctly.
- **TC-SL2-05**: Refresh returns 429 when triggered twice within 15 mins.
- **TC-SL2-06**: Refresh respects DistributedLock concurrent checks.

## Execution Slices

### Slice 2 — API Gateway (Micro-Spec)
- **Value Delivered**: Provides a secure door to retrieve pre-computed BOD dashboard data instantly, and an escape hatch for admins to refresh the data on demand safely.
- **Complexity**: Medium. Requires thread-safe background service triggering and custom rate limit state mapping.
- **Entry State**: Slice 1 backend calculator is fully complete.
- **Exit State**: Both `GET` and `POST` endpoints are fully working, verified by high-coverage automated integration tests.
- **Micro-Spec Acceptance Criteria**:
  - `[AC-1]` `GET /api/analytics/bod` retrieves latest snap (200 OK) for admin.
  - `[AC-2]` `GET /api/analytics/bod` returns 404 with standard message if snapshot table is empty.
  - `[AC-3]` `GET` and `POST` return 403 for non-admins (e.g. area_manager).
  - `[AC-4]` `POST /api/analytics/bod/refresh` triggers job and returns 200 on first call.
  - `[AC-5]` `POST` returns 429 with custom JSON `{ "status": "rate_limited", "retryAfter": "15 min" }` on subsequent calls within 15 minutes.
  - `[AC-6]` `POST` respects advisory lock so concurrent requests get rejected cleanly rather than double running.

<command_logs>
- Viewed AnalyticsEndpoints.cs
- Viewed AppCapabilities.cs
- Viewed AppDbContext.cs
</command_logs>

## Handoff Block
- Execute Slice 2 ONE step at a time:
  1. Write C# integration tests in `BodAnalyticsEndpointTests.cs` matching all 6 acceptance criteria.
  2. Implement DI updates in `Program.cs`.
  3. Implement rate-limiting and TriggerOnDemandAsync inside `BodReportWorker.cs`.
  4. Implement `GetBodReport.cs` and `RefreshBodReport.cs` handler endpoints.
  5. Register the new endpoints in `AnalyticsEndpoints.cs`.
  6. Run `rtk dotnet test` and confirm all tests pass successfully.
