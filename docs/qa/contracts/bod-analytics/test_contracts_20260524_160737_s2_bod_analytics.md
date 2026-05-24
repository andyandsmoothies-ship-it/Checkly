# Test Contracts: BOD Analytics Slice 2 API Gateway
Feature: Board of Directors Analytics API Gateway

## TC-SL2-01: Admin role can successfully fetch latest snapshot
```gherkin
Scenario: Admin fetches the latest complete BOD snapshot successfully
  Given a user with the role "admin" is logged in
  And the capability "analytics:bod" is assigned to the "admin" role
  And there is a completed BOD snapshot dated "2026-05-24" in the database
  When the user sends a GET request to "/api/analytics/bod"
  Then the response status code should be 200 OK
  And the response body should contain the status "Complete"
  And the response body should contain the computed snapshot date "2026-05-24"
```

## TC-SL2-02: Non-admin user gets 403 Forbidden on fetch/refresh
```gherkin
Scenario: Auditor user tries to fetch BOD snapshot and gets forbidden
  Given a user with the role "auditor" is logged in
  And the capability "analytics:bod" is not assigned to the "auditor" role
  When the user sends a GET request to "/api/analytics/bod"
  Then the response status code should be 403 Forbidden

Scenario: Auditor user tries to trigger manual refresh and gets forbidden
  Given a user with the role "auditor" is logged in
  And the capability "analytics:bod" is not assigned to the "auditor" role
  When the user sends a POST request to "/api/analytics/bod/refresh"
  Then the response status code should be 403 Forbidden
```

## TC-SL2-03: Fetch returns 404 when database has no snapshots
```gherkin
Scenario: Admin tries to fetch BOD snapshot but the database is empty
  Given a user with the role "admin" is logged in
  And the capability "analytics:bod" is assigned to the "admin" role
  And the BOD snapshots table in the database is completely empty
  When the user sends a GET request to "/api/analytics/bod"
  Then the response status code should be 404 Not Found
  And the response JSON should match:
    """
    {
      "error": "No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM."
    }
    """
```

## TC-SL2-04: Fetch deserializes and returns full nested KPIs
```gherkin
Scenario: Admin retrieves the snapshot and parses the full KPI and leaderboard dashboard structure
  Given a user with the role "admin" is logged in
  And the capability "analytics:bod" is assigned to the "admin" role
  And a valid complete BOD snapshot is populated in the database
  When the user sends a GET request to "/api/analytics/bod"
  Then the response status code should be 200 OK
  And the response payload should contain deserialized KPI metrics, topStores, bottomStores, weaknesses, actionPlanAging, and auditorProductivity
```

## TC-SL2-05: Refresh returns 429 when triggered twice within 15 mins
```gherkin
Scenario: Admin triggers a manual refresh and then immediately triggers another refresh
  Given a user with the role "admin" is logged in
  And the capability "analytics:bod" is assigned to the "admin" role
  And the manual refresh lock is free and last run was over 15 minutes ago
  When the user sends a POST request to "/api/analytics/bod/refresh"
  Then the response status code should be 200 OK
  And the response body should contain status "triggered"
  When the user sends a POST request to "/api/analytics/bod/refresh" again within 15 minutes
  Then the response status code should be 429 Too Many Requests
  And the response JSON should match:
    """
    {
      "status": "rate_limited",
      "retryAfter": "15 min"
    }
    """
```

## TC-SL2-06: Refresh respects DistributedLock concurrent checks
```gherkin
Scenario: Admin triggers a manual refresh but a concurrent calculation is already running in background
  Given a user with the role "admin" is logged in
  And the capability "analytics:bod" is assigned to the "admin" role
  And the PostgreSQL advisory lock "Checkly.BodReportWorker" is already acquired by another process
  When the user sends a POST request to "/api/analytics/bod/refresh"
  Then the response status code should be 400 Bad Request or 409 Conflict
  And the response JSON should contain error "Another refresh job is already in progress."
```
