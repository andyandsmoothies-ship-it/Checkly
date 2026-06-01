---
ConversationID: 326acb94-76b9-487a-9906-54fa1bd07b9b
---

# Slice 3 Task: Rewrite GetBodReport Live Queries

```
 [Client API Call] ---> [GET /api/analytics/bod]
                             |
                             +---> If IsGlobal == true
                             |         |
                             |         +---> Join active stores directly in DB (O(1) memory)
                             |         +---> Omit "refresh" allowed action
                             |
                             +---> Else (Region/Store filter)
                                       |
                                       +---> Filter by memory IDs list
                                       +---> Include "refresh" allowed action
                             |
                             v
              [Index-Friendly Range Queries]
      (Explicit OR checks on CompletedAt & CreatedAt)
```

## 1. Executive Summary
The acceptance tests and production code for **BOD Live Queries - Slice 3** have been fully implemented, verified, and certified. All queries have been rewritten to hit high-efficiency database indexes, and memory footprint has been optimized to O(1) for global reporting routes.

---

## 2. Builder Implementation Checklist

- [x] **Identify Global Query Path**: Determine if the query filters by a specific store/region or spans across all stores (global query).
- [x] **Optimize Global Store Filtration**:
  - For global query routes, avoid loading and executing memory-intensive `filteredStoreIds.Contains(...)` checks.
  - Join the `Store` navigation property directly in the SQL query and filter on `Store.IsActive == true`.
- [x] **Rewrite Date Boundary Queries**:
  - Locate all queries using null-coalescing operations (e.g. `CompletedAt ?? CreatedAt`).
  - Rewrite these expressions into explicit logical OR range checks (e.g., `(s.CompletedAt.HasValue && s.CompletedAt >= start && s.CompletedAt <= end) || (!s.CompletedAt.HasValue && s.CreatedAt >= start && s.CreatedAt <= end)`).
- [x] **Exclude "refresh" Action for Global Queries**:
  - Dynamically construct the `allowedActions` DTO list.
  - Omit the `"refresh"` string action for global reporting queries.
  - Include the `"refresh"` string action only when regional or store-level filters are active.

---

## 3. Key Files Reference

### Verification Test File
* [BodLiveQueries_Slice3_Tests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/BodLiveQueries_Slice3_Tests.cs) (Contains the dynamic integration tests proving active store filtration, dynamic allowed actions, and query index performance)

### Modified Production Files
* [GetBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/GetBodReport.cs) (Rewrote dynamic live query paths for global/filtered plans)

---

## 4. Verification Commands

Run the targeted Slice 3 integration tests to confirm compliance:
```powershell
rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter BodLiveQueries_Slice3_Tests
```
