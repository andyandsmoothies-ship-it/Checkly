---
ConversationID: 43a6d3be-90b3-4a93-b845-d4413b14705f
---

# Walkthrough: Store Management Improvements (Slice 1)

This walkthrough documents the design decisions, implementation details, and verification traces for the first slice of the Store Management Improvements feature.

## Proposed Changes

### 1. Backend Query Filtering in `ListStores.cs`
- Modified the `ListStoresQuery` to accept optional parameters: `Province`, `District`, and `ManagerName`.
- Added query execution logic in the handler to conditionally filter stores by:
  - `Province`: Exact match against `s.Address2.Province`.
  - `District`:
    - If `District` is `"Unassigned"`, matches stores where `s.Address2.District` is `null` or empty (`""`).
    - Otherwise, performs an exact match against `s.Address2.District`.
  - `ManagerName`: Performs a case-insensitive search matching the search string against the full name of either a Store Manager or Area Manager assigned to the store via `ProfileStoreAssignments`.
- Structured the database query to be fully server-side projected using PostgreSQL-safe null inequality and inclusion checks.

### 2. Reference Districts Endpoint in `GetDistricts.cs`
- Created a new feature handler `GetDistrictsQuery` under `server/Features/Reference/GetDistricts.cs`.
- Queries `AppDbContext` to retrieve distinct sorted districts for active stores in a specified province.
- Filters out null or empty districts from the database query.
- Appends the value `"Unassigned"` to the sorted result list if there are any active stores in the specified province where the district is null or empty (`s.Address2.District == null || s.Address2.District == ""`).
- Mapped `/api/reference/districts` route in `ReferenceEndpoints.cs`.

## Decision Log

### Why `"Unassigned"` is appended to the Districts list
To support administrative cleanup of stores lacking a district, the filter dropdown must display an `"Unassigned"` option. Appending `"Unassigned"` dynamically when database records exist with empty districts ensures that users can easily discover and filter these incomplete records.

### Joining Store and Area Managers for Name Filtering
A store can be assigned to multiple profiles with different roles (`store_manager` or `area_manager`). The name search performs a case-insensitive sub-string match on the profile's full name, checking both roles linked via the `ProfileStoreAssignments` relationship.

## Verification Handoff

### Test Traces

All tests passed successfully inside the test suite:
- `ListStores_WithProvinceFilter_ReturnsFilteredStores`
- `ListStores_WithDistrictFilter_ReturnsFilteredStores`
- `ListStores_WithUnassignedDistrictFilter_ReturnsStoresWithoutDistrict`
- `ListStores_WithManagerNameFilter_ReturnsStoresManagedByMatchingName`
- `GetDistricts_ReturnsSortedDistrictsForProvince`
- `GetDistricts_WithUnassignedDistricts_AppendsUnassignedToResult`
- `GetDistricts_WithoutStoresInProvince_ReturnsEmptyList`

<test_trace>
Passed!  - Failed:     0, Passed:     7, Skipped:     0, Total:     7, Duration: 23 s - Checkly.Api.Tests.dll (net10.0)
</test_trace>

<forensic_evidence>
Command: rtk dotnet test --filter StoreManagement_Slice1_Tests
Output:
Passed!  - Failed:     0, Passed:     7, Skipped:     0, Total:     7, Duration: 23 s - Checkly.Api.Tests.dll (net10.0)
</forensic_evidence>
