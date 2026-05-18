# Diagnostic Report: SM7 Empty Analytics Bug

Workflow: /diagnose

## Input Lineage
User report indicating user `sm7` sees "No analytics yet" on Profile > My Store, despite having audits and tasks.

## Root Cause
A **Silent DTO Contract Drift** occurred between the ASP.NET Backend and the Flutter Frontend.
1. The backend `GetAnalytics` endpoint groups all top-level KPI metrics (e.g., `totalAudits`, `avgScore`) inside a nested `kpis` object in the JSON response: `{"kpis": {"totalAudits": 2, ...}}`.
2. The frontend `AnalyticsManager.dart` was trying to parse these KPIs from the root of the JSON object (e.g., `json['totalAudits']`).
3. This resulted in `totalAudits` evaluating to `null`, which hit the fallback `?? 0`.
4. The `analytics_body.dart` widget reads `totalAudits == 0` and renders the empty state placeholder.

The Flutter tests were previously passing due to "Mock Mirroring", where `analytics_manager_test.dart` provided a fake JSON response with KPIs at the root level, incorrectly matching the broken frontend parser rather than the real backend DTO.

## Explicit Code Trace (Premises + Proof)
**Backend (GetAnalytics.cs):**
```csharp
return Results.Ok(new {
    kpis = new {
        totalAudits = kpiData.TotalAudits,
        avgScore = kpiData.AvgScore,
        ...
    }
});
```

**Frontend (AnalyticsManager.dart - Before Fix):**
```dart
final kpis = AnalyticsKpis(
  totalAudits: json['totalAudits'] as int? ?? 0,
  avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0.0,
  ...
);
```
Since `json['totalAudits']` was `null` (it should have been `json['kpis']['totalAudits']`), `totalAudits` became `0`.

## Proposed Scope-Limited Fix (Already Implemented)
- **Frontend**: Update `AnalyticsManager.dart` to parse `json['kpis']` first, and then extract the metrics from that map.
- **Testing**: Update the mocked API response in `analytics_manager_test.dart` to correctly reflect the backend's `kpis` nesting. 

### Trade-offs / Pros & Cons
- **Pros**: Perfectly aligns the frontend client with the actual backend DTO. Fixes the empty state bug for all users. Ensures test suites accurately mirror production API contracts, preventing future regression.
- **Cons**: Required modifying both production parsing logic and the test suite's mock data simultaneously.

<forensic_evidence>
- `view_file` on `server/Features/Analytics/GetAnalytics.cs`
- `view_file` on `lib/features/analytics/manager/analytics_manager.dart`
- `view_file` on `test/features/analytics/manager/analytics_manager_test.dart`
- `run_command` created temporary diagnostic test in ASP.NET
- `replace_file_content` on `AnalyticsManager.dart` to fix parsing
- `replace_file_content` on `analytics_manager_test.dart` to fix mock
- `run_command` `flutter test` - 543 tests passed.
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict & Persistent path**: The "No analytics yet" bug was caused by a silent DTO contract drift where the frontend expected flat JSON but the backend sent nested JSON. Path: `docs/diagnostics/failure_report_20260518_161546_diag_empty_analytics.md`.
2. **The required fix and its blast radius**: The parsing logic in `AnalyticsManager.dart` and the mock JSON in `analytics_manager_test.dart` were updated. Blast radius is limited to the Analytics feature data loading. Fix is already implemented and verified via `flutter test`.
3. **AI Agent Mission Brief**: The diagnostic fix is completed and verified. No further implementation is needed for this specific bug.
4. **Execution Queue**:
- [ ] @[/verify] (To finalize the fix if desired, or proceed to the next feature)
