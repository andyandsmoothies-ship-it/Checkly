<latent_space_scratchpad>
## Edge Cases & Decisions

**Data Seed SQL safety:**
The epic proposes:
```sql
INSERT INTO ProfileStoreAssignments (ProfileId, StoreId, CreatedAt)
SELECT p.Id, s.Id, now() FROM Profiles p
JOIN AppUserRoles r ON p.Id = r.UserId
JOIN Stores s ON p.AreaId = s.AreaId
WHERE r.Role = 'area_manager' AND p.AreaId IS NOT NULL
```
The risk: if the `AppUserRoles` table has duplicate rows (one user has 2 `area_manager` entries), the cross join would produce duplicate PSA rows violating the composite PK. The SQL must use `ON CONFLICT DO NOTHING` (PostgreSQL upsert guard). Let me design this into the plan as a mandatory protection.

**Navigation property on `Profile`:**
Should I add `ICollection<ProfileStoreAssignment> StoreAssignments` to the `Profile` entity? The epic doesn't require it for Slice 1 but it is good EF Core practice. However, the rule is "Stay in Your Lane" — Slice 2 will need it for `OwnershipScopeFilter`. Add it now since it is entity-level and has zero blast radius outside the entity class.

**`ProfileStoreAssignment` primary key strategy:**
The epic says `PRIMARY KEY (ProfileId, StoreId)`. This matches the `UserGroupMember` pattern in the codebase (composite unique index). However, I see `UserGroupMember` still uses a separate `Id` PK — it uses `HasIndex(...).IsUnique()` as a uniqueness constraint, not a composite PK.

I have two choices:
- A: Composite PK `HasKey(x => new { x.ProfileId, x.StoreId })` — no surrogate Id column. Clean for a pure junction table.
- B: Surrogate Guid PK `Id` + unique index on `(ProfileId, StoreId)` — consistent with existing junction tables (`UserGroupMember`, `TemplateAssignment`, `ProgramAssignment`).

Decision: **Option A (composite PK)** because this is a pure junction table with no extra data that would benefit from a surrogate ID. A composite PK IS the unique index — one fewer index to maintain. This is the architecturally correct pattern for pure junction tables in EF Core.

**Table name:** snake_case → `profile_store_assignments`. Column names: `profile_id`, `store_id`, `created_at`.

**`AppDbContext` size:** Currently 831 lines. Adding a `ConfigureProfileStoreAssignment` method and one `DbSet` line will bring it to ~850. Still under the 400-line rule? The file is already 831 lines — this is a violation of GEMINI.md. I should flag this. But I cannot split AppDbContext now (that would be scope creep). I will add a Risk Warning note and defer the split.

**Migration data seed:**
PostgreSQL `now()` is fine. The SQL should also wrap the INSERT in `ON CONFLICT DO NOTHING` to be idempotent if the migration is ever re-run.

**No `UpdatedAt` on junction table:** Since this is a pure junction (just tracks existence), no `UpdatedAt` column is needed. Only `CreatedAt`.
</latent_space_scratchpad>

# Implementation Plan: Slice 1 — DB Foundation & Data Migration

## Input Lineage
- **Epic:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\analysis_epic_20260503_215500_2b21e338_area_override.md`
- **Decision Record:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260503_214850_synth_store_area_consolidation.md`

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Data seed SQL produces no rows (wrong table names) | 🔴 HIGH | TC-03 verifies seed results before Slice 2 is unblocked |
| Duplicate rows violate composite PK during seed | 🔴 HIGH | `ON CONFLICT DO NOTHING` guard in seed SQL |
| AM with null AreaId loses access prematurely | 🟢 LOW | Auth guards still use old `AreaId` logic until Slice 2 |
| AppDbContext exceeds 400-line limit (currently 831 lines) | 🟡 MEDIUM | Deferred to a dedicated housekeeping task; not in scope here |
| FK Cascade delete accidentally removes valid PSA rows | 🟡 MEDIUM | TC-06 and TC-07 verify cascade/restrict behavior |

---

## Verification Plan

1. `dotnet build server/Checkly.Api` → must exit 0 with no warnings.
2. `dotnet test --filter "FullyQualifiedName~ProfileStoreAssignment"` → TC-01 through TC-07 must be GREEN.
3. Restart `dotnet run` server → migration auto-applies via `db.Database.Migrate()`.
4. Manual spot check: Query `SELECT COUNT(*) FROM profile_store_assignments` via a DB client — count must match the number of (AM, Store) pairs derived from existing `Profile.AreaId` → `Store.AreaId` links.

---


