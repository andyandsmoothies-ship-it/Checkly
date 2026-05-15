# Walkthrough: Phase C — ActionGuard UI Wiring

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260514_223612_PBAC02_hybrid_entity_ui.md`
- **Verification Gate**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\verification_20260514_230235_PBAC02B_actionguard.md`
- **Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac\task_20260514_233356_PBAC02C_ui_wiring.md`

---

## Decision Log

| Decision | Proposed in Plan | Actually Implemented | Reason |
|---|---|---|---|
| Wiring Location | `submission_row.dart` (implied by "wiring") | `submission_row.dart` | The only place with a raw `PolicyManager.can()` check for `AppCapabilities.submissionsReview` related to voiding an audit. |
| Hybrid Check Implementation | Wrap widget in `ActionGuard` | Inline hybrid ternary | `ActionGuard` is a widget wrapper, but `PopupMenuButton.itemBuilder` returns a `List<PopupMenuEntry>`. We cannot wrap a list item in a standard widget. Thus, the hybrid logic (`allowedActions` vs `PolicyManager`) was implemented inline matching `ActionGuard`'s exact internal logic. |

---

## Verification Handoff

Manual test steps:
1. Log in to the app and go to the Dashboard.
2. Ensure you have the `submissionsReview` capability (e.g., login as `reviewer`).
3. Open the context menu (three dots) on a Draft submission. The "Void Audit" option should be available based on capability fallback.
4. If a submission is already Voided or Finalized, it won't be a draft, so the menu is skipped entirely. 
5. The logic correctly aligns UI options with the backend data when online and uses JWT capabilities when offline.

Blast radius: Low. Modifications strictly confined to `SubmissionRow` rendering logic. No state or database side effects.

<test_trace>
Full Flutter test suite (exit code 0 — no regressions):

00:49 +498: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
00:52 +499: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
00:53 +500: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: TC-F1-01: AC_429_ReturnsRetryScheduled_NoDelay
00:58 +501: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: (tearDownAll)
00:59 +501: All tests passed!

Exit code: 0
</test_trace>

<forensic_evidence>
cmd /c "rtk flutter analyze lib/features/dashboard/pages/widgets/submission_row.dart 2>&1"
Analyzing submission_row.dart...                                
No issues found! (ran in 3.1s)
</forensic_evidence>

---

## Gotcha Protocol

No new gotchas identified during this phase. The widget vs list-item mismatch is a standard Flutter rendering constraint successfully mitigated using inline logic.
