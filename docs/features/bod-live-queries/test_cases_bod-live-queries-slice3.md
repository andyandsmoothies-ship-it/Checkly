---
ConversationID: aa0d4917-b447-4894-b6c8-3c45d26b9ecd
---

# Test Cases: Bod Live Queries Slice 3

This document maps the approved acceptance criteria to concrete integration test cases.

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice3_20260601_154600.md`

---

## 1. Acceptance Criteria Mapping (Gherkin)

### TC-SL3-01: Global Query Omit Refresh
```gherkin
Given an authenticated administrator
When calling GET "/api/analytics/bod" (with or without empty province/district filters)
Then the API must respond with 200 OK
And the returned "allowedActions" list must not contain "refresh"
```

### TC-SL3-02: Filtered Query Include Refresh
```gherkin
Given an authenticated administrator
When calling GET "/api/analytics/bod?province=Hanoi"
Then the API must respond with 200 OK
And the returned "allowedActions" list must contain "refresh"
```

### TC-SL3-03: Active Stores Only Processing
```gherkin
Given store A is active and store B is inactive
And submissions and action plans exist on both stores
When calling GET "/api/analytics/bod" (Global Query)
Then the returned KPIs must count store A's data
And the returned KPIs must exclude store B's data
```

---

## 2. Smoke Gate Report

| Test Name | Status | Type | Error Summary |
|---|---|---|---|
| `GetGlobalReport_FiltersOutInactiveStoresSubmissionsAndActionPlans` | PASSED | ✅ Business | Verified active/inactive store partitioning. |
| `GetReport_AllowedActionsrefreshBehavior_OmittedOnGlobalIncludedOnFiltered` | RED | ✅ Business | Assert.Contains() Failure: Item "refresh" not found in allowedActions |
| `GetBodReportCode_DoesNotContainIndexUnfriendlyNullCoalescingOperator` | RED | ✅ Business | Assert.DoesNotContain() Failure: "CompletedAt ?? s.CreatedAt" found in code |

### Verdict
- ✅ All failing tests are `Business` failures (RED for the right reason). Test infrastructure is stable and ready for the Builder.
