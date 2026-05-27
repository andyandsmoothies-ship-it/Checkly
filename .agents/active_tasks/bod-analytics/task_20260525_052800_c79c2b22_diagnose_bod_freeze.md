# Task: BOD Analytics Dashboard — Main Isolate Paused On Exception

Workflow: /diagnose | Track: B2

## Input Lineage

- **Source Input**: User screenshot + IDE Call Stack image
- **Key Evidence**: `main` PAUSED ON EXCEPTION; API 200 in 4.7ms; Drift isolate PAUSED ON ENTRY

## Steps

- [x] Step 2: Symptom Isolation — `main` PAUSED ON EXCEPTION; API 200 in 4.7ms; BodRegionFilterBar DropdownButtonFormField assertion
- [x] Step 3: Skill & Rule Discovery — `dropdown_card.dart` is project pattern; GEMINI.md Hardcoded Role Filtering gotcha
- [x] Step 4: Resolution Plan — Fixed `DropdownButtonFormField<String?>` + null-sentinel items; 18/18 tests pass
- [x] Step 5: Deliverable Handoff — `docs/diagnostics/failure_report_20260525_052800_c79c2b22_bod_freeze.md`

## Hypotheses

1. `BodReportResponse.fromJson` throws TypeError when server sends null for non-nullable field (e.g. `goldenStore`, `snapshotStatus`)
2. `BodDashboardBody` widget build throws exception via type cast on dynamic list elements
3. `BodScoreTrend` line 111 unnecessary `!` operator masks a null access that throws at runtime
4. `notifyListeners()` fires during a build frame and triggers rebuild exception ("setState called during build")
5. `DropdownButtonFormField` `value:` deprecated member throws at runtime (seen as warning in Problems panel)

## Artifact Inventory

| Status | File Path | Type |
| [NEW]  | docs/diagnostics/failure_report_20260525_052800_c79c2b22_bod_freeze.md | Report |
