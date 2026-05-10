# Walkthrough: PBAC UI Final Polish — Step 4 (ProgramListPage)

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac-ui-fix\implementation_plan_20260509.md`
- **Step**: Step 4 — Graceful Degradation in ProgramListPage (Audit Item 5)

---

## Decision Log

| Topic | Proposed | Implemented | Reason |
|---|---|---|---|
| Capability token | `programsReview` (plan Task 4.2) | `programsReview` | Correctly targets the ability to view/review a specific program. Used to disable the `onTap` for unauthorized users. |
| Read-only indication | Hide trailing chevron, nullify onTap | Hide trailing chevron, nullify onTap | Graceful degradation. The user can still see the program list, but the lack of a chevron icon visually communicates that the row is not actionable. Nullifying `onTap` enforces this. |

### Gating Logic
```
buildBody()
  → pm = GetIt.instance<PolicyManager>()
  → canReview = pm.can(AppCapabilities.programsReview)
  → trailing: canReview ? const Icon(Icons.chevron_right) : null
  → onTap: canReview ? () => context.push('/programs/review/$id') : null
```

---

## Files Modified

| File | Change |
|---|---|
| `lib/features/programs/pages/program_list_page.dart` | Fetched `canReview` from `PolicyManager` inside `_buildBody`. Used it to conditionally render `trailing: const Icon(Icons.chevron_right)` and `onTap` callback in the `ListView.separated` item builder. |

### Test Changes
No UI tests existed for `ProgramListPage` that asserted the presence of the chevron icon or `onTap` behavior. The basic widget presence test in `hq_program_dashboard_test.dart` passes.

---

## Verification Handoff

**Manual check**:
1. Log in as a user with `programs:review` → navigate to Programs → verify the list items have a `>` icon and tapping them opens the program review page.
2. Log in as a user WITHOUT `programs:review` → navigate to Programs → verify the list items lack the `>` icon and tapping them does nothing. The items should visually appear read-only.

---

<test_trace>
Command: rtk flutter test --concurrency=1 > .agents/tmp/test_step4.txt 2>&1
Exit code: 0
Last lines of output:
  02:05 +467: All tests passed!
</test_trace>

<forensic_evidence>
1. flutter analyze lib/features/programs/pages/program_list_page.dart: No issues found (ran in 2.3s)
2. flutter test (global --concurrency=1): 467/467 passed, 0 failed
3. verify_workflow.py: to be run post-artifact creation
</forensic_evidence>

---

## Gotcha Protocol

No new gotchas found for this step. The graceful degradation pattern (nullifying `onTap` and removing trailing action icons based on PolicyManager) has proven very effective for list views without disrupting the layout or throwing errors.
