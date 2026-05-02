# Code Audit Report — lib/_shared
**Workflow**: /audit-code | **Role**: Sentinel
**Date**: 2026-05-03T06:03:11+07:00
**ConversationID**: 70e13ccc
**Scope**: `lib/_shared/` — all 7 subdirectories (66 Dart files)

---

## Finding Summary

| ID | Severity | File | Title |
|----|----------|------|-------|
| CS-1 | 🟢 Optimization | `router/main_shell.dart` | Duplicate `_shellIndexFromLocation` function |
| CS-2 | 🟡 Warning | `router/main_shell.dart` | UI Shell imports DAO layer directly (Arch Drift) |
| CS-3 | 🟡 Warning | `services/sync_api.dart` + `sync_api_adapter.dart` | `pullDeltas()` is an unimplemented stub (dead interface method) |
| CS-4 | 🟡 Warning | `services/app_lifecycle_manager.dart`, `router/main_shell.dart` | Zero behavioral test coverage |
| CS-5 | 🟡 Warning | `database/tables.dart` (384 lines), `router/app_router.dart` (323 lines), `database/app_database.dart` (301 lines), `router/main_shell.dart` (299 lines), `database/dao/outbox_dao.dart` (291 lines) | Files approaching or at 250-line warning threshold |

---

## 🟢 CS-1 — Duplicate `_shellIndexFromLocation` Function

**Files**:
- `lib/_shared/router/main_shell.dart` Line 14 (private, `_shellIndexFromLocation`)
- `lib/_shared/router/app_router.dart` Line 315 (public, `@visibleForTesting shellIndexFromLocation`)

### Problem
Two functions with identical logic exist in two files in the same folder:
```dart
// main_shell.dart:14 (private copy)
int _shellIndexFromLocation(String location) {
  if (location.startsWith('/activity')) return 1;
  ...
}

// app_router.dart:315 (public @visibleForTesting copy)
@visibleForTesting
int shellIndexFromLocation(String location) {
  if (location.startsWith('/activity')) return 1;
  ...
}
```
The private copy in `main_shell.dart` was likely created to avoid a cross-file import but creates a silent drift risk: adding a new route must be updated in **two** places.

### Fix
Delete the private `_shellIndexFromLocation` from `main_shell.dart` and import + use the public `shellIndexFromLocation` from `app_router.dart`.

```dart
// In main_shell.dart — add import:
import 'app_router.dart';

// Remove lines 14–22, change line 34 from:
final currentIndex = _shellIndexFromLocation(location);
// to:
final currentIndex = shellIndexFromLocation(location);
```

**Complexity**: Low — delete ~9 lines, add 1 import, change 1 call site. No behavior change.

**Trade-offs**:
- ✅ Eliminates drift risk (1 source of truth)
- ✅ The test in `app_router.dart` already covers the shared function
- ⚠️ Slight cross-file coupling — `main_shell.dart` now imports from `app_router.dart`. Acceptable since both live in `router/`.

---

## 🟡 CS-2 — UI Shell Imports DAO Layer Directly (Architecture Drift)

**File**: `lib/_shared/router/main_shell.dart` Lines 8–9

### Problem
```dart
import '../database/dao/outbox_dao.dart';    // ← DB Layer
import '../services/sync_engine.dart';       // ← Service Layer
```
`MainShell` is a **routing/UI layer** file. It directly imports from the DB DAO layer to call `watchExhaustedCount()`, `discardExhausted()`, and `requeueExhausted()` — bypassing the Service layer entirely.

**Correct architecture:**
```
[UI Layer: MainShell] → [Service Layer: SyncEngine] → [DAO Layer: OutboxDao]
```
**Current broken architecture:**
```
[UI Layer: MainShell] → [DAO Layer: OutboxDao]  ← DRIFT
[UI Layer: MainShell] → [Service Layer: SyncEngine]
```

### Fix
Add the exhaustion management methods to `SyncEngine` and let `MainShell` only talk to `SyncEngine`.

