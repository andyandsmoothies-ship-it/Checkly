# Task: Empty FAB Menu Bug
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\lib\_shared\widgets\checkly_fab.dart`

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Phase 1: Hypotheses
1. **Hypothesis 1:** Store Managers (SM) lack the `canCreateSubmission` capability and `isAdmin` flag, making the `items` list empty, which causes `showMenu` to crash. Proving this: Return `SizedBox.shrink()` if both are false, and the error will disappear.
2. **Hypothesis 2:** The `ChecklyFab` relies on `items.isNotEmpty` which is not guaranteed. Proving this: Wrap `showMenu` with `if (items.isNotEmpty)`.
3. **Hypothesis 3:** The parent pages (e.g., `dashboard_page.dart`) always render `ChecklyFab` regardless of role. Proving this: The FAB is visible on SM devices even though it has no actions.

## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | docs/diagnostics/failure_report_20260506_143643_fab_bug_empty_fab_menu.md | Report |
