<latent_space_scratchpad>
## Pattern Label
Schema Migration (ADD-BACKFILL-DROP-LATER) — a 3-phase safe migration.

## Key Constraints Extracted
C1. The existing `submissions.scoring_mode` column has a composite index `(template_id, scoring_mode)` — this index must be replaced with `(template_id, score_direction)`.
C2. The existing `ix_submissions_scoring_mode` single-col index must be dropped and replaced.
C3. The `Submission` entity has an `IsWeighted` property that ALREADY EXISTS (line 50) — confirmed in live code. The DB column `is_weighted` may already exist too.
C4. `templates` table does NOT currently have `category_tag` column — confirmed from TemplateConfiguration.cs.
C5. `submissions` table does NOT currently have `score_direction` or `category_tag` — confirmed from SubmissionConfiguration.cs.
C6. Migration naming pattern: `[timestamp]_[PascalCaseName].cs`. Latest: `20260527105201_AddCategoryTagsToGroupsAndCriteria`.
C7. Backfill CASE logic: penalty→down, checklist→down, accumulation→up, survey→none.
C8. `category_tag` default must be `'routine'` for all existing rows.
C9. Blast radius: Analytics files (GetAnalytics.cs, GetBodReport.cs, BodReportCalculator.cs) filter on `s.ScoringMode != "survey"` — these must change to `s.ScoreDirection != "none"` but ONLY in Slice 2. Slice 1 is DB-only.
C10. DO NOT DROP `scoring_mode` column in this migration — add-before-drop pattern. Drop happens in Slice 2 after entity + config update.
C11. `is_weighted` ALREADY EXISTS as a nullable column on the Submission entity (line 50 Submission.cs). Verify if the DB column already exists before adding.

## Confirmed Code Facts
- `Submission.cs:17`: `public string ScoringMode { get; set; } = "penalty";`
- `Submission.cs:50`: `public bool? IsWeighted { get; set; }` — field EXISTS already
- `SubmissionConfiguration.cs:20`: maps `scoring_mode` column
- `SubmissionConfiguration.cs:47`: maps `is_weighted` column — ALREADY MAPPED
- `SubmissionConfiguration.cs:69`: composite index `(template_id, scoring_mode)` — must be replaced
- `TemplateConfiguration.cs`: no `category_tag` mapping — field is genuinely NEW
- `Template.cs`: no `CategoryTag` property — genuinely NEW

## Risk: is_weighted already in DB?
The entity field and EF config mapping both exist, which means `is_weighted` column may already exist in the DB from a previous migration. We MUST use `IF NOT EXISTS` or check the AppDbContextModelSnapshot before adding. Looking at AppDbContextModelSnapshot — the grep showed `scoring_mode` in the snapshot but we need to check if `is_weighted` is also there.

## Out of Scope
- Updating C# entity classes (Slice 2)
- Updating EF config (Slice 2)
- Dropping scoring_mode column (Slice 2)
- Flutter/Dart changes (Slice 3)
- Analytics query updates (Slice 2)
</latent_space_scratchpad>

# Implementation Plan: Scoring Redesign – Slice 1: Database Migration

**Plan ID**: SCORING-SLICE1-DB  
**Created**: 2026-05-29  
**Conversation**: `cdefadc1-bcb6-48a6-b2df-d50ea610949f`  
**Status**: READY FOR ACCEPTANCE TESTS

---

## Input Lineage

- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Key Live Files Read**:
  - `server/Common/Persistence/Entities/Submission.cs` (confirmed: `IsWeighted` already exists on entity, line 50)
  - `server/Common/Persistence/Entities/Template.cs` (confirmed: NO `CategoryTag` property — genuinely new)
  - `server/Common/Persistence/Configurations/SubmissionConfiguration.cs` (confirmed: `is_weighted` already mapped; composite index on `template_id + scoring_mode`)
  - `server/Common/Persistence/Configurations/TemplateConfiguration.cs` (confirmed: NO `category_tag` mapping — genuinely new)
  - `server/Common/Persistence/Migrations/20260318003846_AddScoringModeAndDisplayNoun.cs` (reference pattern for migration style)

---

