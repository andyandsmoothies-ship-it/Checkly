---
conversation_id: e4a8d231-abcb-46c0-ae41-613c2d8ed2c0
created_at: 2026-06-01T00:15:00+07:00
topic: bod-analytics-v2
type: implementation_plan
status: IN_PROGRESS
---

# Implementation Plan: Store Manager Benchmark Extension (Slice 2)

This plan outlines the design and step-by-step instructions to deliver **Slice 2** of the **BOD Analytics V2** epic. It extends the store-level Boardroom Dashboard summary endpoint with peer quartile ranking, regional average benchmarking, SLA overdue buckets, and implements role-scoped IDOR tenancy guards.

## 1. Data Flow & Component Relationship

```text
[Flutter Client] ───> GET /api/analytics/stores/{storeId}/bod-summary
                             │
                             ├── [1. Tenancy IDOR Guard]
                             │   ├── Admin: Allow
                             │   ├── Auditor: 403 Forbidden
                             │   ├── Store Manager: profile.StoreId == storeId
                             │   └── Area Manager: ProfileStoreAssignments contains storeId
                             │
                             ├── [2. Province Benchmark & Peer Ranking]
                             │   ├── Retrieve other active stores in the same province
                             │   ├── Compute regional average of stores' AvgScore30d
                             │   └── If total stores >= 4, sort by AvgScore30d & compute quartile ranking
                             │
                             ├── [3. SLA Overdue Action Plan Buckets]
                             │   └── Retrieve open overdue action plans for the store
                             │   └── Segment into "0-7d", "8-30d", "31+d" based on age from deadline
                             │
                             └── Return StoreBodSummary DTO
```

## 2. Overview & Objectives

*   **Goal**: Allow Store Managers and Area Managers to securely view store-level Boardroom summaries while enforcing strict tenant isolation (IDOR protection).
*   **Aesthetic & Benchmark Enrichment**: Enrich the dashboard summary with regional peer ranking and SLA overdue action plan aging segments.
*   **Security & Gate Compliance**: Remove the flat `.RequireCapability(AppCapabilities.AnalyticsBod)` restriction from the route and instead use fine-grained tenancy guards in the endpoint handler.

## 3. Technical Specifications

### A. Endpoint Path: `GET /api/analytics/stores/{storeId:guid}/bod-summary`
*   Modify `AnalyticsEndpoints.cs` to remove `.RequireCapability(AppCapabilities.AnalyticsBod)` from this route.
*   The parent group continues to require `RequireAuthorization()`.

### B. Tenancy Guard Logic in `GetStoreBodSummary.cs`
*   Extract user role and name identifier claims:
    *   **Auditors**: `403 Forbidden` (`TypedResults.Forbid()`).
    *   **Admins** or users possessing `analytics:bod` capability: Unrestricted.
    *   **Store Managers**: Allowed only if `profile.StoreId == storeId`.
    *   **Area Managers**: Allowed only if `ProfileStoreAssignments` contains a mapping for this `storeId` and `profileId`.

### C. Benchmark & Quartile Logic in `GetStoreBodSummary.cs`
*   Retrieve the target store's `Province` via `store.Address2.Province`.
*   If province is null/empty, `quartileLabel = null` and `regionalAvgScore = 0m`.
*   Otherwise, fetch all active stores in the same province along with their `AvgScore30d` from `StoreAnalyticsSnapshots` (using a single joined query).
*   Calculate `regionalAvgScore` as the mathematical average of `AvgScore30d` values across all peers in the province (including the current store).
*   If total peers in the province $\ge 4$:
    *   Sort the peers by `AvgScore30d` in descending order.
    *   Find the rank of the target store (1-indexed).
    *   Calculate percentile rank: `percentile = (totalStores - rank) / (double)totalStores`.
    *   Map to label:
        *   `percentile >= 0.75` → `"Top 25% in Region"`
        *   `percentile >= 0.50` → `"Top 50% in Region"`
        *   `percentile >= 0.25` → `"Top 75% in Region"`
        *   Otherwise → `"Bottom 25% in Region"`
*   If total peers $< 4$, return `null` for `quartileLabel`.

### D. SLA Overdue Aging Buckets in `GetStoreBodSummary.cs`
*   Retrieve all open action plans for the store where `Deadline` is in the past:
    `ap.StoreId == storeId && ap.Status == "open" && ap.Deadline != null && ap.Deadline < now`.
