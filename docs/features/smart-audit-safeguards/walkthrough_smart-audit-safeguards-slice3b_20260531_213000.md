---
ConversationID: e806043a-d178-457b-b974-d1e2c68fce54
---

# Walkthrough: Smart Audit Safeguards - Slice 3B (Offline Geofencing)

This document contains a structured walkthrough of the successfully completed **Slice 3B (Offline Geofencing)** of the Smart Audit Source Safeguards epic.

---

## 1. Architectural Design

The offline geofencing proximity rules evaluate whether the user's location is within a allowed distance threshold from the target store coordinates during the checkout/submission phase.

```
                  [Start Geofence validate()]
                              │
                    Is Mode == 'none'?
                              ├───► (Yes) ──► Allowed (Bypass)
                              └───► (No) ───► Continue
                                                 │
                                                 ▼
                                     Are Store Lat/Lng Null?
                                                 ├───► (Yes) ──► Check mode: Strict blocks, Lax warns
                                                 └───► (No) ───► Continue
                                                                    │
                                                                    ▼
                                                        Get GPS user coordinates
                                                                    │
                                                           Are Coordinates Null?
                                                                    ├───► (Yes) ──► Check mode: Strict blocks, Lax warns
                                                                    └───► (No) ───► Continue
                                                                                       │
                                                                                       ▼
                                                                            Calculate Haversine Proximity
                                                                            Is within max radius?
                                                                                       ├───► (Yes) ──► Allowed
                                                                                       └───► (No) ───► Check mode: Strict blocks, Lax warns
```

### High-Fidelity Design Characteristics
1. **Haversine Math Delegation**: The service delegates the actual distance math to the existing, tested `GpsService.checkProximity()` adapter.
2. **Bimodal Result Model**: `GeofenceValidationResult` maps out flags cleanly for the front-end to act on:
   - `allowed`: Determines if the submission action is valid to execute.
   - `mustBlock`: Signals strict blocking validation error dialog.
   - `mustWarn`: Signals lax validation warning dialog with override capability.
   - `distanceMeters`: Returns computed distance or null.
   - `error`: Explains the underlying validation failure.

---

## 2. Implementation Summary

We modified the following files to implement the offline geofencing validation service and wire it up:

### 1. `lib/_shared/services/geofence_service.dart`
- Added custom `GeofenceMode` class containing constants (`strict`, `lax`, `none`) to eliminate magic strings in business logic.
- Fully implemented `validate()` function mapping all strict, lax, and none mode boundary rules.
- Leveraged GPS device coordinates and store coordinates, delegating the Haversine math to `GpsService.checkProximity()`.

### 2. `lib/locator.dart`
- Registered the new `GeofenceService` in the GetIt dependency injection registry as a lazy singleton.

---

## 3. Automated Test Verification Results

To verify the implementation under all offline edge cases (out of range, missing store coordinates, missing GPS location, within range), we executed the dedicated unit test suite created by the QA team:

### Test File: `test/features/audit/geofence_logic_test.dart`
- **TC-GEOFENCE-01**: Verification of strict mode scenarios (Out of range, GPS unavailable, missing store coordinates).
- **TC-GEOFENCE-02**: Verification of lax mode scenarios (Out of range, GPS unavailable, missing store coordinates allowing bypass).
- **None Mode Verification**: Verification of unconditionally allowed bypasses.
- **Successful In-Range Verification**: Verification of successful strict and lax close-range submissions.

### Test Execution Command & Results
All tests passed with zero failures or compile errors:

```powershell
rtk flutter test test/features/audit/geofence_logic_test.dart
```

```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/geofence_logic_test.dart
00:00 +0: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario A: Out of Range blocks submission
00:00 +1: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario B: GPS Unavailable blocks submission with error message
00:00 +2: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario C: Store location missing blocks submission with error message
00:00 +3: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario A: Out of Range warns but allows bypass
00:00 +4: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario B: GPS Unavailable warns but allows bypass
00:00 +5: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario C: Store location missing warns but allows bypass
00:00 +6: GeofenceService - None Mode Skips geofence check and allows submission unconditionally
00:00 +7: GeofenceService - Successful In-Range Proximity Strict Mode: allows submission without warning or blocks
00:00 +8: GeofenceService - Successful In-Range Proximity Lax Mode: allows submission without warning or blocks
00:00 +9: All tests passed!
```

---

## 4. Full Audit Regression Verification

We ran a comprehensive verification sweep across all existing 93 audit-related unit tests to guarantee zero side effects:

```powershell
rtk flutter test test/features/audit/
```

```
All 93 tests passed!
Exit code: 0
```

---

## 5. Handoff to Next Slice

Slice 3B (Offline Geofencing) is 100% completed, fully tested, and green. Both parts of Slice 3 are now fully integrated and ready.