> [!CAUTION]
> **HIGH RISK — SECURITY PERIMETER MIGRATION**
> This slice creates the new `ProfileStoreAssignment` table and seeds it from existing AM data. If the data seed SQL fails or is incomplete, all Area Managers will log in and see zero stores on the next deployment. Verify with TC-03 before merging.

---

## Executive Summary & Out of Scope

**What this slice builds:**
1. A new `ProfileStoreAssignment` entity (pure junction: `ProfileId` + `StoreId`).
2. Its EF Core configuration (`ProfileStoreAssignmentConfiguration.cs`) with a composite PK and performance index.
3. Registration of `db.ProfileStoreAssignments` DbSet in `AppDbContext`.
4. An EF Core migration that: (a) creates the table, and (b) seeds data by converting existing `Profile.AreaId → Stores.AreaId` links into direct rows.

**Out of Scope (YAGNI):**
- ❌ **Auth guard changes** → Slice 2 (`ResourceAccessGuard`, `OwnershipScopeFilter`).
- ❌ **API changes** → Slice 3 (`UpdateUser`, `CreateUser`, S10 rule deletion).
- ❌ **Flutter sync** → Slice 4 (Profile DTO, Drift table).
- ❌ **Admin UI** → Slice 5 (`user_edit_sheet.dart`).
- ❌ **Splitting `AppDbContext.cs`** → The file is already 831 lines (over the 400-line rule). This must be addressed in a separate housekeeping task. Adding one more `ConfigureX` method here is the minimal safe change.
- ❌ **Removing `Profile.AreaId`** → This column stays alive until Slice 2+ are complete. Removing it now would break all existing auth guards immediately.

---

## System Context

- **Environment:** Server-only (ASP.NET Core / PostgreSQL via EF Core).
- **Auth/RBAC:** No auth changes in this slice. Existing `AreaId`-based guards remain fully active until Slice 2.
- **Offline-First:** Flutter sync is not affected until Slice 4. The new table is invisible to the Flutter app at this stage.
- **Migration Auto-Apply:** Per `server/Common/Persistence/GEMINI.md`, `Program.cs` calls `db.Database.Migrate()` on startup. The user MUST restart the server to apply the migration.

---

## Lifecycle Context (4-State Matrix)

This slice has no UI. States are measured by migration health.

| State | What It Means | Indicator |
|-------|--------------|-----------|
| **Success** | Table exists, composite PK in place, data seed ran correctly | All AMs have rows in `ProfileStoreAssignments` |
| **Loading** | N/A | N/A |
| **Empty** | An AM had `AreaId = null` at migration time | They get 0 rows — this is correct and expected |
| **Error** | SQL seed fails (constraint violation, missing FK) | Migration throws; server restart loop |

---

## Test Contracts

| ID | Test Name | Precondition | Expected Outcome | Why It Fails First |
|----|-----------|-------------|------------------|--------------------|
| TC-01 | `Table_Has_Composite_PK` | Migration applied | `ProfileStoreAssignments` table exists with `(profile_id, store_id)` composite PK | Entity not yet created |
| TC-02 | `Cannot_Insert_Duplicate_ProfileStore_Pair` | Table exists | Second INSERT of same `(ProfileId, StoreId)` throws `UniqueViolation` | Composite PK is not yet enforced |
| TC-03 | `Seed_Converts_Existing_AM_AreaId_Links` | AM `ProfileA` with `AreaId=Area1`; Area1 has `StoreA`, `StoreB` | `ProfileStoreAssignments` has 2 rows: `(ProfileA, StoreA)` and `(ProfileA, StoreB)` | Seed SQL not yet written |
| TC-04 | `AM_With_Null_AreaId_Gets_No_Rows` | AM `ProfileB` with `AreaId=null` | Zero rows seeded for `ProfileB` | None (defensive test) |
| TC-05 | `Seed_Is_Idempotent_With_On_Conflict` | Migration already ran. Run seed SQL again. | No error, no duplicate rows created | `ON CONFLICT DO NOTHING` not yet added |
| TC-06 | `FK_Cascade_Profile_Delete` | `(ProfileA, StoreA)` row exists | Deleting `ProfileA` cascades and deletes its `ProfileStoreAssignment` rows | FK not configured |
| TC-07 | `FK_Restrict_Store_Delete` | `(ProfileA, StoreA)` row exists | Attempting to delete `StoreA` fails with FK violation | FK behavior not configured |

---

## Test Fixture & Payloads

