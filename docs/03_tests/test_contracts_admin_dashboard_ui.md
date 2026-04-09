# ATDD Verification Contracts: Admin Dashboard UI (PBAC Slice 2)

## Dependency Context Array
The Builder must provide or mock the following to fulfill these contracts:
- `ConnectivityService` (Mockable Listenable/Stream)
- `AdminApiService` (Mockable `getRoles`, `getCapabilityCatalog`, `grantCapability`, `revokeCapability`)
- `PolicyManager` (Mockable `can('admin:manage_roles')`)
- `RoleManager` (State holder)

## Gap Analysis (Saboteur ACs)
*   **Gap 1 (In-Flight Drop):** If connectivity drops *while* an atomic grant request is actively in-flight, the UI must immediately render the lock screen and prevent further taps, discarding the local state transition.
*   **Gap 2 (Restoration):** When connectivity returns to true, the UI must not be permanently stuck rendering the "Offline" lock screen; it must automatically restore the data view.

## Contract Matrix

| ID | Title / Target Behavior | State Matrix | Private Method Access | Why it fails now (RED) |
|---|---|---|---|---|
| **AT-01** | `RoleListPage_WhenOffline_ShowsOfflineLock`| Empty/Offline | N/A | `RoleListPage` and `ConnectivityGuard` do not exist. |
| **AT-02** | `RoleDetailPage_WhenConnectionDrops_HidesCheckboxes` | Success -> Error | N/A | `RoleDetailPage` does not react to `ConnectivityService` dynamically. |
| **AT-03** | `RoleDetailPage_WhenNoCapability_CheckboxesDisabled` | Read-only | N/A | `PolicyManager` check on checkboxes is missing. |
| **AT-04** | `RoleDetailPage_GrantRevoke_FiresServiceAndReloads` | Loading -> Success | N/A | `grantCapability` hook logic and automatic refresh missing. |
| **AT-05** | `RoleDetailPage_AtomicFailure_SnackBar` (Negative) | Error | N/A | Failure logic and non-mutation of local UI state missing. |
