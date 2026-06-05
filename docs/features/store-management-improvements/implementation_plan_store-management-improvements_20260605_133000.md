<latent_space_scratchpad>
- Edge Cases & Failure Modes:
  1. Rate-limiting violation with Nominatim: If the administrator spams "Locate on map" or drags/taps rapidly, Nominatim blocks requests returning 429 or 403. We need a client-side throttle/debounce: allow only one request per 1.5 seconds.
  2. Map tap in water or un-addressable region: Reverse geocoding returns success (HTTP 200) but without an address dictionary or with null/empty fields. The UI must fallback gracefully by preserving Lat/Lng without wiping existing address text fields.
  3. Offline usage: Admin page checks online status. When offline, geocoding button is disabled or triggers warning toast.
  4. SQL NULL Inequality: ListStores.cs must handle null values safely. Store manager name lookup can be null if a store is not assigned.
</latent_space_scratchpad>

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\reports\research\store-management-improvements\research_store-management-improvements_20260605_131600.md`

## Executive Summary & Out of Scope
Introduce server-side filtering for stores based on Province, District, and Assigned Manager. Add two-way geocoding (Address ──> Map coordinates) and reverse geocoding (Map tap ──> Address fields auto-populate) using the OpenStreetMap Nominatim API.

### Out of Scope:
- Distance/Proximity sorting based on admin location (GPS).
- "Use Current Location" button on the store form (office workflow).
- Native iOS/Android CoreLocation map layers (Leaflet/flutter_map only).

## First Principles Gate
1. **Physics & Limit**: 
   - *Behavior*: Address & Manager filtering must search all stores in the database, not just the first 50 returned by client-side paging. 
   - *Physical Limit*: Client-side memory and network limits. We solve it by moving filter query parameters (`province`, `district`, `managerName`) to the database query in EF Core before `Skip` and `Take` paging operations.
2. **Simplicity Check**:
   - *Simplest Way*: Load all 1000+ stores into Dart client and filter locally using simple string containment.
   - *Why Not*: Excessive network payload size and client-side CPU overhead on low-end mobile devices.
3. **Blast Radius**:
   - *Worst Case*: A syntax error or EF translation bug in `ListStores.cs` causes 500 Server Errors, completely breaking the Store Management page for all administrators.
4. **Observability**:
   - *Production Proof*: Structured backend logging in `ListStores.cs` recording: `Log.Information("ListStores filter applied: Province={Province}, District={District}, Manager={ManagerName}", ...)`

## System Context
- **Offline/Online**: Nominatim sync requires active internet connection. Check internet state before calling the API.
- **Capabilities**: Store CRUD requires `stores:write`. Store listing requires `stores:read`. User listing (to populate manager filters) requires `users:read`.
- **API Specification**:
  - `GET /api/stores?province=...&district=...&managerName=...`
  - `GET /api/reference/districts?province=...` (Returns distinct active store districts for a given province)
  - `GET /api/admin/users?role=store_manager` and `?role=area_manager`

## Lifecycle Context
### 4-State Matrix for Filtering:
- **Success**: Stores matching filters populate list.
- **Error**: Shows an error banner with a retry button.
- **Empty**: Shows `ChecklyEmptyState` saying "Let's find some stores! Try adjusting your filters...".
- **Loading**: Shows a standard loading indicator.

### 4-State Matrix for Nominatim Sync:
- **Success**: Coordinates updated on map pin; address fields populated.
- **Error/Timeout**: Keeps current state, shows a warning snackbar: "Geocoding API unavailable. Please manually fill the coordinates."
- **Empty/Not Found**: Shows snackbar: "Address could not be resolved on the map. Check address spelling."
- **Loading**: Shows a loading indicator or spinner on the "Locate on Map" button.

## Constraint Traceability

| Input Constraint | Description | Test Contract ID |
| :--- | :--- | :--- |
| Server Filtering | EF Core queries must filter stores by Province, District, and Manager on the server. | TC-SM-01 |
| Vietnam Provinces | Province selection must be limited to the 63 official provinces. | TC-SM-02 |
| Distinct Districts | Districts dropdown must only offer districts existing in that Province. | TC-SM-03 |
| Geocoding Sync | Locate on Map maps Address ──> Coordinates. | TC-SM-04 |
| Rev-Geocoding Sync | Map Taps map Coordinates ──> Address text fields. | TC-SM-05 |

## Test Contracts

| ID | Description | State Matrix | Fail-First Explanation |
| :--- | :--- | :--- | :--- |
| **TC-SM-01** | Backend filters query by province, district, manager name. | Admin + Filter values -> PagedResult | EF Core translation error or zero results returned. |
| **TC-SM-02** | Provinces filter uses official 63 list. | Static list -> UI Dropdown | Dropdown fails to load or corrupts names. |
| **TC-SM-03** | Districts endpoint returns distinct districts. | Province -> List of distinct districts | Database distinct query fails or returns empty. |
| **TC-SM-04** | Nominatim Geocode address input. | Address -> Lat/Lng result | API returns 404 or rate limit block. |
| **TC-SM-05** | Nominatim Reverse-Geocode tap location. | Lat/Lng -> Address result | No address found or API returns 429. |

## Test Fixture & Payloads
- **Seeded State**: Seeded Stores (e.g. 5 stores with varying addresses in "Hồ Chí Minh" and "Hà Nội", assigned to managers "Andy" and "Bob").
- **Nominatim Request**:
  - `GET https://nominatim.openstreetmap.org/search?q=123+Nguyen+Hue,+Quan+1,+Ho+Chi+Minh&format=json&limit=1`
