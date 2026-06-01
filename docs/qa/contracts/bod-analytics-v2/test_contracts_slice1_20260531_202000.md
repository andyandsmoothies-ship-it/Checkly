---
conversation_id: "e4a8d231-abcb-46c0-ae41-613c2d8ed2c0"
created_at: "2026-05-31T20:20:00+07:00"
topic: "bod-analytics-v2"
type: "contracts"
status: "IN_PROGRESS"
---

# Test Contracts: Area Manager BOD Dashboard | Slice 1

## Input Lineage

- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-analytics-v2\implementation_plan_bod-analytics-v2-slice1_20260531_201046.md`

## 1. Specifications & Acceptance Criteria

All scenarios are written in strict Gherkin format to outline clear expectations.

### Scenario 1: Access Denied for Unauthorized Users (Auth Guard)
- **Gherkin**:
  - `Given` a user who is NOT authenticated
  - `Or` a user authenticated with the role `"auditor"` without the `"analytics:area"` capability
  - `When` they perform a `GET` request to `/api/analytics/bod/area`
  - `Then` the system must return `401 Unauthorized` or `403 Forbidden` response

### Scenario 2: Empty Tenancy Store Assignment (Zero State)
- **Gherkin**:
  - `Given` an authenticated user with `"area_manager"` role having the `"analytics:area"` capability
  - `And` this user is NOT assigned to any store in `ProfileStoreAssignments`
  - `When` they perform a `GET` request to `/api/analytics/bod/area`
  - `Then` the response status must be `200 OK`
  - `And` the payload must contain zeroed KPIs:
    - `totalAudits = 0`
    - `avgScore = 0.0`
    - `completionRate = 0.0`
    - `openActionPlans = 0`
    - `overdueActionPlans = 0`
    - `activeStores = 0`
    - `totalAuditors = 0`
    - `avgTtrDays = 0.0`
  - `And` list collections like `trend`, `topStores`, `bottomStores`, and `weaknesses` must be returned as empty arrays

### Scenario 3: Strict Store Tenancy Isolation (Data Partitioning)
- **Gherkin**:
  - `Given` Store A (active) and Store B (active) exist in the database
  - `And` Area Manager 1 is assigned to Store A
  - `And` Area Manager 2 is assigned to Store B
  - `And` Store A has a completed audit in the last 30 days with a total score of `85.0`
  - `And` Store B has a completed audit in the last 30 days with a total score of `95.0`
  - `When` Area Manager 1 requests the Area BOD report
  - `Then` the response status must be `200 OK`
  - `And` the KPIs must reflect ONLY Store A's data:
    - `totalAudits = 1`
    - `avgScore = 85.0`
  - `And` Store B's data must be completely excluded (isolation verify)

### Scenario 4: Calculation Engine Validation (KPI Metrics)
- **Gherkin**:
  - `Given` Store A and Store B are assigned to Area Manager 1
  - `And` Store A has 2 completed audits in the last 30 days (scores `80.0` and `90.0`)
  - `And` Store B has 1 completed audit in the last 30 days (score `70.0`)
  - `And` Store A has 1 open Action Plan (created 5 days ago)
  - `And` Store B has 1 open Action Plan (created 10 days ago, past deadline)
  - `When` Area Manager 1 requests the Area BOD report
  - `Then` the response status must be `200 OK`
  - `And` KPIs must be aggregated correctly:
    - `totalAudits = 3`
    - `avgScore = 80.0` ((80 + 90 + 70) / 3)
    - `openActionPlans = 2`
    - `overdueActionPlans = 1`
  - `And` the Action Plan Aging buckets must distribute correctly:
    - `"0-7d"` bucket must have `1` count (Store A)
    - `"8-30d"` bucket must have `1` count (Store B)

### Scenario 5: Exclude Inactive Stores from Dashboard Analytics (Gap AC 1)
- **Gherkin**:
  - `Given` Store A is active (`IsActive == true`)
  - `And` Store B is inactive (`IsActive == false`)
  - `And` Both stores are assigned to Area Manager 1
  - `And` Store A has a completed audit with a score of `80.0`
  - `And` Store B has a completed audit with a score of `95.0`
  - `When` Area Manager 1 requests the Area BOD report
  - `Then` the response status must be `200 OK`
  - `And` `activeStores` count must be `1` (Store A only)
  - `And` `totalAudits` count must be `1` (Store A only)
  - `And` `avgScore` must be `80.0` (excluding Store B entirely)

### Scenario 6: Exclude Rejected Reviews handling Postgres Null inequality (Gap AC 2)
- **Gherkin**:
  - `Given` Store A is assigned to Area Manager 1
  - `And` Store A has 3 completed audits:
    - Audit 1: ReviewStatus is `null`, score `80.0`
    - Audit 2: ReviewStatus is `"approved"`, score `90.0`
    - Audit 3: ReviewStatus is `"rejected"`, score `95.0`
  - `When` Area Manager 1 requests the Area BOD report
  - `Then` the response status must be `200 OK`
  - `And` `totalAudits` count must be `2` (excluding the rejected audit)
  - `And` `avgScore` must be `85.0` ((80.0 + 90.0) / 2)

---

## 2. Test Infrastructure Map

### Helper Methods
| Method | Signature | Behavior |
|--------|-----------|----------|
| `EnsureDatabaseCreated` | `void` | Truncates relevant tables and seeds bootstrap credentials. |
| `RegisterUserAsync` | `Task<(string, Guid)>` | Creates a test user under specified role and returns token + Id. |
| `CreateAuthenticatedClient` | `HttpClient` | Wraps HttpClient with authentication Bearer token. |

### Test Database Context
- **Name**: `checkly_test` (safeguarded logic verified on startup).
- **Cleanup**: Pre-test execution TRUNCATE tables: `action_plans`, `submissions`, `stores`, `profile_store_assignments`, `profiles`.

### JSON Mapping Contracts
- **PascalCase vs camelCase**: Serialization matches camelCase via API configuration settings.
