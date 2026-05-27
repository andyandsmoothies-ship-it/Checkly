# Implementation Plan: Audit Template `CategoryTags` Integration

<!--
<latent_space_scratchpad>
ACCURATE CODEBASE STATE — confirmed by fresh grep + file reads:

## What ALREADY exists (do NOT redo):
1. PostgreSQL migration `20260527105201_AddCategoryTagsToGroupsAndCriteria.cs` — DONE
2. EF Core model snapshot — CategoryTags in both Groups + Criteria — DONE
3. Flutter `tables.dart` — `CachedGroups` does NOT have `categoryTags` declared in source
   BUT `app_database.g.dart` already has `categoryTags` as `String?` in `CachedGroup`
   This means `tables.dart` WAS already updated (the column IS there in the generated code)
   but the `tables.dart` SOURCE file still does NOT have the declaration.
   Conclusion: Someone ran build_runner on an intermediate state. We need to add it to tables.dart and re-run.

## What is MISSING (must implement):
### Backend:
- Group.cs: NO `CategoryTags` property
- Criterion.cs: NO `CategoryTags` property  
- Dtos.cs: GroupDto record — NO `List<string>? CategoryTags`
- Dtos.cs: CriterionDto record — NO `List<string>? CategoryTags`
- SaveTemplateTree.cs: SaveGroupRequest record — NO `List<string>? CategoryTags`
- SaveTemplateTree.cs: SaveCriterionRequest record — NO `List<string>? CategoryTags`
- SaveTemplateTree.cs: upsert logic does NOT write CategoryTags to entity
- SyncTemplates.cs: SyncGroupDto record — NO `List<string>? CategoryTags`
- SyncTemplates.cs: groups projection — does NOT project g.CategoryTags
- SyncTemplates.cs: criteria projection — does NOT project c.CategoryTags  
- GetTemplate.cs: GroupDto projection — does NOT project g.CategoryTags
- GetTemplate.cs: CriterionDto projection — does NOT project c.CategoryTags

### Flutter:
- tables.dart: `CachedGroups` — needs `TextColumn get categoryTags`
- tables.dart: `CachedCriteria` — needs `TextColumn get categoryTags`
- app_database.dart: needs `from < 31` migration to add categoryTags columns
- template_dto.dart: `GroupDto` — needs `List<String>? categoryTags`
- template_dto.dart: `CriterionDto` — needs `List<String>? categoryTags`
- template_dao.dart: `_upsertGroupsRecursive` — needs to pass categoryTags companion
- template_dao.dart: `_upsertCriteriaInBatch` — needs to pass categoryTags companion
- template_dao.dart: `buildTree` in `getTemplateTree` — needs to map categoryTags back to GroupDto/CriterionDto

## Gap G2: Criterion.cs stale comment — easy 1-line fix (add to Slice 1)

## Storage format for CategoryTags in Flutter:
The generated .g.dart stores `categoryTags` as `String?` (single column).
The server sends it as `List<string>` in JSON (`["Food Safety","Hygiene"]`).
The Flutter DTO must serialize/deserialize this as JSON string for SQLite storage.
Pattern: store as `'["tag1","tag2"]'` in SQLite TextColumn.

## Blast radius:
- The template save endpoint (PUT /templates/{id}/tree) — caller sends GroupDto tree
  The mobile admin template builder calls saveTemplateTree() → it sends `groups` as List<Map>
  Currently no categoryTags in the request body → server just ignores it (no crash)
  Adding it makes it optional (nullable) → no breaking change
- The sync endpoint → currently doesn't send categoryTags → adding it to DTO is additive
- No existing tests reference CategoryTags → no test rewrites needed
- The .g.dart is ahead of tables.dart → need to sync tables.dart then re-run build_runner

## Risk:
- Drift TypeConverter needed for List<String> in SQLite (SQLite has no arrays)
  Two options: a) JSON-encode to String (TypeConverter<List<String>?, String?>) or
               b) Comma-join (fragile if tags have commas)
  Choose JSON-encode (matches existing `metadata` pattern in the codebase)
- app_database schemaVersion must increment to 31 for the Drift migration

## Slice Plan:
Slice 1 (Backend only — 4 files):
  Group.cs, Criterion.cs, Dtos.cs, SyncTemplates.cs, SaveTemplateTree.cs, GetTemplate.cs
  That's 5 files — too many. Split:
  Slice 1A: Group.cs + Criterion.cs + Dtos.cs (entities + DTOs)
  Slice 1B: SaveTemplateTree.cs + GetTemplate.cs + SyncTemplates.cs (endpoints)