- **Nominatim Response**:
  ```json
  [
    {
      "lat": "10.7758",
      "lon": "106.7018",
      "display_name": "Nguyen Hue, Quan 1, Ho Chi Minh, Vietnam"
    }
  ]
  ```

## Tools & Commands
- Backend: `dotnet test`
- Frontend: `flutter test`

## Proposed Changes

| File | Action | Purpose |
| :--- | :---: | :--- |
| `server/Features/Stores/ListStores.cs` | `MOD` | Implement server-side filtering for Province, District, and Manager. |
| `server/Features/Reference/GetDistricts.cs` | `NEW` | Add endpoint to fetch distinct store districts for a given province. |
| `server/Features/Reference/ReferenceEndpoints.cs` | `MOD` | Map `/api/reference/districts` route. |
| `lib/features/stores/services/store_api_service.dart` | `MOD` | Add query parameters to `getStores`. |
| `lib/features/admin/services/admin_api_service.dart` | `MOD` | Expose `role` parameter in `getUsers` search. |
| `lib/features/admin/manager/admin_store_manager.dart` | `MOD` | Maintain filter state (province, district, manager) in manager. |
| `lib/_shared/services/geocoding_service.dart` | `NEW` | Nominatim API client with rate-limiting & header compliance. |
| `lib/features/admin/pages/store_management_page.dart` | `MOD` | Add filter pills for Province, District, and Manager. |
| `lib/features/admin/pages/widgets/store_form_body.dart` | `MOD` | Add "Locate on Map" button and integrate Nominatim sync. |
| `lib/features/admin/pages/widgets/store_form_sheet.dart` | `MOD` | Connect controller changes and map taps to geocoding services. |

### UI Component Table:
| Component | Truncation Limit | Overflow Action | Required New Route |
| :--- | :--- | :--- | :--- |
| Filter Pills Row | Single line (scrollable) | Horizontal scroll view wrapper | N/A (wrap with SingleChildScrollView) |
| Store Manager List | Max 100 entries | ListView with scrollbar | N/A |

## Concept Diagram
```
[User Interface (StoreManagementPage)]
   │
   ├── [Select Filters: Province / District / Manager] ──> [Call AdminStoreManager.load()]
   │                                                             │
   │                                                             ▼
   │                                                     [StoreApiService.getStores()]
   │                                                             │
   │                                                             ▼
   │                                                    [GET /api/stores?Filters]
   │
   └── [Store Form Sheet (Create/Edit)]
         │
         ├── [Fill Address] ──> [Locate on Map] ──> [GeocodingService] ──> [Nominatim API]
         │                                                                       │
         │                                                                       ▼
         │                                                           [Update Lat/Lng & Map Pin]
         │
         └── [Tap Map] ──────> [Reverse Geocode] ─> [GeocodingService] ──> [Nominatim API]
                                                                                 │
                                                                                 ▼
                                                                     [Auto-fill Address Fields]
```

## Execution Slices

