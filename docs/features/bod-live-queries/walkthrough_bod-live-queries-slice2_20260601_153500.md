# Walkthrough: BOD Live Queries Slice 2 (Database Schema Optimization)

---

## 1. Executive Summary
This walkthrough documents the successful implementation of **Slice 2 (Database Schema Optimization)** for the Boardroom Analytics Live Queries epic. High-efficiency PostgreSQL composite indices were introduced across three critical tables (`submissions`, `submission_section_scores`, and `action_plans`) to eliminate sequential table scans and optimize dynamic analytics performance. 

Additionally, the EF Core ATDD metadata verification tests were updated to use `IDesignTimeModel` to ensure resilient execution across both runtime-optimized and design-time EF contexts. All verification tests pass cleanly.

---

## 2. Structural & Architectural Design
To support real-time boardroom calculations without a background-calculated cache, we designed and registered four composite indexes:

```
[submissions]                     --> { status, completed_at DESC }
                                  --> { status, store_id, completed_at }
[submission_section_scores]       --> { created_at, store_id }
[action_plans]                    --> { status, deadline }
```

### Purpose of Each Index:
1. **`IX_submissions_status_completed_at` (CompletedAt DESC)**: 
   Optimizes time-based queries filtering by status (e.g. `Completed`) and sorting descending by completion date (e.g. dynamic rolling period checks, KPI scores).
2. **`IX_submissions_status_store_id_completed_at`**: 
   Supports multi-dimensional grouping and filtering by status, store, and date range for leaderboard sorting.
3. **`IX_submission_section_scores_created_at_store_id`**: 
   Optimizes category weakness queries scanning section scores within the past 90 days and grouping by store.
4. **`IX_action_plans_status_deadline`**: 
   Allows instant O(log N) lookup and counting of open overdue action plans.

---

## 3. Implementation Details

### Configuration Modifications
We registered the composite indexes in the EF Core configurations:
- **`SubmissionConfiguration.cs`**:
  ```csharp
  e.HasIndex(x => new { x.Status, x.CompletedAt }).IsDescending(false, true);
  e.HasIndex(x => new { x.Status, x.StoreId, x.CompletedAt });
  ```
- **`SubmissionSectionScoreConfiguration.cs`**:
  ```csharp
  e.HasIndex(x => new { x.CreatedAt, x.StoreId });
  ```
- **`ActionPlanConfiguration.cs`**:
  ```csharp
  e.HasIndex(x => new { x.Status, x.Deadline });
  ```

### Database Migration
The EF Core migration `AddBodLiveQueryIndexes` was generated to create physical indexes inside PostgreSQL:
```csharp
migrationBuilder.CreateIndex(
    name: "IX_submissions_status_completed_at",
    table: "submissions",
    columns: new[] { "status", "completed_at" },
    descending: new[] { false, true });
```

### Resilient Test Assertions
To verify the `IsDescending` metadata of index columns at runtime, the ATDD test suite was updated to query the design-time metadata model via `IDesignTimeModel` to bypass runtime model optimization checks:
```csharp
var model = db.GetService<Microsoft.EntityFrameworkCore.Metadata.IDesignTimeModel>().Model;
```

---

## 4. Verification Results
All 4 ATDD tests passed successfully under `checkly_test`:
- `VerifyEfCoreModel_SubmissionsIndexes_ExistAndAreNonUnique` - **PASSED**
- `VerifyEfCoreModel_SubmissionSectionScoresIndex_ExistsAndIsNonUnique` - **PASSED**
- `VerifyEfCoreModel_ActionPlansIndex_ExistsAndIsNonUnique` - **PASSED**
- `VerifyPostgresCatalog_IndexesExist` - **PASSED**

---

## 5. File Changes
- **Modified**: [SubmissionConfiguration.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Persistence/Configurations/SubmissionConfiguration.cs)
- **Modified**: [SubmissionSectionScoreConfiguration.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Persistence/Configurations/SubmissionSectionScoreConfiguration.cs)
- **Modified**: [ActionPlanConfiguration.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Persistence/Configurations/ActionPlanConfiguration.cs)
- **Created**: [20260601083722_AddBodLiveQueryIndexes.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Persistence/Migrations/20260601083722_AddBodLiveQueryIndexes.cs)
- **Modified**: [BodLiveQueries_Slice2_Tests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Analytics/BodLiveQueries_Slice2_Tests.cs)
