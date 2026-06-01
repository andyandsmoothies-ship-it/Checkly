# Test Cases: BOD Live Queries Slice 2 (Database Schema Optimization)

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice2_20260601_152500.md`

---

## 1. Acceptance Criteria Test Cases

| Test Case ID | Scenario | Given | When | Then |
|--------------|----------|-------|------|------|
| **TC-IDX-01** | Submissions Index A | The submissions entity configuration is loaded | Registering indexes in EF Core AppDbContext | It contains a non-unique composite index on `(Status, CompletedAt DESC)` |
| **TC-IDX-02** | Submissions Index B | The submissions entity configuration is loaded | Registering indexes in EF Core AppDbContext | It contains a non-unique composite index on `(Status, StoreId, CompletedAt)` |
| **TC-IDX-03** | Section Scores Index C | The submission_section_scores configuration is loaded | Registering indexes in EF Core AppDbContext | It contains a non-unique composite index on `(CreatedAt, StoreId)` |
| **TC-IDX-04** | Action Plans Index D | The action_plans configuration is loaded | Registering indexes in EF Core AppDbContext | It contains a non-unique composite index on `(Status, Deadline)` |
| **TC-IDX-05** | Postgres Catalog Integrity | The database is updated to the latest migration | Querying pg_catalog tables inside `checkly_test` | All 4 physical composite indexes exist on disk with correct columns and directions |
