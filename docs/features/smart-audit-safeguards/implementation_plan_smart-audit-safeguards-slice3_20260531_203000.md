<latent_space_scratchpad>
Thinking Process - Slice 3:
- Goal: Implement client-side debounced score calculations (200ms) and the offline geofence validation helper class.
- Risks & Edge Cases:
  - Debounce timer leaks if `AuditManager` is disposed. We must cancel the timer in the `dispose` method.
  - Race condition: If the auditor selects an option and immediately hits "Submit" within 200ms, the score recalculation timer would not have fired yet. We MUST synchronously cancel any pending debounce timer and execute `_recalculateScore()` immediately at the beginning of the submit pipeline in `_submitAuditLogic`.
  - GPS Coordinate Availability: Coordinates for the user or the store might be null. We need robust logic inside `GeofenceService` to handle missing coordinates gracefully based on the selected `geofenceMode` (lax vs strict vs none).
  - Under strict mode, missing coordinates (GPS failed/timeout) must block submission.
  - Under lax mode, missing coordinates allows submission but raises a warning and logs it as bypassed.
- Slicing:
  - Slice 3 focus: Pure business logic and algorithms. We will write `GeofenceService` and modify `AuditManager` to support debouncing.
  - We will NOT build UI widgets or dialog screens in Slice 3; those belong entirely to Slice 4.
</latent_space_scratchpad>

## Input Lineage

- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\analysis_epic_20260531_162500.md`

## Executive Summary & Out of Scope

This implementation plan covers the business logic and algorithmic validation phase (Slice 3) of the **Smart Audit Source Safeguards** epic. 

### In-Scope
1. **Auditor HUD Debouncing (200ms)**: Refactoring `AuditManager` to update answer state immediately for interactive responsiveness while debouncing the expensive compliance score recalculation loop by 200ms.
2. **Offline Geofence Distance Calculation Helper**: Creating a standalone `GeofenceService` to evaluate user location proximity to the store using `GpsService` and local configuration tokens.
3. **DI Registrations**: Registering `GeofenceService` in `lib/locator.dart`.
4. **Logic Unit Tests**: Writing comprehensive isolated unit tests for both debouncing and geofence state evaluation rules.

### Out of Scope (YAGNI)
1. **Auditor HUD UI Component**: Building the HUD circular score widget is deferred to Slice 4.
2. **Warning/Blocking Interstitials**: Creating warning sheets or blocking modal dialogs is deferred to Slice 4.
3. **Endpoint Integration**: Routing the geofence bypass parameters to the outbox and sync engine is deferred to the UI and submission integration in Slice 4.

---

## Risk Assessment

### 1. Debounce Input-Checkout Concurrency Gap
* **Risk**: Tapping an answer and immediately submitting the audit within 200ms bypasses score calculations, causing the sync payload to submit stale scoring telemetry.
* **Mitigation**: Synchronously cancel `_scoreDebounceTimer` and execute `_recalculateScore()` immediately at the entry point of `_submitAuditLogic` to guarantee fresh client score calculations.

### 2. Battery Warming & Background GPS Drain
* **Risk**: High geofence checking frequencies during audit execution drains device battery.
* **Mitigation**: Evaluate geofence boundaries lazily on-demand when user attempts to submit the audit, rather than polling continuous coordinates in the background.

---

## System Context

### 1. Offline & Sync Loop
- `GeofenceService` evaluates boundaries entirely offline by comparing local device position coordinates with `gpsLat` and `gpsLng` cached inside the SQLite `CachedStores` table.
- Template geofencing controls (`geofenceMode`, `geofenceRadiusMeters`) are retrieved offline from `CachedTemplates`.

### 2. Dependency Injection
- `GeofenceService` requires a singleton registration in `lib/locator.dart` and depends on `GpsService` for location fetching and Haversine math.

---

## Lifecycle Context

We define the 4-State Matrix for the Geofence Evaluation lifecycle:

| State | Context & Handling |
|---|---|
| **Success** | Position is within template boundaries; validation passes seamlessly without interruptions. |
| **Loading** | Retrieving current device GPS position. Shimmer/spinner displays during coordinate acquisition. |
| **Error** | GPS coordinate acquisition fails (timeout or permissions denied). Handled bimodally: Strict mode blocks; Lax mode warns. |
| **Empty** | Missing store coordinates in database. Handled bimodally: Strict mode blocks; Lax mode warns. |

---

## Constraint Traceability

| Constraint ID | Source Constraint | Description | Test Contract ID |
|---|---|---|---|
| **C-HUD-01** | Epic Section 1 | 200ms debounced running compliance score | **TC-DEBOUNCE-01** |
| **C-GEO-01** | Epic Section 2 | Strict geofence mode blocks out-of-range | **TC-GEOFENCE-01** |
| **C-GEO-02** | Epic Section 2 | Lax geofence mode warns but allows bypass | **TC-GEOFENCE-02** |
| **C-GEO-03** | Epic Section 2 | Offline geofence Haversine calculations | **TC-GEOFENCE-03** |

---

## Test Contracts

### TC-DEBOUNCE-01: Compliance Score Calculation Debounce
- **Description**: Verifies that answer mutations do not trigger synchronous calculation stutters but debounce by 200ms.
- **Entry State**: `AuditManager` initialized with template.
- **Trigger**: Mutate answers three times in rapid succession (under 200ms total).
- **Exit State Guaranteed**:
  - `_answers` updates immediately on each mutation.
  - `_recalculateScore` executes exactly ONCE (200ms after the last mutation).
  - Calling `submitAudit()` triggers an immediate synchronous recalculation.

### TC-GEOFENCE-01: Strict Geofence Mode Validation Rules
- **Description**: Verifies that Strict Mode geofencing blocks submissions if out of range or if GPS is unavailable.
- **Entry State**: `GeofenceService` with strict mode config.
- **Scenario A (Out of Range)**: Distance deviation > radius.
  - **Exit State**: `allowed = false`, `mustBlock = true`, `distanceMeters = computedDistance`.
- **Scenario B (GPS Unavailable)**: GPS returns null.
  - **Exit State**: `allowed = false`, `mustBlock = true`, `error = 'GPS location is unavailable'`.

### TC-GEOFENCE-02: Lax Geofence Mode Validation Rules
- **Description**: Verifies that Lax Mode warns but allows bypass when out of range or if GPS is unavailable.
- **Entry State**: `GeofenceService` with lax mode config.
- **Scenario A (Out of Range)**: Distance deviation > radius.
  - **Exit State**: `allowed = true`, `mustWarn = true`, `distanceMeters = computedDistance`.
- **Scenario B (GPS Unavailable)**: GPS returns null.
  - **Exit State**: `allowed = true`, `mustWarn = true`, `error = 'GPS location is unavailable'`.

---

## Test Fixture & Payloads

### 1. Mock GPS Service State
Mock `Position` returned by coordinates locator mock:
```dart
Position(
  latitude: 21.028511,
  longitude: 105.804817,
  timestamp: DateTime.now(),
  accuracy: 5.0,
  altitude: 10.0,
  heading: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
);
```

---

## Tools & Commands

### Skills Required
- `flutter-architecture`: get_it service locator patterns.
- `tdd`: Classical testing structure for state machines and validation logic.

### Verification Command
Run Flutter unit tests verifying the logic constraints:
```powershell
cmd /c rtk flutter test test/features/audit/geofence_logic_test.dart
```

---

## Proposed Changes

```
[UI/UX]
  │
  ▼
