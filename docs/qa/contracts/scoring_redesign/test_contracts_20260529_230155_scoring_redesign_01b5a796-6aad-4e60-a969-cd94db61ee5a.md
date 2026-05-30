# Test Contracts: Scoring Redesign – Slice 1: DB Migration

**Topic**: scoring_redesign  
**Conversation ID**: `01b5a796-6aad-4e60-a969-cd94db61ee5a`  
**Timestamp**: 2026-05-29  

## Input Lineage

- **Epic Plan**: `file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/scoring_redesign/analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Implementation Plan**: `file:///c:/Users/HP/Documents/GitHub/Checkly/docs/architecture/scoring_redesign/implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md`
- **SRE Audit Failure Report**: `file:///c:/Users/HP/Documents/GitHub/Checkly/docs/diagnostics/scoring_redesign/audit_failure_report_20260529_225240_scoring_redesign_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md`

---

## 1. Executive Summary

This document specifies the behavior and database schema criteria for **Slice 1 (Database Migration)** of the Scoring Redesign epic. 
These test contracts are designed as a strict, verifiable set of Gherkin scenarios representing the **Outer Loop** (Acceptance TDD). The Sentinel QA Agent will implement these scenarios as failing integration tests (RED) which the Builder will eventually pass.

---

## 2. Gherkin Scenarios (Acceptance Criteria)

### Scenario 1: `score_direction` Column Existence
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C1`, SRE Audit Discoveries `1`.
- **Gherkin**:
  ```gherkin
  Given the database migrations have been successfully applied
  When the database schema is queried for the "submissions" table
  Then the column "score_direction" must exist
  And its data type must be "text" or "character varying"
  And it must NOT allow NULL values
  ```

### Scenario 2: `category_tag` Column on `templates` Table
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C2`, SRE Audit Discoveries `1`.
- **Gherkin**:
  ```gherkin
  Given the database migrations have been successfully applied
  When the database schema is queried for the "templates" table
  Then the column "category_tag" must exist
  And its data type must be "text" or "character varying"
  And it must NOT allow NULL values
  ```

### Scenario 3: `category_tag` Column on `submissions` Table
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C3`, SRE Audit Discoveries `1`.
- **Gherkin**:
  ```gherkin
  Given the database migrations have been successfully applied
  When the database schema is queried for the "submissions" table
  Then the column "category_tag" must exist
  And its data type must be "text" or "character varying"
  And it must NOT allow NULL values
  ```

### Scenario 4: Old `scoring_mode` Column Safety
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C10`.
- **Gherkin**:
  ```gherkin
  Given the database migrations have been successfully applied
  When the database schema is queried for the "submissions" table
  Then the column "scoring_mode" must still exist
  And it must allow NULL values (to support phased transition)
  ```

### Scenario 5: Single `is_weighted` Column Safety
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C11`.
- **Gherkin**:
  ```gherkin
  Given the database migrations have been successfully applied
  When the database schema is queried for the "submissions" table
  Then there must be exactly one column named "is_weighted"
  ```

### Scenario 6: Composite Index Update on Submissions
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C12`, `C1`.
- **Gherkin**:
  ```gherkin
  Given the database migrations have been successfully applied
  When the database indexes are queried for the "submissions" table
  Then a composite index containing both "template_id" and "score_direction" columns must exist
  And the old composite index containing both "template_id" and "scoring_mode" columns must NOT exist
  ```

### Scenario 7: Backfill Scoring Mode 'penalty'
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C4`, `C13`, SRE Audit Discoveries `2`, `3`.
- **Gherkin**:
  ```gherkin
  Given a legacy submission exists in the database with "scoring_mode" set to "penalty"
  When the database migrations are successfully applied
  Then the submission's "score_direction" must be backfilled to "down"
  And its "is_weighted" must be backfilled to "true"
  And its "category_tag" must be backfilled to "routine"
  ```

### Scenario 8: Backfill Scoring Mode 'checklist'
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C5`, `C13`, SRE Audit Discoveries `2`, `3`.
- **Gherkin**:
  ```gherkin
  Given a legacy submission exists in the database with "scoring_mode" set to "checklist"
  When the database migrations are successfully applied
  Then the submission's "score_direction" must be backfilled to "down"
  And its "is_weighted" must be backfilled to "false"
  And its "category_tag" must be backfilled to "routine"
  ```

