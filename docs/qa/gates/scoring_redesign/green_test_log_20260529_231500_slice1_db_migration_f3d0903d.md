# Test Log: Scoring Redesign – Slice 1: DB Migration

- **Date of Run**: 2026-05-29
- **Environment**: Local PostgreSQL (`checkly_test` database)
- **Suite**: `Checkly.Api.Tests`
- **Result**: ✅ **GREEN (5/5 Passed)**

## Run Configurations
```cmd
rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~ScoringRedesign"
```

## Raw Test Results
```text
Passed!  - Failed:     0, Passed:     5, Skipped:     0, Total:     5, Duration: 4.4 s
```

## Detailed Test Breakdown

| Test ID | Test Method Name | Description | Status |
|---|---|---|---|
| **TC_SL1_01** | `TC_SL1_01_DbSchema_HasScoreDirectionColumn` | Verifies `score_direction` column of type `character varying(20)` exists in `submissions`. | ✅ Passed |
| **TC_SL1_02** | `TC_SL1_02_DbSchema_HasCategoryTagColumns` | Verifies `category_tag` column exists in both `templates` and `submissions`. | ✅ Passed |
| **TC_SL1_03** | `TC_SL1_03_DbSchema_CompositeIndexExists` | Verifies old `(template_id, scoring_mode)` index is dropped and new `(template_id, score_direction)` index is created. | ✅ Passed |
| **TC_SL1_04** | `TC_SL1_04_DbSchema_DefaultValuesAndNullability` | Verifies default value for `score_direction` is 'down', and nullabilities are correct. | ✅ Passed |
| **TC_SL1_05** | `TC_SL1_05_DbSchema_BackfillCorrectness` | Verifies that Entity Framework Model mapping configurations perfectly match expected Db schema. | ✅ Passed |
