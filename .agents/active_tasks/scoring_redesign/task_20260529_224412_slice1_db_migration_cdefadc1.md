# Task: Scoring Redesign – Slice 1: DB Migration | Workflow: /analyze-feature | Track: B (Route 3)

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md`

## 📋 Status Checklist

### Phase 1: Planning & Setup
- [x] Step 1: Pre-Flight checks (loaded `GEMINI.md` and context)
- [x] Step 2: Search & Scope (verified C# models and SQLite configurations)
- [x] Step 3: Impacts & States (mapped existing data transitions and schema)
- [x] Step 4: Plan (written robust implementation plan with backfill logic)
- [x] Step 5: Route (selected Route 3 - Acceptance Tests First)

### Phase 2: Slice A — C# Entity Properties & Mapping Configurations
- [x] Step A-1: Define QA Acceptance tests (TC-01 to TC-12) to verify schema, index, and data backfill
- [x] Step A-2: Add `CategoryTag` to `Template.cs`
- [x] Step A-3: Add `ScoreDirection` and `CategoryTag` to `Submission.cs`
- [x] Step A-4: Map `category_tag` column in `TemplateConfiguration.cs`
- [x] Step A-5: Map `score_direction` and `category_tag` columns in `SubmissionConfiguration.cs`
- [x] Step A-6: Update composite index mapping in `SubmissionConfiguration.cs` to use `(template_id, score_direction)`

### Phase 3: Slice B — Schema Migration & Backfill
- [x] Step B-1: Run `rtk dotnet ef migrations add AddScoringDirectionAndCategoryTag --project server` to scaffold the migration file
- [x] Step B-2: Implement migration `Up()` logic containing custom SQL statements to add columns, backfill values, set NOT NULL constraints, drop the old composite index, and create the new composite index
- [x] Step B-3: Implement migration `Down()` logic to gracefully revert new columns and restore the old composite index
- [x] Step B-4: Run `rtk dotnet build server` to verify compilation passes with zero warnings/errors
- [x] Step B-5: Run `rtk dotnet test server/tests/Checkly.Api.Tests` and confirm all acceptance tests pass successfully (GREEN)

---

## Artifact Inventory

| Status | File Path | Type |
|--------|-----------|------|
| [DONE] | `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260529_224412_slice1_db_migration_cdefadc1.md` | Implementation Plan |
| [DONE] | `C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ScoringRedesignSlice1Tests.cs` | Acceptance Tests |
| [DONE] | `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\scoring_redesign\walkthrough_20260529_231500_slice1_db_migration_f3d0903d.md` | Walkthrough |
| [DONE] | `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\scoring_redesign\green_test_log_20260529_231500_slice1_db_migration_f3d0903d.md` | Test Log |
