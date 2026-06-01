---
conversation_id: e4a8d231-abcb-46c0-ae41-613c2d8ed2c0
created_at: 2026-05-31T23:55:00+07:00
topic: bod-analytics-v2
type: implementation_plan
status: DRAFT
---

# Implementation Plan: Admin Geofence Telemetry KPI (Slice 3)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-analytics-v2\analysis_epic_20260531_195500.md`

## Executive Summary & Out of Scope
- **Objective**: Expose the geofence bypass KPI within the executive dashboard KPIs.
- **Out of Scope**: We are not modifying client-side geofencing validation, geo-fenced boundaries, or manager alerts.

## System Context
- Offline caching utilizes the local SQLite db, while analytics computes metrics on the server either via nightly pre-cached calculations or on-demand province/district queries.

## Lifecycle Context
- **Success State**: Card displays exact bypass count.
- **Loading State**: Shimmer loading is rendered.
- **Error State**: Displays standard toast / fallback.
- **Empty State**: Displays 0.

## Constraint Traceability
| Constraint | Test Contract ID |
|---|---|
| Bypass telemetry matches non-rejected completed submissions | TC-GP-01 |

## Test Contracts
- **TC-GP-01**: completed non-rejected submissions submitted with `IsGeofenceBypassed == true` within the last 30 days are summed correctly.

## Test Fixture & Payloads
- PostgreSQL schema has nullable boolean `IsGeofenceBypassed` on `Submissions` table.

## Tools & Commands
- Execution: `rtk dotnet test`, `flutter test`

## Proposed Changes

### Backend Changes (C#)

#### File 1: `server/Features/Analytics/BodReportDtos.cs`
- **Objective**: Extend `BodChainKpis` with a `GeofenceBypassCount` parameter.
- **Change**:
  ```csharp
  public record BodChainKpis(
      int TotalAudits,
      decimal AvgScore,
      decimal AvgTtrDays,
      decimal CompletionRate = 0,
      int OpenActionPlans = 0,
      int OverdueActionPlans = 0,
      int ActiveStores = 0,
      int TotalAuditors = 0,
      int GeofenceBypassCount = 0 // New optional parameter
  );
  ```

#### File 2: `server/Features/Analytics/BodReportCalculator.cs`
- **Objective**: Compute the geofence bypass count in the nightly snapshot calculation.
- **Change**:
  - Retrieve the date 30 days ago (relative to local date/timezone).
  - Count completed, non-rejected submissions submitted with `IsGeofenceBypassed == true`.
  - Add `GeofenceBypassCount` parameter when constructing `BodChainKpis`.

#### File 3: `server/Features/Analytics/GetBodReport.cs`
- **Objective**: Compute the geofence bypass count in live district/province query path.
- **Change**:
  - In `HandleAsync`, calculate `geofenceBypassCount` for the filtered subset of stores in the last 30 days.
  - Return `geofenceBypassCount` within the anonymous `kpis` payload.

### Frontend Changes (Dart)

#### File 1: `lib/features/analytics/manager/bod_analytics_data.dart`
- **Objective**: Extend `BodChainKpis` with the `geofenceBypassCount` field.
- **Change**:
  - Add `final int geofenceBypassCount;` to `BodChainKpis` class.
  - Update default constructor parameter to `this.geofenceBypassCount = 0`.
  - Update `BodChainKpis.fromJson` to map `geofenceBypassCount: json['geofenceBypassCount'] ?? 0`.
  - Update `toJson` to include `'geofenceBypassCount': geofenceBypassCount`.

#### File 2: `lib/features/analytics/services/mock/bod_mock_data.dart`
- **Objective**: Align mock dashboard data with the extended DTO payload.
- **Change**:
  - Add `"geofenceBypassCount": 5` inside `"kpis"` object in `reportJson()`.

#### File 3: `lib/features/analytics/widgets/bod_kpi_grid.dart`
- **Objective**: Render the geofence bypass count in the remaining card slot.
- **Change**:
  - Extract `geofenceBypassCount` from `chainKpis` parameter.
  - Replace the blank `SizedBox` widget under `Total Auditors` with the new KPI card:
    ```dart
    Expanded(
      child: _buildKpiCard(
        context,
        'Geofence Bypasses',
        '$geofenceBypassCount',
        description: 'Audits submitted bypassing geofence (last 30 days)',
        isAlert: geofenceBypassCount > 0,
      ),
    )
    ```

## Concept Diagram
```
[Flutter UI: BodKpiGrid] ---> HTTP GET /api/analytics/bod-report ---> [ASP.NET GetBodReport Endpoint]
```

## Execution Slices
- **Slice 3**: Plan -> Write Acceptance & Unit Tests -> Build

## Risk Assessment
1. **PostgreSQL Null Inequality Bug**: If a submission's `ReviewStatus` is `NULL`, writing standard inequality operations (`ReviewStatus != "rejected"`) will exclude the record. We must guard against this by using `(s.ReviewStatus == null || s.ReviewStatus != "rejected")`.
2. **Missing/Null `IsGeofenceBypassed` Value**: Older audits in the system might have a `NULL` value in the database. Our EF Core queries must explicitly check `IsGeofenceBypassed == true` and not rely on simple default conversions.

## Verification Plan
- Execute `rtk dotnet test` and write integration tests asserting:
  - Both nightly calculation and live filtering paths correctly isolate completed non-rejected audits in the last 30 days.
  - Submissions with `IsGeofenceBypassed == true` are counted, while `false` or `null` values are ignored.
