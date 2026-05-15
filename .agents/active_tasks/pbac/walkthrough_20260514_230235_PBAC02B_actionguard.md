# Walkthrough: Phase B — Flutter ActionGuard Widget + SubmissionDto Update

## Input Lineage
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260514_223612_PBAC02_hybrid_entity_ui.md`
- **TDD Tests (RED Phase)**: `C:\Users\HP\Documents\GitHub\Checkly\test\unit\widgets\action_guard_test.dart`
- **Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\pbac\task_20260514_230235_PBAC02B_actionguard.md`

---

## Decision Log

| Decision | Proposed in Plan | Actually Implemented | Reason |
|---|---|---|---|
| `ActionGuard` widget type | `StatelessWidget` | `StatelessWidget` | Matches plan. Online path is a snapshot; no reactive rebuild needed. |
| Offline path widget | `StatelessWidget` direct read | `ValueListenableBuilder<Set<String>>` | The direct call to `GetIt.instance<AuthManager>().capabilities.value` triggered a get_it v9 async reset race in the test environment. `ValueListenableBuilder` is the idiomatic pattern (matches `PermissionGuard`). |
| Test `setUp` | Not specified | Added `await` to `GetIt.instance.reset()` | **Test Infrastructure Fix**: get_it v9's `reset()` returns `FutureOr<void>`. Without `await`, the async reset wipes the mock registration before the widget builds. Classified as infrastructure fix per ATDD quality gates. |
| `SubmissionActions` class modifier | `abstract class` | `abstract final class` | Prevents both instantiation AND inheritance — correct for a Dart constants namespace class. |
| Drift persistence of `allowedActions` | NOT persisted | NOT persisted | Confirmed. Transient field only. No Drift schema changes. |
| `withStatus()` propagation | Must propagate | Propagates `allowedActions` | Prevents silent field loss when `HistoryManager` hydrates local draft state. |

---

## Files Created / Modified

| Status | File | Summary |
|---|---|---|
| [NEW] | `lib/_shared/constants/submission_actions.dart` | Type-safe action key constants. Mirrors C# constants. |
| [NEW] | `lib/_shared/widgets/action_guard.dart` | `ActionGuard` widget. 4-state matrix (online/offline x allow/deny). |
| [MOD] | `lib/features/audit/model/submission_dto.dart` | Added `List<String>? allowedActions`. Updated `fromJson` and `withStatus()`. |
| [MOD] | `test/unit/widgets/action_guard_test.dart` | Infrastructure fix: `await GetIt.instance.reset()`. Added real import. Removed placeholder stub. |

---

## Verification Handoff

Manual test steps:
1. Log in as reviewer. Open a `completed` audit. Confirm Finalize button is visible.
2. Open a `finalized` audit. Confirm Finalize button is hidden.
3. Go offline (airplane mode). Confirm button behaviour matches JWT capability.

Blast radius: Zero. `ActionGuard` is not imported by any feature file yet (wiring is Phase C).

<test_trace>
Full Flutter test suite (exit code 0 — no regressions):

TC-07: actions=null, user has fallbackCapability -> PASS
TC-08: actions=null, user lacks fallbackCapability -> PASS
TC-09: actions=[] (empty list) -> PASS
Online check: actions contains requiredAction -> PASS
Full suite: All tests passed. Exit code: 0
</test_trace>

<forensic_evidence>
flutter analyze (3 files) -> No issues found! (ran in 71.1s)
</forensic_evidence>

---

## Gotcha Protocol

**Proposed addition to `lib/GEMINI.md`:**

> **Gotcha: get_it v9 async reset in widget tests**
> - **Root Cause**: `GetIt.instance.reset()` in get_it v9 returns `FutureOr<void>`. If the project has `registerSingletonAsync` registrations, reset is fully async. Calling without `await` causes a race: the async reset wipes registrations after `registerSingleton` runs.
> - **Fix**: ALWAYS use `setUp(() async { await GetIt.instance.reset(); ... })` in widget tests that use GetIt mocks.
