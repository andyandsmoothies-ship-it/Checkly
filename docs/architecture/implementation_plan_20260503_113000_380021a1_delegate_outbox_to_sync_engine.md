<latent_space_scratchpad>
CRITICAL INSIGHT: The methods in OutboxDao already exist and work perfectly. We are NOT moving logic.
We are adding thin proxy methods on SyncEngine that delegate to _outboxDao (which SyncEngine already owns
indirectly via CoreAuditSyncModule). Wait — SyncEngine does NOT hold OutboxDao. It only holds a list of modules.
So we have two options:
Option A: Inject OutboxDao into SyncEngine constructor directly (simple, direct)
Option B: Have SyncEngine ask CoreAuditSyncModule for the stream (module exposes it)

Option A is simpler and correct. SyncEngine already knows about outbox management conceptually (its rules
mention "UX Red Badge"). Adding OutboxDao as a constructor param for this purpose is clean — it's a monitoring
concern, not a sync drain concern. The module system handles the PUSH logic; SyncEngine can hold the DAO
for MONITORING only.

For sign_out_tile: syncableCount() and exhaustedCount() are one-time Future calls, not streams.
These should also delegate via SyncEngine.

IMPORTANT: sign_out_tile.dart comment on line 11 says 
"Outbox status is fetched via SyncEngine to avoid UI coupling to DAOs." — this is the INTENT already
written in the code, but not yet implemented. The current code is wrong per its own comment!

No test files for sign_out_tile or main_shell exist. We need to add unit tests for the new SyncEngine methods.
These are simple delegations — no complex logic. Route 1 (TDD) is correct.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\consolidated_refactoring_plan.md`
- **Slice**: Phase 1, Steps 1 & 2 (CS-2 + CF-2)

## Executive Summary & Out of Scope

**What we are doing:**
1. **Step 1 (CS-2)**: Add 5 proxy methods to `SyncEngine` that delegate to `OutboxDao`: `watchExhaustedCount()`, `discardExhausted()`, `requeueExhausted()`, `syncableCount()`, `exhaustedCount()`. Inject `OutboxDao` into `SyncEngine`'s constructor. Update `locator.dart` to pass the `OutboxDao` into `SyncEngine`.
2. **Step 2 (CF-2 + main_shell)**: Update `main_shell.dart` and `sign_out_tile.dart` to call these new `SyncEngine` methods instead of `OutboxDao` directly. Remove the `OutboxDao` import from both files.

**Why:** `main_shell.dart` and `sign_out_tile.dart` are UI-layer widgets reaching directly into a data-layer DAO. This violates the architecture boundary. Notably, `sign_out_tile.dart`'s own doc comment already states *"Outbox status is fetched via SyncEngine to avoid UI coupling to DAOs"* — but the actual code contradicts this! This plan fixes that.

**Out of Scope:**
- ❌ Step 3 (CF-1 — `dashboard_manager` + `action_required_widget`) — separate slice
- ❌ Phases 2–4 of the consolidated plan (hygiene, SRP, test coverage)
- ❌ Any changes to `OutboxDao` logic — the methods are not touched, only proxied
- ❌ No new Drift tables or DB migrations
- ❌ No server/backend changes

---

## Logs & Audits

No new logging needed. This is a pure boundary enforcement refactor. Behavior is identical.

---

## 4-State Matrix

This is a pure refactor. All UI states are identical before and after.

| State | Before | After |
|---|---|---|
| **Exhausted badge visible** | `OutboxDao.watchExhaustedCount()` > 0 | `SyncEngine.watchExhaustedCount()` > 0 (same DB query) |
| **Badge hidden** | count == 0 | count == 0 (same) |
| **Sign-out blocked (syncable)** | `OutboxDao.syncableCount()` > 0 | `SyncEngine.syncableCount()` > 0 (same DB query) |
| **Sign-out blocked (exhausted)** | `OutboxDao.exhaustedCount()` > 0 | `SyncEngine.exhaustedCount()` > 0 (same) |

---

## Test Contracts

| ID | Test Description | Why it fails first |
|----|------------------|--------------------|
| TC-01 | `SyncEngine.watchExhaustedCount()` emits 0 when outbox is empty | Method does not exist yet |
| TC-02 | `SyncEngine.watchExhaustedCount()` emits 2 when 2 exhausted rows exist | Method does not exist yet |
| TC-03 | `SyncEngine.discardExhausted()` removes all exhausted rows from DB | Method does not exist yet |
| TC-04 | `SyncEngine.requeueExhausted()` resets exhausted rows to `pending` | Method does not exist yet |
| TC-05 | `SyncEngine.syncableCount()` returns 0 for empty outbox | Method does not exist yet |
| TC-06 | `SyncEngine.syncableCount()` returns 1 when 1 pending submission exists | Method does not exist yet |
| TC-07 | `SyncEngine.exhaustedCount()` returns 0 for empty outbox | Method does not exist yet |
| TC-08 | `SyncEngine.exhaustedCount()` returns 1 when 1 exhausted submission exists | Method does not exist yet |

> **CRITICAL:** These are delegation tests — they prove the proxy forwards to the real DAO correctly. Use an in-memory `AppDatabase.forTesting(NativeDatabase.memory())` instance, seed rows, call the engine method, and assert the DB state.

---

## Test Fixture & Payloads

No network mocks needed. All tests use:
- `AppDatabase.forTesting(NativeDatabase.memory())` — in-memory SQLite
- `OutboxDao(db)` — the real DAO
- A real `SyncEngine` constructed with the `OutboxDao`
- Stub `ConnectivityService` (always online) and `AuthCheck` (always logged in) — already exist in the test suite as `AlwaysOnlineConnectivity` and `AlwaysAuthCheck`

**Seed helper needed:**
```dart
Future<void> seedExhaustedSubmission(OutboxDao dao, {String id = 'sub-1'}) async {
  await dao.insertSubmission(PendingSubmissionsCompanion(
    id: Value(id),
    syncStatus: Value('exhausted'),
    // ... other required fields with dummy values
  ));
}
```

---

## Tools & Commands

- **Skills needed**: `tdd`, `flutter-architecture`
- **Verify commands:**
```bash
# New delegation tests
rtk flutter test test/_shared/services/sync_engine_outbox_delegation_test.dart --reporter=expanded

