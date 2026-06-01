# Test Log: BOD Live Queries Slice 2 (Database Schema Optimization)

---

## 1. Run Metadata
- **Date**: 2026-06-01
- **Target Suite**: `Checkly.Api.Tests.Features.Analytics.BodLiveQueries_Slice2_Tests`
- **Execution Command**: `rtk dotnet test --filter FullyQualifiedName~BodLiveQueries_Slice2_Tests`
- **Environment**: Local PostgreSQL `checkly_test` Database with automatic migrations on startup

---

## 2. Test Execution Summary

| Test Case Name | Status | Duration | Assertion Verified |
| :--- | :--- | :--- | :--- |
| `VerifyEfCoreModel_SubmissionsIndexes_ExistAndAreNonUnique` | **PASSED** | 5 ms | EF metadata maps non-unique index `{ Status, CompletedAt DESC }` and `{ Status, StoreId, CompletedAt }` |
| `VerifyEfCoreModel_SubmissionSectionScoresIndex_ExistsAndIsNonUnique` | **PASSED** | < 1 ms | EF metadata maps non-unique index `{ CreatedAt, StoreId }` |
| `VerifyEfCoreModel_ActionPlansIndex_ExistsAndIsNonUnique` | **PASSED** | < 1 ms | EF metadata maps non-unique index `{ Status, Deadline }` |
| `VerifyPostgresCatalog_IndexesExist` | **PASSED** | 22 ms | Physical schema contains `IX_submissions_status_completed_at` (DESC), `IX_submissions_status_store_id_completed_at`, `IX_submission_section_scores_created_at_store_id`, and `IX_action_plans_status_deadline` |

---

## 3. Command Output Detail
```text
  Determining projects to restore...
  All projects are up-to-date for restore.
  Checkly.Api -> C:\Users\HP\Documents\GitHub\Checkly\server\bin\Debug\net10.0\Checkly.Api.dll
  Checkly.Api.Tests -> C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:     4, Skipped:     0, Total:     4, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
```

---

## 4. Diagnostics & Trace Insights
- Automatic migrations ran on execution, applying the `AddBodLiveQueryIndexes` migration successfully to the test database prior to catalog querying.
- The `IDesignTimeModel` query resolved the metadata runtime limitations, confirming that EF correctly flags the `CompletedAt` property on `IX_submissions_status_completed_at` as a descending index column.
