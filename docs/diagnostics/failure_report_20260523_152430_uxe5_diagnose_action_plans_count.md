# Diagnostic Report: Area Action Plans Count Bug (am1)

## 1. Description of the Anomaly
**Symptom**: The Area Manager (`am1`) homepage reported "Area Action Plans" as `0`. However, when navigating to the detailed Action Plans view, the system accurately displayed `All (2)`, `Open (1)`, and `Verify (1)`.
**Severity**: High (UI/Data Mismatch). The manager dashboard is providing false negatives about pending work.

## 2. Evidence Gathered
*   The `am1` user holds the `UserPersona.areaManager` role and has multiple stores in their scope.
*   The `DashboardManager` dart code paths to populate `ManagerDashboardState` handle both `storeManager` and `areaManager` identically via the `_loadManagerState` method.
*   The drift local database properly cached the action plans, as evidenced by the detailed Action Plans page returning correct results.
*   The `_loadManagerState` function incorrectly relied on the local database's `cachedStores.limit(1)` to fetch a `storeId`, then explicitly requested action plan counts *for that specific single store* (`getOpenApCountForStore(storeId)`).

## 3. Root Cause Analysis
The dashboard's data retrieval logic was inappropriately constricting the "Area" aggregation. Because an Area Manager governs multiple stores, their `cachedStores` drift table contains several records. By retrieving only the first store and filtering dashboard metrics exclusively by that `storeId`, the system was entirely blinding itself to action plans that originated from the Area Manager's *other* stores. Consequently, if the arbitrarily selected first store had 0 action plans, the dashboard incorrectly summarized the entire area as having 0.

## 4. Implementation Fix
The logic inside `DashboardManager._loadManagerState` was refactored:
*   Introduced a persona-aware query branch to determine if the user is an `areaManager` or `storeManager`.
*   If `UserPersona.areaManager`, the dashboard now invokes `getMyOpenApCount()` and `getGlobalOverdueApCount()`. These queries compute the sums globally across the local drift cache. Because the local `cachedActionPlans` table is strictly scoped (by the background sync process) to only the stores the Area Manager governs, this perfectly represents the "Area Action Plans" count.
*   If `UserPersona.storeManager`, the dashboard preserves the prior behavior of scoping to their specific `storeId`.
*   Similar changes were applied to ensure `Area Avg Score` is calculated precisely across all scope-assigned stores, not just the first one.

## 5. Blast Radius & Verification
*   **Affected Personas**: `areaManager`.
*   **Unaffected Personas**: `auditor`, `admin`, `storeManager`.
*   **Actionable Advice**: The bug fix resolves the data consistency issue locally without requiring any backend schema or endpoint modifications.
