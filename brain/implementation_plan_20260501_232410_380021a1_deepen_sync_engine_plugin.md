<latent_space_scratchpad>
CRITICAL DEPENDENCY: This ADR explicitly requires _processQueue to already exist ("Extract the previously designed _processQueue backoff algorithm into a BaseSyncModule"). That means this plan DEPENDS ON the backoff extraction plan being implemented first. The Scout must flag this as a pre-condition.

BLAST RADIUS ANALYSIS:
- sync_engine.dart: HEAVY MOD — constructor collapses from 10 params to 3, all drain calls replaced by module loop
- sync_engine_drains.dart: DELETE — entire file disappears; drain logic moves to feature modules
- sync_api.dart: DELETE — the monolithic SyncApi interface breaks into module-specific API interfaces
- service_adapters.dart: Partial MOD — SyncApiAdapter may be partially deleted or redistributed
- locator.dart: MOD — SyncEngine registration changes; 3 new module registrations added
- 8 test files: ALL need constructor migration from 10-param to modules:[] pattern

NEW FILES:
- lib/_shared/services/sync_module.dart (abstract SyncModule + BaseSyncModule)
- lib/features/audit/services/core_audit_sync_module.dart
- lib/features/action_plans/services/action_plan_sync_module.dart  
- lib/features/programs/services/program_sync_module.dart

RISK: The SyncApi interface problem. Currently SyncApi has 7 methods covering ALL domains. If we split it, each module needs its own API interface. But service_adapters.dart has SyncApiAdapter that implements ALL 7 methods. This creates a split problem — we need to decide if we split the SyncApi interface or keep it monolithic and pass a scoped view to each module.

SIMPLER ALTERNATIVE: Keep SyncApi as-is and pass a reference to the relevant methods via closures to BaseSyncModule. This avoids splitting the adapter.

SCOPE RISK: sync_engine_drains.dart contains the SyncEngine.buildAnswerPayload static method which is used by the drains. This must move to wherever CoreAuditSyncModule lives.

TEST MIGRATION STRATEGY: Each test file will need to be updated to use the new constructor. The safest approach is to create a helper `_makeSyncEngine({modules: []})` in each test OR create a shared test helper. The "No Mirroring" rule (never copy-paste production functions to test) means we must design the modules to be independently testable.

SLICING DECISION: This is too big for a single slice. Must split:
- Slice A: New interface + BaseSyncModule + CoreAuditSyncModule (touches sync_api.dart, sync_engine.dart, sync_engine_drains.dart)
- Slice B: ActionPlanSyncModule + ProgramSyncModule 
- Slice C: locator.dart + test migration (all 8 test files)

These are 3 slices. This is an EPIC-level task. Scout should flag this.
</latent_space_scratchpad>

# Implementation Plan: Deepen SyncEngine — Pluggable `SyncModule` System
**Date**: 2026-05-01 | **Conversation**: 380021a1 | **Status**: Ready for Builder

