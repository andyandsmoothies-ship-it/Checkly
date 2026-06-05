---
ConversationID: 43a6d3be-90b3-4a93-b845-d4413b14705f
---
# Failure Mode & Flop-Catcher Audit: Store Management Improvements
Type: SRE Audit Report | Status: Reviewed

## 1. Executive Summary & First Principles Gate

### First Principles Analysis:
1. **Physics & Limit**: 
   - **Nominatim API Limit**: Strict limit of **1 request per second per IP**. Any high frequency calling (e.g., multiple admins updating stores or dragging map pins rapidly) will result in HTTP 429 / 403 blocks.
   - **DB Query Performance**: Server-side filtering using case-insensitive contains on unindexed fields (`FullName` of manager, `Province`, `District`) will result in sequential scans. Scale limit: ~10,000 stores before latency degrades.
2. **Simplicity Check**:
   - Keep the API call logic simple and direct. Use basic key-value extraction from Nominatim's flat JSON response instead of bringing in heavy external geo-parsing packages.
3. **Blast Radius**:
   - If the Nominatim API fails or rate-limits, the impact must be isolated. The administrator must still be able to manually input the address, Latitude, and Longitude. The system must fail-gracefully by alerting the user via toast and preserving inputs.
4. **Observability**:
   - Log geocoding latency and API status codes (`200`, `429`, `503`). Alert when the geocoding error rate exceeds 15% over a 5-minute window.

---

## 2. Identified Flops & Failure Scenarios

### 🔴 Critical Failures (System Crash, DB Error, Data Corruption)
*   **Flop 1: Nominatim 1-Second Rate Limit Lockout**
    *   *Scenario*: User taps "Locate on Map" repeatedly or triggers search as they type in the address field. The API returns HTTP 429 (Too Many Requests) or HTTP 403 (Blocked), causing the application to throw an unhandled DioException or wipe coordinates.
    *   *Fix*: Add a strict client-side throttle/debounce of 1.5 seconds in `GeocodingService` and disable the button with a loading indicator during flight.
*   **Flop 2: Water Map-Tap / Un-addressable Location Null Values**
    *   *Scenario*: User taps in the ocean or a forest on the map. Reverse geocoding returns HTTP 200 but with no `address` object or missing key fields like `province`/`city`. Wiping out existing fields or throwing null-reference exceptions on the client when parsing the response will crash the app.
    *   *Fix*: Geocoding parser must use safe null-coalescing on all nested address fields. If key identifiers like `province` are missing, throw a user-friendly custom exception, display a warning toast, and preserve already filled text fields.
*   **Flop 3: District Null Dropdown Empty Item rendering**
    *   *Scenario*: Legacy stores in the database might have a `null` or empty `District` in `Address2`. The `/api/reference/districts` endpoint queries distinct districts for a province. If it returns `null` or empty string in the JSON array, the Flutter dropdown will attempt to render a null value, leading to a red screen crash.
    *   *Fix*: Filter out `null` and empty strings explicitly in the EF Core query: `Where(s => s.Address2.District != null && s.Address2.District != "")`.

### 🟡 Warning Failures (Visual/Layout Bugs, Test Hanging, Logical Issues)
*   **Flop 4: Inconsistent Dropdown Reset on Province Change**
    *   *Scenario*: User selects Province A, then selects District B (which belongs to Province A). If they change Province to C, District B remains selected in the filter state. When query is run, it looks for stores in Province C and District B, returning zero results. The user sees a blank screen with no indication that their dropdowns are in a conflicting state.
    *   *Fix*: Changing the Province filter selection must immediately reset the District filter selection to null/empty in the state manager.
*   **Flop 5: Nominatim User-Agent Blocking**
    *   *Scenario*: OpenStreetMap blocks requests that do not specify a unique User-Agent header (returning 403 Forbidden). Using a generic HTTP client with default headers will trigger this block.
    *   *Fix*: Explicitly set a custom, unique `User-Agent` (e.g., `Checkly-Mobile-App/1.0 (contact@checkly.com)`) in the Dio client headers inside `GeocodingService`.
*   **Flop 6: Offline Geocoding Hangs**
    *   *Scenario*: Device goes offline. Tapping "Locate on Map" triggers a network request that hangs until timeout.
    *   *Fix*: Check connectivity using the network/connectivity helper before invoking geocoding. Disable the button or show a warning toast if offline.

---

## 3. Action Plan & Code Safeguards

1.  **District Filtering (EF Core)**:
    ```csharp
    var districts = await db.Stores
        .Where(s => s.IsActive == true 
            && s.Address2 != null 
            && s.Address2.Province == province 
            && s.Address2.District != null 
            && s.Address2.District != "")
        .Select(s => s.Address2.District)
        .Distinct()
        .ToListAsync(ct);
    ```
2.  **Geocoding Client (Dart)**:
    - Add custom User-Agent header in HTTP options.
    - Implement a boolean `isLocating` state in the manager to disable the button during API execution.
3.  **UI State Handling**:
    - Update `AdminStoreManager` to clear `selectedDistrict` whenever `selectedProvince` is mutated.