## Executive Summary & Out of Scope

**Goal**: Add the new DB columns (`score_direction`, `category_tag`) needed by the Two Toggles architecture and backfill all existing rows from the old `scoring_mode` string. This is a pure database change — no application code changes.

**Add-Before-Drop Strategy**:
1. ADD new columns (nullable to avoid migration failure on existing rows)
2. BACKFILL with CASE logic
3. ALTER to NOT NULL (after all rows are filled)
4. Replace indexes
5. NEVER drop `scoring_mode` in this migration — the column stays until the entity + config are updated in Slice 2

### Out of Scope (YAGNI)
- ❌ Dropping `scoring_mode` column (Slice 2)
- ❌ Deleting old C# properties (Slice 2)
- ❌ Flutter / Drift / SQLite changes (Slice 3)
- ❌ Analytics query updates (Slice 2)
- ❌ `category_tag` whitelist validation (Slice 4)

> [!IMPORTANT]
> **SRE AUDIT CORRECTION**: C# entity additions (properties only) and mapping configurations are **IN SCOPE** for Slice 1. If we do not add these properties to the C# models, the `dotnet ef migrations add` CLI command will generate a completely empty migration file.

---

## System Context

| Constraint | Detail |
|------------|--------|
| Database | PostgreSQL via EF Core on `checkly` (prod) and `checkly_test` (integration tests) |
| Migration system | EF Core Migrations (`dotnet ef migrations add`, `dotnet ef database update`) |
| Test database | `checkly_test` — already exists natively, auto-migrated by `TestWebApplicationFactory` |
| Online/Offline | Server-only slice. Flutter not touched. |
| RBAC | No permission changes. |
| `is_weighted` status | Column ALREADY EXISTS on `submissions` table (entity + config both mapped). Do NOT add again. |

---

## Lifecycle Context

| State | Behavior |
|-------|----------|
| Success | All rows in `submissions` have `score_direction` and `is_weighted` populated correctly. All rows in `templates` have `category_tag = 'routine'`. |
| Error | Migration fails if columns are added as NOT NULL without a default. **Fix**: add nullable first, backfill, then set NOT NULL. |
| Empty | New DB with no rows — backfill SQL runs cleanly (0 rows updated, no error). |
| Rollback | `Down()` method drops the new columns and restores original indexes. |

---

## Constraint Traceability

| Constraint ID | Source (Epic) | Constraint | Mapped Test Contract |
|---|---|---|---|
| C1 | Epic: DB Schema | `score_direction` added to `submissions` | TC-01 |
| C2 | Epic: DB Schema | `category_tag` added to `templates` | TC-02 |
| C3 | Epic: Denormalization | `category_tag` added to `submissions` | TC-03 |
| C4 | Epic: Backfill Logic | `penalty` → `score_direction = 'down'` | TC-04 |
| C5 | Epic: Backfill Logic | `checklist` → `score_direction = 'down'` | TC-05 |
| C6 | Epic: Backfill Logic | `accumulation` → `score_direction = 'up'` | TC-06 |
| C7 | Epic: Backfill Logic | `survey` → `score_direction = 'none'` | TC-07 |
| C8 | Epic: Migration | No NULL `score_direction` after migration | TC-08 |
| C9 | Epic: Migration | Default `category_tag = 'routine'` for existing rows | TC-09 |
| C10 | Safety | Old `scoring_mode` column must NOT be dropped | TC-10 |
| C11 | Safety | `is_weighted` column NOT added again (already exists) | TC-11 |
| C12 | Performance | Composite index `(template_id, score_direction)` created | TC-12 |
| C13 | Safety (SRE) | `is_weighted` backfilled to `true` for penalty rows | TC-13 |
| C14 | Safety (SRE) | SQL CASE contains fallback `ELSE` to prevent NULLs | TC-14 |

---

## Test Contracts

### TC-01: `score_direction` column exists on `submissions`
- **Type**: Integration (DB schema assertion)
- **State**: After migration runs
- **Fail Scenario**: Column missing → EF query on new field crashes
- **SQL to verify**: `SELECT column_name FROM information_schema.columns WHERE table_name='submissions' AND column_name='score_direction';`