## Input Lineage
- **Source ADR**: `C:\Users\HP\.gemini\antigravity\brain\5badbf76-fcd9-4eb7-8566-2f6faa9d4396\adr_20260501_232000_5badbf76_deepen_sync_engine_plugin.md.resolved`
- **Pre-condition ADR**: `C:\Users\HP\.gemini\antigravity\brain\5badbf76-fcd9-4eb7-8566-2f6faa9d4396\adr_20260501_231600_5badbf76_deepen_sync_engine_backoff.md.resolved`
- **Pre-condition Plan**: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_231745_380021a1_deepen_sync_engine_backoff.md`

> [!CAUTION]
> **HARD DEPENDENCY**: This plan CANNOT be started until the `_processQueue<T>` backoff helper from the previous plan has been implemented and all 5 tests pass green. The ADR explicitly states the plugin system is built ON TOP of `_processQueue`.

---

## Executive Summary & Out of Scope

**Goal**: Refactor `SyncEngine` from a monolithic orchestrator with 10+ constructor parameters into a pure orchestrator that accepts a `List<SyncModule>`. Domain-specific drain logic moves out of `sync_engine_drains.dart` into three feature-owned `SyncModule` implementations: `CoreAuditSyncModule`, `ActionPlanSyncModule`, `ProgramSyncModule`.

**Result for developers**: Adding a new sync-able feature means creating one class implementing `SyncModule` — no core engine changes required.

**Out of Scope (YAGNI):**
- ❌ No new Drift tables or DB migrations.
- ❌ No changes to server API contracts or backend.
- ❌ No changes to UI widgets, routes, or page-level code.
- ❌ No split of `SyncApi` interface — the monolithic `SyncApi` and `SyncApiAdapter` in `service_adapters.dart` remain as-is. Each module receives the specific API methods it needs via constructor injection.
- ❌ `_pullDeltas` and `_pullGlobalRisks` are part of `CoreAuditSyncModule.executePull()` — not a separate module.
- ❌ `SyncMetaDao` stays in `CoreAuditSyncModule` (it manages the global sync timestamp, which is core audit infrastructure).
- ❌ Do NOT extract `SyncEngine.buildAnswerPayload` — move it to `CoreAuditSyncModule` as a static method.

---

## 🚨 Strict Implementation Constraints & Human Reminders

1. **Pre-condition gate**: Run all 5 tests from the backoff plan FIRST. If any fail, STOP.
2. **`sync_engine_drains.dart` deletion**: This file is a `part of 'sync_engine.dart'`. When deleted, the `part` directive in `sync_engine.dart` must also be removed. If forgotten, the compiler will error.
3. **Test migration is MANDATORY**: All 8 test files that call `SyncEngine(...)` MUST be updated. Do not leave broken tests.
4. **Constructor compatibility**: The deprecated `Outbox? outbox` parameter (currently in the old constructor) must be removed. It was already a no-op.
5. **`priority` field**: Modules run in ascending order. Core Audits = 10, Action Plans = 20, Programs = 30. The orchestrator sorts by priority before executing.
6. **GEMINI.md Gotcha preserved**: The batch-abort (`break`) and retry-await rules in `GEMINI.md` must survive in the module implementations via `BaseSyncModule._processQueue`.

---

## Logs & Audits

No new logging is required. The `SyncState` transitions (`syncing → idle → error → offline`) remain entirely in `SyncEngine`'s orchestration loop. The modules have no direct access to `_state` — they communicate errors by throwing exceptions that the orchestrator catches.

---

## 4-State Matrix

| State | Trigger | Outcome |
|---|---|---|
| **Success** | All modules' `executePull()` and `executePush()` complete without exception | `SyncState.idle` |
| **Error (Network)** | Any module throws a non-fatal exception | `SyncState.error`, `_scheduleRetry` called |
| **Offline** | `!_connectivity.isOnline` check between module executions | `SyncState.offline`, `return` immediately |
| **Loading** | `_requestSyncInternal()` runs | `SyncState.syncing` |

---

## Test Contracts

| ID | Test Name | Scenario | Expected | Why it fails first |
|---|---|---|---|---|
| **TC-PLUGIN-1** | `SyncEngine_EmptyModuleList_CompletesWithoutError` | `modules: []`, `requestSync()` called | `engine.state == SyncState.idle` | New constructor is not yet built |
| **TC-PLUGIN-2** | `SyncEngine_PullPhase_ExecutesAllModulesInPriorityOrder` | 3 stub modules with priorities 30, 10, 20 | `executePull()` called in order: 10, 20, 30 | Priority sort not yet implemented |
| **TC-PLUGIN-3** | `SyncEngine_PushPhase_ModuleThrows_SetsErrorState` | Module `executePush()` throws | `engine.state == SyncState.error` | Error propagation not yet wired |
| **TC-PLUGIN-4** | `SyncEngine_OfflineCheck_BetweenModules_AbortsLoop` | Connectivity goes offline between module 1 and 2 | `engine.state == SyncState.offline`, module 2 NOT called | Connectivity check not between modules |
| **TC-COMPAT-1** | All 8 existing test files compile and pass | Constructor migrated | Zero compile errors, all tests GREEN | Constructor signature changed |

> **CRITICAL**: TC-COMPAT-1 is the regression gate. All 8 test files must be updated BEFORE marking this plan done.

---

## Test Fixture & Payloads

**New stub module for unit tests:**
```dart
class _StubSyncModule implements SyncModule {
  final int _priority;
  final List<String> log;
  _StubSyncModule(this._priority, this.log);

