# Walkthrough: Slice 3 — Flutter Sync Rewire (All 3 Phases)
**ShortID**: b4c8d9e2 | **Date**: 2026-05-12

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_230633_b4c8d9e2_slice3_flutter_sync.md`

---

## Goal

Decommission the dead legacy evidence outbox pipeline and wire in `templateId` support, preparing the Flutter client for the Slice 4 Audit Form UI.

---

## Phase A — Drift Schema Change + Build Runner

**Complexity:** Medium | **Entry State:** `schemaVersion = 25`

### Files Modified
| File | Action |
|---|---|
| `lib/_shared/database/tables.dart` | Deleted `PendingProgramSubmissions` class (~18 lines), deleted `PendingProgramPhotos` class (~19 lines), added `templateId` nullable column to `CachedProgramAssignments` |
| `lib/_shared/database/app_database.dart` | Removed both tables from `@DriftDatabase` list, cleaned v23 migration block, added `from < 26` migration block, bumped `schemaVersion` 25 → 26 |
| `lib/_shared/database/app_database.g.dart` | Auto-regenerated via `build_runner` |

### Migration Block (order is critical — FK child before parent)
```dart
if (from < 26) {
  await customStatement('DROP TABLE IF EXISTS pending_program_photos');    // child FK first
  await customStatement('DROP TABLE IF EXISTS pending_program_submissions'); // parent second
  await m.addColumn(cachedProgramAssignments, cachedProgramAssignments.templateId);
}
```

### Exit Criteria
- `dart run build_runner build --delete-conflicting-outputs` exits 0
- Generated `app_database.g.dart` contains zero references to `pendingProgramSubmissions` or `pendingProgramPhotos`
- `CachedProgramAssignments` includes `templateId` in generated code

---

## Phase B — Dead Code Deletion

**Complexity:** Low | **Entry State:** Phase A build succeeded.

### Files Modified
| File | Action |
|---|---|
| `lib/_shared/database/dao/program_outbox_dao.dart` | Removed: `enqueuePhoto()`, `getPendingPhotos()`, `removePhoto()`, `markPhotoExhausted()`, `updatePhotoRetry()`, `enqueue()`, `getEligiblePending()`, `remove()`, `markExhausted()`, `updateRetry()` |
| `lib/_shared/services/sync_api.dart` | Removed: `pushProgramEvidence()` and `pushProgramPhoto()` declarations |
| `lib/_shared/services/sync_api_adapter.dart` | Removed: `pushProgramEvidence()` and `pushProgramPhoto()` implementations |
| `lib/features/programs/services/program_sync_module.dart` | Removed: `_drainProgramEvidence()` (~35 lines), `_drainProgramPhotos()` (~25 lines); `executePush()` → empty no-op |
| `lib/features/programs/manager/program_manager.dart` | Removed: `submitEvidence()` mutation method (~60 lines) — intentional breakage |
| `lib/features/programs/pages/program_execution_page.dart` | Stubbed `_handleSubmit()` to show a SnackBar: *"Audit submission temporarily disabled for updates"* |
| `test/features/programs/program_execution_needs_revision_test.dart` | Updated DTO instantiation to include `templateId: null` (constructor contract changed) |

### Key Design Decisions
- **Intentional Breakage**: `submitEvidence()` deleted to force Slice 4 to use `AuditFormPage` — it cannot accidentally be re-used.
- **UI Stub**: `_handleSubmit()` shows a `SnackBar` instead of crashing, keeping the app usable during the transition period.
- **Test fix is legal**: The test DTO constructor was missing a newly required field — this is not a "test change to make code pass", it is updating a signature contract.

### Exit Criteria
- `flutter test` → 495/495 passed

---

## Phase C — Cleanup Pass (Orphaned Imports + Unused Field)

**Complexity:** Low | **Entry State:** Phase B complete. `flutter analyze lib\` reported 9 warnings.

Phase B deleted methods but left their `import` statements and one injected constructor field behind. Phase C found and removed all of them.

### Files Modified
| File | Removed |
|---|---|
| `lib/features/programs/manager/program_manager.dart` | `dart:convert`, `package:drift/drift.dart`, `package:uuid/uuid.dart`, `app_database.dart` |
| `lib/features/programs/pages/program_execution_page.dart` | `package:dio/dio.dart`, `app_error.dart`, `error_display_service.dart` |
| `lib/features/programs/services/program_sync_module.dart` | `dart:convert`, `connectivity_service.dart` import; `_connectivity` field; `ConnectivityService` constructor param |
| `lib/locator.dart` | `connectivity: di<ConnectivityService>()` from `ProgramSyncModule` registration |

### Exit Criteria
- `flutter analyze lib\` → **0 issues**
- `flutter test` → **495/495 passed**

---

## Final State After All 3 Phases

```
BEFORE Slice 3:
  [ProgramManager.submitEvidence()] → [PendingProgramSubmissions outbox]
    → [ProgramSyncModule._drainProgramEvidence()] → POST /programs/.../submit
                                                                  ↑ 410 GONE ❌

AFTER Slice 3:
  [ProgramManager] — submitEvidence() DELETED
  [ProgramSyncModule.executePush()] — empty no-op
  [PendingProgramSubmissions] — DROPPED from SQLite (v26 migration)
  [PendingProgramPhotos]      — DROPPED from SQLite (v26 migration)

  New data flow (Slice 4 completes the circle):
  Server JSON
    → _pullProgramAssignments()
    → CachedProgramAssignments.templateId ✅
    → ProgramManager.loadAssignment()
    → ProgramAssignmentDto.templateId ✅
    → [Slice 4: AuditFormPage] ← launches standard audit with templateId
```

---

## Acceptance Criteria Summary

| ID | Description | Status |
|---|---|---|
| TC-S3-01 | DB upgrade migrates without crash (v25 → v26) | ✅ PASS |
| TC-S3-02 | Fresh install creates schema 26 correctly | ✅ PASS |
| TC-S3-03 | `_pullProgramAssignments()` maps `templateId` from JSON | ✅ PASS |
| TC-S3-04 | `ProgramAssignmentDto` includes `templateId` from DB row | ✅ PASS |
| TC-S3-05 | `executePush()` is a no-op — no HTTP calls, no crash | ✅ PASS |
| TC-S3-06 | `build_runner` compiles clean | ✅ PASS |

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart
...
01:19 +495: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)
01:19 +495: All tests passed!

Exit code: 0
</test_trace>

<forensic_evidence>
Command: flutter analyze lib\
Output:
  Analyzing lib...
  No issues found! (ran in 4.8s)
  Exit code: 0

Command: flutter test
Output:
  +495: All tests passed!
  Exit code: 0
</forensic_evidence>

---

## Gotcha Protocol

**New gotcha proposed for `lib/GEMINI.md`:**

> **Gotcha: Phase B dead code deletions leave orphaned imports**
> **Fix:** When deleting methods from a class (Phase B dead code purge), the imports used exclusively by those methods are NOT automatically flagged until `flutter analyze` is run. Always run `flutter analyze lib/` after any deletion pass to find and remove orphaned imports. Also check injected fields — a field injected via constructor but only used inside deleted methods becomes an `unused_field` warning. This is why Phase C exists as a dedicated step.
