---
ConversationID: 7e84733f-638e-4569-87dd-9901b796b109
---

# Test Specification: Smart Audit Safeguards - Slice 3B (Offline Geofencing)

This document lists the test cases, expected assertions, and verification parameters for `GeofenceService` offline geofencing proximity rules.

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\implementation_plan_smart-audit-safeguards-slice3_20260531_203000.md`

## 1. Offline Geofencing Tests

### TC-GEOFENCE-01: Strict Geofence Mode Validation Rules
- **Scenario A: Out of Range blocks submission**:
  - Sets user coordinates far away from store coordinates.
  - Assertions: `allowed = false`, `mustBlock = true`, `mustWarn = false`, `distanceMeters = computedDistance`.
- **Scenario B: GPS Unavailable blocks submission**:
  - GPS returns null.
  - Assertions: `allowed = false`, `mustBlock = true`, `mustWarn = false`, `error = 'GPS location is unavailable'`.
- **Scenario C: Store location missing blocks submission**:
  - Store coordinates are null.
  - Assertions: `allowed = false`, `mustBlock = true`, `mustWarn = false`, `error = 'Store location is missing'`.

### TC-GEOFENCE-02: Lax Geofence Mode Validation Rules
- **Scenario A: Out of Range warns but allows bypass**:
  - User coordinates out of range.
  - Assertions: `allowed = true`, `mustBlock = false`, `mustWarn = true`, `distanceMeters = computedDistance`.
- **Scenario B: GPS Unavailable warns but allows bypass**:
  - GPS returns null.
  - Assertions: `allowed = true`, `mustBlock = false`, `mustWarn = true`, `error = 'GPS location is unavailable'`.
- **Scenario C: Store location missing warns but allows bypass**:
  - Store coordinates are null.
  - Assertions: `allowed = true`, `mustBlock = false`, `mustWarn = true`, `error = 'Store location is missing'`.

### None Mode: Skips Proximity Verification
- **Scenario: None Mode**:
  - GPS locator is NOT queried.
  - Assertions: `allowed = true`, `mustBlock = false`, `mustWarn = false`.

### Successful In-Range Proximity Cases
- **Scenario: Strict / Lax Mode within range**:
  - Assertions: `allowed = true`, `mustBlock = false`, `mustWarn = false`, `distanceMeters = computedDistance`.

---

## 2. Running Verification

To execute these tests, run:
```powershell
cmd /c flutter test test/features/audit/geofence_logic_test.dart
```

## Decision Log
* **Haversine Math Delegation**: Decided to delegate core distance calculations to `GpsService.checkProximity()` to leverage existing and tested calculations, minimizing duplicate business logic.
* **Bimodal Proximity Result**: Created a structured `GeofenceValidationResult` token mapping out `allowed`, `mustBlock`, `mustWarn`, `distanceMeters`, and `error` parameters, fully satisfying the specifications in both strict and lax modes.

## Verification Handoff
Please return to the Builder role and pass this file path to implement the geofence validation rules:
`c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\test_spec_smart-audit-safeguards-slice3b_20260531_192000.md`

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/geofence_logic_test.dart
00:00 +0: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario A: Out of Range blocks submission
00:00 +0 -1: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario A: Out of Range blocks submission [E]
  Expected: false
    Actual: <true>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 53:7   main.<fn>.<fn>
  
00:00 +0 -1: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario B: GPS Unavailable blocks submission with error message
00:00 +0 -2: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario B: GPS Unavailable blocks submission with error message [E]
  Expected: false
    Actual: <true>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 73:7   main.<fn>.<fn>
  
00:00 +0 -2: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario C: Store location missing blocks submission with error message
00:00 +0 -3: GeofenceService - Strict Mode (TC-GEOFENCE-01) Scenario C: Store location missing blocks submission with error message [E]
  Expected: false
    Actual: <true>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 90:7   main.<fn>.<fn>
  
00:00 +0 -3: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario A: Out of Range warns but allows bypass
00:00 +0 -4: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario A: Out of Range warns but allows bypass [E]
  Expected: true
    Actual: <false>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 134:7  main.<fn>.<fn>
  
00:00 +0 -4: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario B: GPS Unavailable warns but allows bypass
00:00 +0 -5: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario B: GPS Unavailable warns but allows bypass [E]
  Expected: true
    Actual: <false>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 154:7  main.<fn>.<fn>
  
00:00 +0 -5: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario C: Store location missing warns but allows bypass
00:00 +0 -6: GeofenceService - Lax Mode (TC-GEOFENCE-02) Scenario C: Store location missing warns but allows bypass [E]
  Expected: true
    Actual: <false>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 171:7  main.<fn>.<fn>
  
00:00 +0 -6: GeofenceService - None Mode Skips geofence check and allows submission unconditionally
00:00 +1 -6: GeofenceService - Successful In-Range Proximity Strict Mode: allows submission without warning or blocks
00:00 +1 -7: GeofenceService - Successful In-Range Proximity Strict Mode: allows submission without warning or blocks [E]
  Expected: <15>
    Actual: <null>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 236:7  main.<fn>.<fn>
  
00:00 +1 -7: GeofenceService - Successful In-Range Proximity Lax Mode: allows submission without warning or blocks
00:00 +1 -8: GeofenceService - Successful In-Range Proximity Lax Mode: allows submission without warning or blocks [E]
  Expected: <15>
    Actual: <null>
  
  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\features\audit\geofence_logic_test.dart 276:7  main.<fn>.<fn>
  
00:00 +1 -8: Some tests failed.
</test_trace>

<forensic_evidence>
1. Created geofence_service.dart stub inside lib/_shared/services/geofence_service.dart.
2. Created geofence_logic_test.dart inside test/features/audit/geofence_logic_test.dart.
3. Executed command: `flutter test test/features/audit/geofence_logic_test.dart`
</forensic_evidence>
