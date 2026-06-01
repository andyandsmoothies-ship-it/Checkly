---
conversation_id: "e806043a-d178-457b-b974-d1e2c68fce54"
type: "walkthrough"
topic: "smart-audit-safeguards-slice1-walkthrough"
timestamp: "2026-05-31T21:35:00"
---

# Walkthrough: Smart Audit Safeguards - Slice 1 (Database & Sync Mapping)

```text
[C# DbContext Mappings] ──► [EF Core Migration] ──► [Postgres Tables (templates, submissions)]
          ▲                                                        │
          │ (Sync Engine Mapping / Delta Sync Flow)                │
          ▼                                                        ▼
[Drift tables.dart Schema] ──► [SQLite v34 Migration] ──► [Drift Local Database (cached_*, pending_sub)]
```

This walkthrough outlines the exact changes made and verified in **Slice 1** of the **Smart Audit Source Safeguards** epic, which implements the primary database layers, mappings, schemas, and migrations for both the central PostgreSQL instance and the offline-first Flutter Drift SQLite cache.

---

## 1. Mapped Changes Walkthrough

### 1.1. C# EF Core Backend Persistance

To support central geofencing rules and log offline compliance telemetry on audits, we extended the Entity Framework Core persistence models:

1. **`Template.cs`**:
   - Added `GeofenceMode` (`string`, defaults to `"none"`) to control the geofencing enforcement level (`none`, `lax`, `strict`).
   - Added `GeofenceRadiusMeters` (`int`, defaults to `100`) to define the maximum allowed distance of the auditor from the target store coordinates.

2. **`Submission.cs`**:
   - Added `IsGeofenceBypassed` (`bool?`, nullable) telemetry flag to identify whether the check was bypassed.
   - Added `DistanceMetersOff` (`int?`, nullable) to log how many meters the device GPS coordinates drifted from the target store location.

3. **`TemplateConfiguration.cs`**:
   - Mapped `GeofenceMode` to PostgreSQL column `geofence_mode` (`VARCHAR`, default value `'none'`).
   - Mapped `GeofenceRadiusMeters` to column `geofence_radius_meters` (`INT`, default value `100`).

4. **`SubmissionConfiguration.cs`**:
   - Mapped `IsGeofenceBypassed` to column `is_geofence_bypassed` (`BOOLEAN`, nullable).
   - Mapped `DistanceMetersOff` to column `distance_meters_off` (`INT`, nullable).

### 1.2. PostgreSQL Schema Migration

The database schema changes were packed into an EF Core migration:
- **Migration script**: `AddSmartAuditSafeguardsColumns`
- **Output**: Safely injects nullable telemetry fields to the `submissions` table and configures default geofencing columns on the `templates` table without locking production database instances.

---

## 2. Drift SQLite Offline Schema & Upgrades (Flutter)

To ensure offline-first support, we upgraded the local client-side SQLite schema so that cached and pending records could capture and sync geofencing properties:

### 2.1. Local Table Mappings (`tables.dart`)
We added the new properties to 3 crucial Drift table definitions:
1. **`CachedTemplates`**:
   - Added `geofenceMode` (`TextColumn`, defaults to `'none'`).
   - Added `geofenceRadiusMeters` (`IntColumn`, defaults to `100`).
   - Also integrated a missing helper `displayNoun` (`TextColumn`, nullable) column to align with legacy settings.
2. **`CachedSubmissions`**:
   - Added `isGeofenceBypassed` (`BoolColumn`, nullable).
   - Added `distanceMetersOff` (`IntColumn`, nullable).
3. **`PendingSubmissions`** (The local offline outbox queue):
   - Added `isGeofenceBypassed` (`BoolColumn`, nullable).
   - Added `distanceMetersOff` (`IntColumn`, nullable).

### 2.2. Schema Version Migration (`app_database.dart`)
We incremented `schemaVersion` to **`34`** and added a safe, explicit upgrade routine under the `onUpgrade` handler to prevent SQLite startup crashes when upgrading existing databases:

```dart
if (from < 34) {
  // v34: Smart Audit Safeguards columns
  await m.addColumn(cachedTemplates, cachedTemplates.displayNoun);
  await m.addColumn(cachedTemplates, cachedTemplates.geofenceMode);
  await m.addColumn(cachedTemplates, cachedTemplates.geofenceRadiusMeters);
  await m.addColumn(cachedSubmissions, cachedSubmissions.isGeofenceBypassed);
  await m.addColumn(cachedSubmissions, cachedSubmissions.distanceMetersOff);
  await m.addColumn(pendingSubmissions, pendingSubmissions.isGeofenceBypassed);
  await m.addColumn(pendingSubmissions, pendingSubmissions.distanceMetersOff);
}
```

---

## 3. Automated Quality Gates

All checks compile and execute with **zero warnings** and **zero errors**:

- **Backend compilation**: `rtk dotnet build` ──► 🟢 **0 errors, 0 warnings**
- **Flutter compilation**: `dart run build_runner build` ──► 🟢 **Successful code generation**
- **Backend tests**: `rtk dotnet test` ──► 🟢 **All persistence entity verification tests pass**
- **Frontend migration tests**: `rtk flutter test` ──► 🟢 **All Drift migration tests pass**

---

## 4. Verification & Resiliency Proofs

We implemented and verified robust test suites verifying the database schemas:

1. **Backend Mapping Test (`SmartAuditSafeguards_Slice1_Tests.cs`)**:
   - `TemplateEntity_HasGeofencePropertiesAndMappings`: Verifies the entity has default mapping rules to snake_case and defaults correctly.
   - `SubmissionEntity_HasGeofenceTelemetryPropertiesAndMappings`: Verifies the fields are perfectly nullable.

2. **Frontend Migration Test (`drift_migration_smart_audit_safeguards_test.dart`)**:
   - `TC-SAFEGUARDS-01`: Verifies that database upgrades increments the schema version to 34.
   - `TC-SAFEGUARDS-02`: Uses SQLite `PRAGMA table_info` to assert that `CachedTemplates` has `display_noun`, `geofence_mode` (with `'none'` default), and `geofence_radius_meters` (with `100` default).
   - `TC-SAFEGUARDS-03` & `TC-SAFEGUARDS-04`: Asserts that both `CachedSubmissions` and `PendingSubmissions` have nullable `is_geofence_bypassed` and `distance_meters_off` columns.

---

## 5. Architectural Gotchas Resolved
- **Gotcha: Drift `read<dynamic>` Type Mapping Crash** (Added to `lib/GEMINI.md`):
  > When reading database query rows dynamically (e.g., asserting metadata or defaults returned from PRAGMA table_info in unit tests), never use `row.read<dynamic>('column_name')`. Drift's internal mapping system does not support runtime dynamic types, which throws a runtime exception. Always use concrete nullable types like `row.read<String?>('dflt_value')` to ensure safe database inspections.
