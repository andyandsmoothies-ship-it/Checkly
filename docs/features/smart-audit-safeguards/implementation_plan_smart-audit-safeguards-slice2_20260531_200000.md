<latent_space_scratchpad>
Thinking Process:
- Topic: Smart Audit Source Safeguards - Slice 2 (Server API updates)
- Target Area: ASP.NET Core Minimal API contracts, handlers, and integration tests.
- We must expand:
  - CreateSubmissionRequest: add nullable `IsGeofenceBypassed` (bool?) and `DistanceMetersOff` (int?) properties.
  - SubmissionDto: add nullable `IsGeofenceBypassed` (bool?) and `DistanceMetersOff` (int?) optional properties.
  - SubmissionDetailDto: add nullable `IsGeofenceBypassed` (bool?) and `DistanceMetersOff` (int?) optional properties.
  - CreateSubmission handler: parse request fields, map to the entity, and output in the response.
  - FinalizeSubmission handler: add to FinalizeRequest and map to entity, then output in the response DTO.
  - GetSubmission handler: project the entity properties onto the SubmissionDetailDto.
  - ListSubmissions handler: project/map the entity properties onto the SubmissionDto list.
  - UpdateSubmission handler: map properties onto the returned SubmissionDto.
- Discovered Edge Cases & SRE Safeguards:
  - Safe mapping of nulls: If the client submits coordinates but lacks bypass metrics (e.g. within geofence range), the database holds `null`. We must preserve the null values in the JSON contracts.
  - Test validation rules: SRE Golden gotchas demand that we do NOT assert raw booleans on HTTP responses. We must read the content string on failure and print it to assert.Fail.
- File sizes are well under 400 lines.
</latent_space_scratchpad>

## Input Lineage

- **Source Epic Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\analysis_epic_20260531_162500.md`
- **Slice 1 Task Report**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\task_smart-audit-safeguards-slice1-complete_20260531_191000.md`

---

## Executive Summary & Out of Scope

### High-Level Goal
Expand C# DTO contracts, integrate parameters into the submission API handlers, and write backend integration tests for the **Smart Audit Source Safeguards** Slice 2. This secures the end-to-end telemetry pipeline between the network payload layer and the database persistence layer.

### Out of Scope
- Real-time client-side coordinate calculations and boundary checks (Slice 3).
- Real-time debounced compliance HUD widgets on the mobile client (Slice 3).
- Flutter local SQLite outbox mapping, schemas, or sync triggers (Slice 1 - already built).
- Warning and blocking interstitial sheets or visual UI elements (Slice 4).

---

## Concept Diagram

```text
[HTTP Clients / Flutter Sync]
       │
       ├─► [POST /api/submissions] (CreateSubmissionRequest with telemetry)
       │         │
       │         ▼
       │   [CreateSubmission.HandleAsync]
       │         │ (Maps fields to entity and saves to DB)
       │         ▼
       │   [PostgreSQL Database] (Persisted on submissions table)
       │
       ├─► [PUT /api/submissions/{id}/finalize] (FinalizeRequest with telemetry)
       │         │
       │         ▼
       │   [FinalizeSubmission.HandleAsync]
       │         │ (Maps telemetry and updates status to completed)
       │         ▼
       │   [PostgreSQL Database]
       │
       └─► [GET /api/submissions/{id}]
                 │
                 ▼
           [GetSubmission.HandleAsync] ──► [SubmissionDetailDto] (Returns telemetry)
```

---

## System Context

### API Contract Schema Updates

#### 1. POST /api/submissions Request Payload (`CreateSubmissionRequest`)
```json
{
  "templateId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3d4bad",
  "storeId": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
  "status": "completed",
  "clientScore": 100.0,
  "sectionScores": "{}",
  "gpsLat": 21.028511,
  "gpsLng": 105.804817,
  "isGeofenceBypassed": true,
  "distanceMetersOff": 120,
  "answers": []
}
```

#### 2. GET /api/submissions/{id} Response Body (`SubmissionDetailDto`)
Includes:
- `"isGeofenceBypassed": true` (or `null`)
- `"distanceMetersOff": 120` (or `null`)

---

## Lifecycle Context

This slice maps the HTTP status codes:
- **Success (201 Created / 200 OK)**: Submissions are returned with fully populated telemetry data when requested or stored.
- **Error (400 Bad Request / 403 Forbidden / 404 NotFound)**: Handles security and payload validation failures.
- **Null Safety**: Supports older client drafts or un-bypassed submissions by mapping missing attributes safely to database `NULL` without casting exceptions.

