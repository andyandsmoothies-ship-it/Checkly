# Task: Analytics Showing Empty for Store Manager (sm7)
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: User report indicating user `sm7` sees "No analytics yet" on Profile > My Store, despite having audits and tasks.

# Diagnosis and Resolution (SM7 Empty Analytics Bug)

## Issue
Store Manager `sm7` reported seeing an empty "No analytics yet" screen on the Analytics page, despite having 2 completed audits in the database.

## Root Cause
A **Silent DTO Contract Drift** occurred between the ASP.NET Backend and the Flutter Frontend.
1. The backend `GetAnalytics` endpoint groups all top-level KPI metrics (e.g., `totalAudits`, `avgScore`) inside a nested `kpis` object in the JSON response: `{"kpis": {"totalAudits": 2, ...}}`.
2. The frontend `AnalyticsManager.dart` was trying to parse these KPIs from the root of the JSON object (e.g., `json['totalAudits']`).
3. This resulted in `totalAudits` evaluating to `null`, which hit the fallback `?? 0`.
4. The `analytics_body.dart` widget reads `totalAudits == 0` and renders the empty state placeholder.

The Flutter tests were previously passing due to "Mock Mirroring", where `analytics_manager_test.dart` provided a fake JSON response with KPIs at the root level, incorrectly matching the broken frontend parser rather than the real backend DTO.

## Fix Implemented
- **Frontend**: Updated `AnalyticsManager.dart` to parse `json['kpis']` first, and then extract the metrics from that map.
- **Testing**: Updated the mocked API response in `analytics_manager_test.dart` to correctly reflect the backend's `kpis` nesting. 
- **Verification**: The Flutter test suite (543 tests) was executed and successfully passed.

## Next Steps
The fix is committed and verified. The user can now use the `/verify` or other workflows to proceed.

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
| [DONE]  | c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260518_161546_diag_empty_analytics.md | Report |
