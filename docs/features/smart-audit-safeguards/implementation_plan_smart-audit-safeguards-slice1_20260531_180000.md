<latent_space_scratchpad>
Thinking Process:
- Topic: Smart Audit Source Safeguards - Slice 1 (Database & Sync Mapping)
- The user has assigned the Architect role with Scout persona.
- The request is to analyze/shape **Slice 1 only** using the `/analyze-feature` workflow.
- Slice 1 covers C# EF Core Postgres schema entities/configurations, backend migrations, and Flutter Drift SQLite tables and schema version 34 migrations.
- Discovered Failure Modes from the Red-Team Failure Report:
  1. `Null Store Location GPS`: In Slide 1, we must guarantee that all new telemetry fields (`is_geofence_bypassed`, `distance_meters_off` in Postgres, and `isGeofenceBypassed`, `distanceMetersOff` in Drift SQLite) are fully nullable. This allows unmapped store coordinates to record `null` instead of crashing.
  2. `Drift SQLite Migration Startup Crash`: Upgrading the Drift database without explicit column migrations causes startup crashes. We must increment `schemaVersion` to `34` in `app_database.dart` and add `m.addColumn(...)` under `onUpgrade` for version 34 for all newly added columns, including `CachedTemplates.displayNoun` (to fix a prior drift warning), `CachedTemplates.geofenceMode`, `CachedTemplates.geofenceRadiusMeters`, `PendingSubmissions.isGeofenceBypassed`, `PendingSubmissions.distanceMetersOff`, `CachedSubmissions.isGeofenceBypassed`, and `CachedSubmissions.distanceMetersOff`.
- No new UI components are built in Slice 1. It is purely architectural foundation.
- Route selection: Route 2 (Unit Tests First) because this slice modifies database schema structures on both sides, which requires unit test validation to prevent startup or integration regressions.
</latent_space_scratchpad>

## Input Lineage