# Full regression
rtk flutter test --reporter=expanded
```

---

## Proposed Changes

| Action | File | Description |
|--------|------|-------------|
| `[MOD]` | `lib/_shared/services/sync_engine.dart` | Add `OutboxDao` field + 5 proxy methods |
| `[MOD]` | `lib/locator.dart` | Pass `OutboxDao` to `SyncEngine(outboxDao: ...)` |
| `[MOD]` | `lib/_shared/router/main_shell.dart` | Replace 3 `OutboxDao` calls with `SyncEngine` calls. Remove `OutboxDao` import. |
| `[MOD]` | `lib/features/profile/widgets/sign_out_tile.dart` | Replace 2 `OutboxDao` calls with `SyncEngine` calls. Remove `OutboxDao` import. |
| `[NEW]` | `test/_shared/services/sync_engine_outbox_delegation_test.dart` | 8 unit tests for the new proxy methods |

---

## Concept Diagram

```
BEFORE (broken boundary):
[main_shell.dart] ──────────────────────┐
[sign_out_tile.dart] ──────────────────►[OutboxDao] → SQLite
                                         ↑
                          (UI layer calling DB layer directly — WRONG)

AFTER (correct boundary):
[main_shell.dart] ──────────────────────┐
[sign_out_tile.dart] ──────────────────►[SyncEngine] ──►[OutboxDao] → SQLite
                                         (proxy methods — delegates, no logic)
