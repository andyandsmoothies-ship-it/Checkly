---
ConversationID: 196516cd-9f45-4144-9eb4-14a4e0a8f483
Type: research_report
Topic: store-management-improvements-ideation
Created_at: 2026-06-05T12:38:48+07:00
---

# Research Report: Store Management Feature Improvements

## 1. [ORIGIN_IDEA]
The business goal is to analyze potential features to improve the Admin Store Management page. Specifically:
- **Idea A**: Address filtering (by Province, District, Ward).
- **Idea B**: Manager / Assignment filtering (by Store Manager or Area Manager).
- **Idea C**: Proximity-based sorting (closest stores first using device GPS coordinates).
- **Idea D**: "Use Current Location" button in the store creation/edit form to auto-fill GPS latitude and longitude fields.

---

## 2. <latent_space_scratchpad>
*   **Aesthetic Alignment**: The Store Management screen must align with the premium "Duolingo-like" visual aesthetics. The filters must use `DropdownFilterPill` widgets and align horizontally.
*   **Pagination Bottleneck**: Currently, the server endpoint `ListStores.cs` paginates the list using `pageSize` capped between 1 and 200 (default 50). If the database has 300 stores, a client-side filter will only see the 50 stores loaded on page 1. Therefore, to make filtering correct at scale, Province and Manager filters MUST query the server via query parameters.
*   **Nominatim Geocoding API**: Address-to-map locating and map-to-address auto-filling will query the free OpenStreetMap Nominatim APIs (`https://nominatim.openstreetmap.org/search` and `/reverse`) via `Dio` requests. We must specify a descriptive HTTP `User-Agent` (e.g. `'ChecklyApp/1.0'`) to prevent request rejection.
*   **Address Fields Structure**: Stores currently have `addressProvince`, `addressDistrict`, `addressWard`, and `addressStreet` properties. They are mapped to the `stores` table using EF Core owned type `Address2`. The columns are nullable.
*   **Manager Subqueries**: In `ListStores.cs`, store managers (`smLookup`) and area managers (`amLookup`) are fetched via subqueries. Filtering by manager requires matching these subquery values or adding JOINs in the EF query.
</latent_space_scratchpad>

---

## 3. E2E Workflow Maps

### Address & Manager Filtering (Server-Side Filtering)
```
[User interacts with DropdownFilterPill]
                   │
                   ▼
[UI triggers AdminStoreManager.load(province, managerName)]
                   │
                   ▼
[StoreApiService.getStores(province: X, managerName: Y)]
                   │
         (HTTP GET request with params)
                   │
                   ▼
[Backend: ListStores.cs Handler]
                   │
     (Builds dynamic EF Core query)
                   │
                   ▼
[Database: PostgreSQL Stores Query] ── (Executes filtered query)
```

### Forward Sync: Locate on Map (Address ──> Map)
```
[User enters Street/Ward/District/Province]
                   │
                   ▼
       [Click "Locate on Map" Button]
                   │
                   ▼
  [Query Nominatim Search API via Dio]
                   │
        ┌──────────┴──────────┐
        ▼ (Found)             ▼ (Not Found)
 [Move Map Marker to Location]  [Show "Address not found" Toast]
 [Fill Lat/Lng Fields]
```

### Reverse Sync: Auto-Fill Address (Map ──> Address)
```
[User taps on Map]
        │
        ▼
[Update Map Pin & Lat/Lng Fields]
        │
        ▼
[Query Nominatim Reverse Geocoding API]
        │
        ▼
[Auto-populate: Province, District, Ward, Street]
```

---

## 4. Strategy Assessment

### Option A: Strict Native Fit (Pure Client-Side Logic)
*   **Implementation**: Retrieve all stores at once (no server pagination) or filter only the retrieved page items.
*   **Pros**:
    *   Zero changes required on the ASP.NET Core backend.
*   **Cons**:
    *   **Scale Limit**: Breaks when the database has 100+ stores due to network bandwidth and memory overhead of fetching everything.
    *   **Catastrophic Failure**: If the database exceeds 50 stores, the client-side filter will not search page 2 stores, leading to data invisibility.