### Slice 1: Backend Server Filtering & Districts Endpoint
- **Summary**: Implement filters in `ListStores.cs` and create `/api/reference/districts` endpoint.
- **Value**: Establishes database-side query execution for scalable filtering.
- **Entry State**: Baseline DB schema.
- **Exit State**: Clean backend query matching all filter combinations; districts endpoint tested.
- **Acceptance Criteria**:
  1. `/api/stores?province=X` returns only stores in province X.
  2. `/api/stores?managerName=Y` returns only stores where store manager or area manager name contains Y.
  3. `/api/reference/districts?province=X` returns a list of unique districts for active stores in province X.
  4. Districts query explicitly filters out null and empty strings using:
     `s.Address2.District != null && s.Address2.District != ""` (Flop 3 mitigation).
  5. The store query in `ListStores` must support a special value `district=Unassigned` to find stores with null/empty districts in that province (Unassigned Districts handling).
- **Complexity**: Medium.

### Slice 2: Frontend API and Manager Wiring
- **Summary**: Expose query parameters in `StoreApiService` and filter states in `AdminStoreManager`. Add `role` parameter to `AdminApiService.getUsers`.
- **Value**: Connects backend capabilities to state representation.
- **Entry State**: Slice 1 completed.
- **Exit State**: Notifier correctly calls API with active filter parameters.
- **Flop Mitigation (Flop 4)**: 
  - `AdminStoreManager` must immediately clear the `selectedDistrict` state whenever the `selectedProvince` is modified.
- **Complexity**: Low.

### Slice 3: Geocoding Client Service (Nominatim)
- **Summary**: Create `GeocodingService` in Dart executing OSM Nominatim calls.
- **Value**: Encapsulates external map queries safely.
- **Entry State**: Clean internet/Dio setup.
- **Exit State**: Tested geocoding and reverse geocoding functions.
- **Flop Mitigations (Flop 1, 5, 6)**:
  - Add strict 1.5s client-side throttle/debounce in calls to prevent HTTP 429 lockout.
  - Set a custom, unique `User-Agent` (e.g., `Checkly-Mobile-App/1.0 (contact@checkly.com)`) in custom request headers to prevent OSM HTTP 403 blocks.
  - Check network connectivity using the connectivity helper before firing Nominatim requests. Trigger immediate warning/toast if offline.
  - If rate limited (HTTP 429), return a specific failure status/exception so the UI can display: *"Too many map requests. Please wait a moment or enter the coordinates manually."* Ensure Latitude and Longitude input fields are never disabled or locked from manual editing when errors occur.
- **Complexity**: Medium.

### Slice 4: UI Filters Integration
- **Summary**: Implement filter dropdowns on the main store page.
- **Value**: Allows users to filter the list of stores easily.
- **Entry State**: Slice 2 completed.
- **Exit State**: Dynamic filter pills rendering and updating list.
- **Unassigned District Support**:
  - Show a special **"Unassigned / Other"** option in the District dropdown if there are stores with null/empty districts. Selecting this option queries stores with `district=Unassigned` on the backend.
- **Complexity**: Medium.

### Slice 5: Two-Way Map-Address Form Sync
- **Summary**: Wire `GeocodingService` into the store form, adding "Locate on Map" and reverse geocoding on map tap.
- **Value**: Seamless administrative map-data synchronization.
- **Entry State**: Slice 3 & 4 completed.
- **Exit State**: Interactive, synchronized form view.
- **Flop Mitigation (Flop 2)**:
  - Use robust null-coalescing on the parsed address JSON object.
  - If map tap resolves to water or un-addressable region (missing key parts like province), show a warning snackbar: *"Address name not found, but map coordinates saved"*. Preserve the tapped coordinates (Latitude/Longitude) on the map/form and allow manual address name entry rather than blocking or clearing the fields.
  - Disable map buttons and display loading indicators during active API operations.
- **Complexity**: High.

<command_logs>
- `rtk dotnet test`
- `rtk flutter test`
</command_logs>

## Handoff Block
- **Plan File**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\store-management-improvements\implementation_plan_store-management-improvements_20260605_133000.md`
- **Execution Order**: Slices 1 to 5.
- **Step-by-Step execution**:
  1. Complete Slice 1 (Backend query filters & Districts endpoint).
  2. Run backend integration tests.
  3. Yield to user.
  4. Continue next slices sequentially.