Slice 2 (Flutter — 4 files):
  tables.dart + app_database.dart (schema v31) + template_dto.dart + template_dao.dart

Slice 3: build_runner + verify tests pass
</latent_space_scratchpad>
-->

**Date**: 2026-05-27 | **ShortID**: c3563378  
**Conversation**: c3563378-9cd7-4609-ae6d-2aba9f71c9ff  
**Topic Folder**: `audit-template-gaps`

---

## Input Lineage

- **Gap Source**: `C:\Users\HP\.gemini\antigravity\brain\c3563378-9cd7-4609-ae6d-2aba9f71c9ff\feature_compliance_audit.md` (G1 + G2)
- **Requirements**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\requirements_20260527_151100_a2b3c4d5_audit_template_full_scope_v4.md`

---

## Executive Summary & Out of Scope

**Goal**: Wire the `CategoryTags` field (a nullable string array) through all 7 layers of the template stack — backend entity, DTOs, save/sync endpoints, Flutter DTOs, Drift tables, Dart migration, and the template DAO. Also fix the stale `InputType` comment in `Criterion.cs` (G2).

```
[Admin saves template] ──► [SaveTemplateTree.cs reads CategoryTags from request]
                                      ▼
                               [Group.cs / Criterion.cs entity updated]
                                      ▼
                               [GetTemplate.cs projects CategoryTags in GroupDto/CriterionDto]
                                      ▼
                               [SyncTemplates.cs sends CategoryTags in delta payload]
                                      ▼
                    [Flutter receives → JSON-encodes → stores in SQLite TextColumn]
                                      ▼
                    [template_dao.dart reads → JSON-decodes → exposes as List<String>?]
