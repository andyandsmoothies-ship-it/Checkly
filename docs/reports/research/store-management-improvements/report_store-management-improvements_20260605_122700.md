---
conversation_id: "196516cd-9f45-4144-9eb4-14a4e0a8f483"
type: "research_report"
topic: "store-management-improvements-ideation"
created_at: "2026-06-05T12:27:00+07:00"
---

# Research Report: Store Management Feature Improvements

This report lists ideas to make the Store Management screen better for administrators.

---

## 1. Improvement Ideas

### Idea A: Location Filtering (Province / District / Ward)
Currently, stores have structured address fields (`addressProvince`, `addressDistrict`, `addressWard`), but the UI does not allow filtering by these values. 

**How it works (Logic Flow):**
```
[Filter Pill: Province] --> [Show list of unique Provinces present in retrieved stores]
                       --> [User selects "Ho Chi Minh City"]
                       --> [UI filters stores matching "addressProvince == 'Ho Chi Minh City'"]
```

*   **Filter Pill**: Add a dropdown filter pill next to the "Status" filter pill.
*   **Dynamic Options**: Extract the list of unique provinces from the current stores list to avoid hardcoding.
*   **Sub-filtering**: If a Province is selected, show a second pill for "District" containing only districts inside that province.

---

### Idea B: Manager / Assignment Filtering
Stores are assigned to Store Managers (`managerName`) and Area Managers (`areaManagerName`). Administrators often need to find which stores a specific manager is responsible for.

**How it works (Logic Flow):**
```
[Filter Pill: Manager] --> [Show list of unique managers from the loaded stores]
                      --> [User selects "John Doe"]
                      --> [UI filters where managerName == "John Doe" or areaManagerName == "John Doe"]
```

*   **Pill UI**: Add a filter pill named "Manager".
*   **Search integration**: Or extend the search bar to matching `managerName` or `areaManagerName` strings.

---

### Idea C: Distance / Proximity Sorting (GPS Location)
Since stores contain `gpsLat` and `gpsLng` coordinates, the app can utilize the device's current GPS location to sort stores by distance.

**How it works (Logic Flow):**
```
[Device GPS] -------------> [Calculate distance to each store coordinates]
[UI: Sort Dropdown] ------> [Sort stores list by calculated distance ascending]
```

*   **Sort Options**: A sort menu to choose:
    *   `Nearest First` (requires GPS permission)
    *   `Alphabetical (A-Z / Z-A)`
    *   `Creation Date (Newest / Oldest)`
*   **Distance Indicator**: Display the distance (e.g., `1.2 km away`) directly on the `StoreCard` when sorted by proximity.

---

### Idea D: "Use Current Location" in Store Creation
When creating a new store, typing GPS coordinates manually is slow and prone to errors.

**How it works (Logic Flow):**
```
[User clicks "Pin My Current Location"] 
  --> [Fetch current GPS position]
  --> [Pre-fill Latitude and Longitude fields]
  --> [Animate map marker to new position]
```

*   **Button UI**: Add an icon button with a GPS locator icon next to the Latitude/Longitude text fields in `StoreFormBody`.

---

## 2. Recommendation

For the next step, implementing **Idea A (Province Filter Pill)** is highly recommended because:
1. It uses existing DTO properties (`addressProvince`) that are already populated.
2. It does not require any backend updates or external device permissions (unlike GPS features).
3. It fits perfectly into the existing filter bar layout next to the "Status" filter pill.
