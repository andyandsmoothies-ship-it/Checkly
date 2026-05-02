<latent_space_scratchpad>
KEY RISK: _drainSubmissions builds a large payload and has 2 DIFFERENT fatal-error checks (400=BadRequest, 403=Forbidden) before the retry math kicks in. The _processQueue signature must support a multi-condition `isFatalError` closure, NOT just a single boolean check. The ADR's proposed interface uses `bool Function(dynamic error) isFatalError` — that is correct and handles this.

KEY RISK 2: _drainRisks has a 409-Conflict handler that is OPPOSITE to fatal — it's actually a SUCCESS path ("already on server, drain it"). The ADR's `onConflict` optional parameter handles this correctly.

KEY RISK 3: _drainSubmissions uses `continue` on fatal errors to process the NEXT record, but uses `break` on network errors. _drainRisks also uses `break` on network errors. _drainProgramEvidence uses `continue` for fatals and `break` for network. This is consistent — `_processQueue` should `break` the batch on network error and let the caller `continue` past fatals.

KEY RISK 4: The existing AC4/AC5/AC6 tests in sync_engine_backoff_test.dart test _drainSubmissions' backoff behavior via `requestSync()`. These tests must still pass AFTER the refactor without any modification. This is the golden verification gate.

SCOPE NOTE: _drainActionPlans does NOT qualify for _processQueue. Its catch block does not use _backoffDelays at all. DO NOT include it.
</latent_space_scratchpad>

# Implementation Plan: Deepen SyncEngine — Extract `_processQueue<T>` Helper
**Date**: 2026-05-01 | **Conversation**: 380021a1 | **Status**: Ready for Builder

## Input Lineage
- **Source ADR**: `C:\Users\HP\.gemini\antigravity\brain\5badbf76-fcd9-4eb7-8566-2f6faa9d4396\adr_20260501_231600_5badbf76_deepen_sync_engine_backoff.md.resolved`
- **Source File**: `c:\Users\HP\Documents\GitHub\Checkly\lib\_shared\services\sync_engine_drains.dart`

---

## Executive Summary & Out of Scope

**Goal**: The exponential backoff loop (try → catch → increment retries → schedule timer → mark exhausted) is copy-pasted across 4 drain methods. Extract it into a single private `_processQueue<T>()` helper inside the `_SyncEngineDrains` extension. The 4 drain methods become thin wrappers that call this helper with their specific closures.

**Out of Scope (YAGNI):**
- ❌ `_drainActionPlans` — its error handling has NO backoff loop. It immediately marks exhausted on any non-409 error. It does NOT qualify for `_processQueue`.
- ❌ No DAO interface changes.
- ❌ No changes to `sync_engine.dart` (the orchestrator and shared fields).
- ❌ No changes to any existing test file — they must pass unchanged.
- ❌ No new Drift tables, no new server API calls.

---

## 🚨 Strict Implementation Constraints & Human Reminders

1. **GEMINI.md Gotcha: Batch Abort Rule.** The `break` behaviour on network error in the existing drains must be preserved in `_processQueue`. Each drain method processes records sequentially and stops the batch (breaks) on a network error — but allows the sync orchestrator to continue with the NEXT drain phase. `_processQueue` must `break` its internal `for` loop on network errors (via `bool` return or equivalent).
2. **Fatal Error Path uses `continue`, not `break`.** Fatal errors (`400`, `403`) skip to the next record. Verify this is preserved per drain.
3. **`_drainRisks` 409 = Success.** The `onConflict` optional closure removes the record (treats as synced). This must NOT be a fatal path.
4. **Existing test gate.** `test/shared/services/sync_engine_backoff_test.dart` — AC4, AC5, AC6 — must ALL pass after refactor, with ZERO changes to the test file.
5. **File size gate.** `sync_engine_drains.dart` is 344 lines. After refactor, it should shrink by ~100-120 lines (the duplicated backoff loops). If it grows instead, something is wrong.

---

## Logs & Audits

No new logging is required. The backoff logic already updates `syncStatus` and `error` fields in each DAO — this is the audit trail. The refactor must preserve these writes exactly.

---

## 4-State Matrix

This is an internal service layer, not a UI component. The "states" map to `SyncState`:

