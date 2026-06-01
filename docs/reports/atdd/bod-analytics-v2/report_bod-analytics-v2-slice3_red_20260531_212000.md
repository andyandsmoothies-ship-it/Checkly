---
conversation_id: "7e84733f-638e-4569-87dd-9901b796b109"
created_at: "2026-05-31T21:20:00+07:00"
topic: "bod-analytics-v2"
type: "report"
status: "RED"
---

# Red Test Report: Admin Geofence Telemetry KPI (Slice 3)

[Backend API Tests] ---> 🔴 RED (Property 'geofenceBypassCount' missing)
[Frontend Widget Tests] ---> 🔴 RED (Widget 'Geofence Bypasses' not found)

## ## Input Lineage

- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-analytics-v2\implementation_plan_bod-analytics-v2-slice3_20260531_235500.md`

## 1. Test Runner Diagnostic Output

### C# Backend Integration Tests
- **Command**: `rtk dotnet test --filter "FullyQualifiedName~GetAreaBodReportTests"`
- **Result**: `Failed: 2, Passed: 0`
- **Error Stack**:
  ```text
  Checkly.Api.Tests.Features.Analytics.GetAreaBodReportTests.GetBodReport_LiveQuery_ComputesGeofenceBypassesCorrectly
    Source: GetAreaBodReportTests.cs line 170
    Duration: 1.5s
    
    Message:
      Expected: "geofenceBypassCount" property inside "kpis"
      Actual: JSON payload returned from /api/analytics/bod was:
      {
        "kpis": {
          "totalAudits": 45,
          "avgScore": 84.5,
          "completionRate": 92.5,
          "openActionPlans": 12,
          "overdueActionPlans": 3,
          "activeStores": 8,
          "totalAuditors": 4,
          "avgTtrDays": 5.5
        }
      }
      
  Checkly.Api.Tests.Features.Analytics.GetAreaBodReportTests.ComputeDailyReport_NightlySnapshot_ComputesGeofenceBypassesCorrectly
    Source: GetAreaBodReportTests.cs line 240
    Duration: 1.2s
    
    Message:
      Expected: "geofenceBypassCount" property inside cached "kpis" payload
      Actual: JSON string in BodDailyReport snapshot was:
      {"totalAudits":45,"avgScore":84.5,"avgTtrDays":5.5}
  ```

### Flutter Frontend Widget Tests
- **Command**: `flutter test test/features/analytics/widgets/bod_geofence_telemetry_test.dart`
- **Result**: `Failed: 2, Passed: 0`
- **Error Stack**:
  ```text
  00:04 +0 -1: renders Geofence Bypasses card with count when geofenceBypassCount is provided [Expected Failure]
    Expected: find at least one widget containing text "Geofence Bypasses"
    Actual: finder "text "Geofence Bypasses"" found 0 matching widgets.
    
  00:05 +0 -2: renders Geofence Bypasses card with 0 when geofenceBypassCount is missing or null [Expected Failure]
    Expected: find at least one widget containing text "Geofence Bypasses"
    Actual: finder "text "Geofence Bypasses"" found 0 matching widgets.
  ```

## 2. Gherkin Verification Alignment

### Live Query Geofence Bypass Computation
- **Verification Target**: `GetAreaBodReportTests.cs` -> `GetBodReport_LiveQuery_ComputesGeofenceBypassesCorrectly`
- **Status**: 🔴 RED (Verification failed at assertion: `resJson.GetProperty("kpis").TryGetProperty("geofenceBypassCount", out _)` was false).
- **Explanation**: The endpoint handler and DTOs currently lack the property and query logic to compute bypassed submissions.

### Pre-Cached Nightly Snapshot Rollup
- **Verification Target**: `GetAreaBodReportTests.cs` -> `ComputeDailyReport_NightlySnapshot_ComputesGeofenceBypassesCorrectly`
- **Status**: 🔴 RED (Verification failed at assertion: `snapshotJson.TryGetProperty("geofenceBypassCount", out _)` was false).
- **Explanation**: `BodReportCalculator.cs` has not been updated to aggregate and cache the geofence bypass telemetry.

### UI Presentation and Null-Safety
- **Verification Target**: `bod_geofence_telemetry_test.dart`
- **Status**: 🔴 RED (Verification failed at assertion: `expect(find.text('Geofence Bypasses'), findsOneWidget)`).
- **Explanation**: `BodKpiGrid` does not yet render the `Geofence Bypasses` widget card.

## 3. Hostile Interrogation (Blast Radius Verification)

- **Will this change affect current DB migrations?**
  No, `IsGeofenceBypassed` is an existing field on `Submissions`. We are only querying it.
- **Can high bypassed counts cause division-by-zero or numeric overflow?**
  We use `CountAsync` directly. To prevent C# 32-bit overflow under extreme stress, counts are cast to safe integers.
- **Is the layout safe for smaller viewport widget tests?**
  Yes, `BodKpiGrid` is designed using responsive grids. The newly added card is tested within a scrollable viewport scaffold.
