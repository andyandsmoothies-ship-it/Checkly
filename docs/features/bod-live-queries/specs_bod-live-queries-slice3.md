---
ConversationID: aa0d4917-b447-4894-b6c8-3c45d26b9ecd
---

# Specifications: Bod Live Queries Slice 3

This document defines the functional specs and technical constraints for testing and implementing optimized live queries inside GET `/api/analytics/bod`.

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice3_20260601_154600.md`

---

## 1. Functional Specifications

1. **Global Query Handling**:
   - The endpoint must detect if both `province` and `district` query parameters are null, empty, or whitespace.
   - If global, the API must bypass memory-intensive list filtering (`filteredStoreIds.Contains(...)`) and perform direct active store filtering in DB (`s.Store != null && s.Store.IsActive == true`).

2. **Index-Friendly Boundary Filter**:
   - The API must leverage composite indexes by replacing all `CompletedAt ?? CreatedAt` comparisons inside submissions queries with:
     `s.CompletedAt.HasValue && s.CompletedAt >= start30DaysAgo`.

3. **Allowed Actions Logic**:
   - The endpoint payload contains an `allowedActions` list.
   - If the report is a **Global Report** (`isGlobal == true`), `"refresh"` must be **omitted** from `allowedActions`.
   - If the report is a **Filtered Report** (`isGlobal == false`), `"refresh"` must be **included** in `allowedActions`.

---

## 2. Test Infrastructure Map

### Helper Methods
| Method | Signature | Behavior |
|---|---|---|
| `LoginBootstrapAdminAsync` | `(HttpClient)` | Logs in as the seed admin, returns the JWT token. |
| `CreateAuthenticatedClient` | `(token)` | Returns an HttpClient with authorization header attached. |
| `ClearDatabaseAsync` | `(AppDbContext)` | Truncates database tables to guarantee test isolation. |

### Seed Data
- **Admin User**: `admin@checkly.test` (seeded by `TestWebApplicationFactory`)
- **Database**: PostgreSQL `checkly_test`, auto-migrated during factory startup.

### Expected Response Format
```json
{
  "isLiveData": true,
  "kpis": {
    "totalAudits": 1,
    "avgScore": 95.0,
    "completionRate": 100.0,
    "openActionPlans": 1,
    "overdueActionPlans": 0,
    "activeStores": 1,
    "totalAuditors": 1,
    "avgTtrDays": 0.0,
    "geofenceBypassCount": 0
  },
  "goldenStore": {
    "storeName": "Active Hanoi Store",
    "avgScore": 95.0,
    "province": "Hanoi"
  },
  "allowedActions": []
}
```