---

## Constraint Traceability

| Source Constraint / Failure Mode | Target File | Test Contract ID | Description |
|---|---|---|---|
| POST Payload Extension | `Dtos.cs` | `CON-NET-DTO-CREATE` | Add `IsGeofenceBypassed` and `DistanceMetersOff` to `CreateSubmissionRequest`. |
| GET Detail Payload Extension | `Dtos.cs` | `CON-NET-DTO-DETAIL` | Add `IsGeofenceBypassed` and `DistanceMetersOff` to `SubmissionDetailDto`. |
| List & Update Response Extension | `Dtos.cs` | `CON-NET-DTO-LIST` | Add `IsGeofenceBypassed` and `DistanceMetersOff` to `SubmissionDto`. |
| Create Mapping | `CreateSubmission.cs` | `CON-NET-MAP-CREATE` | Capture telemetry parameters from request and write them to `Submission` entity. |
| Finalize Mapping | `FinalizeSubmission.cs`| `CON-NET-MAP-FINALIZE` | Capture telemetry parameters from request and update the `Submission` entity. |
| Get Projection | `GetSubmission.cs` | `CON-NET-PROJ-GET` | Map `Submission` entity fields onto the returned `SubmissionDetailDto`. |
| List Projection | `ListSubmissions.cs` | `CON-NET-PROJ-LIST` | Map `Submission` entity fields onto the returned `SubmissionDto` elements. |
| Update Projection | `UpdateSubmission.cs` | `CON-NET-PROJ-UPDATE` | Map `Submission` entity fields onto the returned `SubmissionDto`. |

---

## Test Contracts

### 1. `API-SUBMISSION-CREATE-TELEMETRY`
- **Objective**: Assert that posting a submission payload with geofence bypass metrics correctly persists and returns the fields.
- **Required State**: Seeded template and store.
- **Verification Strategy (Fail First)**: Add an integration test that posts a `completed` status submission with `IsGeofenceBypassed = true` and `DistanceMetersOff = 80`. Assert that the returned `SubmissionDto` matches. Assert that the database entity has the values.

### 2. `API-SUBMISSION-GET-TELEMETRY`
- **Objective**: Assert that retrieving a single submission details endpoint maps and returns the bypass telemetry fields.
- **Required State**: Seeded submission in PostgreSQL with geofence bypass metrics.
- **Verification Strategy (Fail First)**: Create a submission directly in the DB with `IsGeofenceBypassed = true` and `DistanceMetersOff = 150`. Send `GET /api/submissions/{id}` and assert response JSON matches.

### 3. `API-SUBMISSION-NULLS-RESILIENCE`
- **Objective**: Assert that older or regular payloads mapping `null` coordinates and bypass values do not throw format exceptions.
- **Required State**: Active endpoint routes.
- **Verification Strategy**: Post a payload omitting `isGeofenceBypassed` and `distanceMetersOff`. Assert it completes with `201 Created` and database registers `NULL` for the columns.

---

## Test Fixture & Payloads

### Test Web API Endpoint Post Payload:
```json
{
  "templateId": "TEMPLATE_ID_HERE",
  "storeId": "STORE_ID_HERE",
  "status": "completed",
  "clientScore": 100.00,
  "gpsLat": 21.028511,
  "gpsLng": 105.804817,
  "isGeofenceBypassed": true,
  "distanceMetersOff": 120,
  "answers": [
    {
      "criteriaId": "CRITERIA_ID_HERE",
      "value": "conform",
      "numericValue": 0.0,
      "note": "Within bypass margin",
      "photoUrl": "https://example.com/bypass.jpg"
    }
  ]
}
```

---

## Tools & Commands

### Builder Required Skills
- **backend-architect**: REST API design, Clean Architecture mapping.
- **ef-core**: EF Core projections and transactional persistence.
- **testing-strategy**: ASP.NET Core integration tests with `WebApplicationFactory`.

### Execution & Testing Commands
- **Backend Build**:
  `cmd /c rtk dotnet build` (from `server/` directory)
- **Backend Tests**:
  `cmd /c rtk dotnet test --filter "FullyQualifiedName~SmartAuditSafeguards_Slice2_Tests"` (from `server/` directory)

---

## Proposed Changes

