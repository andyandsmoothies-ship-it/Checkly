---
ConversationID: 0cd4f3c3-3fc1-4825-bc0c-f9294a6e2948
---

# Implementation Plan - Slice 3: Rewrite GetBodReport.cs Live Queries

[Client (Flutter Dashboard)] ---> [GET /api/analytics/bod]
                                          |
                                          +---> [Is Global Query?]
                                          |         |
                                          |         +---> YES: Join and Query Active Stores Directly
                                          |         +---> NO: Filter using `filteredStoreIds`
                                          v
                                 [Live SQL Queries]
                        (Indexed via status & completed_at)
                                          |
                                          v
                                [IMemoryCache (60s)]

This plan describes the optimization of the live query engine inside `GetBodReport.cs` to eliminate `IN` clause database performance issues for global reports and optimize range queries to hit PostgreSQL indexes.

---

## 1. Objectives

- **Live Query Scalability**: Bypasses the memory-intensive `filteredStoreIds.Contains(...)` query pattern when `isGlobal == true` (province/district are null or empty).
- **Index Friendly**: Replaces all `(CompletedAt ?? CreatedAt)` calculations with index-friendly `CompletedAt.HasValue && CompletedAt >= ...` range filters to hit composite indices created in Slice 2.
- **Allowed Actions Verification**: Dynamically omits `"refresh"` from `allowedActions` when `isGlobal == true`.

---

## 2. Proposed Changes

### Target File: `server/Features/Analytics/GetBodReport.cs`

- Declare a boolean `isGlobal` to check if both `province` and `district` query parameters are null or empty:
  ```csharp
  var isGlobal = string.IsNullOrEmpty(province) && string.IsNullOrEmpty(district);
  ```
- Refactor the 12 dynamic queries inside `GetBodReport.cs` to use optimized database joins and query bounds:
  - Create base query builders `baseSubmissionsQuery`, `scheduledQuery`, `actionPlansQuery`, and `sectionScoresQuery` that toggle between direct active store filtering (`s.Store != null && s.Store.IsActive == true`) for global reports and memory list filtering (`filteredStoreIds.Contains(...)`) for filtered reports.
  - Rewrite range boundaries to check `s.CompletedAt.HasValue && s.CompletedAt >= start30DaysAgo` to utilize performance indexes.
  - Dynamically populate `allowedActions` with `"refresh"` only when `isGlobal` is `false`.

---

## 3. Verification & Testing Steps

- Run sequential C# testing command to verify functionality:
  ```cmd
  cmd /c rtk dotnet test --filter "Checkly.Api.Tests.Features.Analytics.BodLiveQueries_Slice1_Tests"
  ```
- Run the entire test project to ensure no regression on existing analytics tests:
  ```cmd
  cmd /c rtk dotnet test
  ```
