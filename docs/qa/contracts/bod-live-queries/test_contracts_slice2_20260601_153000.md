# Test Contracts: BOD Live Queries Slice 2 (Database Schema Optimization)

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice2_20260601_152500.md`

---

## 1. Acceptance Criteria & Gherkin Scenarios

### Scenario 1: Submissions Table Optimization
**Description:** Verifies that the EF Core configuration mapping is set up to register two non-unique composite indexes on the `submissions` table:
1. Index on `{ Status, CompletedAt }` where `CompletedAt` is descending.
2. Index on `{ Status, StoreId, CompletedAt }`.

```gherkin
Given the submissions entity configuration
When registering the database indexes in the EF Core AppDbContext
Then it should contain a composite index on { Status, CompletedAt }
And the "CompletedAt" column index direction should be set to DESC
And the index should be configured as non-unique
And it should contain a composite index on { Status, StoreId, CompletedAt }
And the index should be configured as non-unique
```

---

### Scenario 2: Submission Section Scores Table Optimization
**Description:** Verifies that the EF Core configuration mapping is set up to register a non-unique composite index on the `submission_section_scores` table for `{ CreatedAt, StoreId }`.

```gherkin
Given the submission section scores entity configuration
When registering the database indexes in the EF Core AppDbContext
Then it should contain a composite index on { CreatedAt, StoreId }
And the index should be configured as non-unique
```

---

### Scenario 3: Action Plans Table Optimization
**Description:** Verifies that the EF Core configuration mapping is set up to register a non-unique composite index on the `action_plans` table for `{ Status, Deadline }`.

```gherkin
Given the action plans entity configuration
When registering the database indexes in the EF Core AppDbContext
Then it should contain a composite index on { Status, Deadline }
And the index should be configured as non-unique
```

---

### Scenario 4: PostgreSQL Physical Database Catalog Integrity
**Description:** Verifies that the generated EF Core migrations correctly create physical database indexes with the specified sorting and column orders inside the PostgreSQL system catalogs.

```gherkin
Given the database is updated to the latest migration
When querying the PostgreSQL system catalogs ("pg_class", "pg_index", "pg_indexes")
Then there should exist a physical index on "submissions" containing "status" and "completed_at DESC"
And there should exist a physical index on "submissions" containing "status", "store_id", and "completed_at"
And there should exist a physical index on "submission_section_scores" containing "created_at" and "store_id"
And there should exist a physical index on "action_plans" containing "status" and "deadline"
```

---

## 2. Test Infrastructure Map

### Target Database Columns
- `submissions.Status`
- `submissions.CompletedAt`
- `submissions.StoreId`
- `submission_section_scores.CreatedAt`
- `submission_section_scores.StoreId`
- `action_plans.Status`
- `action_plans.Deadline`

### Verification SQL Query
```sql
SELECT 
    t.relname AS table_name,
    i.relname AS index_name,
    pg_get_indexdef(ix.indexrelid) AS index_def
FROM pg_class t
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
WHERE t.relname IN ('submissions', 'submission_section_scores', 'action_plans');
```