| Action | Target File Path | Description |
|---|---|---|
| `[MOD]` | `server/Features/Submissions/Dtos.cs` | Add `bool? IsGeofenceBypassed` and `int? DistanceMetersOff` to `CreateSubmissionRequest`, `SubmissionDto`, and `SubmissionDetailDto`. |
| `[MOD]` | `server/Features/Submissions/CreateSubmission.cs` | Populate properties from request parameters to the `Submission` entity and map them back to the returned `SubmissionDto`. |
| `[MOD]` | `server/Features/Submissions/FinalizeSubmission.cs` | Expand `FinalizeRequest` to accept geofence bypass fields. Map properties to the `Submission` entity and return them in the `SubmissionDto`. |
| `[MOD]` | `server/Features/Submissions/GetSubmission.cs` | Map properties from the `Submission` entity onto the projected `SubmissionDetailDto` constructor. |
| `[MOD]` | `server/Features/Submissions/ListSubmissions.cs` | Include properties inside the pagination LINQ `.Select` projection and map them onto `SubmissionDto`. |
| `[MOD]` | `server/Features/Submissions/UpdateSubmission.cs` | Map properties from entity to the returned `SubmissionDto`. |
| `[NEW]` | `server/tests/Checkly.Api.Tests/SmartAuditSafeguards_Slice2_Tests.cs` | Create API contract integration test suite asserting correct telemetry persistence, projection, and null resilience. |

---

## Execution Slices

### Slice 2.1: Expand DTOs and API Contract Record Schemas (Happy Path Backend)
- **Summary**: Add geofence telemetry fields to submission records in `Dtos.cs`.
- **Value**: Opens up the interface contract channels for geofence telemetry so data can flow across network requests.
- **Complexity**: 🟢 Low
- **Entry State**: DTO record classes lack geofence bypass properties.
- **Exit State**: Properties added safely as optional/nullable attributes to prevent breaking existing API consumers.
- **Acceptance Criteria**:
  1. `CreateSubmissionRequest` has `bool? IsGeofenceBypassed = null` and `int? DistanceMetersOff = null`.
  2. `SubmissionDto` has `bool? IsGeofenceBypassed = null` and `int? DistanceMetersOff = null`.
  3. `SubmissionDetailDto` has `bool? IsGeofenceBypassed = null` and `int? DistanceMetersOff = null`.
  4. File `Dtos.cs` compiles cleanly.

### Slice 2.2: Implement Mapping Integrations in Handlers (Happy Path Backend)
- **Summary**: Populate database entities and project properties in all Submission endpoints.
- **Value**: Couples the API layer with the database schema layers, enabling telemetry writes and reads across the system.
- **Complexity**: 🟡 Medium
- **Entry State**: API handlers ignore incoming geofence fields and omit them in outgoing DTO responses.
- **Exit State**: Every endpoint cleanly bridges the new database columns to their respective DTO fields.
- **Acceptance Criteria**:
  1. `CreateSubmission.cs` reads `request.IsGeofenceBypassed` and `request.DistanceMetersOff` and writes to the newly created entity. It maps them back in `new SubmissionDto(...)`.
  2. `FinalizeSubmission.cs` reads `request.IsGeofenceBypassed` and `request.DistanceMetersOff` from expanded `FinalizeRequest`, writes to the entity, and maps back in `new SubmissionDto(...)`.
  3. `GetSubmission.cs` retrieves properties from the entity and projects them onto `new SubmissionDetailDto(...)`.
  4. `ListSubmissions.cs` includes `s.IsGeofenceBypassed` and `s.DistanceMetersOff` in the anonymous database selection projection, and maps them to `new SubmissionDto(...)`.
  5. `UpdateSubmission.cs` maps `submission.IsGeofenceBypassed` and `submission.DistanceMetersOff` onto `new SubmissionDto(...)`.
  6. Backend compiles with zero warnings or errors.

### Slice 2.3: API Contract Integration Tests (Security & Resiliency)
- **Summary**: Write integration tests asserting telemetry serialization, persistence, and null resilience.
- **Value**: Verifies system invariants and provides proof of correct data flow under happy path and edge conditions.
- **Complexity**: 🟡 Medium
- **Entry State**: End-to-end telemetry flows are unverified.
- **Exit State**: E2E integration test suite validates payloads and reports 100% success.
- **Acceptance Criteria**:
  1. Test suite `SmartAuditSafeguards_Slice2_Tests.cs` created and registered under the integration test project.
  2. Test `CreateSubmission_WithGeofenceTelemetry_PersistsAndReturnsFields` asserts that when posting `isGeofenceBypassed = true` and `distanceMetersOff = 120`, the API returns a `201 Created` with matching values, and the database stores them.
  3. Test `GetSubmission_WithGeofenceTelemetry_ReturnsCorrectFields` asserts that GET request properly projects the telemetry data.
  4. Test `CreateSubmission_OmitGeofenceTelemetry_SavesNullsSuccessfully` asserts that regular submissions omitting the fields write `NULL` to PostgreSQL without exceptions.
  5. All integration tests pass cleanly when running `rtk dotnet test`.