  @override int get priority => _priority;
  @override Future<void> executePull() async => log.add('pull-$_priority');
  @override Future<void> executePush() async => log.add('push-$_priority');
}
```

**8 test files that need constructor migration:**
1. `test/sync_engine_test.dart`
2. `test/sync_engine_payload_test.dart`
3. `test/_shared/services/sync_engine_push_test.dart`
4. `test/_shared/services/sync_engine_hardening_test.dart`
5. `test/shared/services/sync_engine_backoff_test.dart`
6. `test/features/global_risks/sync_engine_global_risks_test.dart`
7. `test/features/action_plans/sync_engine_action_plan_stale_state_test.dart`
8. `test/features/audit/audit_manager_online_path_test.dart` *(indirect — uses mocked SyncEngine)*

For tests that test domain-specific drain behavior (AC4/AC5/AC6 backoff, global risks, action plan stale state), those tests must be MIGRATED to test the **SyncModule** directly, not the SyncEngine. Each module is independently testable via `module.executePush()`.

---

## Tools & Commands

**Skills needed by Builder:**
- `flutter-architecture` — confirms extension → module migration pattern
- `tdd` — enforces red-green-refactor cycle
- `flutter-get-it-service` — for locator.dart DI pattern

**Verification commands:**
```bash
# Gate: pre-condition must pass first
rtk flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded

# New plugin unit tests (after Slice A)
rtk flutter test test/_shared/services/sync_engine_plugin_test.dart --reporter=expanded

# Full regression (after all slices)
rtk flutter test --reporter=expanded
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Pre-condition not met (`_processQueue` not implemented) | Medium | Critical | Hard gate: run backoff tests FIRST. Do NOT start this plan if they fail. |
| `part of` directive left dangling after `sync_engine_drains.dart` deletion | High | High | Checklist item: remove `part 'sync_engine_drains.dart'` from `sync_engine.dart` |
| 8 test files break on constructor change | Certain | High | Slice C is dedicated entirely to test migration. Do not skip. |
| Module `priority` collision | Low | Low | Use constants: `CoreAudit = 10, ActionPlan = 20, Program = 30`. Document in `SyncModule` abstract class. |
| `buildAnswerPayload` static method orphaned | Medium | Medium | Move to `CoreAuditSyncModule` as `static`. Update any usages in tests. |
| `SyncApi` interface becomes stale | Low | Low | `SyncApi` stays monolithic. Each module receives only the methods it needs via constructor. |

---

## Verification Plan

**Gate 1 — Pre-condition (before ANY work):**
```bash
rtk flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded
```
> AC4/AC5/AC6 must ALL pass. If not — STOP.

**Gate 2 — After Slice A (core infrastructure):**
```bash
rtk flutter test test/_shared/services/sync_engine_plugin_test.dart --reporter=expanded
rtk flutter analyze lib/_shared/services/
```

**Gate 3 — After Slice B (feature modules):**
```bash
rtk flutter test test/features/ --reporter=expanded
rtk flutter analyze lib/features/
```

**Gate 4 — After Slice C (test migration + locator):**
```bash
rtk flutter test --reporter=expanded
rtk flutter analyze lib/
```

---

## Proposed Changes

