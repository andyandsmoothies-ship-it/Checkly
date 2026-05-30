# SRE Audit Failure Report: Scoring Redesign Slice 1 (DB Migration)

**Topic**: scoring_redesign  
**Conversation ID**: `ac4575e5-39d8-4b20-a4a6-49ce53ce5264`  
**Timestamp**: 2026-05-29  
**Source Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md`

## Overview & Verdict

**Audit Verdict**: `Fatal`

The provided implementation plan contains a fundamental misunderstanding of how Entity Framework Core (Code-First) migrations operate, which will result in an empty migration file. Furthermore, the plan accidentally drops a critical data backfill step, which would silently corrupt the scoring calculations for all existing audits in the production database.

These flops must be corrected in the plan before any code is generated.

---

## Discovered Flops

### 1. `🔴 Critical`: EF Core Empty Migration Failure
*   **The Flop**: The plan explicitly states: "Out of scope: C# entity class changes... The EF migration is auto-updated by `dotnet ef`". It instructs the Builder to run `dotnet ef migrations add` WITHOUT modifying the C# Entity classes (`Submission.cs`, `Template.cs`) or their Configuration classes.
*   **The Reality**: EF Core Code-First generates migrations by comparing the *current C# model* against the *Snapshot*. If the C# entities are not updated with `ScoreDirection` and `CategoryTag`, EF Core assumes no schema changes are needed and will generate a completely empty `Up()` and `Down()` method. 
*   **Action Required**: Move the C# Entity additions (properties only) and `IEntityTypeConfiguration` mapping additions into **Slice 1**. The removal of old properties can remain in Slice 2, but the *additions* must be present before running the CLI command.

### 2. `🔴 Critical`: Missing `is_weighted` Data Backfill
*   **The Flop**: The plan correctly notes that the `is_weighted` column already exists in the database and should not be added via `AddColumn`. However, it mistakenly removed the SQL `UPDATE` statement needed to backfill its values. 
*   **The Reality**: Existing database rows likely have `is_weighted = NULL` or `false` because they relied on `scoring_mode = 'penalty'`. If we do not explicitly update `is_weighted = true` for all penalty rows, all legacy penalty audits will become unweighted. When the scoring engine runs, it will calculate radically incorrect scores (0% deductions instead of weighted percentages).
*   **Action Required**: Re-insert the SQL backfill for `is_weighted` into the Slice 1 implementation plan:
    ```sql
    UPDATE submissions SET is_weighted = CASE scoring_mode 
      WHEN 'penalty' THEN true 
      ELSE false 
    END;
    ```

### 3. `🟡 Warning`: Unsafe SQL CASE Statement (Null Risk)
*   **The Flop**: The Risk Assessment section mentions that existing `scoring_mode` rows might be NULL, but the proposed SQL `CASE` statement in the Concept Diagram does not include an `ELSE` clause.
*   **The Reality**: If the `CASE` statement encounters a NULL or unrecognized string, it will return NULL. The plan subsequently tries to run `ALTER COLUMN ... NOT NULL`. If even one row evaluated to NULL, the entire migration will crash on production and rollback.
*   **Action Required**: Ensure the SQL backfill contains a definitive fallback:
    ```sql
    UPDATE submissions SET score_direction = CASE scoring_mode
      WHEN 'accumulation' THEN 'up'
      WHEN 'survey' THEN 'none'
      ELSE 'down' -- Safely captures penalty, checklist, and NULLs
    END;
    ```

---

## Handoff Block
- **Audit Verdict**: `Fatal`
- **Next Steps**: The Builder must update the Slice 1 Implementation Plan to include adding the new properties to the C# Entities (`Submission.cs`, `Template.cs`) so the EF Core CLI works correctly. They must also add the `is_weighted` UPDATE statement and the `ELSE` fallback to the SQL backfill logic before running the migration.
