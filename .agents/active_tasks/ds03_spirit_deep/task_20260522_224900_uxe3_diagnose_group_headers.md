# Task: Diagnose Inconsistent Store Group Headers
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: User provided screenshots showing inconsistent group headers between Activity (Audits) and Action Plans tabs.

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260522_224900_uxe3_group_headers.md | Report |

## Hypotheses
1. If the Audits list and Action Plans list use different custom widgets for their group headers, changing them to use a single shared `StoreGroupHeader` primitive will resolve the inconsistency.
2. If one header hardcodes typography (like `letterSpacing: 1.5`) while the other uses standard theme typography, unifying the text style will fix the visual difference.
3. If the badge components (the number indicators) are implemented differently, standardizing on a single `CountBadge` or `PillChip` primitive will resolve it.