| Action | File | Description |
|---|---|---|
| `[NEW]` | `lib/_shared/services/sync_module.dart` | Abstract `SyncModule` interface + `BaseSyncModule` with `_processQueue<T>` |
| `[MOD]` | `lib/_shared/services/sync_engine.dart` | Collapse constructor to 3 params. Replace drain calls with module loop. Remove `part` directive. |
| `[DEL]` | `lib/_shared/services/sync_engine_drains.dart` | Entire file deleted. Logic migrated to feature modules. |
| `[DEL]` | `lib/_shared/services/sync_api.dart` | Monolithic interface deleted. Each module gets its own scoped interface OR uses Dio directly. |
| `[NEW]` | `lib/features/audit/services/core_audit_sync_module.dart` | Handles `_pullDeltas`, `_pullGlobalRisks`, `_drainSubmissions`, `_drainRisks`. Contains `buildAnswerPayload`. Priority = 10. |
| `[NEW]` | `lib/features/action_plans/services/action_plan_sync_module.dart` | Handles `_drainActionPlans`. Priority = 20. |
| `[NEW]` | `lib/features/programs/services/program_sync_module.dart` | Handles `_pullProgramAssignments`, `_drainProgramEvidence`, `_drainProgramPhotos`. Priority = 30. |
| `[MOD]` | `lib/locator.dart` | Register 3 SyncModules. Simplify SyncEngine registration to `{connectivity, auth, modules}`. |
| `[MOD]` | `test/sync_engine_test.dart` | Migrate constructor to modules pattern |
| `[MOD]` | `test/sync_engine_payload_test.dart` | Migrate constructor + move to CoreAuditSyncModule test |
| `[MOD]` | `test/_shared/services/sync_engine_push_test.dart` | Migrate to module-based test |
| `[MOD]` | `test/_shared/services/sync_engine_hardening_test.dart` | Migrate to module-based test |
| `[MOD]` | `test/shared/services/sync_engine_backoff_test.dart` | Migrate — backoff tests move to `core_audit_sync_module_test.dart` |
| `[MOD]` | `test/features/global_risks/sync_engine_global_risks_test.dart` | Migrate to `core_audit_sync_module_test.dart` |
| `[MOD]` | `test/features/action_plans/sync_engine_action_plan_stale_state_test.dart` | Migrate to `action_plan_sync_module_test.dart` |
| `[MOD]` | `test/features/audit/audit_manager_online_path_test.dart` | Migrate mock SyncEngine to new interface |

---

## Concept Diagram

```
BEFORE:
[SyncEngine] ←── 10 constructor params (api, outboxDao, actionPlanApi, actionPlanOutboxDao,
                  globalRiskDao, submissionRiskOutboxDao, syncMetaDao, programOutboxDao, ...)
    ↓
[_requestSyncInternal]
    ├── _pullDeltas()
    ├── _drainSubmissions()
    ├── _drainActionPlans()
    ├── _drainRisks()
    ├── _pullProgramAssignments()
    ├── _drainProgramEvidence()
    └── _drainProgramPhotos()
         (all hardcoded in sync_engine_drains.dart)

AFTER:
[SyncEngine] ←── 3 constructor params (connectivity, auth, modules: List<SyncModule>)
    ↓
[_requestSyncInternal]
    └── for module in modules.sortedByPriority:
            await module.executePull()   ← check connectivity between each
            await module.executePush()   ← check connectivity between each

[CoreAuditSyncModule] (priority=10)   ← lib/features/audit/services/
    ├── executePull() → _pullDeltas, _pullGlobalRisks
    └── executePush() → _drainSubmissions, _drainRisks (via BaseSyncModule._processQueue)

[ActionPlanSyncModule] (priority=20)  ← lib/features/action_plans/services/
    └── executePush() → _drainActionPlans

[ProgramSyncModule] (priority=30)     ← lib/features/programs/services/
    ├── executePull() → _pullProgramAssignments
    └── executePush() → _drainProgramEvidence, _drainProgramPhotos (via BaseSyncModule._processQueue)

[BaseSyncModule]                       ← lib/_shared/services/sync_module.dart
    └── _processQueue<T>()             ← shared backoff algorithm
```

---

## Execution Slices

> **Total Complexity: HIGH** — This is a full architectural migration touching 16+ files across 3 layers (core infra, features, tests).

### Slice A — Core Infrastructure (New Interface + Engine Refactor)
**Complexity**: High | **Blast Radius**: `sync_engine.dart`, `sync_engine_drains.dart`, `sync_module.dart`

1. Write `sync_engine_plugin_test.dart` with TC-PLUGIN-1 through TC-PLUGIN-4 → Run → All FAIL (RED).
2. Create `lib/_shared/services/sync_module.dart`:
   - Abstract `SyncModule { int priority; executePull(); executePush(); }`
   - Abstract `BaseSyncModule extends SyncModule` with the `_processQueue<T>` body copied from the previous plan.
3. Refactor `sync_engine.dart`:
   - Remove all 8 DAO/API constructor params.
   - Add `List<SyncModule> modules`.
   - Replace the hardcoded drain chain in `_requestSyncInternal` with a `for` loop sorted by priority.
   - Remove the `part 'sync_engine_drains.dart'` directive.
4. Delete `sync_engine_drains.dart`.
5. Run Slice A tests → All PASS (GREEN).

