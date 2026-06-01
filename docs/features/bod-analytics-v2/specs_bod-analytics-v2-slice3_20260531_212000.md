---
conversation_id: "7e84733f-638e-4569-87dd-9901b796b109"
created_at: "2026-05-31T21:20:00+07:00"
topic: "bod-analytics-v2"
type: "specs"
status: "APPROVED"
---

# Specs: Admin Geofence Telemetry KPI (Slice 3)

[UI: BodKpiGrid] ---> HTTP GET /api/analytics/bod ---> [ASP.NET GetBodReport Endpoint]

## ## Input Lineage

- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-analytics-v2\implementation_plan_bod-analytics-v2-slice3_20260531_235500.md`

## 1. Acceptance Criteria

### AC-1: Dynamic Calculation Rules for Geofence Bypasses
- **Rule Source**: `implementation_plan_bod-analytics-v2-slice3_20260531_235500.md` (Test Contracts)
- **Gherkin**:
  ```gherkin
  Given the store is assigned to an active province and has multiple submissions
  When a BOD report query is performed for the province
  Then only completed non-rejected submissions submitted with IsGeofenceBypassed = true in the last 30 days are counted
  And other submissions (IsGeofenceBypassed = false, draft status, rejected review status, or outside 30 days) are excluded
  ```

### AC-2: Nightly Pre-Cached Snapshot Telemetry
- **Rule Source**: `implementation_plan_bod-analytics-v2-slice3_20260531_235500.md` (Proposed Changes: File 2)
- **Gherkin**:
  ```gherkin
  Given the nightly snapshot execution triggers
  When BodReportCalculator.ComputeDailyReportWithTimezoneAsync computes the rollups
  Then it includes geofenceBypassCount in the cached JSON kpis payload
  ```

### AC-3: Front-End UI Grid Presentation & Null Safety
- **Rule Source**: `implementation_plan_bod-analytics-v2-slice3_20260531_235500.md` (Frontend Changes: File 3)
- **Gherkin**:
  ```gherkin
  Given the BodKpiGrid is rendered
  When a non-zero geofenceBypassCount is provided in the chainKpis payload
  Then a dedicated premium card labeled "Geofence Bypasses" is rendered showing the count
  And if the property is missing or null, it falls back gracefully to display 0
  ```

## 2. Test Infrastructure Map

### Helper Methods
| Method | Signature | Behavior |
|--------|-----------|----------|
| `LoginBootstrapAdminAsync` | `(HttpClient)` | Logs in as seeded admin, returning JWT token |
| `EnsureDatabaseCreated` | `()` | Re-creates test DB schema and seeds baseline lookup tables |

### Expected JSON Payload Shape
```json
{
  "kpis": {
    "totalAudits": 45,
    "avgScore": 84.5,
    "completionRate": 92.5,
    "openActionPlans": 12,
    "overdueActionPlans": 3,
    "activeStores": 8,
    "totalAuditors": 4,
    "avgTtrDays": 5.5,
    "geofenceBypassCount": 5
  }
}
```
