---
ConversationID: aa0d4917-b447-4894-b6c8-3c45d26b9ecd
---

# Test Contracts: Bod Live Queries Slice 3

This document defines the strict API contract, behavior expectations, and performance constraints for **Slice 3: Rewrite GetBodReport.cs Live Queries**.

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice3_20260601_154600.md`

---

## 1. API Contract Definition

### GET `/api/analytics/bod`

#### Query Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `province` | `string` | No | Province name to filter. If null or empty, query is global. |
| `district` | `string` | No | District name to filter. If null or empty, query is global. |

#### Allowed Actions Contract

The `allowedActions` array returned in the JSON payload must dynamically update based on whether the query parameters describe a global or filtered report:

```json
{
  "isLiveData": true,
  "kpis": { ... },
  "goldenStore": { ... },
  "trend": [ ... ],
  "topStores": [ ... ],
  "bottomStores": [ ... ],
  "weaknesses": [ ... ],
  "actionPlanAging": [ ... ],
  "auditorProductivity": [ ... ],
  "allowedActions": [] // MUST omit "refresh" when isGlobal == true; MUST include "refresh" when isGlobal == false.
}
```

---

## 2. Performance Contracts (Database Queries)

To hit database indexes and eliminate performance bottlenecks, the following C# dynamic query patterns are strictly enforced:

### A. Global vs Filtered Branching

1. **Global Queries (`isGlobal == true`)**
   - Active store query base: `s.Store != null && s.Store.IsActive == true`.
   - Bypasses the memory contains list `filteredStoreIds.Contains(...)` completely in database-level queries.

2. **Filtered Queries (`isGlobal == false`)**
   - Hitting filtered stores: `filteredStoreIds.Contains(s.StoreId.Value)`.

### B. Index-Friendly Range Bounds

- All completed submission date filters must query using the direct `CompletedAt` field:
  - **Correct**: `s.CompletedAt.HasValue && s.CompletedAt.Value >= start30DaysAgo`
  - **Incorrect**: `(s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo`

---

## 3. Approved Acceptance Criteria (Given/When/Then)

### AC-Slice3-01: Global Query Omit Refresh AllowedAction
- **Given** an authenticated administrator
- **When** calling GET `/api/analytics/bod` with both null, empty, or missing query parameters
- **Then** the API must respond with `200 OK`
- **And** the returned `allowedActions` list must **not** contain `"refresh"`

### AC-Slice3-02: Filtered Query Include Refresh AllowedAction
- **Given** an authenticated administrator
- **When** calling GET `/api/analytics/bod` with a valid `province` filter
- **Then** the API must respond with `200 OK`
- **And** the returned `allowedActions` list must **contain** `"refresh"`

### AC-Slice3-03: Global Query Active Stores Safeguard
- **Given** an active store Hanoi and an inactive store Saigon
- **When** calling GET `/api/analytics/bod` without filters (Global Query)
- **Then** the returned KPIs must only include submissions and action plans from Hanoi (active store)
- **And** the returned KPIs must completely exclude Saigon's data