**PRO/CON for `BaseSyncModule` location:**
- **Option A**: `BaseSyncModule` in `lib/_shared/services/sync_module.dart` — Clean, all modules import from one place.
- **Option B**: `BaseSyncModule` is just `SyncModule` with a default `_processQueue` implementation. Modules that don't need backoff can still implement `SyncModule` directly.
> **Scout Recommendation**: Use Option A. Keep `BaseSyncModule` abstract with the `_processQueue` helper. Modules that don't need it (like `ActionPlanSyncModule`) just don't call it.

---

### Slice B — Feature Module Implementations
**Complexity**: Medium | **Blast Radius**: 3 new files in features/, `service_adapters.dart` (read-only reference)

1. Create `CoreAuditSyncModule`: Move `_pullDeltas`, `_pullGlobalRisks`, `_drainSubmissions`, `_drainRisks`, and `buildAnswerPayload` from `sync_engine_drains.dart` into it. Inject `SyncApi`, `OutboxDao`, `GlobalRiskDao`, `SubmissionRiskOutboxDao`, `SyncMetaDao` via constructor.
2. Create `ActionPlanSyncModule`: Move `_drainActionPlans`. Inject `ActionPlanApi`, `ActionPlanOutboxDao` via constructor.
3. Create `ProgramSyncModule`: Move `_pullProgramAssignments`, `_drainProgramEvidence`, `_drainProgramPhotos`. Inject `SyncApi`, `ProgramOutboxDao`, `SyncMetaDao` via constructor.
4. Each module: write module-specific unit tests (red first, then green).
5. Run feature tests → all PASS.

---

### Slice C — DI Wiring + Test Migration
**Complexity**: Medium | **Blast Radius**: `locator.dart`, 8 test files

1. Update `locator.dart`: Register `CoreAuditSyncModule`, `ActionPlanSyncModule`, `ProgramSyncModule`. Update `SyncEngine` registration to `SyncEngine(connectivity: ..., auth: ..., modules: [...])`.
2. Migrate all 8 test files to the new constructor. For tests that tested domain drain behavior, redirect them to test the module directly.
3. Run full test suite → zero failures.
4. Run `flutter analyze lib/` → zero warnings.

> **CRITICAL**: Slices A → B → C are STRICTLY sequential. Do NOT start B before A passes. Do NOT start C before B passes.

---

<command_logs>
- `view_file` → `adr_20260501_232000_5badbf76_deepen_sync_engine_plugin.md.resolved`
- `view_file` → `locator.dart` (252 lines, full read)
- `grep_search` → `SyncEngine` in `lib/` (usage map: 30+ hits)
- `grep_search` → `SyncEngine(` in `test/` (8 test files confirmed)
- `view_file` → `sync_api.dart` (35 lines, full read)
- `list_dir` → `lib/features/` (12 feature directories)
</command_logs>

---

## Handoff Block

**For the next AI agent (Builder/Forge):**
- This plan has a **hard pre-condition**: `_processQueue<T>` must exist in `sync_engine_drains.dart` (or be ready to move to `BaseSyncModule`) before any work starts.
- The `SyncApi` interface stays **monolithic** — it is not split. Modules that need API calls receive the whole `SyncApi` object via constructor.
- `sync_engine_drains.dart` is deleted entirely. The `part 'sync_engine_drains.dart'` line in `sync_engine.dart` must be removed simultaneously.
- There are **8 test files** that must be migrated. This is Slice C and it must be done.
- The `buildAnswerPayload` static method moves to `CoreAuditSyncModule`.

**Routing — execute ONE AT A TIME, in order:**

**Pre-condition check (BEFORE any slice):**
> `@[/verify]` Verify backoff plan is complete: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_231745_380021a1_deepen_sync_engine_backoff.md`

**Slice A — Core Infrastructure:**
> @[/tdd] Execute tests for SyncEngine Plugin Core (Slice A): `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_232410_380021a1_deepen_sync_engine_plugin.md`

**Slice B — Feature Modules (after Slice A green):**
> @[/implement] Execute build for Feature SyncModules (Slice B): `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_232410_380021a1_deepen_sync_engine_plugin.md`

**Slice C — DI + Test Migration (after Slice B green):**
> @[/implement] Execute build for DI Wiring and Test Migration (Slice C): `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_232410_380021a1_deepen_sync_engine_plugin.md`

**Concurrency**: ALL slices are sequential. A → B → C. No parallelism.
