<latent_space_scratchpad>
KEY DECISIONS:
1. Drift table DROP: Drift doesn't have m.dropTable() in MigrationStrategy. Options:
   A. Keep tables in schema (orphaned, never written to again) - SIMPLE but leaves dead schema
   B. Use customStatement("DROP TABLE IF EXISTS ...") in migration - WORKS, but removes from @DriftDatabase list too
   C. Remove from @DriftDatabase and tables.dart, use customStatement DROP in migration - CORRECT approach
   
   Decision: Option C — remove PendingProgramSubmissions and PendingProgramPhotos from tables.dart and 
   app_database.dart @DriftDatabase list. In the v26 migration block, issue:
     await customStatement('DROP TABLE IF EXISTS pending_program_submissions');
     await customStatement('DROP TABLE IF EXISTS pending_program_photos');
   This is the cleanest because after schema bump, the generated .g.dart won't reference them.
   BUT: PendingProgramPhotos has a FK to PendingProgramSubmissions. Must drop photos first.
   Also: program_outbox_dao.dart has methods for enqueuePhoto, getPendingPhotos, etc. — those must be deleted.

2. ProgramManager.submitEvidence() new flow:
   - Reads CachedProgramAssignments.templateId (after Slice 3 adds it) to get templateId
   - Writes PendingSubmissionsCompanion with programAssignmentId field (server expects it)
   - BUT: PendingSubmissions outbox row has a 'payload' TEXT field (see outbox_dao.dart)
   - Look at PendingSubmission model and outbox_dao structure

3. PendingSubmissions vs ProgramSubmissions:
   Looking at outbox_dao.dart which handles PendingSubmissions:
   - It has `payload` as a JSON blob  
   - `targetSubmissionId` for finalize routing
   - `idempotencyKey`
   
   The AuditManager.submitAudit() is the reference pattern.
   ProgramManager.submitEvidence() needs to build a payload JSON that includes programAssignmentId.
   The SyncApiAdapter.pushSubmission() will pass it as-is to POST /api/submissions.
   The programAssignmentId field will be in the JSON payload.

4. SyncApi interface: Remove pushProgramEvidence and pushProgramPhoto methods entirely.
   SyncApiAdapter: Remove those method implementations.
   BUT: ProgramSyncModule uses them — we're deleting _drainProgramEvidence and _drainProgramPhotos entirely.
   So ProgramSyncModule.executePush() becomes a no-op (or just does nothing).
   Actually: we can simplify executePush to an empty async body since the 
   PendingSubmissions drain is handled by CoreAuditSyncModule already.

5. WHAT DOES ProgramSyncModule DO AFTER SLICE 3?
   - executePull() → _pullProgramAssignments() — KEEP (pull assignments from server)
   - executePush() → REMOVE _drainProgramEvidence and _drainProgramPhotos → becomes empty
   
   Actually executePush can be removed entirely by just making it a no-op.
   The PendingSubmissions outbox is drained by CoreAuditSyncModule already.

6. templateId in CachedProgramAssignments:
   - Add TextColumn get templateId => text().nullable()()
   - In ProgramSyncModule._pullProgramAssignments(): map json['templateId'] into the companion
   - In ProgramAssignmentDto: add String? templateId field
   - In ProgramManager.loadAssignment(): now returns templateId so ProgramExecutionPage can use it (Slice 4)