### Option B: Selected Strategy (Server-Side Filtering + Nominatim Map-Address Sync)
*   **Implementation**: Add query parameters to the backend (`province`, `managerName`). Perform text search for other fields (District, Ward, Street) using the general search query. Provide two-way map-address sync in the Flutter form using Nominatim.
*   **Pros**:
    *   **High Scalability**: Paging, filtering, and sorting happen at the database level.
    *   **Consistent State**: Avoids mismatched UI list pagination.
    *   **Seamless Map/Address UX**: Clicking "Locate on Map" or tapping on the map syncs the visual marker with text fields.
*   **Cons**:
    *   **Nominatim API Rate Limit**: Nominatim has a usage limit of 1 request per second. We must cache queries or warn the user.

---

## 5. Pugh Decision Matrix

| Evaluation Criteria | Status Quo | Option A (Client-Side) | Option B (Selected Strategy) |
| :--- | :---: | :---: | :---: |
| **Scalability (1000+ Stores)** | 0 | -1 (high memory/broken pagination) | +2 (fast DB queries) |
| **UX Responsiveness** | 0 | +1 (no network delays for filter) | 0 (standard api request delay) |
| **Backend Integration Complexity** | 0 | 0 (no server change) | -1 (requires API/DB updates) |
| **Offline Reliability** | 0 | 0 (both require API access) | 0 (both require API access) |
| **Address-Map Cohesion** | 0 | 0 (separate fields) | +2 (two-way sync) |
| **Total Score** | **0** | **0** | **+3** |

*Verdict*: **Option B** is selected.

---

## 6. UI Component Routing Table

| Widget Name | Target List / Source | Page Limits | Navigation / Action |
| :--- | :--- | :--- | :--- |
| `StoreManagementPage` | `ListView.builder` | max 200 items | Opens `StoreFormSheet` (Create/Edit) |
| `DropdownFilterPill` | Horizontal filter row | None | Opens `StoreStatusFilterSheet`, `StoreProvinceFilterSheet`, `StoreManagerFilterSheet` |
| `StoreLocationMapWidget` | `flutter_map` container | Viewport bounds | Tapping map updates Lat/Lng and reverse-geocodes to fill address fields |
| `LocateOnMapButton` | Store Form Sheet | None | Geocodes form fields and places map pin |

---

## 7. <forensic_evidence>
*   **Backend Entity**: `StoreConfiguration.cs` configures the owned type `Address2` with structured address fields:
    *   `C:\Users\HP\Documents\GitHub\Checkly\server\Common\Persistence\Configurations\StoreConfiguration.cs`
*   **Backend Endpoint**: `ListStores.cs` implements name search and status limits:
    *   `C:\Users\HP\Documents\GitHub\Checkly\server\Features\Stores\ListStores.cs`
*   **Frontend Model**: `StoreDto.dart` parses `addressProvince`, `addressDistrict`, `addressWard`, and `addressStreet`:
    *   `C:\Users\HP\Documents\GitHub\Checkly\lib\features\stores\model\store_dto.dart`
*   **Frontend Page**: `StoreManagementPage` manages search controller and status filters:
    *   `C:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\pages\store_management_page.dart`
</forensic_evidence>

---

## 8. Handoff Block
- **Final Verdict**: **Viable**. Option B (Server-side filtering/sorting and client-side Nominatim Geocoding utility) is the robust architectural choice.
- **Effort Sizing**: **Track C (Moderate Implementation)**.
- **AI Agent Mission Brief**: Implement server-side filtering (by province and managerName) in `ListStores.cs`. In the frontend, extend `StoreApiService` and `AdminStoreManager` to pass these parameters, render new `DropdownFilterPill` widgets in `StoreManagementPage` (for Province and Manager), and add a "Locate on Map" button + map tap reverse-geocoding to the `StoreFormBody` form.
- **Next Workflow Command**:
  ```bash
  /analyze-feature c:\Users\HP\Documents\GitHub\Checkly\docs\reports\research\store-management-improvements\research_store-management-improvements_20260605_123848.md
  ```
