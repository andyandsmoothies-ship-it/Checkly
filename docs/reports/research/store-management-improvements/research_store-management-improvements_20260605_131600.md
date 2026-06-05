---
ConversationID: 196516cd-9f45-4144-9eb4-14a4e0a8f483
Type: research_report
Topic: store-management-improvements-ideation
Created_at: 2026-06-05T13:16:00+07:00
---

# Research Report: Store Management Feature Improvements (Revised)

This report defines the final strategy and feature set for improving the Admin Store Management screen.

## 1. Feature Definition & Decisions

The feature set has been refined based on administrative constraints and integration needs:

### Idea A: Address Filtering (Province / District)
- **Status**: **Approved (Server-Side)**.
- **Why**: To prevent client-side pagination mismatch (where clients only search the first paginated page of 50 stores), filtering must occur server-side.
- **Scope**: Dropdown filters for Province and District. Selecting a Province dynamically limits District options.

### Idea B: Manager / Assignment Filtering
- **Status**: **Approved (Server-Side)**.
- **Why**: Allows filtering stores by Store Manager or Area Manager. Implemented as a server-side filter to support large numbers of stores.

### Idea C: Distance / Proximity Sorting (GPS Location)
- **Status**: **Rejected**.
- **Why**: Not needed for the administrator's workflow.

### Idea D: "Use Current Location" Button
- **Status**: **Rejected**.
- **Why**: Administrators typically create and update stores from the central office, so the device's current GPS location is irrelevant to the store's physical location.

### Idea E: Address-Map Two-Way Sync (New Core Capability)
- **Status**: **Approved (Selected)**.
- **Why**: Currently, address text fields and map latitude/longitude coordinates exist as separate inputs in the creation form. This links them into a single, cohesive spatial definition:
  1. **Geocoding (Address ──> Map)**: Clicking "Locate on Map" reads the text inputs (Street, Ward, District, Province), queries the Nominatim API, moves the map pin to that location, and populates the Latitude and Longitude fields.
  2. **Reverse Geocoding (Map ──> Address)**: Clicking or tapping on the map places a pin, queries Nominatim, and auto-populates the Street, Ward, District, and Province text fields.

---

## 2. Technical Architecture & Constraints

- **OpenStreetMap Nominatim API**: We use `https://nominatim.openstreetmap.org/search` for geocoding and `https://nominatim.openstreetmap.org/reverse` for reverse geocoding.
- **Usage Policy**: We must include a custom, descriptive HTTP `User-Agent` (e.g., `'ChecklyApp/1.0'`) and respect the 1 request/second rate limit.
- **Server Filtering**: Add query parameters `province` and `managerName` to the `ListStores.cs` endpoint.
- **Offline Fallback**: Nominatim requires a network connection. When offline, geocoding buttons should degrade gracefully (e.g., showing a warning toast or disabling sync).

---

## 3. Pugh Decision Matrix

| Evaluation Criteria | Status Quo | Client-Side Filtering | Server Filtering + Nominatim Sync (Selected) |
| :--- | :---: | :---: | :---: |
| **Scalability (1000+ Stores)** | 0 | -1 (broken paging) | +2 (dynamic EF Core query) |
| **UX Cohesion (Address/Map)** | 0 | 0 (disjointed inputs) | +2 (two-way automated sync) |
| **Implementation Simplicity** | 0 | +1 (no server work) | -1 (requires API/DB/sync work) |
| **Offline Robustness** | 0 | 0 (local static) | 0 (Nominatim requires network) |
| **Total Score** | **0** | **0** | **+3** |

---

## 4. UI Component Routing Table

| Widget Name | Target List / Source | Page Limits | Action / Interaction |
| :--- | :--- | :--- | :--- |
| `StoreManagementPage` | `ListView.builder` | Capped at 200 | Displays store cards, triggers server filters. |
| `DropdownFilterPill` | Horizontal filter row | None | Filter selectors for Status, Province, and Manager. |
| `StoreFormBody` | Edit / Create form sheet | N/A | Form wrapper providing input fields and map view. |
| `LocateOnMapButton` | Inside `StoreFormBody` | N/A | Triggers geocoding lookup and updates map + coords. |
| `StoreLocationMapWidget` | Leaflet `flutter_map` | N/A | Handles tap events to reverse-geocode and auto-fill address. |

---

## 5. E2E Workflow Maps

### Geocoding Workflow (Address ──> Map)
```
[Fill Street/Ward/District/Province] ──> [Click "Locate on Map"]
                                                 │
                                                 ▼
                                     [Query Nominatim Search]
                                                 │
                        ┌────────────────────────┴────────────────────────┐
                        ▼ (Found)                                         ▼ (Not Found)
        [Update Lat/Lng Text Controllers]                      [Show "Address not found" toast]
        [Move Map Pin to Coordinates]
```

### Reverse Geocoding Workflow (Map ──> Address)
```
             [User taps on Map]
                      │
                      ▼
        [Move Map Pin to Target Coords]
        [Update Lat/Lng Text Controllers]
                      │
                      ▼
           [Query Nominatim Reverse]
                      │
                        ┌────────────────────────┴────────────────────────┐
                        ▼ (Success)                                       ▼ (Error/Timeout)
        [Parse Address: street, ward, district, province]      [Keep Lat/Lng, show warning toast]
        [Update Form Text Controllers]
```

---

## 6. Forensic Evidence & Code Locations
- **Backend Query Handler**: `server/Features/Stores/ListStores.cs`
- **Backend Entity Configuration**: `server/Common/Persistence/Configurations/StoreConfiguration.cs`
- **Frontend Api Client**: `lib/features/stores/services/store_api_service.dart`
- **Frontend State Manager**: `lib/features/admin/managers/admin_store_manager.dart` (or similar manager file)
- **Frontend Views**: `lib/features/admin/pages/store_management_page.dart`, `lib/features/admin/widgets/store_form_body.dart`