```

**Out of Scope (YAGNI)**:
- **NO UI changes**: No Flutter template builder widget updates in this slice.
- **NO BOD analytics queries**: No changes to how `SectionScoreExploder.cs` computes category scores.
- **NO new API endpoints**: No `/api/templates/tags` listing endpoint.
- **NO permission gates**: CategoryTags requires no new PBAC capability.

---

## System Context

- **Architecture Pattern**: Full-stack 7-Step Sync (entity → DTO → endpoint → sync → Flutter DTO → Drift table → DAO).
- **Offline-first**: CategoryTags must flow all the way to the Drift SQLite cache so auditors have access offline.
- **Backward Compatible**: All additions are nullable — no existing client breaks.
- **PostgreSQL column**: Already exists (`text[]`, migration `20260527105201`). No new backend migration needed.
- **SQLite storage**: Drift `TextColumn` stores JSON-encoded string (`'["Food Safety","Hygiene"]'`). A TypeConverter handles `List<String>? ↔ String?`.
- **Drift schema version**: Must increment from `30` to `31` with a `from < 31` upgrade path.

---

## ⚠️ Risk Warning

> **Blast Radius: MEDIUM**
> - 6 backend files modified across 3 endpoint handlers
> - 4 Flutter files modified including the Drift table definitions
> - Must run `dart run build_runner build` after Flutter changes to regenerate `app_database.g.dart`
> - `app_database.g.dart` currently has `categoryTags` as `String?` in `CachedGroup` BUT `tables.dart` does NOT have this column declared. This is an inconsistent state. The plan below repairs this consistently.

---

## Lifecycle Context (4-State Matrix)

| State | Behavior |
|---|---|
| **Success** | CategoryTags saved to DB and returned in sync/get responses |
| **Loading** | No change — template load/sync is unchanged |
| **Error** | Tags are nullable — null tags = no tags. No crash on absence |
| **Empty** | `null` or `[]` → stored as `NULL` in SQLite; DAO returns `null` |

---

## Constraint Traceability

| Constraint | Source | Test Contract |
|---|---|---|
| `Group.CategoryTags` must be a nullable `List<string>` on the entity | Requirements V4 §2 | TC-CAT-01 |
| `Criterion.CategoryTags` must be a nullable `List<string>` on the entity | Requirements V4 §2 | TC-CAT-02 |
| Tags saved via `PUT /api/templates/{id}/tree` | Requirements V4 §2 | TC-CAT-03 |
| Tags returned via `GET /api/templates/{id}` | Requirements V4 §2 | TC-CAT-04 |
| Tags included in delta sync via `GET /api/sync/templates?since=` | Requirements V4 §2 | TC-CAT-05 |
| Flutter `GroupDto` must carry `List<String>? categoryTags` | Dual-stack requirement | TC-CAT-06 |
| Drift `CachedGroups` must persist `categoryTags` as JSON string | Offline-first requirement | TC-CAT-07 |
| Drift schema version must increment to 31 | Drift migration rule | TC-CAT-08 |
| Existing templates without tags must still load (null-safe) | Backward compat | TC-CAT-09 |
| `Criterion.cs` comment must list all 9 valid InputType values | G2 fix | TC-CAT-10 |

---

## Test Contracts

### TC-CAT-01: Backend — Group entity accepts CategoryTags
- **Track**: B2 (acceptance test first)
- **Test**: `PUT /api/templates/{id}/tree` with groups containing `categoryTags: ["Food Safety"]`
- **Assert**: `GET /api/templates/{id}` returns the group with `categoryTags: ["Food Safety"]`
- **Fail-First**: Before the fix, `SaveGroupRequest` has no `categoryTags` param so the field is silently dropped

### TC-CAT-02: Backend — Criterion entity accepts CategoryTags
- **Track**: B2 (acceptance test first)
- **Test**: `PUT /api/templates/{id}/tree` with criteria containing `categoryTags: ["Hygiene"]`
- **Assert**: `GET /api/templates/{id}` returns criteria with `categoryTags: ["Hygiene"]`
- **Fail-First**: Before the fix, `SaveCriterionRequest` has no `categoryTags` param so the field is silently dropped

### TC-CAT-03: Backend — Sync endpoint includes CategoryTags
- **Track**: B2 (acceptance test first)  
- **Test**: After saving tags, `GET /api/sync/templates?since=epoch` delta
- **Assert**: `SyncGroupDto` response contains `categoryTags: ["Food Safety"]`
- **Fail-First**: Before the fix, `SyncGroupDto` has no `categoryTags` field, so it's not serialized

### TC-CAT-04: Backward Compat — Null tags do not break responses
- **Track**: B2
- **Test**: `GET /api/templates/{id}` on template saved before CategoryTags existed
- **Assert**: Response has `"categoryTags": null` (not an error, not missing key)
- **Fail-First**: Null safety must be preserved in the C# projection

### TC-CAT-05: Flutter DAO — Round-trip encode/decode
- **Track**: B2 (unit test)
- **Test**: `upsertGroups()` with a GroupDto containing `categoryTags: ["Food Safety"]` → then `getTemplateTree()`
- **Assert**: Retrieved `GroupDto.categoryTags` equals `["Food Safety"]`
- **Fail-First**: Before fix, DAO companion has no `categoryTags` field → compile error

---

## Test Fixture & Payloads

### Required Fixture State
- Admin-authenticated user token
- One seeded `Template` with at least one `Group` and one `Criterion`

### PUT /api/templates/{id}/tree Request (with CategoryTags)
```json
{
  "title": "Food Safety V2",
  "type": "QC",
  "version": 1,
  "groups": [
    {
      "id": null,
      "title": "Front of House",
      "categoryTags": ["Food Safety", "Cleanliness"],
      "orderIndex": 0,
      "children": [],
      "criteria": [
        {
          "id": null,
          "label": "Temperature Log",
          "inputType": "pass_fail",
          "categoryTags": ["Food Safety"],
          "orderIndex": 0
        }
      ]
    }
  ]
}
```

### GET /api/templates/{id} Response (with CategoryTags)
```json
{
  "id": "...",
  "title": "Food Safety V2",
  "groups": [
    {
      "id": "...",
      "title": "Front of House",
      "categoryTags": ["Food Safety", "Cleanliness"],
      "children": [],
      "criteria": [
        {
          "id": "...",
          "label": "Temperature Log",
          "categoryTags": ["Food Safety"]
        }
      ]
    }
  ]
}
```

---

## Tools & Commands

- **Skills needed**: `dotnet-scaffolding` (for entity pattern), `ef-core` (for property declaration)
- **Backend test**: `cmd /c rtk dotnet test server/tests/ --filter "Category=Templates"`
- **Flutter analyze**: `cmd /c rtk flutter analyze`
- **Flutter test**: `cmd /c rtk flutter test test/features/templates/`
- **Drift codegen**: `cmd /c rtk dart run build_runner build --delete-conflicting-outputs` (from `lib/` directory)
- **Backend build**: `cmd /c rtk dotnet build server/ --no-restore`

---

## Proposed Changes

### Build Order (sequential, dependency-aware)

| Order | Status | File | Change |
|---|---|---|---|
| 1 | [MOD] | `server/Common/Persistence/Entities/Group.cs` | Add `List<string>? CategoryTags` property |
| 2 | [MOD] | `server/Common/Persistence/Entities/Criterion.cs` | Add `List<string>? CategoryTags` property + fix stale comment |
| 3 | [MOD] | `server/Features/Templates/Dtos.cs` | Add `List<string>? CategoryTags` to `GroupDto` + `CriterionDto` |
| 4 | [MOD] | `server/Features/Templates/SaveTemplateTree.cs` | Add to `SaveGroupRequest`, `SaveCriterionRequest`, + entity write logic |
| 5 | [MOD] | `server/Features/Templates/GetTemplate.cs` | Add `CategoryTags` to Group + Criterion projections |
| 6 | [MOD] | `server/Features/Templates/SyncTemplates.cs` | Add `List<string>? CategoryTags` to `SyncGroupDto` + projections |
| 7 | [MOD] | `lib/_shared/database/tables.dart` | Add `TextColumn get categoryTags` to `CachedGroups` + `CachedCriteria` |
| 8 | [MOD] | `lib/_shared/database/app_database.dart` | Increment schema to v31 + add `from < 31` migration |
| 9 | [MOD] | `lib/features/templates/models/template_dto.dart` | Add `List<String>? categoryTags` to `GroupDto` + `CriterionDto` |
| 10 | [MOD] | `lib/_shared/database/dao/template_dao.dart` | Add `categoryTags` to DAO write + read paths |
| 11 | [RUN] | `app_database.g.dart` | Re-run `build_runner` to regenerate |

---

## Concept Diagram

```
[PUT /templates/{id}/tree]
  ← SaveGroupRequest.categoryTags: List<string>?
  ← SaveCriterionRequest.categoryTags: List<string>?
       │
       ▼
  [SaveTemplateTree.cs]
  group.CategoryTags = req.categoryTags;
  criterion.CategoryTags = req.categoryTags;
       │
       ▼
  [PostgreSQL groups.category_tags text[]]
  [PostgreSQL criteria.category_tags text[]]
       │
       ├──► [GET /templates/{id}]  — GroupDto.CategoryTags, CriterionDto.CategoryTags
       │
       └──► [GET /api/sync/templates?since=]  — SyncGroupDto.CategoryTags
                    │
                    ▼
             [Flutter template_dto.dart]
             GroupDto.categoryTags: List<String>?
             CriterionDto.categoryTags: List<String>?
                    │
                    ▼
             [template_dao.dart — upsertGroups()]
             JSON-encode → TextColumn → SQLite cached_groups.category_tags
                    │
                    ▼
             [template_dao.dart — getTemplateTree()]
             JSON-decode → List<String>? → GroupDto.categoryTags