| State | Trigger | Outcome |
|---|---|---|
| **Success** | `_processQueue` drains all items without error | `SyncState` stays `syncing` → becomes `idle` after all phases |
| **Error (Network)** | A non-fatal error is caught and retries are not exhausted | `_state = SyncState.error`, `break` the batch, retry scheduled via `_scheduleRetry` |
| **Error (Exhausted)** | `retryCount >= _backoffDelays.length` | DAO `markExhausted` called. `_state = SyncState.error`. Triggers UX red badge. |
| **Offline** | `!_connectivity.isOnline` check inside loop | `_state = SyncState.offline`, `return` immediately |

---

## Test Contracts

| ID | Test Name | Scenario | Expected DB State | Why it fails first |
|---|---|---|---|---|
| **AC4** | `SyncEngine_FirstFailure_SetsRetryCountOneAndNextRetryAt2s` | `retryCount=0`, API throws. | `syncStatus='pending'`, `retryCount=1`, `nextRetryAt ≈ now+2s` | `_processQueue` not yet implemented — backoff not triggered |
| **AC5** | `SyncEngine_ThirdFailure_SetsNextRetryAt60s` | `retryCount=3`, API throws. | `syncStatus='pending'`, `retryCount=4`, `nextRetryAt ≈ now+60s` | Same — correct delay index not used |
| **AC6** | `SyncEngine_FourthFailure_SetsStatusExhausted` | `retryCount=4`, API throws. | `syncStatus='exhausted'`, `engine.state=SyncState.error` | Same |
| **AC-409** | `_drainRisks_409Conflict_TreatedAsSuccess_RecordRemoved` | Risk push throws `contains('409')` | Row removed from DB (not exhausted, not retried) | 409 path inverts the error — easy to break |
| **AC-FATAL** | `_drainSubmissions_400FatalError_MarkedExhausted_NoRetry` | API throws `contains('400')`. | `syncStatus='exhausted'`, `retryCount` unchanged | Fatal path must skip retry math |

> **CRITICAL:** AC4/AC5/AC6 are the existing golden tests. The Builder MUST NOT touch them. Run `flutter test test/shared/services/sync_engine_backoff_test.dart` as the verification gate after refactor.

---

## Test Fixture & Payloads

**Existing fixture (in sync_engine_backoff_test.dart):**
- `FailingApi` — throws `Exception('Simulated network error')` on `pushSubmission`.
- `AlwaysOnlineConnectivity` — always returns `true`.
- `AlwaysAuthCheck` — always returns `true`.
- In-memory `AppDatabase.forTesting(NativeDatabase.memory())`.
- `seedEligibleSub({int retryCount})` — seeds a `PendingSubmission` with configurable `retryCount`.

**New fixture needed (for AC-409 and AC-FATAL):**
- `_409RiskApi` — `pushSubmissionRisk` throws `Exception('409 Conflict')`.
- `_FatalSubmissionApi` — `pushSubmission` throws `Exception('400 ClientFormatError')`.
- Seed: a `PendingSubmissionRisk` row in the DB.

---

## Tools & Commands

**Skills needed by Builder:**
- `flutter-architecture` — confirms extension pattern & `part of` files
- `tdd` — enforces red-green-refactor cycle

