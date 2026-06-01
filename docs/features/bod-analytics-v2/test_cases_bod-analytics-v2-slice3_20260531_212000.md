---
conversation_id: "7e84733f-638e-4569-87dd-9901b796b109"
created_at: "2026-05-31T21:20:00+07:00"
topic: "bod-analytics-v2"
type: "test_cases"
status: "APPROVED"
---

# Test Cases: Admin Geofence Telemetry KPI (Slice 3)

## ## Input Lineage

- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-analytics-v2\implementation_plan_bod-analytics-v2-slice3_20260531_235500.md`

## 1. Automated Test Suite Map

### Backend (C# Integration Tests)
- **Suite File**: [GetAreaBodReportTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/GetAreaBodReportTests.cs)
- **Status**: 🔴 RED (Failing as expected during ATDD Phase)

| Test Case Name | Target Path | Failure/Success Logic |
|---|---|---|
| `GetBodReport_LiveQuery_ComputesGeofenceBypassesCorrectly` | `server/tests/Checkly.Api.Tests/Features/Analytics/GetAreaBodReportTests.cs` | Validates live logic filters geofences by dates, non-rejected status, and completion. |
| `ComputeDailyReport_NightlySnapshot_ComputesGeofenceBypassesCorrectly` | `server/tests/Checkly.Api.Tests/Features/Analytics/GetAreaBodReportTests.cs` | Validates nightly calculator computes `geofenceBypassCount` and serializes into JSON rollup. |

### Frontend (Dart Widget Tests)
- **Suite File**: [bod_geofence_telemetry_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/widgets/bod_geofence_telemetry_test.dart)
- **Status**: 🔴 RED (Failing as expected during ATDD Phase)

| Test Case Name | Target Path | Failure/Success Logic |
|---|---|---|
| `renders Geofence Bypasses card with count when geofenceBypassCount is provided` | `test/features/analytics/widgets/bod_geofence_telemetry_test.dart` | Renders BOD KPI Grid with dynamic geofence count; asserts "Geofence Bypasses" card is shown. |
| `renders Geofence Bypasses card with 0 when geofenceBypassCount is missing or null` | `test/features/analytics/widgets/bod_geofence_telemetry_test.dart` | Renders grid with missing/null parameters; asserts card falls back to 0. |

## 2. Gherkin Scenarios

### Scenario 1: Live Query Computes Bypasses Correctly
```gherkin
Given a manager queries BOD report for Province "HN"
And database has:
  | StoreId | CompletedAt | ReviewStatus | IsGeofenceBypassed | Included? | Reason |
  | ST-001  | 5 days ago  | approved     | true               | Yes       | Fits criteria |
  | ST-002  | 10 days ago | approved     | false              | No        | Not bypassed |
  | ST-003  | 45 days ago | approved     | true               | No        | Outside 30 days |
  | ST-004  | 2 days ago  | rejected     | true               | No        | Rejected status |
  | ST-005  | 1 day ago   | null         | true               | Yes       | Completed, non-rejected |
When the API endpoint executes the query
Then the "geofenceBypassCount" returned in KPIs is exactly 2
```

### Scenario 2: UI Presentation and Fallback Rendering
```gherkin
Given a user views the BOD KPIs page
When the server payload contains "geofenceBypassCount": 18
Then a premium card is displayed showing "Geofence Bypasses"
And the text value on the card displays "18"

When the server payload has no "geofenceBypassCount" property
Then the card labeled "Geofence Bypasses" is displayed
And the text value on the card displays "0"
```