```dart
// In SyncEngine — add:
Stream<int> watchExhaustedCount() => _outbox.watchExhaustedCount();
Future<void> discardExhausted() => _outbox.discardExhausted();
Future<void> requeueExhausted() {
  final fut = _outbox.requeueExhausted();
  requestSync();  // Trigger sync immediately after requeue
  return fut;
}

// In MainShell — replace:
_di<OutboxDao>().watchExhaustedCount()   → _di<SyncEngine>().watchExhaustedCount()
_di<OutboxDao>().discardExhausted()      → _di<SyncEngine>().discardExhausted()
_di<OutboxDao>().requeueExhausted() + _di<SyncEngine>().requestSync()
  → _di<SyncEngine>().requeueExhausted()  // consolidated in engine

// Remove the OutboxDao import from main_shell.dart
```

**Complexity**: Low-Medium — small change, but touches both `SyncEngine` and `MainShell`. Must test `SyncEngine.requeueExhausted()` calls `requestSync()` internally.

**Trade-offs**:
- ✅ Fixes layer violation — UI never touches DB directly
- ✅ `SyncEngine` becomes the single authority for all outbox-affecting actions
- ✅ Allows future mocking in widget tests (mock `SyncEngine`, not `OutboxDao`)
- ⚠️ Adds 3 thin delegation methods to `SyncEngine` — minor bloat but justified

---

## 🟡 CS-3 — `pullDeltas()` is an Unimplemented Stub (Dead Interface Method)

**Files**: `services/sync_api.dart` Line 10, `services/sync_api_adapter.dart` Lines 94–98

### Problem
```dart
// sync_api_adapter.dart:94
@override
Future<DeltaPullResult> pullDeltas(DateTime? since) async {
  // Delta pull — future enhancement to sync templates/stores/submissions.
  // For now, individual managers handle their own cache refresh.
  return DeltaPullResult(serverTimestamp: DateTime.now());
}
```
This method is declared in the `SyncApi` abstract interface and implemented in the adapter, but the implementation is a **no-op stub** that returns fake data. 

`core_audit_sync_module.dart` calls `_api.pullDeltas(...)` but the result (`DeltaPullResult`) is only used for its `serverTimestamp` — not for any actual delta data.

This is confusing and creates a false impression that delta pulling is working.

### Fix Option A — Make the stub explicit with a clear comment (Low effort)
```dart
// sync_api_adapter.dart — Rename to signal intent:
/// Not yet implemented — delta pulling is handled per-entity by individual SyncModules.
/// Returns a synthetic timestamp to allow SyncMeta updates to proceed.
@override
Future<DeltaPullResult> pullDeltas(DateTime? since) async =>
    DeltaPullResult(serverTimestamp: DateTime.now());
```

### Fix Option B — Remove from interface, replace with SyncMeta timestamp (Medium effort)
Remove `pullDeltas` from `SyncApi` entirely. Let each `SyncModule` read/write its own `SyncMeta` entry directly. This is cleaner but requires updating `CoreAuditSyncModule`.

**Complexity**: Option A = Low (comment change). Option B = Medium (interface change + module update).

**Trade-offs**:
- Option A: ✅ Fast, zero risk. ⚠️ The interface still lies about what it does.
- Option B: ✅ Cleaner architecture. ⚠️ More files to touch, requires test update.

---

## 🟡 CS-4 — Zero Behavioral Test Coverage for Critical UI/Lifecycle Files

**Files with zero tests**:
| File | Lines | Risk |
|------|-------|------|
| `router/main_shell.dart` | 299 | High — exhaustion banner UX, nav tab logic |
| `services/app_lifecycle_manager.dart` | 74 | Medium — 4-tier lifecycle recovery behavior |

### Problem
`app_lifecycle_manager.dart` implements the C2 lifecycle recovery tiers (< 5min no-op, 5min-12h auth check, 12h-7d resync, > 7d force login). This is complex branching domain logic that **should have unit tests** per the orchestration standards' "Heavy Math Exception."