**Verification commands:**
```bash
# Mandatory gate — must PASS with zero changes to test file
rtk flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded

# Full regression pass
rtk flutter test test/_shared/ --reporter=expanded
rtk flutter test test/features/global_risks/ --reporter=expanded
rtk flutter test test/features/action_plans/ --reporter=expanded
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Regression in AC4/AC5/AC6 backoff timing | Low | High | Run `sync_engine_backoff_test.dart` as golden gate after every change. Do NOT modify that file. |
| `_drainActionPlans` accidentally included | Medium | Medium | This method has NO backoff loop. Builder must explicitly skip it. Its catch block uses `markExhausted` directly. |
| `_processQueue` break vs continue confusion | Medium | High | Fatal errors = `continue` (next record). Network errors = `break` (stop batch). 409 = `onConflict` (success path). Spell this out in code comments. |
| File size growth (not shrinkage) | Low | Low | After refactor, file must be < 280 lines. Verify with `(Get-Content sync_engine_drains.dart).Count`. |
| `_drainSubmissions` payload-build logic lost | Low | Critical | The payload-build code (lines 45-70 in original) runs BEFORE `push()`. It stays in `_drainSubmissions`; only the push/retry loop moves to `_processQueue`. |

---

## Verification Plan

**Gate 1 — Before writing `_processQueue`:**
```bash
rtk flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded
```
> Expected: AC4/AC5/AC6 all PASS. If any fail, the baseline is broken. Stop and report.

**Gate 2 — After writing new AC-409 and AC-FATAL tests (TDD RED phase):**
```bash
rtk flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded
```
> Expected: AC4/AC5/AC6 still PASS. New AC-409/AC-FATAL FAIL. This confirms the tests are testing real behaviour.

**Gate 3 — After implementing `_processQueue` (GREEN phase):**
```bash
rtk flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded
```
> Expected: ALL 5 tests PASS.

**Gate 4 — Full regression after drain refactor (REFACTOR phase):**
```bash
rtk flutter test test/_shared/ --reporter=expanded
rtk flutter test test/features/global_risks/ --reporter=expanded
rtk flutter test test/features/action_plans/ --reporter=expanded
```
> Expected: Zero regressions.

**Gate 5 — File size check:**
```bash
rtk flutter analyze lib/_shared/services/sync_engine_drains.dart
```
> Expected: Zero errors or warnings. File should be < 280 lines.

---

| Action | File | Description |
|---|---|---|
| `[MOD]` | `lib/_shared/services/sync_engine_drains.dart` | Add private `_processQueue<T>()` method. Refactor `_drainSubmissions`, `_drainRisks`, `_drainProgramEvidence`, `_drainProgramPhotos` to delegate to it. |
| `[NO-TOUCH]` | `lib/_shared/services/sync_engine.dart` | Zero changes. `_backoffDelays`, `_scheduleRetry`, and `_state` are already accessible via `part of`. |
| `[MOD]` | `test/shared/services/sync_engine_backoff_test.dart` | **ONLY** if new tests for AC-409/AC-FATAL are added. The existing AC4/AC5/AC6 tests are frozen. |

---

## Concept Diagram

```
BEFORE:
[_drainSubmissions]  → [try/catch + backoff math — 50 lines]
[_drainRisks]        → [try/catch + backoff math — 45 lines]
[_drainProgramEv]    → [try/catch + backoff math — 55 lines]
[_drainProgramPh]    → [try/catch + backoff math — 45 lines]

AFTER:
[_drainSubmissions]  → [build payload]   → [_processQueue<T>(items, push: ..., onSuccess: ..., onRetry: ..., onExhausted: ..., isFatalError: ...)]
[_drainRisks]        → [_processQueue<T>(items, push: ..., onSuccess: ..., onRetry: ..., onExhausted: ..., isFatalError: ..., onConflict: ...)]
[_drainProgramEv]    → [_processQueue<T>(items, push: ..., onSuccess: ..., onRetry: ..., onExhausted: ..., isFatalError: ...)]
[_drainProgramPh]    → [_processQueue<T>(items, push: ..., onSuccess: ..., onRetry: ..., onExhausted: ..., isFatalError: ...)]
                                    ↓
                        [_processQueue<T> — ONE canonical implementation]
                          1. Check connectivity → return if offline
                          2. try: push(item), then onSuccess(item)
                          3. catch: isFatalError? → onExhausted(item), continue
                          4. catch: isConflict(409)? → onConflict?(item), continue
                          5. retryCount < max? → onRetry(item,...), _scheduleRetry, break
                          6. else → onExhausted(item), _state=error, break
