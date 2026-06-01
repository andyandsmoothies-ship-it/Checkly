---
conversation_id: dcbfac81-a3e9-4fad-af42-bc281b403b75
created_at: 2026-05-31T17:50:00+07:00
topic: smart-audit-safeguards
type: diagnostic_report
status: COMPLETED
---

# SRE Diagnostics Failure Report: Smart Audit Source Safeguards

```text
[Auditor Client] ──(Offline Cache / Outbox)──► [Drift SQLite] ──(Sync Queue)──► [PostgreSQL DB]
      │                                             │                                 │
      ▼                                             ▼                                 ▼
[HUD Debounce Timer]                          [Drift Migration]              [Null Store GPS Check]
(Potential Hang Flop)                        (Startup Crash Flop)             (Inequality Query Flop)
```

---

## Executive Summary
This SRE Red-Team diagnostics audit reviews the structural design and code landscapes for the **Smart Audit Source Safeguards** epic. By analyzing database constraints, calculation boundaries, offline sync loops, and layout constraints, we have pre-identified **2 Critical Poison Pills** and **4 Warnings** that would crash or corrupt the production environment if left unmitigated.

---

## Discovered Failure Modes & Flops

### 1. 🔴 Critical: Store Location GPS Null Reference Crash
* **Target Area**: `lib/features/audit/widgets/audit_form_dialogs.dart` & `GpsService.dart`
* **Trigger Condition**: An auditor attempts to checkout/submit an audit for a store that has no GPS coordinates configured (`store.gpsLat` or `store.gpsLng` is `null`).
* **Root Cause**: `GpsService.checkProximity(...)` defines `storeLat` and `storeLng` as non-nullable `double` values. Passing a `null` value or calling it without checks triggers a Dart runtime type crash (`TypeError: Null is not a subtype of type double`).
* **Impact**: Total lockout. Auditors cannot submit or bypass audits for any unmapped stores, stopping all field execution.
* **Mitigation**: 
  1. Add an explicit `null` check on the store coordinates before calling `checkProximity`.
  2. If the store lacks coordinates, gracefully skip the geofence check (even in strict mode), log an SRE warning, and record `distanceMetersOff = null` in the database.

### 2. 🔴 Critical: Drift SQLite Migration Startup Crash
* **Target Area**: `lib/_shared/database/app_database.dart`
* **Trigger Condition**: Users upgrade to the new app version containing the geofencing database updates.
* **Root Cause**: Adding columns (`geofenceMode`, `geofenceRadiusMeters`, `isGeofenceBypassed`, `distanceMetersOff`, `displayNoun`) to Drift tables in `tables.dart` without writing matching column migration steps in `app_database.dart` causes database schema drift. Upon startup, SQLite tries to open the database and crashes instantly because the actual database schema does not match the generated code definitions.
* **Impact**: Critical app outage. 100% of upgrading users experience instant startup crashes.
* **Mitigation**:
  1. Increment the database `schemaVersion` to `34` in `app_database.dart`.
  2. Add an explicit migration step under `onUpgrade` for version `34` using `m.addColumn(...)` for every newly added column:
     - `CachedTemplates.displayNoun` (resolves an existing contract drift warning)
     - `CachedTemplates.geofenceMode`
     - `CachedTemplates.geofenceRadiusMeters`
     - `PendingSubmissions.isGeofenceBypassed`
     - `PendingSubmissions.distanceMetersOff`
     - `CachedSubmissions.isGeofenceBypassed`
     - `CachedSubmissions.distanceMetersOff`

### 3. 🟡 Warning: Card Title Flex Layout Overflow
* **Target Area**: Geofence Interstitial Warning/Block Sheets
* **Trigger Condition**: Rendering the geofencing warning dialog on a narrow mobile device (e.g., SE size) or in a headless CI widget testing environment, where the store has a long corporate name (e.g., *"VinMart+ Supermarket - 142 Le Hong Phong District 10"*).
* **Root Cause**: Placing store text horizontally next to status/warning icons inside a `Row` widget without wrapping it in flexible constraints causes the layout engine to throw a horizontal layout overflow exception.
* **Impact**: The UI breaks, showing yellow-and-black warning lines on production devices, and headless widget tests fail in the CI pipeline.
* **Mitigation**: Wrap the store name and address text in `Expanded` or `Flexible` widgets, and restrict vertical growth using `maxLines: 2` with `overflow: TextOverflow.ellipsis`.

### 4. 🟡 Warning: Asynchronous Timer Leak in Widget Tests
* **Target Area**: `AuditExecutionPage` HUD circular compliance widget
* **Trigger Condition**: Running Flutter unit/widget tests for the audit execution screen.
* **Root Cause**: The running compliance score HUD debounces calculations by 200ms using a standard Dart `Timer` inside its state controller. If the test disposes of the widget tree before the timer completes, the Flutter testing framework fails the test with: `A Timer is still pending even after the widget tree was disposed`.
* **Impact**: Breaks local and remote CI/CD test execution pipelines.
* **Mitigation**: Store a reference to the active `Timer` inside the controller/state and explicitly call `timer.cancel()` in the `dispose()` lifecycle callback.

### 5. 🟡 Warning: Drift SQLite Array Serialization Mismatches
* **Target Area**: `tables.dart` — SQLite lacks native array support
* **Trigger Condition**: Synchronizing template data containing metadata tags or arrays.
* **Root Cause**: SQLite does not support native array types. Storing complex collections (like category tags) directly will crash or corrupt database state.
* **Mitigation**: Serialize all array fields into a comma-separated String when writing to SQLite, and sanitize the outputs via `.where((t) => t.isNotEmpty).toList()` during retrieval.

---

## Action Plan & Test Mapping

The discovered failure modes must be explicitly covered by the test plan and checked during implementation:

| Failure Mode | Severity | Mitigation Task | Test Verification Case |
|---|---|---|---|
| Null Store Coordinates | 🔴 Critical | Fallback to Lax Mode + Warning Snackbar | `StoreGpsNull_GracefullySkipsGeofence_Test` |
| Drift Schema Drift | 🔴 Critical | Migrate schema version to 34 under `onUpgrade` | `DriftMigration_Version34_UpgradeSucceeds_Test` |
| Title Flex Overflow | 🟡 Warning | Wrap store header text in `Expanded` | `GeofenceDialog_LongStoreName_DoesNotOverflow_Test` |
| HUD Timer Leak | 🟡 Warning | Cancel debouncer timer inside `dispose()` | `HudWidget_DisposesCleanly_NoPendingTimers_Test` |
| SQLite Array Sync | 🟡 Warning | Comma-separated serialization + empty filtering | `Drift_ArraySerialization_SanitizesCommaOutputs_Test` |

---

## SRE Verdict
**SRE Verdict: BRITTLE**
The current design is highly vulnerable to runtime crashes on unmapped stores and startup crashes on mobile client upgrades. However, with the implementation of the detailed SRE safeguards mapped above, the architecture will achieve a **RESILIENT** state.
