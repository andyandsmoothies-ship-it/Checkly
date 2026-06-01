---
ConversationID: 7e84733f-638e-4569-87dd-9901b796b109
---

# Test Specification: Smart Audit Safeguards (Slice 1)

This document lists the test cases, expected assertions, and verification parameters for backend and frontend data schemas to support smart audit geofence controls and reskin display customization.

## 1. Backend (EF Core) Entity Tests

### Test Case C#-01: Template Entity Geofence and Display Properties
- **Method**: `TemplateEntity_HasGeofencePropertiesAndMappings`
- **Verification**:
  - `GeofenceMode` is defined on `Template` entity and mapped correctly.
  - `GeofenceRadiusMeters` is defined on `Template` entity and mapped correctly.
  - `DisplayNoun` is defined on `Template` entity and mapped correctly.
  - DB mapping defines `GeofenceMode` as a required string column with a default value of `"none"`.
  - DB mapping defines `GeofenceRadiusMeters` as a required integer column with a default value of `100`.
  - DB mapping defines `DisplayNoun` as an optional string column.

### Test Case C#-02: Submission Entity Geofence Telemetry Properties
- **Method**: `SubmissionEntity_HasGeofenceTelemetryPropertiesAndMappings`
- **Verification**:
  - `IsGeofenceBypassed` is defined on `Submission` entity as a nullable boolean.
  - `DistanceMetersOff` is defined on `Submission` entity as a nullable integer.
  - DB mapping defines these columns as optional in EF Core configuration.

---

## 2. Frontend (Drift Database) Schema Tests

### Test Case Dart-01: Schema Version Verification
- **Test ID**: `TC-SAFEGUARDS-01`
- **Verification**: `AppDatabase.schemaVersion` must equal `34`.

### Test Case Dart-02: CachedTemplates Table Schema
- **Test ID**: `TC-SAFEGUARDS-02`
- **Verification**:
  - `display_noun` column exists, is nullable.
  - `geofence_mode` column exists, is not null, defaults to `'none'`.
  - `geofence_radius_meters` column exists, is not null, defaults to `100`.

### Test Case Dart-03: CachedSubmissions Table Schema
- **Test ID**: `TC-SAFEGUARDS-03`
- **Verification**:
  - `is_geofence_bypassed` column exists, is nullable.
  - `distance_meters_off` column exists, is nullable.

### Test Case Dart-04: PendingSubmissions Table Schema
- **Test ID**: `TC-SAFEGUARDS-04`
- **Verification**:
  - `is_geofence_bypassed` column exists, is nullable.
  - `distance_meters_off` column exists, is nullable.