```
Fixture: Seeded Area Manager
- Area "District 1" (Id = area1Id)
- Store "Store Alpha" (Id = storeAlphaId, AreaId = area1Id)
- Store "Store Beta" (Id = storeBetaId, AreaId = area1Id)
- Profile AM1 (Id = am1Id, AreaId = area1Id, Role = "area_manager")
- Profile AM_Unassigned (Id = am2Id, AreaId = null, Role = "area_manager")

Expected post-migration state in ProfileStoreAssignments:
  - (am1Id, storeAlphaId, created_at)
  - (am1Id, storeBetaId, created_at)
  [No row for am2Id]
```

---

## Tools & Commands

- **Skill:** `ef-core` (for migration patterns and composite PK configuration)
- **Test Command:** `cmd /c rtk dotnet test server/tests/Checkly.Api.Tests --filter "FullyQualifiedName~ProfileStoreAssignment" --no-build`
- **Build Verification:** `cmd /c rtk dotnet build server/Checkly.Api`
- **Migration Add:** `cmd /c rtk dotnet ef migrations add AddProfileStoreAssignment --project server/Checkly.Api --startup-project server/Checkly.Api`

---

## Proposed Changes

| Status | File | Description |
|--------|------|-------------|
| [NEW] | `server/Common/Persistence/Entities/ProfileStoreAssignment.cs` | New pure junction entity |
| [NEW] | `server/Common/Persistence/Configurations/ProfileStoreAssignmentConfiguration.cs` | EF Core config with composite PK, FKs, and performance index |
| [MOD] | `server/Common/Persistence/AppDbContext.cs` | Add `DbSet<ProfileStoreAssignment>` + `ConfigureProfileStoreAssignment()` call |
| [MOD] | `server/Common/Persistence/Entities/Profile.cs` | Add navigation collection `ICollection<ProfileStoreAssignment>` |
| [MOD] | `server/Common/Persistence/Entities/Store.cs` | Add navigation collection `ICollection<ProfileStoreAssignment>` |
| [NEW] | `server/Checkly.Api/Migrations/XXXX_AddProfileStoreAssignment.cs` | EF Core migration (auto-generated) with embedded data seed SQL |
| [NEW] | `server/tests/Checkly.Api.Tests/ProfileStoreAssignmentTests.cs` | Integration tests for TC-01 through TC-07 |

---

## Concept Diagram

```
[EF Core Migration runs on server restart]
    │
    ├─► CREATE TABLE profile_store_assignments
    │     (profile_id UUID FK → profiles.id CASCADE)
    │     (store_id   UUID FK → stores.id RESTRICT)
    │     (created_at TIMESTAMPTZ)
    │     PRIMARY KEY (profile_id, store_id)
    │
    └─► DATA SEED (raw SQL)
          SELECT AM profiles WHERE AreaId IS NOT NULL
          JOIN stores ON profiles.AreaId = stores.AreaId
          INSERT INTO profile_store_assignments
          ON CONFLICT DO NOTHING
```

---

## Execution Phase

**Complexity: Medium** — Pure server-side. No UI or Flutter changes. Risk is in the SQL seed correctness and FK cascade behavior.

### Step 1: Create the Entity
**File:** `server/Common/Persistence/Entities/ProfileStoreAssignment.cs`

Follow the same style as `UserGroupMember.cs` for junction tables. The entity should have:
- `ProfileId` (Guid, not null)
- `StoreId` (Guid, not null)
- `CreatedAt` (DateTimeOffset, not null)
- Navigation: `Profile? Profile` and `Store? Store`
- **NO surrogate `Id` column** — the composite key IS the PK.

### Step 2: Create EF Core Configuration
**File:** `server/Common/Persistence/Configurations/ProfileStoreAssignmentConfiguration.cs`

Follow the `UserGroupMemberConfiguration.cs` style. Key rules:
- `e.HasKey(x => new { x.ProfileId, x.StoreId })` — composite PK (creates a clustered index automatically).
- Column names: `profile_id`, `store_id`, `created_at`. Table name: `profile_store_assignments`.
- FK to `Profile`: `OnDelete(DeleteBehavior.Cascade)` — deleting an AM cascades to their assignments.
- FK to `Store`: `OnDelete(DeleteBehavior.Restrict)` — cannot delete a store that has AM assignments (prevents orphaned access).
- **Do NOT add a separate performance index** — the composite PK is already a clustered index that covers all IDOR lookup patterns.

### Step 3: Register in AppDbContext
**File:** `server/Common/Persistence/AppDbContext.cs`

Two small changes:
- Add `public DbSet<ProfileStoreAssignment> ProfileStoreAssignments => Set<ProfileStoreAssignment>();` to the DbSet block (after line 40, with `ProgramEvidence`).
- Add `ConfigureProfileStoreAssignment(modelBuilder);` to the `OnModelCreating` method (after `ConfigureProgramEvidence`).
- Add the private static `ConfigureProfileStoreAssignment(ModelBuilder mb)` method at the end of the class.

