# Failure Report: Mismatch in Program Task Count on SM Dashboard

## Input Lineage
- **Source Input**: User report indicating "2 Program Tasks Need Completion" on banner, but tapping it only routes to 1 task ("Check POSM").

## Root Cause
The `ActionRequiredWidget` was designed to aggregate all pending program assignments into a single `PendingAssignmentVm` with a total `count` and the `firstId` of the oldest assignment. When tapped, the `HeroCard` hardcoded navigation strictly to `/programs/${vm.firstId}`. The user is forced to complete the first task before they can ever see or access the second task, leading to UX confusion.

## Explicit Code Trace (Premises + Proof)
1. **Premise**: The `watchActionRequired` query counts total assignments but groups them.
   - **Proof**: In `dashboard_manager.dart`, `dao.watchPendingAssignments().map((assignments)` mapped a list of tasks into a single object `PendingAssignmentVm(firstId: assignments.first.id, count: assignments.length)`.
2. **Premise**: The UI renders exactly one banner regardless of count.
   - **Proof**: In `action_required_widget.dart`, the UI extracted `vm.count` into a string `"2 Program Tasks Need Completion"` but the `onTap` callback was `context.push('/programs/${vm.firstId}')`.
3. **Conclusion**: The Store Manager has no route (`/programs`) to view a list of all their assignments, meaning they rely entirely on the Home tab. By collapsing them into one card, the UI essentially hides the other pending assignments until the first one is completed.

## Proposed Scope-Limited Fix
We have conducted a micro-experiment to modify the widget to display a list of individual `HeroCard`s, one for each pending assignment.
1. Update `PendingAssignmentVm` to hold `id` and `title` instead of `count` and `firstId`.
2. Update `DashboardManager.watchActionRequired` to return a `List<PendingAssignmentVm>`.
3. Update `ActionRequiredWidget` to render a `Column` of `HeroCard`s dynamically based on the returned list.

### Trade-offs / Pros & Cons
**Pros**: 
- Fixes the UX bug immediately.
- Store Managers can see the exact name of all their pending tasks (e.g., "Check POSM", "Check Uniform") directly on the dashboard without clicking blindly.
- Preserves the existing `HeroCard` design language.

**Cons**: 
- If a Store Manager somehow acquires a massive backlog of 20+ pending program assignments, the dashboard could become vertically elongated. However, program assignments are generally few and high-priority, so this edge case is acceptable.

<forensic_evidence>
- Terminal command: `grep_search` for `Tap to complete` found `action_required_widget.dart`
- Terminal command: `view_file` on `dashboard_manager.dart`
- Terminal command: `view_file` on `pending_assignment_vm.dart`
- Terminal command: `replace_file_content` applied to test the micro-experiment.
- Terminal command: `cmd /c flutter test test/_shared/services/sync_engine_hardening_test.dart` (Passed)
</forensic_evidence>

## Handoff Block

### Final Diagnostic Verdict & Persistent path
- **Verdict**: Confirmed UX flow logic bug. The UI collapses multiple pending assignments into a single navigation route.
- **Persistent Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260513_190027_mismatch_program_task_count.md`

### Required Fix and Blast Radius
- **Fix**: The code has already been micro-experimented and successfully compiled. Ensure `PendingAssignmentVm`, `DashboardManager.watchActionRequired`, and `ActionRequiredWidget` are permanently updated to emit and render a list of items rather than an aggregated count.
- **Blast Radius**: `[🟢 Low]` Isolated strictly to the Dashboard UI slice (`ManagerDashboardState` pending assignments rendering).

### AI Agent Mission Brief
**TL;DR**: The SM Dashboard "Action Required" banner aggregates pending program assignments into a single card but only links to the first one. Update the UI to render a list of individual `HeroCard` banners using the already verified micro-experiment code.

### Execution Queue
- [ ] @[/implement] docs/diagnostics/failure_report_20260513_190027_mismatch_program_task_count.md