- **Source Epic Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\analysis_epic_20260531_162500.md`
- **SRE Diagnostics Failure Report**: `c:\Users\HP\Documents\GitHub\Checkly\docs\reports\diagnostics\smart-audit-safeguards\audit_failure_report_20260531_175000.md`

---

## Executive Summary & Out of Scope

### High-Level Goal
Implement the database layer foundations for the **Smart Audit Source Safeguards** epic. This includes updating the PostgreSQL schema configurations and migrations via Entity Framework Core on the C# backend, and extending the offline-first Drift SQLite schema and version upgrade migrations on the Flutter mobile client.

### Out of Scope
- real-time GPS coordinate fetching or distance boundary checking logic (Slice 3).
- C# REST API request/response DTOs, endpoint routes, or controllers (Slice 2).
- Real-time debounced compliance HUD scoring widgets (Slice 3).
- Warning and blocking interstitial sheets or visual UI elements (Slice 4).
- GPS permission checks or location-enabled device hardware controls.

---

## System Context

### Offline / Online Sync Flow
1. **Drift SQLite Cache & Outbox (Offline-First)**:
   - When templates are delta-synced, their geofencing settings (`geofenceMode`, `geofenceRadiusMeters`, `displayNoun`) are stored in the local SQLite `CachedTemplates` table.
   - When an auditor completes an audit offline, the validation results (`isGeofenceBypassed`, `distanceMetersOff`) are captured inside the local `PendingSubmissions` outbox table and mirrored in the local history `CachedSubmissions` table.
2. **Synchronization (Outbox Queue)**:
   - Once network connectivity is restored, the `SyncEngine` reads the pending submissions outbox queue and flushes the data (including coordinates and geofence telemetry) to the C# backend API.
3. **Backend Persistance**:
   - The server stores template geofencing constraints in the `templates` table and saves submission geofence telemetry in the `submissions` table.

---

## Lifecycle Context

This slice focuses purely on the structural data schema lifecycle:
- **Fresh Database Creation**: When the database is initialized from scratch (EF `EnsureCreated` or Drift `onCreate`), all tables are constructed with the latest schemas.
- **Migration & Upgrade**: When an existing environment is upgraded, C# PostgreSQL runs migrations, and the mobile client runs Drift `onUpgrade` to version `34` to safely add columns.
- **Nullable Defaults**: The new telemetry columns default to `null` to gracefully support drafts, GPS timeouts, or unmapped stores.

---

## Constraint Traceability

| Source Constraint / Failure Mode | Target File | Test Contract ID | Description |
|---|---|---|---|
| Bimodal Geofencing Templates | `Template.cs`, `TemplateConfiguration.cs` | `CON-NET-TEMPLATE-SCHEMA` | Define `geofence_mode` and `geofence_radius_meters` columns with default values. |
| Persistent Geofencing Sync | `Submission.cs`, `SubmissionConfiguration.cs` | `CON-NET-SUBMISSION-SCHEMA` | Define `is_geofence_bypassed` and `distance_meters_off` nullable columns. |
| Null Store Location Coordinates | `tables.dart` | `CON-DRIFT-NULLABLE-GPS` | New telemetry and coordinate columns must be fully nullable to prevent crashes. |
| Drift SQLite Migration Upgrade | `app_database.dart` | `CON-DRIFT-UPGRADE-MIGRATION`| Safely upgrade database schema from version `33` to `34` using `m.addColumn(...)` for all 7 added columns. |

---

## Test Contracts

### 1. `DB-NET-SCHEMA-CONFIG`
- **Objective**: Assert that the C# `Template` and `Submission` entities map exactly to their designated PostgreSQL columns.
- **Required State**: Active EF Core DbContext.
- **Verification Strategy (Fail First)**: Add assertions verifying the properties `GeofenceMode`, `GeofenceRadiusMeters` exist on `Template`, and `IsGeofenceBypassed`, `DistanceMetersOff` exist on `Submission`. Ensure they map to the correct snake_case columns.

### 2. `DB-NET-MIGRATION`
- **Objective**: Verify that EF Core migrations can be added and applied to the database cleanly.
- **Required State**: Local `checkly_test` database is active.
- **Verification Strategy**: Run `rtk dotnet ef database update` to ensure migration SQL compiles and applies without breaking indexes.

### 3. `DB-DRIFT-COLUMNS`
- **Objective**: Assert that Drift SQLite generated tables (`CachedTemplates`, `CachedSubmissions`, `PendingSubmissions`) contain the correct columns.
- **Required State**: Drift schema code-generation completed.
- **Verification Strategy**: Compile Drift codebase and verify generated models include the correct property getters.

### 4. `DB-DRIFT-MIGRATION-UPGRADE`
- **Objective**: Assert that the Drift migration from schema version `33` to `34` succeeds without throwing SQLite exceptions or causing startup crashes.
- **Required State**: Initial database state seeded with version `33` schema.
- **Verification Strategy**: Execute database migration strategy in unit tests. Assert that columns exist on the upgraded database.

---

## Test Fixture & Payloads

This slice is database-only, so there are no REST API JSON payloads. However, we define the required entity structures:

### 1. C# Entity Mock Configurations
```csharp
var testTemplate = new Template
{
    Id = Guid.NewGuid(),
    Title = "Smart Geofence Test Template",
    Type = "QC",
    Version = 1,
    GeofenceMode = "lax",
    GeofenceRadiusMeters = 150
};