### TC-02: `category_tag` column exists on `templates`
- **Type**: Integration (DB schema assertion)
- **State**: After migration runs
- **Fail Scenario**: Column missing → template save crashes on new field

### TC-03: `category_tag` column exists on `submissions`
- **Type**: Integration (DB schema assertion)
- **State**: After migration runs
- **Fail Scenario**: Column missing → analytics join fails silently

### TC-04–07: Backfill correctness (per old scoring_mode value)
- **Type**: Integration (data assertion)
- **State**: After migration on test DB with seeded rows
- **Fixture**: 4 submissions pre-seeded with `scoring_mode = 'penalty'/'checklist'/'accumulation'/'survey'`
- **Assertions**:
  - `penalty` row → `score_direction = 'down'` and `is_weighted = true` (SRE fix)
  - `checklist` row → `score_direction = 'down'` and `is_weighted = false` (SRE fix)
  - `accumulation` row → `score_direction = 'up'` and `is_weighted = false`
  - `survey` row → `score_direction = 'none'` and `is_weighted = false`

### TC-08: No NULL `score_direction` after migration
- **Type**: Integration (NULL audit)
- **SQL**: `SELECT COUNT(*) FROM submissions WHERE score_direction IS NULL;` → must return 0

### TC-09: `category_tag = 'routine'` for all existing rows
- **Type**: Integration (NULL audit)
- **SQL**: `SELECT COUNT(*) FROM templates WHERE category_tag IS NULL OR category_tag != 'routine';` → 0 for pre-migration rows

### TC-10: `scoring_mode` column still exists
- **Type**: Integration (schema safety)
- **SQL**: `SELECT column_name FROM information_schema.columns WHERE table_name='submissions' AND column_name='scoring_mode';` → must return 1 row

### TC-11: `is_weighted` column not duplicated
- **Type**: Integration (schema safety)
- **SQL**: `SELECT COUNT(*) FROM information_schema.columns WHERE table_name='submissions' AND column_name='is_weighted';` → must return exactly 1

### TC-12: Composite index `(template_id, score_direction)` exists
- **Type**: Integration (schema assertion)
- **SQL**: `SELECT indexname FROM pg_indexes WHERE tablename='submissions' AND indexdef LIKE '%score_direction%';` → must return 1 row

---

## Test Fixture & Payloads

### Required Fixture State (for integration test)
The `TestWebApplicationFactory` auto-migrates `checkly_test` on startup. The integration test must:
1. Seed 4 submissions directly into DB with `scoring_mode` values: `'penalty'`, `'checklist'`, `'accumulation'`, `'survey'`.
2. Run schema assertions AFTER `TestWebApplicationFactory` has started (migration auto-applies).
3. Assert data correctness by querying `checkly_test.submissions`.

### No JSON payloads needed — this is a schema-only slice (no API changes).

---

## Tools & Commands

| Tool | Purpose |
|------|---------|
| `dotnet ef migrations add [Name] --project server` | Generate the migration file scaffolding |
| `rtk dotnet build server` | Verify migration compiles |
| `rtk dotnet test server/tests/Checkly.Api.Tests` | Run integration tests to validate migration |

**Skills needed**: `ef-core`, `testing-strategy`

---

## Concept Diagram

```text
[C# Entities updated with new properties]
        |
        v
[dotnet ef migrations add ...]
        |
        v
[Migration: Up()]
        |
        +-- ADD COLUMN: submissions.score_direction (nullable, text)
        +-- ADD COLUMN: submissions.category_tag (nullable, text)
        +-- ADD COLUMN: templates.category_tag (nullable, text)
        |
        v
[SQL Backfill (Safe CASE + ELSE + is_weighted)]
        |
        +-- UPDATE submissions SET score_direction = CASE scoring_mode
        |     WHEN 'accumulation' THEN 'up'
        |     WHEN 'survey'       THEN 'none'
        |     ELSE 'down'
        |   END
        +-- UPDATE submissions SET is_weighted = (scoring_mode = 'penalty')
        +-- UPDATE submissions SET category_tag = 'routine'
        +-- UPDATE templates  SET category_tag = 'routine'
        |
        v
[ALTER COLUMN: make NOT NULL]
        |
        +-- ALTER submissions.score_direction NOT NULL
        +-- ALTER submissions.category_tag NOT NULL
        +-- ALTER templates.category_tag NOT NULL
        |
        v
[Index Management]
        |
        +-- DROP old composite index (template_id, scoring_mode)
        +-- CREATE new composite index (template_id, score_direction)
```

