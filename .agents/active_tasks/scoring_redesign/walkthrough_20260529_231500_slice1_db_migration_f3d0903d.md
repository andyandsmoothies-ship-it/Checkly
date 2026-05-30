# Walkthrough: Scoring Redesign – Slice 1: DB Migration

## Input Lineage
- **Source Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md`
- **Failing Tests (Contract)**: `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringRedesignSlice1Tests.cs`

---

## Decision Log

### 1. Multi-Phase Safe Database Migration (Add-Before-Drop)
- **Proposed**: Add columns directly, then backfill.
- **Implemented**: To ensure existing data is not corrupted or filled with incorrect defaults, we added `score_direction` as a nullable column first. Then, we executed custom SQL backfills to correctly map legacy data based on the historical `scoring_mode` values:
  - `accumulation` $\rightarrow$ `'up'`
  - `survey` $\rightarrow$ `'none'`
  - `penalty`/`checklist`/null $\rightarrow$ `'down'`
- After executing the backfill, we modified the column to be `NOT NULL` with a default constraint of `'down'`. This is a highly robust migration pattern for production databases.

### 2. Nullable Fields for Extensibility
- We mapped `category_tag` in `templates` and `submissions` as nullable `text` columns. We backfilled their existing records with `'routine'` to maintain consistent baseline data across all audits.

### 3. Composite Index Replacement
- Replaced the deprecated composite index on `(template_id, scoring_mode)` with a highly efficient composite index on `(template_id, score_direction)` on the `submissions` table.

---

## Verification Handoff

### Steps for QA Verification:
1. Ensure the PostgreSQL schema contains the new columns:
   - `templates.category_tag` (nullable text)
   - `submissions.category_tag` (nullable text)
   - `submissions.score_direction` (non-nullable varchar(20), default 'down')
2. Verify that existing records successfully mapped to their new values based on the logic:
   - Accumulation submissions $\rightarrow$ `'up'`
   - Survey submissions $\rightarrow$ `'none'`
   - Penalty & Checklist submissions $\rightarrow$ `'down'`
   - Existing template and submission category tags $\rightarrow$ `'routine'`

---

## Test Trace
Below is the raw execution output from the global test suite filter for the Scoring Redesign:

```
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ok dotnet test: 5 tests passed, 0 warnings in 1 projects (4.4 s)
```

---

## Forensic Evidence
The following validation commands were run and executed successfully:
```cmd
rtk dotnet build server
rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~ScoringRedesign"
```

---

## Gotcha Protocol
We added the following rule to `server/GEMINI.md`:
* **Gotcha: Safe Non-Nullable Column Migration & Backfill**: When adding a new non-nullable column (like `score_direction`) to an existing database with production data, adding it directly as non-nullable in the migration step can cause issues or fill with a generic default.
  * **Fix**: Always add the column as `nullable: true` first, execute custom SQL to backfill values based on existing states (e.g., mapping `scoring_mode` using CASE), and then alter the column to `nullable: false` with its final default value constraint. This guarantees historical correctness and zero data corruption.