---

## Handoff Block

* **Implementation Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\smart-audit-safeguards\implementation_plan_smart-audit-safeguards-slice2_20260531_200000.md`

### Next Steps for user
The next agent (Builder) must execute the slices listed below in sequential order, validating each slice before moving to the next.

### Handoff Execution Strategy
You must execute the slices **ONE AT A TIME**. Do not perform bulk edits or run all code updates concurrently. Follow this sequence:

1. **Step 1: Write API Contract Tests (First Loop of ATDD)**
   - Route: **Route 3 (Acceptance Tests First)**
   - Action: Create `SmartAuditSafeguards_Slice2_Tests.cs` and implement the three test cases. They should fail compilation initially since the properties don't exist on the DTOs yet.
2. **Step 2: Expand DTO contracts in `Dtos.cs` (Slice 2.1)**
   - Route: **Route 3 (Acceptance Tests First)**
   - Action: Add the fields to `CreateSubmissionRequest`, `SubmissionDto`, and `SubmissionDetailDto` in `Dtos.cs`. Compilation errors in test cases should now resolve.
3. **Step 3: Integrate Handlers mapping (Slice 2.2)**
   - Route: **Route 3 (Acceptance Tests First)**
   - Action: Implement mappings in `CreateSubmission.cs`, `FinalizeSubmission.cs`, `GetSubmission.cs`, `ListSubmissions.cs`, and `UpdateSubmission.cs`.
4. **Step 4: Execute API Contract Tests (Slice 2.3)**
   - Route: **Route 3 (Acceptance Tests First)**
   - Action: Run `rtk dotnet test` to verify that all new integration test cases pass cleanly.

---

## Risk Assessment

### Identified Architectural Failure Modes & Safeguards:

1. **Failure Mode 1: PostgreSQL Null Inequality Projection Trap**
   - **Risk**: In C# EF Core mappings, a query filtering out rejected submissions might write `s.ReviewStatus != "rejected"`, which silently drops rows where `ReviewStatus` is `NULL` (due to standard SQL tri-value logic).
   - **Safeguard**: Although this slice doesn't implement review status logic, any DB filter queries must safely use `(s.ReviewStatus == null || s.ReviewStatus != "rejected")`. Our implementation avoids filtering on null telemetry values and maps them directly as nullable `bool?` and `int?` to prevent database projection failures on un-bypassed telemetry values.

2. **Failure Mode 2: DTO Serialization Format/Type Mismatches**
   - **Risk**: Standardizing custom telemetry parameters might cause runtime formatting errors or invalid casts (e.g., trying to parse an older draft submission that has missing or incorrectly-typed geofence properties).
   - **Safeguard**: All geofence bypass parameters are designed to be completely optional (`bool?` and `int?` types) in all DTO classes and EF projections, mapping cleanly to C# standard null values if absent. Contract tests verify that payloads lacking these fields are saved/retrieved successfully with nulls.

---

## Verification Plan

### Automated Checks:
1. **Compilation Check**:
   Run the following command to ensure the backend project builds without compilation warnings or errors:
   ```cmd
   rtk dotnet build
   ```
2. **API Contract Tests Check**:
   Verify correct end-to-end telemetry propagation, persistence, and null resilience by running the newly-created integration tests:
   ```cmd
   rtk dotnet test --filter "FullyQualifiedName~SmartAuditSafeguards_Slice2_Tests"
   ```

### Manual Visual Audits (Handoff to User):
1. Send a `POST` request to `/api/submissions` containing standard coordinate details and valid telemetry properties (`"isGeofenceBypassed": true` and `"distanceMetersOff": 120`). Verify it returns a `201 Created` with matching properties.
2. Query `GET /api/submissions/{id}` using the created submission ID. Confirm that both geofence bypass fields are successfully mapped and displayed in the JSON response body.
3. Validate that standard submissions omitting the fields compile, save, and retrieve without throwing exceptions, resulting in `null` telemetry values in the JSON output.