---

## Proposed Changes

| Order | Action | File | Notes |
|-------|--------|------|-------|
| 1 | [MOD] | `server/Common/Persistence/Entities/Template.cs` | Add `public string CategoryTag { get; set; } = "routine";` |
| 2 | [MOD] | `server/Common/Persistence/Entities/Submission.cs` | Add `public string ScoreDirection { get; set; } = "down";` and `public string CategoryTag { get; set; } = "routine";` |
| 3 | [MOD] | `server/Common/Persistence/Configurations/TemplateConfiguration.cs` | Configure `category_tag` column mapping |
| 4 | [MOD] | `server/Common/Persistence/Configurations/SubmissionConfiguration.cs` | Configure `score_direction` and `category_tag` mappings. Update composite index from `(TemplateId, ScoringMode)` to `(TemplateId, ScoreDirection)`. |
| 5 | [NEW] | `server/Common/Persistence/Migrations/[Timestamp]_AddScoringDirectionAndCategoryTag.cs` | EF migration with nullable additions, backfill SQL, NOT NULL alter, and index updates |
| 6 | [MOD] | `server/Common/Persistence/Migrations/AppDbContextModelSnapshot.cs` | Auto-updated by `dotnet ef` CLI — do NOT hand-edit |

---

## Execution Slices

### Slice A — C# Entity Properties & Mapping Configurations
**Complexity**: Low  
**Scope**: Add new properties to C# models and mapping configurations so EF Core CLI can scaffold correctly.  
**Acceptance Criteria**:
1. `Template.cs` has `CategoryTag` property.
2. `Submission.cs` has `ScoreDirection` and `CategoryTag` properties.
3. `TemplateConfiguration.cs` maps `category_tag` column.
4. `SubmissionConfiguration.cs` maps `score_direction` and `category_tag` columns.
5. Composite index in `SubmissionConfiguration.cs` updated from `(x.TemplateId, x.ScoringMode)` to `(x.TemplateId, x.ScoreDirection)`.

### Slice B — Schema Migration & Backfill
**Complexity**: Medium  
**Scope**: Scaffold and implement migration containing column additions, SQL backfill, NOT NULL constraints, and index updates.  
**Acceptance Criteria**:
1. Migration runs and applies successfully.
2. `submissions.score_direction` is NOT NULL and correctly backfilled (`penalty`/`checklist` → `'down'`, `accumulation` → `'up'`, `survey` → `'none'`, defaults to `'down'`).
3. `submissions.is_weighted` is backfilled (`penalty` → `true`, others → `false`).
4. `templates.category_tag` and `submissions.category_tag` are NOT NULL and backfilled to `'routine'`.
5. Old composite index `(template_id, scoring_mode)` is dropped.
6. New composite index `(template_id, score_direction)` is created.
7. Old `scoring_mode` column is preserved.
8. No duplicate `is_weighted` column is added.

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Migration adds `is_weighted` column that already exists | HIGH | Do NOT add `is_weighted`. Only add `score_direction` and `category_tag`. Verified: column already mapped in `SubmissionConfiguration.cs:47`. |
| Backfill runs against NULL `scoring_mode` rows | MEDIUM | Wrap CASE with `COALESCE(..., 'penalty')` to default any NULLs to `'down'`. |
| ALTER COLUMN NOT NULL fails if backfill missed a row | HIGH | Run NULL count assertion before applying NOT NULL constraint. Use two separate `Sql()` calls. |
| Drop of old `(template_id, scoring_mode)` index breaks running analytics | MEDIUM | Drop the OLD index in `Down()` only. `Up()` adds new index BEFORE dropping old to maintain coverage. |
| Hand-editing `AppDbContextModelSnapshot.cs` | HIGH | **Never hand-edit.** Run `dotnet ef migrations add` and let EF regenerate it. |