[AuditManager] ──(Debounces 200ms)──► [ScoringEngine]
  │
  ▼
[GeofenceService] ──(Checks Proximity)──► [GpsService]
```

### Proposed File Modifications

#### 1. `lib/_shared/services/geofence_service.dart` [NEW]
- Implements `GeofenceService` class to evaluate offline geofence proximity rules based on templates and user coordinates.

#### 2. `lib/locator.dart` [MOD]
- Register `GeofenceService` lazy singleton:
  ```dart
  di.registerLazySingleton<GeofenceService>(() => GeofenceService(di<GpsService>()));
  ```

#### 3. `lib/features/audit/manager/audit_manager.dart` [MOD]
- Add `Timer? _scoreDebounceTimer` and update calculations `_recalculateScore` to cancel active timers.
- Add `void _recalculateScoreDebounced()` helper method.
- Update `setAnswer`, `clearAnswerValue`, `setCcp`, and `setRisk` to delegate calculation tasks to `_recalculateScoreDebounced()`.
- Add `dispose` method override to explicitly cancel any active debounce timers.

#### 4. `test/features/audit/geofence_logic_test.dart` [NEW]
- Implements all test cases for `GeofenceService` (lax/strict validations, missing store location, GPS failed) and `AuditManager` debounced recalculations.

---

## Concept Diagram

```
[Auditor Mutates Input]
          │
          ├──► Update local answer immediately
          ├──► Call notifyListeners() (Snappy UI option toggle)
          ├──► Cancel pending Timer
          └──► Start new Timer (200ms)
                     │
            (Inactivity for 200ms)
                     │
                     ▼
           Execute _recalculateScore()
           Call notifyListeners() (HUD updates smoothly)
```

---

## Execution Slices

### Slice 3A: Business Logic & Calculations Debouncer
* **Micro-Spec Summary**: Refactor the Client Score calculation inside `AuditManager` to utilize a 200ms debouncing mechanism.
* **Value**: Removes layout recalculation stutter on high input mutation frequencies.
* **Entry State**: `AuditManager` instantiated.
* **Exit State Guaranteed**: Input updates are immediate, but compilation/score computations debounce by 200ms.
* **Complexity**: Medium.

### Slice 3B: Offline Geofence Validator Helper
* **Micro-Spec Summary**: Build `GeofenceService` wrapping Haversine distance calculations into bimodal rules.
* **Value**: Secures audit integrity without degrading user experience or battery.
* **Entry State**: `GeofenceService` registered in DI.
* **Exit State Guaranteed**: Proximity is evaluated accurately and outputs a structured `GeofenceValidationResult` token.
* **Complexity**: Easy.

---

## Verification Plan

### 1. Automating Validation
- Run unit test suites to confirm both debouncing timing and validation rules work perfectly:
  `cmd /c rtk flutter test test/features/audit/geofence_logic_test.dart`

### 2. Manual Inspection
- Inspect logs of the test suite ensuring no asynchronous timer leaks or exception traps occur during teardowns.

---

<command_logs>
1. Run rtk flutter test to confirm current code base health.
</command_logs>

## Handoff Block

- **Handoff Target Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\implementation_plan_smart-audit-safeguards-slice3_20260531_203000.md`

### Sequence of Slices
- **Slice 3A (HUD Debouncing)**: Plan -> Write Unit Tests -> Build
- **Slice 3B (Offline Geofencing)**: Plan -> Write Unit Tests -> Build

Please execute the slices **ONE AT A TIME**.
