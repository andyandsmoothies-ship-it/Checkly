<latent_space_scratchpad>
CRITICAL INSIGHT: These tests provide the final behavioral safety nets requested by the consolidated refactoring plan (Steps 9-12).
AppLifecycleManager uses real DateTime.now(), so testing time passage will require clock injection or `fake_async` testing utility in Dart.
ActionPlan transitions require strict guarding checks and tracking mock calls.
Audit submit/draft requires verifying complex DTO mappings and idempotency/draft deletion logic.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\consolidated_refactoring_plan.md`

## Executive Summary & Out of Scope
**What we are doing:**
- We are implementing unit tests to provide behavioral safety nets for the critical state math and workflows of 4 specific manager files (Phase 4 of the consolidated refactoring plan).
- Step 9: `AppLifecycleManager` (4 recovery tiers)
- Step 10: `ActionPlanManagerTransitions` (state machine, roles, offline behavior)
- Step 11: `AuditManagerSubmit` (pipeline, mutex, outbox inserts, draft teardown)
- Step 12: `AuditManagerDraft` (scheduling, restoring, discarding, force saving)

**Out of Scope:**
- ❌ No production code changes (only tests).
- ❌ No integration/E2E tests (only unit tests).
- ❌ No backend/API changes.
- ❌ No UI changes.

## Logs & Audits
N/A - Test files do not generate production logs.

## 4-State Matrix

| State | Behavior |
|-------|----------|
| **Success** | All tests pass, coverage confirmed, CI green |
| **Error** | Tests fail with expected assertions when given invalid data |
| **Loading** | Tests execute quickly within CI timeout |
| **Empty** | Edge cases and empty boundaries properly asserted in tests |

## Test Contracts

### Step 9: AppLifecycleManager
| ID | Exact Text | State Matrix | Why it fails first |
|----|------------|--------------|--------------------|
| TC-09-01 | `< 5 mins elapsed triggers no callbacks` | Success | No test exists |
| TC-09-02 | `Exactly 5 mins elapsed triggers onAuthCheck` | Success | Boundary condition not tested |
| TC-09-03 | `5 mins - 12 hours elapsed triggers onAuthCheck` | Success | No test exists |
| TC-09-04 | `Exactly 12 hours elapsed triggers onFullResync` | Success | Boundary condition not tested |
| TC-09-05 | `12 hours - 7 days elapsed triggers onFullResync` | Success | No test exists |
| TC-09-06 | `Exactly 7 days elapsed triggers onForceReLogin` | Success | Boundary condition not tested |
| TC-09-07 | `> 7 days elapsed triggers onForceReLogin` | Success | No test exists |
| TC-09-08 | `Debounce cancels pending execution on repeated resumes` | Success | No test exists |

### Step 10: ActionPlanManagerTransitions
| ID | Exact Text | State Matrix | Why it fails first |
|----|------------|--------------|--------------------|
| TC-10-01 | `submitEvidence asserts store_manager role and open status` | Error | No test exists |
| TC-10-02 | `submitEvidence online delegates to API and updates memory` | Success | No test exists |
| TC-10-03 | `submitEvidence offline writes to OutboxDao and patches UI optimism` | Success | No test exists |
| TC-10-04 | `closePlan asserts auditor/admin role and pending_verify status` | Error | No test exists |
| TC-10-05 | `closePlan calls API with verifierName and updates status` | Success | No test exists |
| TC-10-06 | `rejectEvidence asserts auditor/admin role and pending_verify status` | Error | No test exists |
| TC-10-07 | `rejectEvidence clears evidence and returns to open status` | Success | No test exists |
| TC-10-08 | `Transitions throw on terminal plan status` | Error | No test exists |

### Step 11: AuditManagerSubmit
| ID | Exact Text | State Matrix | Why it fails first |
|----|------------|--------------|--------------------|
| TC-11-01 | `_submitAuditLogic drops concurrent calls silently (mutex)` | Success | No test exists |
| TC-11-02 | `_submitAuditLogic throws exception if answers are empty` | Error | No test exists |
| TC-11-03 | `_submitAuditLogic inserts atomic submission and deletes draft` | Success | No test exists |
| TC-11-04 | `_submitAuditLogic sets _wasQueuedOffline=true if offline` | Success | No test exists |
| TC-11-05 | `_submitAuditLogic sets _error string on internal failure` | Error | No test exists |

### Step 12: AuditManagerDraft
| ID | Exact Text | State Matrix | Why it fails first |
|----|------------|--------------|--------------------|
| TC-12-01 | `_scheduleDraftSaveLogic saves to DraftService and sets saved time` | Success | No test exists |
| TC-12-02 | `_restoreDraftLogic restores valid answers and notes from pendingDraft` | Success | No test exists |
| TC-12-03 | `_restoreDraftLogic silently skips corrupted answer formats` | Success | No test exists |
| TC-12-04 | `_discardDraftLogic deletes draft key and nullifies pending draft` | Success | No test exists |
| TC-12-05 | `_forceSaveLogic bypasses debounce and completes immediately` | Success | No test exists |

## Test Fixture & Payloads
- **AppLifecycleManager**: `fake_async` to simulate time passage and `AppLifecycleState` changes without real waiting.
- **ActionPlanManagerTransitions**: Mock `ActionPlanManager`, Mock `ConnectivityService`, Mock `ActionPlanOutboxDao`, Mock API. Use seeded `ActionPlanDto`.
- **AuditManagerSubmit/Draft**: Mock `AuditManager`, Mock `DraftService`, Mock `OutboxDao`. Seeded with dummy `TemplateDto` and `StoreDto`.

## Tools & Commands
- **Skills needed**: `tdd`, `testing-strategy`
- **Commands**:
```bash
rtk flutter test test/_shared/services/app_lifecycle_manager_test.dart
rtk flutter test test/features/action_plans/manager/action_plan_manager_transitions_test.dart
rtk flutter test test/features/audit/manager/audit_manager_submit_test.dart
rtk flutter test test/features/audit/manager/audit_manager_draft_test.dart
rtk flutter analyze test/
```

## Proposed Changes
| Action | File | Description |
|--------|------|-------------|
| `[NEW]` | `test/_shared/services/app_lifecycle_manager_test.dart` | Implementation of TC-09-* |
| `[NEW]` | `test/features/action_plans/manager/action_plan_manager_transitions_test.dart` | Implementation of TC-10-* |
| `[NEW]` | `test/features/audit/manager/audit_manager_submit_test.dart` | Implementation of TC-11-* |
| `[NEW]` | `test/features/audit/manager/audit_manager_draft_test.dart` | Implementation of TC-12-* |

## Concept Diagram
```text
[Manager Class] <--- Unit Tests ---> [Mock Dependencies]
   |
   +-- Assert Lifecycle Timers
   +-- Assert Finite State Guards
   +-- Assert SQLite/Outbox Inserts
