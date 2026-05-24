# Test Contracts: BOD Analytics Slice 1 (Data Engine)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\bod-analytics\implementation_plan_20260524_151500_s1_bod_analytics.md`

---

## 📋 Gherkin Scenarios

### TC-SL1-01: Idempotent Snapshot Upsert
* **Source**: `implementation_plan_20260524_151500_s1_bod_analytics.md#L18`
* **Gherkin**:
  ```gherkin
  Given a daily snapshot does not exist or already exists in the database for date "2026-05-24"
  When the BodReportWorker runs the nightly computation job for "2026-05-24"
  Then a single snapshot row is saved in the database with Date = "2026-05-24" and Status = "Complete"
  And calling the computation job a second time updates the existing row rather than inserting a duplicate
  ```

### TC-SL1-02: Query Resiliency with PartiallyFailed Status
* **Source**: `implementation_plan_20260524_151500_s1_bod_analytics.md#L45`
* **Gherkin**:
  ```gherkin
  Given the daily computation job begins execution
  When one of the analytical database queries fails or throws a database timeout exception
  Then the daily snapshot is successfully saved to the database
  And the snapshot Status is marked as "PartiallyFailed"
  And the payload contains the successful queries' data with empty/safe fallbacks for the failed queries
  ```

### TC-SL1-03: Retention Pruning of Expired Snapshots
* **Source**: `implementation_plan_20260524_151500_s1_bod_analytics.md#L30`
* **Gherkin**:
  ```gherkin
  Given snapshots exist in the database with dates older than 90 days (e.g. 91 days ago) and newer than 90 days (e.g. 89 days ago)
  When the BodReportWorker executes its nightly maintenance tick
  Then all snapshot records older than 90 days are deleted from the database
  And all snapshot records newer than or equal to 90 days remain untouched
  ```

### TC-SL1-04: Distributed Advisory Locking (Concurrency Safeguard)
* **Source**: `implementation_plan_20260524_151500_s1_bod_analytics.md#L55`
* **Gherkin**:
  ```gherkin
  Given another instance of BodReportWorker or an active database connection holds the transaction-scoped advisory lock for the scope "Checkly.BodReportWorker"
  When the nightly computation job is triggered on the current worker
  Then the current worker fails to acquire the advisory lock
  And the current worker immediately skips execution without running the OLAP queries or modifying database snapshots
  ```

### TC-SL1-05: Timezone-Aware Corporate Date Derivation
* **Source**: `implementation_plan_20260524_151500_s1_bod_analytics.md#L62`
* **Gherkin**:
  ```gherkin
  Given the daily computation job is triggered at a specific UTC timestamp "2026-05-24T19:30:00Z"
  When resolving the local corporate date for the configured timezone "Asia/Ho_Chi_Minh" (UTC+7)
  Then the derived corporate DateOnly is resolved to "2026-05-25"
  And resolving the date for timezone "US/Eastern" (UTC-4) resolves to "2026-05-24"
  ```

### TC-SL1-06: Static Capability and Seeding for Admin Role
* **Source**: `GEMINI.md#Governance Rules`
* **Gherkin**:
  ```gherkin
  Given the application bootstrap sequence executes
  When role-based access control and system database seeding is completed
  Then a static action constant "analytics:bod" is defined in AppCapabilities
  And the "admin" role is successfully mapped to the "analytics:bod" capability in the database
  ```

### TC-SL1-07: Timezone Fallback Resilience (Gap Analysis Edge-Case 1)
* **Source**: Gap Analysis - Resiliency Against Malformed System Configuration
* **Gherkin**:
  ```gherkin
  Given the corporate timezone configuration is set to an invalid or unsupported string "Invalid/TimeZone_Name"
  When the nightly job initializes
  Then the worker falls back gracefully to a default timezone (e.g. UTC or local timezone)
  And the worker executes the job successfully without crashing or halting the service
  ```

### TC-SL1-08: Empty Database Graceful Aggregation (Gap Analysis Edge-Case 2)
* **Source**: Gap Analysis - Zero Submissions Boundary Safeguard
* **Gherkin**:
  ```gherkin
  Given there are zero submissions, action plans, or stores in the database
  When the nightly computation job runs
  Then the job completes successfully with Status = "Complete"
  And the snapshot payload is written with safe aggregate defaults (e.g. TotalAudits = 0, AvgScore = 0.0)
  ```