```

---

## Execution Slices

### Slice 1: Backend — Entity + DTO Layer (4 files)

**Summary**: Add `CategoryTags` property to `Group` and `Criterion` entities and all 4 DTO/request records.  
**Value**: Enables the backend to persist and return tags. No endpoint behavior changes yet.  
**Entry State**: Migration exists. Entity files have no `CategoryTags` property.  
**Exit State**: Backend compiles. `Group.cs`, `Criterion.cs`, `Dtos.cs`, and `SaveTemplateTree.cs` all have `CategoryTags`.  
**Files**: `Group.cs`, `Criterion.cs`, `Dtos.cs`, `SaveTemplateTree.cs` (**exactly 4**)  
**Complexity**: 🟢 Low

**Acceptance Criteria**:
- `dotnet build server/ --no-restore` exits 0
- `GroupDto` and `CriterionDto` records include `List<string>? CategoryTags`
- `SaveGroupRequest` and `SaveCriterionRequest` records include `List<string>? CategoryTags`
- `SaveTemplateTree.cs` entity write logic assigns `req.CategoryTags` to the entity
- `Criterion.cs` comment updated to list all 9 InputType values (G2 fix)

---

### Slice 2: Backend — Endpoint Projection Layer (2 files)

**Summary**: Wire `CategoryTags` into the LINQ projections for `GetTemplate.cs` (GET tree) and `SyncTemplates.cs` (delta sync).  
**Value**: Clients can now read and sync tags.  
**Entry State**: Slice 1 done. Entities have the property. Endpoints still don't project it.  
**Exit State**: `GET /api/templates/{id}` and `GET /api/sync/templates?since=` include `categoryTags` in response.  
**Files**: `GetTemplate.cs`, `SyncTemplates.cs` (**exactly 2**)  
**Complexity**: 🟢 Low

**Acceptance Criteria**:
- `dotnet build server/ --no-restore` exits 0
- Server integration test TC-CAT-01 through TC-CAT-04 pass
- `SyncGroupDto` includes `List<string>? CategoryTags` and projects `g.CategoryTags`
- `GroupDto` projection in `GetTemplate.cs` includes `g.CategoryTags`
- `CriterionDto` projection in `GetTemplate.cs` includes `c.CategoryTags`

---

### Slice 3: Flutter — DTO + Drift + DAO (4 files)

**Summary**: Add `categoryTags` to Flutter DTOs, Drift table definitions, app_database.dart schema migration, and the DAO read/write paths.  
**Value**: Tags flow end-to-end offline. Synced templates have their tags persisted in SQLite.  
**Entry State**: Slice 2 done. Server sends tags. Flutter discards them (field not mapped).  
**Exit State**: Flutter compiles. Tags persist in SQLite and round-trip correctly through the DAO.  
**Files**: `template_dto.dart`, `tables.dart`, `app_database.dart`, `template_dao.dart` (**exactly 4**)  
**Complexity**: 🟡 Medium (TypeConverter for JSON encoding required)

**Acceptance Criteria**:
- `flutter analyze` shows 0 issues
- `flutter test test/features/templates/` passes
- `GroupDto.categoryTags: List<String>?` in Dart (JSON-decoded from server)
- `CriterionDto.categoryTags: List<String>?` in Dart
- `CachedGroups` has `TextColumn get categoryTags => text().nullable()()` in `tables.dart`
- `CachedCriteria` has `TextColumn get categoryTags => text().nullable()()` in `tables.dart`
- `app_database.dart` schemaVersion == 31 with `from < 31` migration
- DAO upsert passes `categoryTags` as JSON string to Drift companion
- DAO buildTree decodes JSON string back to `List<String>?`
- After `build_runner`, `app_database.g.dart` reflects new table shape

**Type Converter Design**:
```dart
// In template_dao.dart or a shared converter file
List<String>? _decodeTagsFromDb(String? raw) {
  if (raw == null) return null;
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded.cast<String>();
}

