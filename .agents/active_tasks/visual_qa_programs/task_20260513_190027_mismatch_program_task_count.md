# Task: Program Task Count Mismatch
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: User report with images showing "2 Program Tasks Need Completion" on SM7 homepage banner, but only 1 task listed when clicked.

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260513_190027_mismatch_program_task_count.md | Report |

## Hypotheses
1. If the issue is that `ActionRequiredWidget` groups multiple tasks into a single banner and hardcodes navigation to the first one, then changing the widget to render a list of individual `HeroCard` banners will prove it and fix the issue.
2. If the issue is that the router lacks a dedicated Store Manager pending list view, then creating one and redirecting the banner there will prove it.
3. If the backend is mistakenly bundling tasks under the same ID, then examining the SQLite DB will prove it (falsified: count is correctly calculated client-side).