```

---

## Execution Phase

> **Complexity**: Medium
> **Risk**: Low — pure internal refactor, zero API surface change, zero DAO change, zero UI impact.

### Step-by-step (TDD Red-Green-Refactor)

The Builder MUST follow this order precisely. Do NOT write `_processQueue` before writing the new tests.

**Step 1: Write new tests (RED)**
- Add `AC-409` and `AC-FATAL` tests to `test/shared/services/sync_engine_backoff_test.dart`.
- Run `sync_engine_backoff_test.dart`. AC4/AC5/AC6 still pass. New tests FAIL with the expected error (wrong behavior in current code, or they test a code path not yet present).

**Step 2: Implement `_processQueue<T>` (GREEN)**
- Add the private helper at the bottom of `sync_engine_drains.dart`.
- The exact interface (from the ADR):
  ```
  Future<void> _processQueue<T>(
    List<T> items, {
    required int Function(T item) getRetryCount,
    required Future<void> Function(T item) push,
    required Future<void> Function(T item) onSuccess,
    required Future<void> Function(T item, String error) onExhausted,
    required Future<void> Function(T item, int newRetryCount, DateTime nextRetry, String error) onRetry,
    required bool Function(dynamic error) isFatalError,
    Future<void> Function(T item)? onConflict,
  });
  ```
- The connectivity check (`if (!_connectivity.isOnline)`) happens at the TOP of the loop for each item.
- The `break` on network error sets `_state = SyncState.error` before breaking.
- The conflict check `e.toString().contains('409')` routes to `onConflict` (if provided) or falls through to retry.
- Run all tests. All 5 tests (AC4/AC5/AC6 + AC-409 + AC-FATAL) must now PASS.

**Step 3: Refactor the 4 drains (REFACTOR)**
- Replace `_drainSubmissions`, `_drainRisks`, `_drainProgramEvidence`, `_drainProgramPhotos` with thin wrappers that call `_processQueue`.
- `_drainActionPlans` is **NOT touched**.
- Run full test suite. All existing tests must still pass.

**Step 4: Size check**
- `sync_engine_drains.dart` must be < 280 lines after the refactor (was 344).
- If it's bigger, stop and report to user.

### Pros & Cons of the locked-in approach (Design 1: Minimalist)

| Aspect | Pro | Con |
|---|---|---|
| **Blast radius** | Only 1 file changed. Zero DAO/API/UI impact. | — |
| **Readability** | Drain methods become 10-15 lines of pure intent. | `_processQueue` signature is long (6 named params). |
| **Testability** | Existing tests prove behaviour without change. | Helper is private — tested via drain methods only. |
| **Extensibility** | Adding a new drain = 15 lines, not 50. | Closures can be verbose at call site. |

> **Scout Decision**: Design 1 is confirmed. No need for user input — the ADR already locked this in.

---

<command_logs>
- `view_file` → `scout_persona.md`
- `view_file` → `orchestration-standards.md`
- `view_file` → `adr_20260501_231600_5badbf76_deepen_sync_engine_backoff.md.resolved`
- `view_file` → `sync_engine_drains.dart` (344 lines, full read)
- `view_file` → `sync_engine.dart` (226 lines, full read)
- `view_file` → `GEMINI.md` (services local rules)
- `list_dir` → `lib/_shared/services/`
- `grep_search` → `sync_engine` in `lib/` (usage map)
- `grep_search` → `sync_engine` in `test/` (test file map)
- `view_file` → `sync_engine_backoff_test.dart` (267 lines, full read)
- `view_file` → `drain_result.dart`
</command_logs>

---

## Handoff Block

**For the next AI agent (Builder/Forge):**
- The ADR has been analyzed and confirmed. The design is locked (Design 1: Minimalist closure-based helper).
- **4 drains qualify**: `_drainSubmissions`, `_drainRisks`, `_drainProgramEvidence`, `_drainProgramPhotos`.
- **`_drainActionPlans` does NOT qualify** — it has no backoff loop.
- The `_drainSubmissions` method has complex payload-building logic BEFORE the push. The Builder must preserve this pre-processing; `_processQueue` only wraps the `push → catch → retry/exhaust` loop.
- The golden test gate is `test/shared/services/sync_engine_backoff_test.dart`. Do NOT modify it.

**Routing (execute ONE AT A TIME):**

**Step 1 — Write new tests first (TDD):**
> @[/tdd] Execute tests for SyncEngine Backoff AC-409 and AC-FATAL: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_231745_380021a1_deepen_sync_engine_backoff.md`

**Step 2 — Build the helper (after Step 1 RED tests confirmed):**
> @[/implement] Execute build for `_processQueue<T>` helper + drain refactor: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_231745_380021a1_deepen_sync_engine_backoff.md`

**Concurrency:** Step 2 MUST wait for Step 1 to complete. They are sequential, not parallel.