7. ProgramManager.submitEvidence() new signature:
   The UI (ProgramExecutionPage) still calls submitEvidence — but for now (Slice 3) we just fix the OUTBOX
   The actual UI rewire to AuditFormPage is Slice 4. So submitEvidence needs to:
   - Read assignment.templateId from cache  
   - Build a PendingSubmissions payload with programAssignmentId
   - BUT the existing submitEvidence takes (assignmentId, note, {photoPath}) — simple evidence
   - After Slice 4, the UI won't call submitEvidence anymore (will use AuditFormPage flow)
   
   DECISION: In Slice 3, we keep the submitEvidence signature but change its internals to write
   to PendingSubmissions outbox. The evidence format becomes a single-question submission 
   (note → answers[0]) with programAssignmentId set.
   
   WAIT — actually this is wrong. The whole POINT of the bridge is that programs now use AuditFormPage
   which creates full submissions via the existing audit flow. So:
   - Slice 3: JUST kill the dead outbox tables + add templateId to cache
   - Slice 4: ProgramExecutionPage gets replaced by AuditFormPage
   - ProgramManager.submitEvidence() becomes DEAD CODE after Slice 4
   
   For Slice 3, we should:
   1. Kill PendingProgramSubmissions + PendingProgramPhotos tables (migration + delete from Dart)
   2. Kill ProgramManager.submitEvidence() method — it writes to tables that no longer exist
      (and Slice 4 won't use it either — ProgramExecutionPage gets replaced entirely)
   3. Kill _drainProgramEvidence + _drainProgramPhotos in ProgramSyncModule
   4. Remove pushProgramEvidence + pushProgramPhoto from SyncApi + SyncApiAdapter
   5. Add templateId to CachedProgramAssignments + sync it in _pullProgramAssignments
   6. Add templateId to ProgramAssignmentDto

8. FILE SIZE CHECK:
   - tables.dart = 399 lines. Removing PendingProgramSubmissions (lines ~361-378 = 18 lines) 
     and PendingProgramPhotos (lines ~380-398 = 19 lines) would bring it to ~362 lines. 
     Adding templateId is +1 line. Final: ~363 lines. SAFE.
   - app_database.dart = 307 lines. Removing 2 table refs from @DriftDatabase list = -2 lines. 
     No split needed.
   - program_outbox_dao.dart = 174 lines. Removing photo methods (~50 lines) → ~124 lines. SAFE.
   - program_sync_module.dart = 125 lines. Removing 2 drain methods (~60 lines) → ~65 lines. SAFE.
   - sync_api.dart = 34 lines. Removing 2 methods → ~28 lines. SAFE.
   - sync_api_adapter.dart = 186 lines. Removing 2 methods (~25 lines) → ~161 lines. SAFE.
   - locator.dart = 292 lines. No change (ProgramSyncModule still registered same way). SAFE.
   - program_manager.dart = 140 lines. Removing submitEvidence (~60 lines) → ~80 lines. SAFE.

9. FLUTTER TESTS: Must run `flutter test lib/` to verify no regressions.
</latent_space_scratchpad>

# Implementation Plan: Slice 3 — Flutter Sync Rewire (Drift + Outbox)
**Program-Submission Bridge**

**ShortID**: b4c8d9e2 | **Date**: 2026-05-11

---

## Input Lineage
- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260511_182900_b4c8d9e2_program_submission_bridge.md`
- **Slice 2 Walkthrough**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\program_submission_bridge\walkthrough_20260511_224220_b4c8d9e2_slice2_server_api.md`

---

## Executive Summary & Out of Scope

**What Slice 3 does (4 goals):**

```
GOAL 1 — Kill the dead outbox tables:
  PendingProgramSubmissions (points to dead 410 endpoint) → DROP TABLE
  PendingProgramPhotos (orphaned FK child)                → DROP TABLE
  schema: 25 → 26

GOAL 2 — Kill dead code that writes to those tables:
  ProgramManager.submitEvidence()       → DELETE METHOD (Slice 4 replaces it)
  ProgramSyncModule._drainProgramEvidence() → DELETE
  ProgramSyncModule._drainProgramPhotos()   → DELETE
  SyncApi.pushProgramEvidence()         → DELETE from interface
  SyncApi.pushProgramPhoto()            → DELETE from interface
  SyncApiAdapter implementations        → DELETE

GOAL 3 — Add templateId to assignment cache (needed by Slice 4):
  CachedProgramAssignments.templateId   → new nullable TEXT column
  schema v26 migration: addColumn
  ProgramSyncModule._pullProgramAssignments() → map json['templateId']
  ProgramAssignmentDto.templateId        → new field

GOAL 4 — Clean ProgramOutboxDao (remove photo methods that reference dead table):
  enqueuePhoto / getPendingPhotos / removePhoto / markPhotoExhausted / updatePhotoRetry → DELETE
```

**Out of Scope (Slice 4):**
- `ProgramExecutionPage` → `AuditFormPage` rewire (UI is Slice 4)
- Writing to `PendingSubmissions` outbox with `programAssignmentId` (that happens via AuditFormPage in Slice 4)
- Any server changes (Slice 2 is complete and deployed)
- E2E tests (Slice 5)

---

## ⚠️ Risk Warning

**Drift schema migration** (`schemaVersion` 25 → 26) must be done with exact steps:
1. Remove table class declarations from `tables.dart`
2. Remove from `@DriftDatabase` list in `app_database.dart`
3. Regenerate `app_database.g.dart` via `build_runner`
4. Add `from < 26` migration block using `customStatement('DROP TABLE IF EXISTS ...')`

**Order matters:** Drop `pending_program_photos` (FK child) BEFORE `pending_program_submissions` (FK parent) inside the migration block.

**`submitEvidence()` deletion:** After this slice, `ProgramManager` has no way to submit evidence. This is intentional — Slice 4 wires the UI to `AuditFormPage` which uses the standard audit outbox. Deleting `submitEvidence` now forces Slice 4 to not use it accidentally.

---

## System Context

- **Environment**: Flutter (Dart), offline-first, SQLite via Drift
- **RBAC**: Not applicable to Flutter sync layer
- **Build command**: `dart run build_runner build --delete-conflicting-outputs` (must run after Drift table changes)
- **Test command**: `flutter test lib/`
- **Flutter local rules**: `lib/GEMINI.md` — check before editing
- **No server changes** in Slice 3

---

## Lifecycle Context

| State | Behavior |
|---|---|
| **Fresh install (schema 26)** | `pending_program_submissions` and `pending_program_photos` tables never created. No action. |
| **Upgrade from schema < 26** | Migration block drops both old tables. Any pending rows (pointing to dead 410 endpoint) are safely purged — they would never succeed anyway. |
| **Pull sync cycle** | `_pullProgramAssignments()` maps `templateId` from server response into `CachedProgramAssignments`. |
| **SM navigates to program** | `ProgramManager.loadAssignment()` returns `ProgramAssignmentDto` with `templateId` populated — ready for Slice 4. |
| **Push sync cycle** | `ProgramSyncModule.executePush()` becomes a no-op. Standard `CoreAuditSyncModule` drains `PendingSubmissions` as before. |

---

## Test Contracts

| ID | Scenario | Given | When | Then | Why fails first |
|---|---|---|---|---|---|
| TC-S3-01 | DB upgrade migrates without crash | Existing SQLite DB at schema 25 | App opens (triggers Drift migration to v26) | App boots, no exception. Both old tables absent. | Migration block missing |
| TC-S3-02 | Fresh install creates schema 26 correctly | Clean install | App opens for first time | All v26 tables created. `pending_program_submissions` never exists. | Schema not yet updated |
| TC-S3-03 | pullProgramAssignments maps templateId | Server returns assignments with `templateId` | ProgramSyncModule.executePull() | `CachedProgramAssignments.templateId` is non-null | Field not in Drift table |
| TC-S3-04 | ProgramAssignmentDto includes templateId | Assignment in DB has templateId | ProgramManager.loadAssignment(id) | Returned DTO has non-null templateId | DTO lacks field |
| TC-S3-05 | executePush is a no-op | Any | ProgramSyncModule.executePush() | Returns immediately. No HTTP calls. No crash. | Would crash trying to use deleted DAO methods |
| TC-S3-06 | build_runner compiles clean | After Drift table changes + schema bump | dart run build_runner build | Generates new app_database.g.dart without errors | Stale generated file references deleted tables |

---

## Test Fixture & Payloads

**Server JSON that `_pullProgramAssignments` must handle (from Slice 2):**
```json
{
  "items": [
    {
      "id": "{{assignmentId}}",
      "programId": "{{programId}}",
      "programTitle": "Weekend Hygiene Blitz",
      "category": "QC",
      "deadline": "2026-05-20T00:00:00Z",
      "status": "pending",
      "templateId": "{{templateId}}",
      "createdAt": "2026-05-11T00:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 50
}
```

**Drift column addition (templateId nullable text, no default):**
```dart
// In CachedProgramAssignments table:
TextColumn get templateId => text().nullable()();
```

**Migration v26 block:**
```
// v26: Bridge Slice 3 — drop legacy evidence tables + add templateId to assignments
await customStatement('DROP TABLE IF EXISTS pending_program_photos');
await customStatement('DROP TABLE IF EXISTS pending_program_submissions');
await m.addColumn(cachedProgramAssignments, cachedProgramAssignments.templateId);
```

---

## Tools & Commands

**Skills needed:** None (standard Drift migration pattern)

**Build commands (ordered):**
```bash
# After making Dart changes, regenerate Drift generated file:
dart run build_runner build --delete-conflicting-outputs

# Run all Flutter unit tests:
flutter test lib/
```

---

## Proposed Changes

```
[MOD] lib/_shared/database/tables.dart
      - Remove PendingProgramSubmissions class (~18 lines)
      - Remove PendingProgramPhotos class (~19 lines)
      + Add templateId column to CachedProgramAssignments

[MOD] lib/_shared/database/app_database.dart
      - Remove PendingProgramSubmissions from @DriftDatabase list
      - Remove PendingProgramPhotos from @DriftDatabase list
      + Add from < 26 migration block (DROP TABLE x2, addColumn templateId)
      + Bump schemaVersion: 25 → 26

[MOD] lib/_shared/database/dao/program_outbox_dao.dart
      - Remove enqueuePhoto()
      - Remove getPendingPhotos()
      - Remove removePhoto()
      - Remove markPhotoExhausted()
      - Remove updatePhotoRetry()
      (Keep all PendingProgramSubmissions methods — they are safe dead stubs for now,
       but also remove them since table is dropped)
      - Remove enqueue()
      - Remove getEligiblePending()
      - Remove remove()
      - Remove markExhausted()
      - Remove updateRetry()
      Keep only: upsertCachedAssignment, deleteAllCachedAssignments, 
                 watchPendingAssignments, getNonSubmittedAssignments, getCachedAssignment

[MOD] lib/_shared/services/sync_api.dart
      - Remove pullProgramAssignments() — KEEP (it is used in _pullProgramAssignments)
      - Remove pushProgramEvidence()
      - Remove pushProgramPhoto()

[MOD] lib/_shared/services/sync_api_adapter.dart
      - Remove pushProgramEvidence() implementation
      - Remove pushProgramPhoto() implementation

[MOD] lib/features/programs/services/program_sync_module.dart
      - Remove _drainProgramEvidence()
      - Remove _drainProgramPhotos()
      - executePush() → empty async body (or just: Future<void> executePush() async {})

[MOD] lib/features/programs/manager/program_manager.dart
      - Remove submitEvidence() method (dead — Slice 4 replaces via AuditFormPage)

[MOD] lib/features/programs/model/program_assignment_dto.dart
      + Add String? templateId field
      + Map it in fromDb() factory

[DEL] lib/_shared/database/app_database.g.dart
      (Auto-regenerated by build_runner — Builder must run build_runner after edits)
```

**Total files**: 8 MOD, 1 auto-regenerated = 8 explicit changes.

---

## Concept Diagram

```
BEFORE Slice 3:
  [ProgramManager.submitEvidence()] → [PendingProgramSubmissions outbox] → [SyncEngine] 
    → [ProgramSyncModule._drainProgramEvidence()] → POST /programs/assignments/{id}/submit
                                                                            ↑ 410 GONE ❌

AFTER Slice 3:
  [ProgramManager] — submitEvidence() DELETED
  [ProgramSyncModule.executePush()] — empty (no-op)
  [PendingProgramSubmissions table] — DROPPED from SQLite
  [PendingProgramPhotos table]      — DROPPED from SQLite

  New data flow (Slice 4 will complete the circle):
  [CachedProgramAssignments.templateId] ← _pullProgramAssignments (maps json['templateId'])
  [ProgramAssignmentDto.templateId]     ← ProgramManager.loadAssignment()
  [Slice 4: AuditFormPage]             ← uses templateId to start standard audit
```

---

## Execution Phases

### Phase A — Drift Schema Change + Build Runner

**Complexity: Medium.** Drift table deletion + schema bump must be done atomically with build_runner regeneration.

- **Summary**: Modify `tables.dart` to remove the two dead outbox table classes and add `templateId` to `CachedProgramAssignments`. Update `app_database.dart`: remove tables from `@DriftDatabase`, bump `schemaVersion` to 26, add migration block. Run `build_runner` to regenerate `app_database.g.dart`.
- **Value**: SQLite schema is clean. Old evidence tables are gone on upgrade. `templateId` is available for queries.
- **Entry state**: Slice 2 complete. `schemaVersion = 25`.
- **Exit state**: `build_runner` succeeds with zero errors. `schemaVersion = 26`. Generated file references no `PendingProgramSubmission` or `PendingProgramPhoto`.
- **Scope**:
  - `[MOD]` `tables.dart` — remove 2 table classes, add `templateId` to `CachedProgramAssignments`
  - `[MOD]` `app_database.dart` — remove from `@DriftDatabase`, bump version, add migration block
  - Run: `dart run build_runner build --delete-conflicting-outputs`
- **Migration block order (critical):**
  ```
  if (from < 26) {
    await customStatement('DROP TABLE IF EXISTS pending_program_photos');    // child first
    await customStatement('DROP TABLE IF EXISTS pending_program_submissions'); // parent second
    await m.addColumn(cachedProgramAssignments, cachedProgramAssignments.templateId);
  }
  ```
- **Acceptance Criteria**:
  - `dart run build_runner build` exits 0
  - `app_database.g.dart` does not reference `pendingProgramSubmissions` or `pendingProgramPhotos`
  - `CachedProgramAssignments` now includes `templateId` in generated code

### Phase B — Dead Code Deletion

**Complexity: Low.** Pure deletion — no new logic introduced.

- **Summary**: Remove the dead outbox methods from `ProgramOutboxDao` (all `PendingProgramSubmissions` and `PendingProgramPhotos` methods). Remove `pushProgramEvidence` and `pushProgramPhoto` from `SyncApi` abstract class and `SyncApiAdapter`. Delete `_drainProgramEvidence()` and `_drainProgramPhotos()` from `ProgramSyncModule`. Make `executePush()` a no-op. Delete `submitEvidence()` from `ProgramManager`.
- **Value**: No dead code remains. No code references tables that no longer exist. Compiler proves no callers exist.
- **Entry state**: Phase A complete. Build runner passed.
- **Exit state**: `flutter test lib/` passes. No compile errors referencing removed symbols.
- **Scope**:
  - `[MOD]` `program_outbox_dao.dart` — remove all evidence outbox methods
  - `[MOD]` `sync_api.dart` — remove 2 dead abstract methods
  - `[MOD]` `sync_api_adapter.dart` — remove 2 dead implementations
  - `[MOD]` `program_sync_module.dart` — remove 2 drain methods, no-op executePush
  - `[MOD]` `program_manager.dart` — remove submitEvidence method
- **Acceptance Criteria**:
  - `flutter analyze lib/` produces zero `undefined` or `unused` errors for removed symbols
  - `flutter test lib/` passes

### Phase C — TemplateId Sync + DTO

**Complexity: Low.** Map one new JSON field through 3 files.

- **Summary**: Add `String? templateId` to `ProgramAssignmentDto`. Update `fromDb()` factory to map it. Update `_pullProgramAssignments()` in `ProgramSyncModule` to read `json['templateId']` and write it into the `CachedProgramAssignmentsCompanion`. Extend the existing `TC-S3-03` and `TC-S3-04` unit tests to assert the field is populated.
- **Entry state**: Phase B complete.
- **Exit state**: `ProgramManager.loadAssignment()` returns DTO with `templateId` populated. `flutter test lib/` passes.
- **Scope**:
  - `[MOD]` `program_assignment_dto.dart` — add `templateId` field + constructor param + fromDb mapping
  - `[MOD]` `program_sync_module.dart` — map `json['templateId']` in `CachedProgramAssignmentsCompanion`
- **Acceptance Criteria**:
  - `ProgramAssignmentDto.templateId` is non-null in unit tests that seed a DB row with templateId
  - `_pullProgramAssignments()` does not throw if `templateId` key is absent from JSON (nullable field)

---

<command_logs>
- view_file: walkthrough_20260511_224220_b4c8d9e2_slice2_server_api.md — confirmed Slice 2 complete, 12 tests passed
- view_file: tables.dart — 399 lines; confirmed PendingProgramSubmissions (361-378) and PendingProgramPhotos (380-398); CachedProgramAssignments (345-359) has no templateId
- view_file: app_database.dart — confirmed schemaVersion=25, @DriftDatabase includes PendingProgramSubmissions and PendingProgramPhotos at lines 36-37
- view_file: program_outbox_dao.dart — 174 lines; confirmed photo methods (enqueuePhoto etc.) reference PendingProgramPhotos
- view_file: program_sync_module.dart — 125 lines; confirmed _drainProgramEvidence (63-98) and _drainProgramPhotos (101-123)
- view_file: program_manager.dart — 140 lines; confirmed submitEvidence (78-138) writes to PendingProgramSubmissions
- view_file: sync_api.dart — 34 lines; confirmed pushProgramEvidence and pushProgramPhoto methods
- view_file: sync_api_adapter.dart — 186 lines; confirmed both dead implementations
- view_file: program_assignment_dto.dart — 53 lines; confirmed no templateId field
- view_file: locator.dart — 292 lines; confirmed ProgramSyncModule registered at lines 179-187, still correct after Slice 3
</command_logs>

---

## Handoff Block

> [!IMPORTANT]
> **Route: `/implement` (no new logic — pure deletion + schema migration).**
> Run phases **A → B → C in strict order**. Do NOT run Phase B before `build_runner` succeeds in Phase A.

```
@[/implement] Execute build for Slice 3 — Phase A:
C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_230633_b4c8d9e2_slice3_flutter_sync.md

@[/implement] Execute build for Slice 3 — Phase B (after Phase A):
C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_230633_b4c8d9e2_slice3_flutter_sync.md

@[/implement] Execute build for Slice 3 — Phase C (after Phase B):
C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260511_230633_b4c8d9e2_slice3_flutter_sync.md
```

> [!WARNING]
> **Do NOT start Slice 4 (UI rewire)** until `flutter test lib/` passes for all 3 phases.
> **locator.dart does NOT change** — `ProgramSyncModule` is still registered the same way.