*   Group them in-memory into 3 segments:
    *   `0-7d`: `(now - Deadline).TotalDays <= 7.0`
    *   `8-30d`: `(now - Deadline).TotalDays > 7.0 && (now - Deadline).TotalDays <= 30.0`
    *   `31+d`: `(now - Deadline).TotalDays > 30.0`

### E. DTO Extension in `BodReportDtos.cs`
*   Update `StoreBodSummary` record constructor to support the new optional fields with safe default values:
    ```csharp
    public record StoreBodSummary(
        string StoreName, 
        List<RecentAuditEntry> RecentAudits, 
        List<CategoryScoreEntry> CategoryBreakdown,
        string? QuartileLabel = null,
        decimal RegionalAvgScore = 0m,
        List<BodApAgingBucket>? SlaOverdueBuckets = null);
    ```

## Proposed Changes

### Step 1: Write integration/unit tests in `BodAnalyticsExtendedSlice2Tests.cs`
Assert the following:
*   `Store Manager` can access their own store's summary.
*   `Store Manager` gets `403 Forbidden` if attempting to view a different store's summary.
*   `Area Manager` can view a store summary if assigned to it.
*   `Area Manager` gets `403 Forbidden` if the store is not assigned to them.
*   `Auditor` gets `403 Forbidden` on store summary request.
*   `quartileLabel` calculates correctly when >= 4 stores are in the province, and returns `null` when < 4.
*   `slaOverdueBuckets` Segments correctly into the respective aging ranges.

### Step 2: Implement Endpoint Tenancy & Logic changes
*   Update `BodReportDtos.cs` DTO models.
*   Update `AnalyticsEndpoints.cs` routing constraints.
*   Update `GetStoreBodSummary.cs` endpoint logic to include Tenancy Guards, Quartile Ranking, and SLA Aging Buckets.

### Step 3: Verify C# Backend Tests
*   Run the integration tests using `rtk dotnet test` and ensure all tests pass.

### Step 4: Implement Flutter Client updates
*   Update the Flutter `StoreBodSummary` Dart model class (`lib/features/analytics/models/store_bod_summary.dart`) to support `quartileLabel`, `regionalAvgScore`, and `slaOverdueBuckets`.
*   Update corresponding service or repository layers if needed.
*   Update UI widget `StoreBodSummaryView` to visually display the quartile chip (e.g. green pill chip), the regional average score indicator, and the SLA overdue buckets using the existing high-quality UI design tokens.

## Risk Assessment

### 1. Database Query Performance under High Load
*   **Risk**: Doing N+1 lookups or scanning all stores to filter by province dynamically could slow down under production size.
*   **Mitigation**: Use a single EF Core query with an explicit `.Where(s => s.Address2.Province == province)` filter on the Snapshots/Stores. Join `Stores` with `StoreAnalyticsSnapshots` so the C# runtime does not do manual loops.
*   **Edge Case**: Handling `null` or empty `Province`. If the store's address has an empty province, return defaults (`null` for quartile label) immediately without querying the DB to prevent performance degradation.

### 2. SLA Overdue Date Time Zones
*   **Risk**: Date comparison differences between database time zones and localized user times (`DateTime.UtcNow`).
*   **Mitigation**: Compare deadlines exclusively in UTC using Postgres' native timezone comparisons, ensuring unified boundary calculations.

## Verification Plan

### Automated Integration & Unit Tests
1. **Backend Integration Tests**:
   * Run the test suite: `rtk dotnet test` in the `server/` directory.
   * Target test class: `BodAnalyticsExtendedSlice2Tests` to verify all access controls, benchmarking calculations, and SLA overdue buckets.
2. **Frontend Model Serialization Tests**:
   * Run the Dart model mapping tests: `flutter test test/features/analytics/store_bod_summary_test.dart`.

### Manual Acceptance Verification Flow
1. **Login as Store Manager A**: View Dashboard, verify store A's data renders with the correct benchmark card.
2. **Access Store B's API URL**: Confirm the response returns `403 Forbidden` for Store Manager A.
3. **Login as Area Manager**: View summaries for assigned stores, verify non-assigned stores return `403 Forbidden`.