### Step 4: Add Navigation Properties
**Files:** `Profile.cs`, `Store.cs`

Add `public ICollection<ProfileStoreAssignment> StoreAssignments { get; set; } = [];` to `Profile`.
Add `public ICollection<ProfileStoreAssignment> AssignedManagers { get; set; } = [];` to `Store`.

These are navigation-only changes, no migration impact.

### Step 5: Add EF Core Migration (with data seed)
Run the migration tool. Then **manually edit** the generated migration's `Up()` method to embed the data seed SQL after the table creation:

```csharp
migrationBuilder.Sql(@"
    INSERT INTO profile_store_assignments (profile_id, store_id, created_at)
    SELECT p.id, s.id, now()
    FROM profiles p
    JOIN user_roles ur ON p.id = ur.user_id AND ur.role = 'area_manager'
    JOIN stores s ON p.area_id = s.area_id
    WHERE p.area_id IS NOT NULL
    ON CONFLICT DO NOTHING;
");
```

The `Down()` method should only `DropTable("profile_store_assignments")` — no inverse for the data seed.

**⚠️ Important:** Do not edit anything else in the generated migration file.

### Step 6: Write Tests (TC-01 to TC-07)
**File:** `server/tests/Checkly.Api.Tests/ProfileStoreAssignmentTests.cs`

Write integration tests using the existing `TestWebApplicationFactory` pattern. Tests must:
- Follow the `IClassFixture<TestWebApplicationFactory>` pattern.
- Use `localDb` scope from the factory to directly insert and query entities.
- Verify TC-01 through TC-07 per the Test Contract table above.

---

<command_logs>
- list_dir server/Common/Persistence → Confirmed folders: Entities, Configurations, Migrations
- list_dir server/Common/Persistence/Entities → Confirmed 25 entity files. No ProfileStoreAssignment yet.
- list_dir server/Common/Persistence/Configurations → Confirmed 21 config files. No PSA config yet.
- view_file server/Common/Persistence/AppDbContext.cs (lines 1-800) → Confirmed 831-line file, DbSet block at lines 17-40, OnModelCreating at lines 42-71, ConfigureArea at lines 499-514.
- view_file server/Common/Persistence/Entities/Profile.cs → Confirmed Profile.AreaId (Guid?) exists at line 14.
- view_file server/Common/Persistence/Entities/Store.cs → Confirmed Store.AreaId (Guid?) exists at line 12.
- view_file server/Common/Persistence/Configurations/AreaConfiguration.cs → Confirmed table name "areas", no composite PK.
- view_file server/Common/Persistence/Configurations/ProfileConfiguration.cs → Confirmed FK to Area via AreaId (line 29-32), will KEEP this FK intact in Slice 1.
- view_file server/Common/Persistence/Entities/ProgramAssignment.cs → Reviewed as pattern reference for junction table.
- view_file server/Common/Persistence/GEMINI.md → Confirmed auto-migrate on restart. NpgsqlRetryingExecutionStrategy delegate mandate confirmed.
- grep_search "public DbSet" AppDbContext.cs → Confirmed 24 existing DbSets (lines 17-40).
- grep_search "AreaId" server/Common/Persistence → Profile.cs line 14, Store.cs line 12.
</command_logs>

---

## Handoff Block

**Slice:** 1 — DB Foundation & Data Migration
**Plan File:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\implementation_plan_20260504_070000_838cfcdf_slice1_db_foundation.md`

**Agent Mission Brief:** Create `ProfileStoreAssignment` entity + EF Core config + AppDbContext registration + EF Core migration with embedded SQL data seed. All server-only. No auth or API or Flutter changes. Run tests TC-01 to TC-07 to verify before declaring done.

**Route:** Route 3 — Integration/DB (Acceptance Tests First)

> [!WARNING]
> **Restart Required:** After the migration is created and the server restarts, `db.Database.Migrate()` in `Program.cs` will auto-apply it. Tell the user to restart their `dotnet run` terminal after the Builder is done.

**Step-by-Step Commands (run ONE AT A TIME):**

1. **Build tests first:**
   ```
   @[/atdd] Execute specs for Slice 1 DB Foundation: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\implementation_plan_20260504_070000_838cfcdf_slice1_db_foundation.md
   ```

2. **After ATDD tests are RED (for the right reason), implement:**
   ```
   @[/implement] Execute build for Slice 1 DB Foundation: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\implementation_plan_20260504_070000_838cfcdf_slice1_db_foundation.md
   ```

3. **Slice 2 cannot begin until Slice 1 tests are GREEN.**
