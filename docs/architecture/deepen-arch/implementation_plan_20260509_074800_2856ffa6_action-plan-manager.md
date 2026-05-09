## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Existing `TC-10-*` tests break due to manager interface drift | Low | High | Manager public API is not modified. Transitions part file still calls same logic path. Run full regression before declaring done. |
| `ActionPlan` entity accidentally imports Flutter or Drift | Low | Medium | Enforce zero-import rule at code review. Entity file has no `import` for Flutter or Drift packages. |
| `area_manager` role omitted from entity guards | Low | High | Carry forward exact role lists from `_closePlanLogic` (L104) and `_rejectEvidenceLogic` (L121) in transitions file. |

---

## Verification Plan

```bash
# Step 1: Run entity unit tests (should be RED before implementation, GREEN after)
rtk flutter test test/features/action_plans/domain/action_plan_entity_test.dart

# Step 2: Run full manager regression (must stay GREEN throughout)
rtk flutter test test/features/action_plans/manager/

# Step 3: Run full feature test suite
rtk flutter test test/features/action_plans/

# Step 4: Full analyze (no new warnings)
rtk flutter analyze lib/features/action_plans/
```

**Pass criteria:** Exit code 0 on all 4 commands above. Zero new warnings or errors.

---

<latent_space_scratchpad>
The ADR has locked in Design 3: a rich ActionPlan entity. The entity holds immutable state and exposes pure transition methods that throw exceptions when guards fail.

Key design observations from the actual code:
1. Guards (_assertRole, _assertStatus, _assertNotTerminal) in action_plan_manager.dart L272-296 reference `_userRole.role` — this is the critical coupling. The entity can't own the UserRoleProvider; it must receive the role string as a parameter at call time.
2. The transitions file calls `manager._assertXxx()` — so the transition logic currently lives in the manager scope. After extraction, `ActionPlan.submitEvidence(role: role, ...)` returns a modified copy; the manager then calls the network/DB layer.
3. `ActionPlanDto` is a pure immutable Dart class — ideal as the underlying data carrier. `ActionPlan` wraps it.
4. The 8 existing tests in action_plan_manager_transitions_test.dart mock the manager directly. They test the public `submitEvidence()`, `closePlan()`, `rejectEvidence()` methods. These tests MUST still pass without modification — they are the safety net. The manager's public API does not change.
5. The `_submitEvidenceLogic` in the transitions file builds optimistic DTOs manually. After refactor, this optimistic build logic can move into `ActionPlan.submitEvidence(...)` which returns a new `ActionPlan` with the updated status/fields. The manager then reads `.toDto()` to get the Drift-compatible payload.
6. New file count: 1 new file (action_plan.dart entity), 2 modified files (action_plan_manager.dart, action_plan_manager_transitions.dart). Blast radius is narrow.
7. The `area_manager` role is already in `_closePlanLogic` and `_rejectEvidenceLogic` — the entity must carry this too.
8. Edge case: `ActionPlan.submitEvidence` for offline must still return the optimistic DTO with timestamps. The manager owns the Drift/API I/O but the entity owns the optimistic field population.
</latent_space_scratchpad>

