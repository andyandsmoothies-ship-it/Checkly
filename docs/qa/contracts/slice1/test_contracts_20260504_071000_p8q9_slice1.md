# Test Contracts: Slice 1 DB Foundation & Migration

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\implementation_plan_20260504_070000_838cfcdf_slice1_db_foundation.md`

## Smoke Gate Report

| Test Name | Status | Type | Error Summary |
|-----------|--------|------|---------------|
| `Table_Has_Composite_PK` | RED | ✅ Business | Build Error: CS0246 Type 'ProfileStoreAssignment' could not be found. |
| `Cannot_Insert_Duplicate_ProfileStore_Pair` | RED | ✅ Business | Build Error: CS0246 Type 'ProfileStoreAssignment' could not be found. |
| `Seed_Converts_Existing_AM_AreaId_Links` | RED | ✅ Business | Build Error: CS0246 Type 'ProfileStoreAssignment' could not be found. |
| `FK_Cascade_Profile_Delete` | RED | ✅ Business | Build Error: CS0246 Type 'ProfileStoreAssignment' could not be found. |
| `FK_Restrict_Store_Delete` | RED | ✅ Business | Build Error: CS0246 Type 'ProfileStoreAssignment' could not be found. |

### Verdict
- ✅ All failures are Business (Missing Type) → proceed to handoff.

---

## Test Cases (Acceptance Criteria)

| ID | Scenario | Given | When | Then |
|----|----------|-------|------|------|
| TC-01 | Composite PK Exists | Migration is applied | EF Core interrogates model | Model returns `ProfileStoreAssignment` with `(ProfileId, StoreId)` PK |
| TC-02 | Prevent Duplicate | `(pId, sId)` already inserted | A second insert of `(pId, sId)` is saved | EF Core throws `DbUpdateException` |
| TC-03 | Seed Migration | AM has `AreaId`, Area has Stores | The raw migration SQL is run | Junction rows exist mapping AM to those Stores |
| TC-04 | Seed Ignores Null AreaId | AM has `AreaId` = NULL | The raw migration SQL is run | Zero junction rows are seeded for AM |
| TC-05 | Seed is Idempotent | Seed was already run once | The raw migration SQL is run again | SQL executes successfully without duplicate errors |
| TC-06 | FK Cascade (Profile) | Junction row exists | Profile is deleted | Junction row is cascade deleted |
| TC-07 | FK Restrict (Store) | Junction row exists | Store is deleted | EF Core throws `DbUpdateException` |
| TC-08 | Seed Checks Role (Gap) | User has `AreaId` but is 'auditor' | The raw migration SQL is run | Zero junction rows are seeded for this user |

---

## Test Infrastructure Map

### Helper Methods
| Method | Behavior |
|--------|----------|
| `TestWebApplicationFactory.EnsureDatabaseCreated` | Starts Testcontainers DB, seeds admin user & capabilities |

### Expected Environment
- **Database**: Fresh `checkly_test` PostgreSQL database, recreated per test class lifecycle via Testcontainers.
- **Migration**: Evaluated by executing the SQL statements directly against `TestWebApplicationFactory` DbContext using `.ExecuteSqlRawAsync()` since schema migrations are bypassed or run early by `Program.cs`.