var testSubmission = new Submission
{
    Id = Guid.NewGuid(),
    TemplateId = testTemplate.Id,
    Status = "completed",
    GpsLat = 21.028511m,
    GpsLng = 105.804817m,
    IsGeofenceBypassed = true,
    DistanceMetersOff = 50
};
```

---

## Tools & Commands

### Builder Required Skills
- **ef-core**: EF Core mappings, configurations, and PostgreSQL migrations.
- **testing-strategy**: ASP.NET integration testing.
- **flutter-architecture**: Drift SQLite schema modeling, migrations, and code generation.

### Execution & Testing Commands
- **Backend Build**:
  `cmd /c rtk dotnet build` (from `server/` directory)
- **Backend Database Migration Generation**:
  `cmd /c rtk dotnet ef migrations add AddSmartAuditSafeguardsColumns --project Common/ --startup-project Api/` (from `server/` directory)
- **Backend Tests**:
  `cmd /c rtk dotnet test` (from `server/` directory)
- **Frontend Code Generation**:
  `cmd /c dart run build_runner build --delete-conflicting-outputs` (from root directory)
- **Frontend Tests**:
  `cmd /c flutter test test/database_migration_test.dart` (from root directory)

---

## Proposed Changes

### Sequential Build Order:
`Backend Entities` -> `Backend Entity Configurations` -> `Backend Migration` -> `Drift SQLite Tables` -> `Drift Migration & Schema Version` -> `Code Generation` -> `Verification Tests`

| Action | Target File Path | Description |
|---|---|---|
| `[MOD]` | `server/Common/Persistence/Entities/Template.cs` | Add `GeofenceMode` (`string`) and `GeofenceRadiusMeters` (`int`) properties. |
| `[MOD]` | `server/Common/Persistence/Entities/Submission.cs` | Add `IsGeofenceBypassed` (`bool?`) and `DistanceMetersOff` (`int?`) properties. |
| `[MOD]` | `server/Common/Persistence/Configurations/TemplateConfiguration.cs` | Map properties to `geofence_mode` and `geofence_radius_meters` in PostgreSQL with default values `'none'` and `100`. |
| `[MOD]` | `server/Common/Persistence/Configurations/SubmissionConfiguration.cs` | Map properties to `is_geofence_bypassed` and `distance_meters_off` in PostgreSQL (both nullable). |
| `[NEW]` | `server/Common/Persistence/Migrations/[Timestamp]_AddSmartAuditSafeguardsColumns.cs` | Automatically generated C# migration script representing the DB changes. |
| `[MOD]` | `lib/_shared/database/tables.dart` | Add columns to `CachedTemplates` (`displayNoun`, `geofenceMode`, `geofenceRadiusMeters`), `CachedSubmissions` (`isGeofenceBypassed`, `distanceMetersOff`), and `PendingSubmissions` (`isGeofenceBypassed`, `distanceMetersOff`). |
| `[MOD]` | `lib/_shared/database/app_database.dart` | Increment `schemaVersion` to `34`. Under `onUpgrade` for `from < 34`, write explicit migrations using `m.addColumn(...)` for the 7 new columns. |

---

## Concept Diagram

```text
[C# Caching/DB Configs]                                [Drift SQLite Tables]
  - Template.cs (Add fields)                             - tables.dart (CachedTemplates)
  - Submission.cs (Add fields)                           - tables.dart (CachedSubmissions)
  - TemplateConfiguration.cs                             - tables.dart (PendingSubmissions)
  - SubmissionConfiguration.cs                                  │
          │                                                     ▼
          ▼                                            [Drift Migration Strategy]
[EF Core Migration Generator]                            - Increment schemaVersion to 34
  - AddSmartAuditSafeguardsColumns                       - Add 7 migrations inside onUpgrade
          │                                                     │
          ▼                                                     ▼
 [PostgreSQL: checkly_test]                            [Local SQLite: checkly_local.db]
```

---

## Execution Slices

### Slice 1.1: EF Core PostgreSQL Schema Entities and Configurations (Happy Path Backend)
- **Summary**: Extend Backend C# Entity Classes and EF Core Configuration Mappings.
- **Value**: Establishes the exact PostgreSQL schema mapping for smart safeguards telemetry and bimodal constraints on the server side.
- **Complexity**: 🟢 Low
- **Entry State**: `Template.cs` and `Submission.cs` lack geofence properties; `TemplateConfiguration.cs` and `SubmissionConfiguration.cs` lack corresponding PostgreSQL column configurations.
- **Exit State**: Properties added and properly configured with strict snake_case column names and defaults.
- **Acceptance Criteria**:
  1. `Template.cs` has `GeofenceMode` (`string`, defaults to `"none"`) and `GeofenceRadiusMeters` (`int`, defaults to `100`).
  2. `Submission.cs` has `IsGeofenceBypassed` (`bool?`, nullable) and `DistanceMetersOff` (`int?`, nullable).
  3. `TemplateConfiguration.cs` maps `GeofenceMode` to column `geofence_mode` (`VARCHAR(20)`, default value `'none'`) and `GeofenceRadiusMeters` to `geofence_radius_meters` (`INT`, default value `100`).
  4. `SubmissionConfiguration.cs` maps `IsGeofenceBypassed` to column `is_geofence_bypassed` (`BOOLEAN`, nullable) and `DistanceMetersOff` to `distance_meters_off` (`INT`, nullable).
  5. Code compiles cleanly on C# backend: `rtk dotnet build` returns 0 warnings.

### Slice 1.2: EF Core DB Migrations (C# Migration Generation)
- **Summary**: Generate and verify EF Core schema migration script.
- **Value**: Creates an official repeatable database update script that backfills database columns safely without locking active PostgreSQL instances.
- **Complexity**: 🟡 Medium (requires validation of migration code against local database).
- **Entry State**: DB schema in PostgreSQL lacks the 4 new columns.
- **Exit State**: Migration created and applied successfully to `checkly_test`.
- **Acceptance Criteria**:
  1. EF Core migration class `AddSmartAuditSafeguardsColumns` generated using `dotnet ef migrations`.
  2. The generated migration file is checked and matches PostgreSQL syntax conventions exactly (e.g. `nullable: true` for submission telemetry).
  3. The local integration test suite compiles and runs cleanly against the auto-migrated `checkly_test` database: `rtk dotnet test` succeeds with zero database setup errors.

### Slice 1.3: Drift SQLite Local Schema Columns and Version 34 Migration (Happy Path Client)
- **Summary**: Add SQLite Drift columns and write schema migration logic.
- **Value**: Hardens the local-first storage layer against startup crashes, ensuring that app upgrades seamlessly backfill columns for the new telemetry logic.
- **Complexity**: 🔴 High-Risk Logic (Drift migrations are critical for avoiding startup crashes).
- **Entry State**: `schemaVersion` is `33`. Upgraded local databases crash because Drift models do not match the on-disk database schema.
- **Exit State**: `schemaVersion` set to `34`. Upgrade migrations added to safely inject 7 new columns.
- **Acceptance Criteria**:
  1. `tables.dart` extended to define `displayNoun` (nullable text), `geofenceMode` (defaults to `'none'`), and `geofenceRadiusMeters` (defaults to `100`) inside `CachedTemplates`.
  2. `tables.dart` extended to define `isGeofenceBypassed` (nullable boolean) and `distanceMetersOff` (nullable integer) inside both `CachedSubmissions` and `PendingSubmissions`.
  3. `app_database.dart` database `schemaVersion` incremented to `34`.
  4. `onUpgrade` contains `from < 34` migration case executing `m.addColumn(...)` separately for each of the 7 new columns.
  5. Code generation compiles successfully: `dart run build_runner build --delete-conflicting-outputs` completes with zero errors.

### Slice 1.4: Drift Migration Unit Tests (Offline Validation & Resiliency)
- **Summary**: Write and execute unit tests asserting schema version 33-to-34 upgrade robustness.
- **Value**: Guarantees offline clients can upgrade their app versions without experiencing SQLite crashes or data corruption.
- **Complexity**: 🟡 Medium
- **Entry State**: Upgrades are untested; potential SQL syntax errors or missing columns remain unverified.
- **Exit State**: Offline migration unit tests run and pass cleanly.
- **Acceptance Criteria**:
  1. Create or extend a Drift migration test in the Flutter test directory (e.g. `test/database_migration_test.dart`).
  2. Test simulates a database at schema version `33` and runs the schema migration up to version `34`.
  3. Assert that the database successfully upgrades without throwing any SQLite exceptions.
  4. Assert that the 7 new columns exist in the database and have the correct nullability/default values.
  5. Test execution command `flutter test` completes with 100% success.

---

<command_logs>
I executed the following proof-of-work commands to discover dependencies and verify system design:
1. `grep_search` to locate C# configurations and entity layouts (`Submission`, `Template`).
2. `view_file` to read `Submission.cs`, `SubmissionConfiguration.cs`, `Template.cs`, `TemplateConfiguration.cs` inside C# persistence.
3. `view_file` on SQLite tables `tables.dart` and database controller `app_database.dart`.
4. `list_dir` on server migrations folder `server/Common/Persistence/Migrations` to evaluate C# schema timestamps.
</command_logs>

---

## Handoff Block

* **Implementation Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\implementation_plan_smart-audit-safeguards-slice1_20260531_180000.md`

### Handoff Execution Strategy
You must instruct the Builder to execute the plan slices **ONE AT A TIME**. Do not perform bulk edits or run all code updates concurrently. Follow this sequence:

1. **Step 1: Code Backend Schema Mappings (Slice 1.1)**
   - Route: **Route 2 (Unit Tests First)**
   - Action: Add fields to `Template.cs` and `Submission.cs`, then add EF Core column configurations to `TemplateConfiguration.cs` and `SubmissionConfiguration.cs`. Compile the backend.
2. **Step 2: Generate EF Core Migration (Slice 1.2)**
   - Route: **Route 2 (Unit Tests First)**
   - Action: Propose command to generate C# migration `AddSmartAuditSafeguardsColumns`, and execute `rtk dotnet test` to ensure it integrates seamlessly with `checkly_test`.
3. **Step 3: Define Drift Columns & Version 34 Upgrades (Slice 1.3)**
   - Route: **Route 2 (Unit Tests First)**
   - Action: Update `tables.dart` and `app_database.dart` (`schemaVersion` to 34 and migration cases). Propose code-generation `dart run build_runner build --delete-conflicting-outputs`.
4. **Step 4: Execute Schema Upgrade Tests (Slice 1.4)**
   - Route: **Route 2 (Unit Tests First)**
   - Action: Propose database schema version upgrade tests verifying version 33 upgrades to version 34 cleanly, and run `flutter test`.