### Scenario 9: Backfill Scoring Mode 'accumulation'
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C6`, `C13`, SRE Audit Discoveries `2`, `3`.
- **Gherkin**:
  ```gherkin
  Given a legacy submission exists in the database with "scoring_mode" set to "accumulation"
  When the database migrations are successfully applied
  Then the submission's "score_direction" must be backfilled to "up"
  And its "is_weighted" must be backfilled to "false"
  And its "category_tag" must be backfilled to "routine"
  ```

### Scenario 10: Backfill Scoring Mode 'survey'
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C7`, `C13`, SRE Audit Discoveries `2`, `3`.
- **Gherkin**:
  ```gherkin
  Given a legacy submission exists in the database with "scoring_mode" set to "survey"
  When the database migrations are successfully applied
  Then the submission's "score_direction" must be backfilled to "none"
  And its "is_weighted" must be backfilled to "false"
  And its "category_tag" must be backfilled to "routine"
  ```

### Scenario 11: SQL Backfill Resiliency (SRE Gap-01)
- **Citation**: SRE Audit Discoveries `3`.
- **Gherkin**:
  ```gherkin
  Given a legacy submission exists in the database with an unrecognized or NULL "scoring_mode"
  When the database migrations are successfully applied
  Then the submission's "score_direction" must be backfilled to "down"
  And its "is_weighted" must be backfilled to "false"
  And its "category_tag" must be backfilled to "routine"
  ```

### Scenario 12: Legacy Template Backfill (C8)
- **Citation**: Implementation Plan `SCORING-SLICE1-DB`, Constraint `C8`.
- **Gherkin**:
  ```gherkin
  Given a legacy template exists in the database with no category tag
  When the database migrations are successfully applied
  Then the template's "category_tag" must be backfilled to "routine"
  ```

---

## 3. Gap Analysis Scenarios

To play the Adversary role and prevent SRE incidents, we specify these additional acceptance criteria:

### Scenario 13 (AC-GAP-01): SQL Migration Reversal (Down) Safety
- **Citation**: Orchestration Standards, Gap Analysis.
- **Gherkin**:
  ```gherkin
  Given the database migrations have been successfully applied
  When the database migration is rolled back (Down execution)
  Then the columns "score_direction" and "category_tag" must be completely removed from "submissions" and "templates" tables
  And the original composite index containing "template_id" and "scoring_mode" must be completely restored
  And the new composite index containing "template_id" and "score_direction" must be dropped
  ```

### Scenario 14 (AC-GAP-02): Pre-migration Schema Constraint Integrity
- **Citation**: Orchestration Standards, Gap Analysis.
- **Gherkin**:
  ```gherkin
  Given migrations have not been applied yet
  When a database entity check is run
  Then the application must compile cleanly
  And the existing "checkly_test" schema must match the pre-migration snapshot exactly
  ```

---

## 4. Test Infrastructure Map

### Helper Methods & Schema Access
Integration tests will run raw SQL against `checkly_test` using the database connection provided by EF Core:
- `db.Database.GetDbConnection()`
- `db.Database.ExecuteSqlRawAsync()`
- `db.Database.SqlQueryRaw<T>()`

### Seed Data
During the integration test setup, the database is seeded with legacy records containing the pre-existing structure (`scoring_mode`) to verify the backfill behavior directly.

| Table | seeded fields | expected outcome after migration |
|---|---|---|
| `submissions` | `scoring_mode = 'penalty'` | `score_direction = 'down'`, `is_weighted = true` |
| `submissions` | `scoring_mode = 'checklist'` | `score_direction = 'down'`, `is_weighted = false` |
| `submissions` | `scoring_mode = 'accumulation'` | `score_direction = 'up'`, `is_weighted = false` |
| `submissions` | `scoring_mode = 'survey'` | `score_direction = 'none'`, `is_weighted = false` |
| `submissions` | `scoring_mode = NULL` | `score_direction = 'down'`, `is_weighted = false` |
| `templates` | `title = 'Legacy Template'` | `category_tag = 'routine'` |