```

---

## Execution Phase

**Complexity:** Low — 5 one-line proxy methods, 4 import removals, 1 new test file.  
**Risk:** Very Low — zero logic change, identical behavior.

### Step 1 — Write new delegation tests (TDD RED)

Create `test/_shared/services/sync_engine_outbox_delegation_test.dart`.  
Construct `SyncEngine` with the new `outboxDao:` parameter.  
Run tests → All 8 FAIL because `SyncEngine` doesn't have the methods yet.

### Step 2 — Add proxy methods to `SyncEngine` (TDD GREEN)

In `sync_engine.dart`, add `final OutboxDao _outboxDao` field and add to constructor. Then add 5 methods:

```dart
Stream<int> watchExhaustedCount() => _outboxDao.watchExhaustedCount();
Future<void> discardExhausted() => _outboxDao.discardExhausted();
Future<void> requeueExhausted() => _outboxDao.requeueExhausted();
Future<int> syncableCount() => _outboxDao.syncableCount();
Future<int> exhaustedCount() => _outboxDao.exhaustedCount();
```

Update `locator.dart` to pass `outboxDao: di<OutboxDao>()` to the `SyncEngine` constructor.

Run tests → All 8 PASS.

### Step 3 — Update call sites (REFACTOR)

- `main_shell.dart`: Replace `_di<OutboxDao>().watchExhaustedCount()` → `_di<SyncEngine>().watchExhaustedCount()`. Same for `discardExhausted()` and `requeueExhausted()`. Remove `outbox_dao.dart` import.
- `sign_out_tile.dart`: Replace `_di<OutboxDao>().syncableCount()` → `_di<SyncEngine>().syncableCount()`. Same for `exhaustedCount()`. Remove `outbox_dao.dart` import. Remove the unused `AuthManager` import if it was only added for the DAO calls.

Run full test suite → zero regressions.

> **Builder Note:** Read each file before editing. The `main_shell.dart` has `_di<SyncEngine>().requestSync()` already on line 132 — confirm the import is there and just extend it. Do NOT add a second `SyncEngine` import.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Forgetting `outboxDao:` in `locator.dart` | Medium | High — compile error | Build gate catches it immediately. Cannot ship. |
| Duplicate `SyncEngine` import in `main_shell.dart` | Low | Low — analyzer warning | Builder must read the file first and confirm the existing import. |
| `AuthManager` import accidentally removed from `sign_out_tile.dart` | Low | High — logout broken | Builder must only remove `outbox_dao.dart` import, nothing else. |

---

## Verification Plan

**Gate 1 — TDD RED (before implementing):**
```bash
rtk flutter test test/_shared/services/sync_engine_outbox_delegation_test.dart --reporter=expanded
```
> Expected: All 8 tests FAIL. If they pass, the tests are wrong.

**Gate 2 — TDD GREEN (after adding proxy methods):**
```bash
rtk flutter test test/_shared/services/sync_engine_outbox_delegation_test.dart --reporter=expanded
```
> Expected: All 8 tests PASS.

**Gate 3 — Build check (after call site updates):**
```bash
rtk flutter analyze lib/
```
> Expected: Zero errors. If `outbox_dao.dart` is still imported, the analyzer will show an unused import warning.

**Gate 4 — Full regression:**
```bash
rtk flutter test --reporter=expanded
```
> Expected: All tests pass. Zero regressions.

---

<command_logs>
- view_file: consolidated_refactoring_plan.md — 55 lines
- grep_search: OutboxDao in lib/ — found call sites
- view_file: main_shell.dart — 300 lines, 3 OutboxDao calls confirmed
- view_file: sign_out_tile.dart — 134 lines, 2 OutboxDao calls confirmed
- view_file: outbox_dao.dart — 292 lines, all 5 target methods confirmed
- view_file: sync_engine.dart — 133 lines, confirmed NO exhausted methods exist
- grep_search: SyncEngine in test/ — no existing test files for sign_out_tile or main_shell
</command_logs>

---

## Handoff Block

**For the Builder:** This is a safe, low-risk delegation refactor. No logic changes. The 5 proxy methods are one-liners. The main risk is forgetting to update `locator.dart` — the `SyncEngine` constructor will break at compile time if `outboxDao:` is not passed.

**Steps (one at a time):**

**Step 1 — Write tests first (TDD RED):**
```
@[/tdd] Execute tests for SyncEngine Outbox Delegation: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_113000_380021a1_delegate_outbox_to_sync_engine.md
```

**Step 2 — Implement proxy methods + update call sites (GREEN + REFACTOR):**
```
@[/implement] Execute build for Delegate Outbox Boundary: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_113000_380021a1_delegate_outbox_to_sync_engine.md
```

**Concurrency:** Step 2 must wait for Step 1. Sequential.