```

## Execution Slices

### Phase A: Core Service Coverage (Step 9)
**Complexity:** Medium (Requires mocking time and lifecycle observer)
- Implement `app_lifecycle_manager_test.dart`.

### Phase B: Action Plan Transitions (Step 10)
**Complexity:** Low (Standard mocked dependency tests)
- Implement `action_plan_manager_transitions_test.dart`.

### Phase C: Audit Submission Pipeline (Step 11 & 12)
**Complexity:** Low (Standard mocked dependency tests)
- Implement `audit_manager_submit_test.dart`.
- Implement `audit_manager_draft_test.dart`.

<command_logs>
- grep_search: Located the 4 manager files to understand their logic.
- view_file: Checked `app_lifecycle_manager.dart` to determine exact Tier constraints.
- view_file: Checked `action_plan_manager_transitions.dart` to determine roles and status guards.
- view_file: Checked `audit_manager_submit.dart` and `audit_manager_draft.dart` for DB and Draft workflows.
</command_logs>

## Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Testing time passage incorrectly | High | High (flaky tests) | Use `fake_async` to mock the dart timer system explicitly. |
| Test doubles not matching production | Medium | Medium | Rely on `mocktail` for strict parameter matching and verifications. |

## Verification Plan
**Gate 1:**
```bash
rtk flutter analyze test/
```
> Expected: Zero errors or warnings in tests.

**Gate 2:**
```bash
rtk flutter test --reporter=expanded
```
> Expected: All newly written matrices pass successfully without side-effects.

## Handoff Block
```markdown
@[/tdd] Execute tests for Phase A: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_125300_baca184a_test_coverage_phase_4.md
@[/tdd] Execute tests for Phase B: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_125300_baca184a_test_coverage_phase_4.md
@[/tdd] Execute tests for Phase C: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_125300_baca184a_test_coverage_phase_4.md
```
