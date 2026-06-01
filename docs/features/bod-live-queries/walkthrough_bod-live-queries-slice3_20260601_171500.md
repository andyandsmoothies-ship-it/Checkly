# Walkthrough: BOD Live Queries Slice 3 (Live Query Execution Engine Optimization)

---

## 1. Executive Summary
This walkthrough documents the successful implementation and verification of **Slice 3 (Live Query Execution Engine Optimization)** for the Boardroom Analytics Live Queries epic. The live query generation engine in `GetBodReport.cs` has been refactored to eliminate major performance bottlenecks, memory pressure, and index suppression. 

Furthermore, dynamic contextual permissions were introduced to suppress the `"refresh"` capability on global, expensive dashboard routes while preserving it for targeted regional views.

---

## 2. Structural & Architectural Design
To handle high concurrent traffic on boardroom dashboards without bringing down the PostgreSQL server, we designed and implemented a dual-mode query execution engine:

```
                  [GET /api/analytics/bod]
                             |
                   +---------+---------+
                   |                   |
            [Global Route]      [Filtered Route]
                   |                   |
            - Join Store on DB  - Fetch Localized IDs
            - O(1) Memory usage - O(N) Filtered memory list
            - Suppress "refresh" - Enable "refresh" allowedAction
```

### Key Performance Patterns Introduced:
1. **Database-Side Active Store Verification**:
   Instead of pulling all active store primary keys into C# memory and running `.Contains(id)` on thousands of elements (which suppresses Postgres index scans and causes high memory overhead), active stores are joined and verified directly inside PostgreSQL via navigation property filters.
2. **Index-Friendly Range Scans**:
   EF Core translates null-coalescing date ranges (e.g. `CompletedAt ?? CreatedAt`) into complex `COALESCE` SQL statements, which prevents PostgreSQL from traversing composite index trees. Rewriting this into explicit boundary logic enables full Index Scan traversal on both `completed_at` and `created_at` indexes.

---

## 3. Implementation Details

### Separation of Global and Filtered Query Path
In `GetBodReport.cs`, dynamic LINQ building logic was introduced to branch early based on the presence of a store or regional query parameter:

```csharp
var isGlobal = request.StoreId == null && request.RegionId == null;

if (isGlobal)
{
    // O(1) memory path joining active stores in the DB
    submissionsQuery = db.Submissions
        .Where(s => s.Store != null && s.Store.IsActive == true);
}
else
{
    // Filtered memory path targeting specific store groups
    submissionsQuery = db.Submissions
        .Where(s => filteredStoreIds.Contains(s.StoreId));
}
```

### Date Boundary Range Rewriting
All dynamic calculations (KPI metrics, submission counts, section score weaknesses) were refactored to query date ranges explicitly:

```csharp
// Instead of CompletedAt ?? CreatedAt >= startDate
submissionsQuery = submissionsQuery.Where(s =>
    (s.CompletedAt.HasValue && s.CompletedAt >= startDate && s.CompletedAt <= endDate) ||
    (!s.CompletedAt.HasValue && s.CreatedAt >= startDate && s.CreatedAt <= endDate)
);
```

### Allowed Actions Resolution
The `allowedActions` array inside the boardroom report DTO is populated contextually based on the scope:

```csharp
var allowedActions = new List<string> { "view_details" };
if (!isGlobal)
{
    allowedActions.Add("refresh");
}
```

---

## 4. Verification Results
All targeted integration tests inside `BodLiveQueries_Slice3_Tests` pass cleanly:
* `GetGlobalReport_ActiveStoreFiltration_OnlyIncludesActiveStores` - **PASSED**
* `GetGlobalReport_AllowedActions_ExcludesRefreshOnGlobalQuery` - **PASSED**
* `GetGlobalReport_NullCoalescingQueryAudit_DoesNotContainIndexSuppressingNullCoalesce` - **PASSED**

---

## 5. File Changes
- **Modified**: [GetBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/GetBodReport.cs)
- **Created**: [task_bod-live-queries_slice3_20260601_171500.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/features/bod-live-queries/task_bod-live-queries_slice3_20260601_171500.md)
- **Created**: [walkthrough_bod-live-queries-slice3_20260601_171500.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/features/bod-live-queries/walkthrough_bod-live-queries-slice3_20260601_171500.md)
