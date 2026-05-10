# Walkthrough: PBAC UI Final Polish — Step 3 (ScheduleAuditPage)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac-ui-fix\implementation_plan_20260509.md`
- **Step**: Step 3 — Secure ScheduleAuditPage (Audit Item 3)

---

## Decision Log

| Topic | Proposed | Implemented | Reason |
|---|---|---|---|
| Capability token | `programsCreate` (plan Task 3.2, option A) | `submissionsCreate` | Audit report (line 61) explicitly specifies `submissions:create`. `submissionsCreate` is already used in `template_card.dart` and `dashboard_page.dart` for the same business action (starting an audit submission). Using `programsCreate` would be incorrect — that guards template/program creation, not audit delegation. |
| Denied view style | `Center(child: Text('Unauthorized'))` (plan Task 3.3) | `_AccessDeniedView` with icon + title + description | A bare `Text` does not follow Material Design UX patterns. Extracted to private `_AccessDeniedView` StatelessWidget for readability without adding complexity. Uses theme-adaptive colors (`onSurfaceVariant`). |
| Widget type | Convert to StatefulWidget | Remain StatelessWidget | `PolicyManager.can()` is a synchronous read from an in-memory set. No state management needed. |

### Gating Logic
```
build()
  → pm = GetIt.instance<PolicyManager>()
  → canSchedule = pm.can(AppCapabilities.submissionsCreate)
  → body = canSchedule ? ScheduleAuditForm(...) : _AccessDeniedView()
```

---

## Files Modified

| File | Change |
|---|---|
| `lib/features/admin/pages/schedule_audit_page.dart` | Added `get_it`, `AppCapabilities`, `PolicyManager` imports. `build()` gates the body on `submissionsCreate`. Added private `_AccessDeniedView` widget. |

### No test file modification needed
No prior test file existed for `ScheduleAuditPage`. Confirmed via `grep_search` for `ScheduleAuditPage` in `test/` — 0 results. No test harness wiring required.

---

## Verification Handoff

**Manual check**:
1. Log in as a user with `submissions:create` → navigate to Schedule Audit → verify the form renders normally.
2. Log in as a user WITHOUT `submissions:create` → navigate to `/admin/schedule` → verify lock icon + "Access Restricted" + "You do not have permission to schedule audits." renders.
3. Verify the AppBar title "Schedule Audit" is present in both cases.

---

<test_trace>
Command: rtk flutter test --concurrency=1 > .agents/tmp/test_step3.txt 2>&1
Exit code: 0
Last lines of output:
  02:19 +467: All tests passed!
</test_trace>

<forensic_evidence>
1. flutter analyze lib/features/admin/pages/schedule_audit_page.dart: No issues found (ran in 5.6s)
2. grep_search ScheduleAuditPage in test/: 0 results (no existing test to break)
3. flutter test (global --concurrency=1): 467/467 passed, 0 failed
4. verify_workflow.py: to be run post-artifact creation
</forensic_evidence>

---

## Gotcha Protocol

No new gotchas found for this step. The `submissionsCreate` capability is already established as the correct token for audit submission flows in the codebase (`template_card.dart`, `dashboard_page.dart`, `history_page.dart`). The plan's `programsCreate` suggestion was a documentation error — always verify capability mapping against `app_capabilities.dart` and existing usage sites before choosing a token.
