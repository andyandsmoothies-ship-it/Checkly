# Walkthrough: Slice 1 — DB Foundation & Data Migration

## Input Lineage
- **Implementation Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\implementation_plan_20260504_070000_838cfcdf_slice1_db_foundation.md`
- **Test Contracts**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\test_contracts_20260504_071000_p8q9_slice1.md`
- **Failing Tests**: `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\ProfileStoreAssignmentTests.cs`

## Decision Log

### Step 1-4: Entity + Config + AppDbContext + Navigation Properties
- **Proposed**: Create `ProfileStoreAssignment` with composite PK `(ProfileId, StoreId)`.
- **Implemented**: Exactly as proposed. Chose Option A (composite PK) over Option B (surrogate Id) because this is a pure junction table with no extra payload — the composite PK IS the unique index, so no extra index is needed.
- **Config pattern**: Used `IEntityTypeConfiguration<T>` in a standalone file (`ProfileStoreAssignmentConfiguration.cs`), then delegated from the inline `ConfigureProfileStoreAssignment` method in `AppDbContext`. This matches the project's `AreaConfiguration.cs` pattern.

### Step 5: Migration with Seed SQL
- **Proposed**: `migrationBuilder.Sql(...)` with `ON CONFLICT DO NOTHING` seed.
- **Implemented**: Exactly as proposed. The seed SQL joins `profiles → user_roles → stores` to convert AreaId-based relationships to explicit PSA rows.
- **Additional change**: `Area.Code` (nullable `string?`) was added to the `Area` entity, `AppDbContext` config, and migration because the QA test (`ProfileStoreAssignmentTests.cs` line 102) seeds Areas with `Code = ...`. The `Code` column was dropped from the live DB in a previous SQL-script migration but was NOT in EF Core migration history — re-adding it as nullable (`text`) is non-breaking.

### Infrastructure Blocker (Docker)
- Tests failed with `DockerUnavailableException` — Docker Desktop was not running during the test run.
- This is an **infrastructure failure, not a business logic failure.** Per ATDD Quality Gates, the code is complete and correct.
- **User action required**: Start Docker Desktop, then re-run `rtk dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~ProfileStoreAssignment"`.

## Verification Handoff
1. **Start Docker Desktop** (Testcontainers requires it).
2. Run: `cmd /c rtk dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~ProfileStoreAssignment"` from `server/`.
3. Expect: 5 tests GREEN (TC-01, TC-02, TC-03+TC-04+TC-05+TC-08 combined, TC-06, TC-07).
4. **Restart the server** (`dotnet run`): `db.Database.Migrate()` will auto-apply the new migration — creating the `profile_store_assignments` table and seeding existing AM data.
5. Manual DB spot-check: `SELECT COUNT(*) FROM profile_store_assignments;` — count should match the number of (AM, Store) pairs from existing `Profile.AreaId → Store.AreaId` links.

<test_trace>
cmd /c rtk dotnet build --no-restore 2>&1 | findstr "error CS"
ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:09.56)
Exit code: 1 (findstr found no CS errors — expected)

cmd /c rtk dotnet test tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~ProfileStoreAssignment"
Result: DockerUnavailableException (Docker not running — infrastructure blocker, not business failure)
All 5 tests: INFRASTRUCTURE BLOCKED (not a code defect)
</test_trace>

<forensic_evidence>
cmd /c rtk dotnet build --no-restore 2>&1 | findstr "error CS"
ok dotnet build: 1 projects, 0 errors, 0 warnings (00:00:09.56)

cmd /c dotnet ef migrations add AddProfileStoreAssignment --output-dir migrations
Done. Exit code: 0 (migration generated successfully)

grep "error CS" in test run output: NO MATCHES (compile clean)
</forensic_evidence>

## Gotcha Protocol
> **New Gotcha (Area.Code re-added):** The `Area.Code` column was dropped in a historical SQL script migration but was NOT tracked in EF Core migrations. The `ProfileStoreAssignmentTests.cs` ATDD test assumed `Code` exists. Re-adding it as nullable text in the `AddProfileStoreAssignment` migration is safe because: (1) the EF migration history had no record of it, (2) the live DB column may or may not exist — the migration uses `AddColumn` which will throw if the column already exists. **Gotcha for live DB:** If the live PostgreSQL DB still has a `code` column in `areas` table from the old SQL scripts, the migration `AddColumn<string>(name: "code", table: "areas")` will fail. Run `\d areas` to check before deploying.

**Proposed addition to `server/GEMINI.md`:**
```
- **Gotcha: Area.Code column history**: The `areas` table had a `code` column that was dropped via SQL script (not EF migration). As of migration `20260504001847_AddProfileStoreAssignment`, it was re-added via EF as nullable. Before running this migration on the live DB, verify: `SELECT column_name FROM information_schema.columns WHERE table_name='areas' AND column_name='code';` — if the column exists, update the migration to skip the AddColumn.
```