String? _encodeTagsForDb(List<String>? tags) {
  if (tags == null || tags.isEmpty) return null;
  return jsonEncode(tags);
}
```

---

### Slice 4: Verification

**Summary**: Run `dotnet test` + `flutter test` globally to confirm no regression.  
**Entry State**: All 3 slices done. `build_runner` has been re-run.  
**Exit State**: All existing tests pass. New ATDD tests pass.  
**Files**: 0 new files  
**Complexity**: 🟢 Low

---

<command_logs>
grep_search: "CategoryTags" in server/ → found in Migrations only (entities/features: 0 results)
grep_search: "CategoryTags" in lib/ → found in app_database.g.dart only (source tables.dart: 0 results)
view_file: Group.cs → no CategoryTags property (30 lines)
view_file: Criterion.cs → no CategoryTags property, stale comment (30 lines)
view_file: Dtos.cs → GroupDto + CriterionDto have no CategoryTags (62 lines)
view_file: SaveTemplateTree.cs lines 1–60 → SaveGroupRequest + SaveCriterionRequest have no CategoryTags
view_file: SyncTemplates.cs → SyncGroupDto + projection: no CategoryTags (95 lines)
view_file: tables.dart → CachedGroups + CachedCriteria: no categoryTags declared (381 lines)
view_file: app_database.dart → schemaVersion = 30 (355 lines)
view_file: template_dto.dart → GroupDto + CriterionDto: no categoryTags (192 lines)
view_file: template_dao.dart → upsertGroups + upsertCriteria: no categoryTags companion field (246 lines)
view_file: app_database.g.dart (lines 690–960) → CachedGroup DOES have `String? categoryTags`
  Conclusion: .g.dart was generated from a tables.dart that HAD categoryTags, but tables.dart was later reverted or the field was never saved. Re-add to tables.dart and re-run build_runner.
</command_logs>

---

## Handoff Block

**Plan location**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-gaps\implementation_plan_20260527_181300_c3563378_audit-template-gaps_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

> [!IMPORTANT]
> Execute ONE slice at a time. Do NOT combine slices.

### Execution Order

- **Slice 1** (Backend Entity + DTO): `@[/atdd]` → write TC-CAT-01, TC-CAT-02 first → then `@[/implement]` with plan path
- **Slice 2** (Backend Endpoint Projection): `@[/atdd]` → write TC-CAT-03, TC-CAT-04 first → then `@[/implement]`
- **Slice 3** (Flutter DTO + Drift + DAO): `@[/atdd]` → write TC-CAT-05 first → then `@[/implement]`
- **Slice 4** (Verification): `@[/verify]` with walkthrough path

> Slices 1 and 2 can be run in the same session by the same agent (they are both backend, sequential dependency). Slice 3 must wait for Slices 1+2 to be verified green first.
