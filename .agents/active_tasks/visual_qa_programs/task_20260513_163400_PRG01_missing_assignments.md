# Task: Missing Program Assignment on SM Dashboard
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: User report with screenshots showing Admin dashboard (assignments exist) and SM dashboard (no assignments visible).

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | c:/Users/HP/Documents/GitHub/Checkly/docs/diagnostics/failure_report_20260513_163400_PRG01_missing_assignments.md | Report |

## Conclusion
- *Finding*: `SyncSubmissions.cs` required `storeId`/`areaId` query parameters, and when the app didn't send them, it threw a `400 BadRequest`. This crashed the entire sync pipeline *before* it could reach the Program assignments module!
- *Fix*: Modified `SyncSubmissions.cs` to automatically infer the `storeId`/`areaId` from the user's Profile if not provided. Also updated `ProgramSyncModule.dart` to save `activeSubmissionId` for draft resumption. Tests pass and the issue is resolved.