## Verification Plan

Run all checks in order after `dotnet ef database update` on `checkly_test`:

```sql
-- TC-01: score_direction column exists
SELECT column_name FROM information_schema.columns
WHERE table_name='submissions' AND column_name='score_direction';
-- Expected: 1 row

-- TC-02: category_tag on templates
SELECT column_name FROM information_schema.columns
WHERE table_name='templates' AND column_name='category_tag';
-- Expected: 1 row

-- TC-03: category_tag on submissions
SELECT column_name FROM information_schema.columns
WHERE table_name='submissions' AND column_name='category_tag';
-- Expected: 1 row

-- TC-08: No NULLs in score_direction
SELECT COUNT(*) FROM submissions WHERE score_direction IS NULL;
-- Expected: 0

-- TC-09: All templates have category_tag = 'routine'
SELECT COUNT(*) FROM templates WHERE category_tag IS NULL;
-- Expected: 0

-- TC-10: scoring_mode still present (not dropped)
SELECT column_name FROM information_schema.columns
WHERE table_name='submissions' AND column_name='scoring_mode';
-- Expected: 1 row

-- TC-11: is_weighted not duplicated
SELECT COUNT(*) FROM information_schema.columns
WHERE table_name='submissions' AND column_name='is_weighted';
-- Expected: exactly 1

-- TC-12: New composite index exists
SELECT indexname FROM pg_indexes
WHERE tablename='submissions' AND indexdef LIKE '%score_direction%';
-- Expected: 1 row
```

**Build verification command**:
```
rtk dotnet build server
rtk dotnet test server/tests/Checkly.Api.Tests
```


- grep_search: scoring_mode in server/ — found 50+ Designer.cs references + live migration files
- grep_search: class Submission in server/ — found Submission.cs at Entities/Submission.cs
- view_file: Submission.cs — confirmed IsWeighted already exists (line 50), ScoringMode exists (line 17)
- view_file: Template.cs — confirmed NO CategoryTag property
- view_file: SubmissionConfiguration.cs — confirmed is_weighted already mapped (line 47); composite index (template_id, scoring_mode) on line 69
- view_file: TemplateConfiguration.cs — confirmed NO category_tag mapping
- view_file: AddScoringModeAndDisplayNoun.cs — learned migration pattern (AddColumn + Sql backfill + CreateIndex)
- view_file: Dtos.cs — confirmed ScoringMode in SubmissionDto and SubmissionDetailDto
- view_file: CreateSubmission.cs:245–270 — confirmed ScoringMode written to submission on create
- grep_search: ScoringMode in Features/ — found 28 references across Analytics, Submissions endpoints
- grep_search: 20260527 in Migrations/ — confirmed latest migration timestamp
</command_logs>

---

## Handoff Block

**Plan path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md`

**Task tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\scoring_redesign\task_20260529_224412_slice1_db_migration_cdefadc1.md`

### Action Sequence (Execute ONE at a time)

1. **Slice A** [Route 3 — Acceptance Tests First]:
   - Step 1: QA writes failing integration tests (TC-01 → TC-12) using the fixture pattern above.
   - Step 2: Builder runs `dotnet ef migrations add AddScoringDirectionAndCategoryTag --project server` to scaffold.
   - Step 3: Builder fills in `Up()` and `Down()` per the plan diagram.
   - Step 4: Builder runs `rtk dotnet test server/tests/Checkly.Api.Tests` to verify GREEN.

2. **Slice B** [Route 3 — included in same acceptance tests]:
   - TC-10 and TC-11 are schema safety assertions — already in the test file from Slice A.

> ⚠️ **Do NOT begin Slice 2 (Backend Parser)** until `dotnet test` passes GREEN for all 12 test contracts above.

### Key Risk Reminder
> `is_weighted` is ALREADY mapped in `SubmissionConfiguration.cs`. **DO NOT add `AddColumn<bool>("is_weighted", ...)` to the migration.** The column already exists in the DB. Only add `score_direction`, `category_tag` (on both tables).