`main_shell.dart` contains the exhausted-record UX safety net banner — an important recovery flow with no widget test coverage.

### Fix (app_lifecycle_manager.dart)
```dart
// test/_shared/services/app_lifecycle_manager_test.dart
test('C2-T1: < 5 min gap → no-op', () {
  final sut = AppLifecycleManager(...);
  // Simulate foreground at T+4 min
  expect(sut.requiredRecoveryAction(gapMinutes: 4), RecoveryAction.noop);
});
test('C2-T2: 5–12h gap → auth check required', () {...});
test('C2-T3: 12h–7d gap → full resync', () {...});
test('C2-T4: > 7d gap → force re-login', () {...});
```

**Complexity**: Low-Medium for lifecycle (pure logic, no Flutter widgets). High for `main_shell.dart` (requires widget test harness with mock DI).

**Trade-offs**:
- ✅ Proves the lifecycle recovery tiers work correctly
- ✅ Catches regressions if thresholds change
- ⚠️ Widget tests for `MainShell` need a full DI setup — may be deferred

---

## 🟡 CS-5 — Files Approaching Line Thresholds

| File | Lines | Status |
|------|-------|--------|
| `database/tables.dart` | 384 | 🟡 WARN (>250, under 400) |
| `router/app_router.dart` | 323 | 🟡 WARN |
| `database/app_database.dart` | 301 | 🟡 WARN |
| `router/main_shell.dart` | 299 | 🟡 WARN |
| `database/dao/outbox_dao.dart` | 291 | 🟡 WARN |
| `database/app_database.g.dart` | 19,021 | ✅ EXEMPT (auto-generated) |

### Analysis
- `tables.dart` (384 lines) — All table definitions in one file. Could be split into `cache_tables.dart` and `outbox_tables.dart`. No urgency yet but worth doing before schema version 30.
- `app_database.dart` (301 lines) — The migration chain is growing. Consider extracting migrations into a separate `app_database_migrations.dart`.
- `app_router.dart` (323 lines) — Route definitions are flat but the `authRedirect` guard is getting complex. Acceptable for now.
- `main_shell.dart` (299 lines) — Once CS-2 is fixed, this drops by ~25 lines automatically.
- `outbox_dao.dart` (291 lines) — DAO is focused and clean. No action needed.

### Fix for tables.dart (Optional, deferred)
```
database/
  cache_tables.dart    ← CachedTemplates, CachedGroups, CachedCriteria, CachedStores...
  outbox_tables.dart   ← PendingSubmissions, PendingAnswers, PendingPhotos...
  tables.dart          ← barrel export only (re-exports both files)
```

**Complexity**: Medium — requires `build_runner` regeneration and import updates in `app_database.dart`. No behavior change.

---

## Secrets Audit
✅ **No hardcoded secrets found.**
- `api_client.dart:90` and `app_network_image.dart:50` use runtime token injection (`'Bearer $token'`) — this is correct and safe.

## Stale Markers
✅ **Zero TODO/FIXME/HACK markers** found in `lib/_shared`.

---

## Recommended Fix Order

| Priority | ID | File | Action |
|----------|----|------|--------|
| 1 (Easy Win) | CS-1 | `main_shell.dart` | Delete private duplicate, use public `shellIndexFromLocation` |
| 2 (Architecture) | CS-2 | `main_shell.dart` + `sync_engine.dart` | Move DAO calls into `SyncEngine`, remove DAO import from shell |
| 3 (Clarity) | CS-3 | `sync_api.dart` | At minimum, add explicit stub comment (Option A). Discuss Option B separately |
| 4 (Quality) | CS-4 | `app_lifecycle_manager.dart` | Write C2 lifecycle unit tests |
| 5 (Deferred) | CS-5 | `tables.dart` | Split before schema version 30 |

---

> *Pass audit report to Builder agent (@Forge) for /implement (Track B).*