## Input Lineage
- **Source**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\deepen-arch\adr_20260509_action_plan_manager.md`

## Executive Summary & Out of Scope

**Goal:** Extract the 3 role-guard methods and state-machine transition logic out of `ActionPlanManager` (a 298-line God Object `ChangeNotifier`) into a new pure Dart `ActionPlan` rich domain entity. The manager becomes a thin coordinator: it receives a pure result from the entity, then performs I/O (Drift writes, API calls, in-memory list patches).

**What changes:**
- `ActionPlan` entity is new: wraps `ActionPlanDto`, owns all guards and transition mutations.
- `ActionPlanManager` delegates guard + mutation logic to `ActionPlan`.
- Transition functions in `action_plan_manager_transitions.dart` call `ActionPlan` methods instead of `manager._assertXxx()`.

**Out of Scope:**
- No backend API changes
- No Drift schema changes
- No `cachedActionPlans` table changes
- No new UI pages or widgets
- No changes to sync engine
- No changes to existing test contracts (TC-10-01 through TC-10-08 must pass unchanged)
- No changes to `ActionPlanDto` — it remains the raw data carrier
- `ActionPlanDto.fromJson` and API serialization — untouched

---

## System Context

| Dimension | Value |
|---|---|
| **Connectivity Model** | Offline-first hybrid: Drift SQLite cache + REST API |
| **RBAC** | `store_manager` → submit evidence; `auditor`, `admin`, `area_manager` → close or reject |
| **Scope** | Flutter client only. Zero server changes. |
| **File Size Pre-check** | `action_plan_manager.dart` = 298 lines ✅ (under 400 limit) |
| **Breaking Change** | None — public API of `ActionPlanManager` is unchanged |

---

## Lifecycle Context (4-State Matrix)

> This is a structural refactor — no UI states change. All existing Success/Error/Loading/Empty behavior is preserved.

| State | Behavior After Refactor |
|---|---|
| **Success** | Entity returns updated `ActionPlan`; manager patches list and notifies listeners. Identical to today. |
| **Error (Role Guard)** | `ActionPlan` throws `RoleGuardException`. Manager propagates it. UI catches it — same as today. |
| **Error (Bad Transition)** | `ActionPlan` throws `InvalidTransitionException`. Same propagation path as today. |
| **Loading** | Manager sets `_isLoading = true` before I/O. Entity is pure and synchronous — no loading state change. |

---

## Test Contracts

| ID | Description | Boundary / Edge Case | Why it fails first (TDD) |
|---|---|---|---|
| TC-11-01 | `ActionPlan.submitEvidence()` throws `RoleGuardException` if role is not `store_manager` | Role = `auditor` | Entity guard not yet extracted |
| TC-11-02 | `ActionPlan.submitEvidence()` throws `InvalidTransitionException` if status is not `open` | Status = `pending_verify` | Status guard not yet extracted |
| TC-11-03 | `ActionPlan.submitEvidence()` throws `InvalidTransitionException` if status is `closed` | Terminal state | `_assertNotTerminal` not yet in entity |
| TC-11-04 | `ActionPlan.closePlan()` throws `RoleGuardException` if role is `store_manager` | Only auditor/admin/area_manager can close | Entity guard not yet extracted |
| TC-11-05 | `ActionPlan.closePlan()` throws `InvalidTransitionException` if status is not `pending_verify` | Status = `open` | Status guard not yet extracted |
| TC-11-06 | `ActionPlan.rejectEvidence()` throws `RoleGuardException` if role is `store_manager` | Same as TC-11-04 | Entity guard not yet extracted |
| TC-11-07 | `ActionPlan.rejectEvidence()` throws `InvalidTransitionException` if status is not `pending_verify` | Status = `closed` | Status guard not yet extracted |
| TC-11-08 | `ActionPlan.submitEvidence()` returns a new `ActionPlan` with `status = pending_verify` | Happy path | Entity mutation not yet implemented |
| TC-11-09 | `ActionPlan.closePlan()` returns a new `ActionPlan` with `status = closed` and `verifierName` set | Happy path | Entity mutation not yet implemented |
| TC-11-10 | `ActionPlan.rejectEvidence()` returns a new `ActionPlan` with `status = open` and evidence fields cleared | Happy path | Entity mutation not yet implemented |
| **Regression** | All TC-10-01 through TC-10-08 in `action_plan_manager_transitions_test.dart` must pass unchanged | Public manager API is identical | If manager interface drifts |

---

## Test Fixture & Payloads

**Required State:** No database or network needed. `ActionPlan` is a pure Dart class.

```dart
// Minimum fixture to test entity in isolation
final openPlan = ActionPlan(ActionPlanDto(
  id: 'plan-123',
  status: 'open',
  criteriaLabel: 'Clean floors',
  groupTitle: 'Cleanliness',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
));
```

No JSON payloads required — entity has no I/O.

---

## Tools & Commands

| Tool | Purpose |
|---|---|
| `flutter-architecture` skill | Confirms manager/entity pattern in PFA |
| `tdd` skill | Red-Green-Refactor for pure Dart entity |

```bash
# Run only the entity unit tests (fast, no DB)
rtk flutter test test/features/action_plans/domain/action_plan_entity_test.dart

# Run full regression to prove manager interface is unchanged
rtk flutter test test/features/action_plans/manager/
```

---

## Proposed Changes

| Status | File | Reason |
|---|---|---|
| `[NEW]` | `lib/features/action_plans/domain/action_plan.dart` | Pure Dart entity. Owns guards + transition methods. Returns new `ActionPlan` instance. |
| `[MOD]` | `lib/features/action_plans/manager/action_plan_manager.dart` | Delete the 3 `_assert*` guard methods (L272–296). They move to the entity. |
| `[MOD]` | `lib/features/action_plans/manager/action_plan_manager_transitions.dart` | Replace `manager._assertXxx()` calls with `ActionPlan(plan).assertXxx(role)` calls. |
| `[NEW]` | `test/features/action_plans/domain/action_plan_entity_test.dart` | Pure unit tests for the entity (TC-11-01 to TC-11-10). No mocks needed. |

---

## Concept Diagram

```
BEFORE:
[ActionPlanManager] ──owns──▶ [_assertRole()]
                           ──owns──▶ [_assertStatus()]
                           ──owns──▶ [_assertNotTerminal()]
                           ──owns──▶ Drift I/O
                           ──owns──▶ API I/O

