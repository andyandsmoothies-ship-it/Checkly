---
conversation_id: e806043a-d178-457b-b974-d1e2c68fce54
created_at: 2026-05-31T23:58:00+07:00
topic: bod-analytics-v2
type: walkthrough
status: COMPLETED
---

# Walkthrough: Admin Geofence Telemetry KPI | Slice 3

This document contains a walk-through of the code changes implemented in Slice 3: **Admin Geofence Telemetry KPI**.

## Technical Architecture Overview

The following text flowchart outlines the data query and presentation pipeline for geofence telemetry bypass metrics:

```
[PostgreSQL Database]
       |
       | (Nightly / Live Queries with Null Inequality Safeguard)
       v
[Backend DTO: BodChainKpis] ---> [ASP.NET Core REST API]
                                         |
                                         | (Sync / Live Pull)
                                         v
                                [Flutter App Model]
                                         |
                                         v
                             [Widget: BodKpiGrid (Row 4)]
                                         |
                                         +---> If Count > 0: warning/alert card
```

---

## Code Modification Detailed Log

### 1. Backend DTO Contract

**File**: `server/Features/Analytics/BodReportDtos.cs`
- Added the `GeofenceBypassCount` parameter (default `0`) to `BodChainKpis` to expose the value over the API.

### 2. Nightly Snapshot Computation

**File**: `server/Features/Analytics/BodReportCalculator.cs`
- Implemented `geofenceBypassCount` query counting completed, non-rejected, bypassed geofence audits up to the target date/time:
  ```csharp
  var geofenceBypassCount = await _context.Submissions
      .CountAsync(s => s.StoreId == storeId 
          && s.Status == "completed" 
          && (s.ReviewStatus == null || s.ReviewStatus != "rejected") 
          && s.IsGeofenceBypassed == true 
          && s.CompletedAt <= targetDateTime, cancellationToken);
  ```

### 3. Live Regional Query Handler

**File**: `server/Features/Analytics/GetBodReport.cs`
- Added the live geofence bypass query restricted to the last 30 days and the user's active province/district:
  ```csharp
  var geofenceBypassCount = await query
      .CountAsync(s => s.IsGeofenceBypassed == true 
          && s.Status == "completed" 
          && (s.ReviewStatus == null || s.ReviewStatus != "rejected") 
          && (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo, cancellationToken);
  ```
- Populated it in the returned dynamic JSON `kpis` payload.

### 4. Frontend Data Model

**File**: `lib/features/analytics/manager/bod_analytics_data.dart`
- Extended `BodChainKpis` class to add `geofenceBypassCount`.
- Updated constructor, `fromJson()`, and `toJson()` methods to correctly deserialize the property.

### 5. Mock Provider

**File**: `lib/features/analytics/services/mock/bod_mock_data.dart`
- Added `"geofenceBypassCount": 14` to mock KPIs so offline simulation matches live payloads.

### 6. KPI Grid Presentation Component

**File**: `lib/features/analytics/widgets/bod_kpi_grid.dart`
- Replaced the empty right-hand slot in the 4th row next to `Total Auditors` with the new warning card.
- Structured the card beautifully using `isAlert: geofenceBypassCount > 0`.

---

## Decision Log

- **Grid Alignment**: Placed the "Geofence Bypasses" card next to "Total Auditors" inside Row 4 of `BodKpiGrid` because the right side was previously a placeholder `const Expanded(child: SizedBox())`. This fully utilizes existing grid real estate without expanding vertical scroll clutter.
- **Alert Semantics**: Configured warning highlight logic (`isAlert: geofenceBypassCount > 0`) to immediately flag anomalous auditor behaviors.
- **Null Safety**: Implemented robust SQL queries wrapping all `ReviewStatus` inequality checks in null-coalescing guards to avoid PostgreSQL inequality evaluation issues on draft audits.

---

## Verification Handoff

Testing was completed seamlessly across both backend (integration tests) and frontend (widget simulation tests).

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/widgets/bod_geofence_telemetry_test.dart
00:00 +0: renders Geofence Bypasses card with count when geofenceBypassCount is provided
00:01 +1: renders Geofence Bypasses card with 0 when geofenceBypassCount is missing or null
00:01 +2: All tests passed!

[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ok dotnet test: completed (binlog-only mode, counts unavailable, 0 warnings) (unknown)
Exit code: 0
</test_trace>

<forensic_evidence>
Ran:
1. `rtk flutter test test/features/analytics/widgets/bod_geofence_telemetry_test.dart`
2. `rtk dotnet test --filter "FullyQualifiedName~GeofenceBypassKpiTests"`
</forensic_evidence>
