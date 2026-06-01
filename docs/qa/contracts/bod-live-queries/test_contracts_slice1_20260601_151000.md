# Test Contracts: BOD Live Queries Slice 1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice1_20260601_145500.md`

---

## 1. Acceptance Criteria & Gherkin Scenarios

### Scenario 1: Deletion of Refresh API (TC-SL1-03)
**Description:** Verifies that the manual refresh endpoint `POST /api/analytics/bod/refresh` is deleted and returns 404 Not Found.

```gherkin
Given an authenticated administrator
When hitting "POST /api/analytics/bod/refresh"
Then it should return HTTP 404 Not Found
```

---

### Scenario 2: Global Live Fallback on Empty Database (TC-SL1-04)
**Description:** Verifies that when the database is empty, the global analytics GET endpoint `/api/analytics/bod` returns `200 OK` with zeroed KPIs and `isLiveData: true` (instead of the previous snapshot-not-found 404 error).

```gherkin
Given an empty database with no stores or submissions
And an authenticated administrator
When hitting "GET /api/analytics/bod" without province or district filters
Then it should return HTTP 200 OK
And the response "isLiveData" should be true
And the KPI metrics (totalAudits, avgScore, completionRate, etc.) should be zeroed
And "allowedActions" should be empty (omitting "refresh")
```

---

### Scenario 3: Global Live Fallback with Seeded Submissions (TC-SL1-04)
**Description:** Verifies that the global GET endpoint correctly calculates and returns live data from the database.

```gherkin
Given a store is seeded in the database
And a completed submission with a total score of 90.0 is seeded
And an open action plan is seeded
And an authenticated administrator
When hitting "GET /api/analytics/bod" without province or district filters
Then it should return HTTP 200 OK
And the response "isLiveData" should be true
And the KPI metrics (totalAudits = 1, avgScore = 90.0, openActionPlans = 1) should match the live values
And "allowedActions" should not contain "refresh"
```

---

## 2. Test Infrastructure Map

### Helper Methods
- `LoginBootstrapAdminAsync(HttpClient)`: Logs in as seed administrator and returns JWT token.
- `CreateAuthenticatedClient(string token)`: Returns authenticated `HttpClient` using Bearer authentication.

### Expected JSON Payload Schema (GET /api/analytics/bod)
```json
{
  "isLiveData": true,
  "kpis": {
    "totalAudits": 1,
    "avgScore": 90.0,
    "completionRate": 100.0,
    "openActionPlans": 1,
    "overdueActionPlans": 0,
    "activeStores": 1,
    "totalAuditors": 1,
    "avgTtrDays": 0.0,
    "geofenceBypassCount": 0
  },
  "goldenStore": {
    "storeName": "Store Name",
    "avgScore": 90.0,
    "province": "Province Name"
  },
  "trend": [
    {
      "month": "2026-06",
      "avgScore": 90.0,
      "auditCount": 1
    }
  ],
  "topStores": [
    {
      "storeId": "store-guid",
      "storeName": "Store Name",
      "avgScore": 90.0,
      "auditCount": 1,
      "lastSyncedAt": null
    }
  ],
  "bottomStores": [
    {
      "storeId": "store-guid",
      "storeName": "Store Name",
      "avgScore": 90.0,
      "auditCount": 1,
      "lastSyncedAt": null
    }
  ],
  "weaknesses": [],
  "actionPlanAging": [
    {"bucket": "0-7d", "count": 1},
    {"bucket": "8-30d", "count": 0},
    {"bucket": "31-90d", "count": 0},
    {"bucket": "90d+", "count": 0}
  ],
  "auditorProductivity": [
    {
      "auditorId": "auditor-guid",
      "auditorName": "Auditor Name",
      "completedAudits": 1,
      "avgScore": 90.0
    }
  ],
  "allowedActions": []
}
```