AFTER:
[ActionPlan entity]  ──owns──▶ [assertRole(role)]     ← pure Dart, no I/O
                           ──owns──▶ [assertStatus()]
                           ──owns──▶ [assertNotTerminal()]
                           ──owns──▶ [submitEvidence(...) → ActionPlan]
                           ──owns──▶ [closePlan(...) → ActionPlan]
                           ──owns──▶ [rejectEvidence() → ActionPlan]

[ActionPlanManager]  ──creates──▶ [ActionPlan(dto)]
                          ──calls──▶  [entity.submitEvidence(role, ...)]
                          ──reads──▶  [entity.dto] for optimistic patch
                          ──owns──▶   Drift I/O + API I/O (no change)
```

---

## Execution Slices

> [!NOTE]
> **Complexity: Low**
> Reason: Pure structural extraction. No new algorithms. No new schemas. One new pure Dart class + one test file. The public interface of `ActionPlanManager` is 100% unchanged.

> Single execution phase — no horizontal split needed (backend is not touched).

### Execution Phase: Domain Entity Extraction

**Plain English Summary:** Create a pure Dart `ActionPlan` class that wraps an `ActionPlanDto`. Move the 3 guard methods and the transition mutation logic into it. Update the transitions part file to call the entity instead of the manager's private methods. Delete the guard methods from the manager.

**Value Delivered:** The domain rules (role matrix, state machine) are now unit-testable in <1ms with zero mocks.

**Entry State Required:** `ActionPlanManager` is the God Object. All guards and transitions live inside it.

**Exit State Guaranteed:**
- `ActionPlan` entity exists at `lib/features/action_plans/domain/action_plan.dart`
- `ActionPlanManager` has no `_assertRole`, `_assertStatus`, or `_assertNotTerminal` methods
- All 8 existing `TC-10-*` tests in `action_plan_manager_transitions_test.dart` still pass
- New `TC-11-01` through `TC-11-10` tests pass

**Scope (files touched):** 2 modified, 2 new files. Estimated ≤ 150 lines total delta.

**Step-by-step (TDD order):**
1. Write `test/features/action_plans/domain/action_plan_entity_test.dart` — all 10 tests fail (RED)
2. Create `lib/features/action_plans/domain/action_plan.dart` with the entity
3. Run entity tests → all GREEN
4. Update `action_plan_manager_transitions.dart` to call entity methods
5. Delete `_assertRole`, `_assertStatus`, `_assertNotTerminal` from `action_plan_manager.dart`
6. Run `rtk flutter test test/features/action_plans/manager/` → full regression GREEN

**Acceptance Criteria:**
- `flutter test test/features/action_plans/domain/action_plan_entity_test.dart` → all pass
- `flutter test test/features/action_plans/manager/action_plan_manager_transitions_test.dart` → all pass (no file changes to test)
- `action_plan_manager.dart` contains no `_assertRole`, `_assertStatus`, `_assertNotTerminal` methods

---

<command_logs>
- `view_file`: adr_20260509_action_plan_manager.md (42 lines)
- `list_dir`: lib/features/action_plans → found GEMINI.md + 7 subdirs
- `view_file`: GEMINI.md (30 lines)
- `view_file`: action_plan_manager.dart (298 lines)
- `view_file`: action_plan_manager_transitions.dart (130 lines)
- `view_file`: action_plan_dto.dart (75 lines)
- `grep_search`: ActionPlanManager usages in lib → 6 consumer files + locator
- `grep_search`: action_plan in test/ → found transitions_test.dart (264 lines, 8 tests TC-10-01 to TC-10-08)
- `list_dir`: manager/ → 3 files confirmed
</command_logs>

---

## Handoff Block

> **Summary for next agent:** This is a pure Flutter-only structural refactor. Extract the 3 guard methods and state-machine mutations from `ActionPlanManager` into a new `ActionPlan` domain entity. The entity is pure Dart — no I/O, no async, no DB dependencies. The manager's public API is completely unchanged. Start with TDD on the entity, then wire the manager to use it.

**Strict Implementation Constraints:**
- `ActionPlan` must be a pure Dart class — zero Flutter/Drift/API imports allowed
- Do NOT modify any existing test files
- Do NOT change the public signatures of `submitEvidence`, `closePlan`, or `rejectEvidence` on `ActionPlanManager`
- The entity transitions must use `area_manager` in the allowed roles for `closePlan` and `rejectEvidence` (already in transitions.dart L104, L121)
- Check `GEMINI.md` gotcha: `Navigator.pop()` + `PopScope` — not relevant here but keep for context

**Route:**
> @[/tdd] Execute tests for Execution Phase: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\deepen-arch\implementation_plan_20260509_074800_2856ffa6_action-plan-manager.md`

**Concurrency:** Single phase. No dependencies. Can run immediately.
