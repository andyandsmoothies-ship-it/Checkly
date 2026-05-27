# Walkthrough: BOD Analytics Slice 1 Server Foundation Complete

**ShortID**: `453a8146` | **Date**: `2026-05-25 11:40:00`

---

## 1. Executive Summary
BOD Analytics Slice 1 (Server Foundation) has been completely implemented, compiled, and verified. The API endpoint (`GET /api/stores/{storeId}/bod-summary`) successfully retrieves, calculates, and returns real-time Board of Directors (BOD) summary statistics, including trend data and the top three recurring issues, following the Strict Bimodal (Hybrid) Authorisation model.

---

## 2. Structural & Architectural Overview

The backend service is structured as a vertical slice:
`[HTTP Client] --> [GetStoreBodSummary Endpoint] --> [EF Core (QueryStoreBodSummaryAsync)] --> [PostgreSQL]`

### Allowed Actions Calculation:
The backend computes allowed actions based on PBAC capabilities from the JWT and the store assignment context:
- `"can_view_bod_drilldown"`: Enabled if the user possesses the `view_bod_drilldown` capability or if the user is a `store_manager` assigned to the target store.

---

## 3. Detailed File Changes

### 3.1. Main Feature Implementation
- **File**: `server/Features/Analytics/GetStoreBodSummary.cs`
- **Changes**:
  - Defined all response contract classes (`StoreBodSummaryResponse`, `StoreBodTrendPoint`, `StoreBodTopIssue`, `DailyBodSubmissionSummary`).
  - Added robust validation check that the store exists (`TypedResults.NotFound()` on null).
  - Implemented the PBAC capability check:
    ```csharp
    var hasGlobalCap = httpContext.User.HasCapability(Capabilities.ViewBodDrilldown);
    var isAssignedManager = false;
    if (httpContext.User.IsInRole(Roles.StoreManager))
    {
        var profileId = httpContext.User.GetProfileId();
        isAssignedManager = await db.ProfileStoreAssignments
            .AnyAsync(x => x.StoreId == storeId && x.ProfileId == profileId);
    }
    if (!hasGlobalCap && !isAssignedManager)
    {
        return TypedResults.Forbid();
    }
    ```
  - Formulated the EF Core queries to load submissions, issues, and template info:
    - Retries and counts submissions for the past 30 days.
    - Aggregates daily counts to form a 30-day timeline.
    - Resolves failed audit checks to compute the top three recurring template issues with their counts.
  - Returns `TypedResults.Ok(response)`.

---

## 4. Verification & Testing

### 4.1. Automated Test Execution
The entire integration test suite under `BodAnalyticsSlice1Tests` was executed and verified:
- **Command**: `rtk dotnet test --filter Checkly.Api.Tests.Features.Analytics.BodAnalyticsSlice1Tests`
- **Output**:
  - `ok dotnet test: 8 tests passed, 0 warnings in 1 projects (7.2 s)`

### 4.2. Tested Scenarios
1. `GetStoreBodSummary_GlobalUserWithCapability_ReturnsSuccess`
2. `GetStoreBodSummary_StoreManagerAssignedToStore_ReturnsSuccess`
3. `GetStoreBodSummary_StoreManagerNotAssignedToStore_ReturnsForbidden`
4. `GetStoreBodSummary_UserWithoutCapabilityOrRole_ReturnsForbidden`
5. `GetStoreBodSummary_NonExistentStore_ReturnsNotFound`
6. `GetStoreBodSummary_ComputesCorrectAllowedActions`
7. `GetStoreBodSummary_ComputesCorrectTrendPoints`
8. `GetStoreBodSummary_ComputesCorrectTopIssues`

All scenarios successfully executed, validated, and passed.
