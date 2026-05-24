<latent_space_scratchpad>
## Constraints from Epic
C1: `areas` DB table must be dropped.
C2: `AreaId` FK on `stores` must be dropped.
C3: `AreaId` FK on `profiles` must be dropped.
C4: All Area CRUD endpoints (7 files in Features/Areas/) must be deleted.
C5: `GetAreaLeaderboard.cs` must be deleted.
C6: Flutter `area_management_page.dart` and its route `/admin/areas` must be deleted.
C7: Flutter `admin_area_manager.dart` must be deleted.
C8: Old `FindExistingAreaManager` method on `RoleAssignmentGuard` (uses Profile.AreaId) must be deleted.
C9: `Area.cs` entity, and nav properties on `Store.cs` and `Profile.cs` must be removed.
C10: `Areas DbSet` on `AppDbContext` must be removed.
C11: All integration test files that exclusively test Area behavior must be deleted.
C12: Residual `areaId` references in other files (Stores, Users, Schedule Audit logic) must be cleaned up.
C13: `areaId` parameter in sync_api.dart and sync_api_adapter.dart must be removed.
C14: Drift table `areaId` column on `CachedStores` must be removed; requires `flutter pub run build_runner build` to regenerate app_database.g.dart.

## Risky Items
- `schedule_audit_form_logic.dart` uses `u['areaId']` to filter auditors. After deletion, the filter must be removed (no area filtering means all auditors for the store are eligible, which is correct post-SL-3/4).
- `store_management_page.dart` and `store_filter_bar.dart` use `selectedAreaId` to filter stores by area. This filter must be removed.
- `user_management_page.dart` passes `areaId` to `UserEditSheet`. Must clean up.
- Tests that seed `db.Areas.Add(...)` in non-Area-exclusive test files (SyncSubmissionsEndpointTests, SubmissionAccessGuardUnitTests, SubmissionDelegationAuthTests, OverdueEscalationTests, ListActionPlansTests, InsightsIntegrationTests, IdorGuardTests, ProfileStoreAssignmentTests) must remove the Area seeding, and the Store seeding that passes `areaId` must set `AreaId = null`.
- `ResourceScope.cs` still has `AreaId = null` as a field — must remove it.
- `RoleAssignmentGuard.FindExistingAreaManager` is NOT called by anyone (confirmed above) but must still be deleted.
</latent_space_scratchpad>

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260518_194804_areadep_area_deprecation.md`

## Executive Summary & Out of Scope

**Goal**: Execute the final, destructive cleanup step of the Area Deprecation Epic. This slice has zero new logic — it only deletes dead code, drops dead DB columns/tables, and removes routes/pages that no longer serve a purpose after SL-1 through SL-4 replaced all dependencies.

**Prerequisite (Entry Gate)**: SL-1, SL-2, SL-3, and SL-4 must all be fully implemented and verified before this slice begins.

**Out of Scope:**
- Any new business logic. This is deletion-only.
- Changing PBAC, ReminderService, Analytics, or Sync logic. Those were handled in SL-1–4.
- Modifying `ProfileStoreAssignment` — it stays and grows in importance.

## System Context
- **Mode**: This is a pure structural migration slice. No API contract changes for active features.
- **RBAC**: No new gates. The `area_manager` role continues to work via `ProfileStoreAssignment`.
- **DB Migration**: One new EF Core migration dropping `area_id` FK columns from `profiles` and `stores`, then dropping the `areas` table.
- **Flutter DB**: Remove `areaId` Drift column from `CachedStores`. Run `build_runner` to regenerate `app_database.g.dart`.

## Lifecycle Context
| State | Description |
|---|---|
| **Success** | App builds clean with zero compilation errors. All tests pass. Route `/admin/areas` returns 404. DB has no `areas` table, no `area_id` columns. |
| **Error** | Missed a reference causes build failure. Fix: search for the specific error and delete the remaining reference. |
| **Empty** | N/A — no UI states change for live features. |
| **Loading** | N/A |

## Constraint Traceability
| Constraint ID | Constraint | Test Contract |
|---|---|---|
| C1 | Drop `areas` DB table | TC-SL5-01 (migration runs clean, no `areas` table in test DB) |
| C2 | Drop `AreaId` FK on `stores` | TC-SL5-01 |
| C3 | Drop `AreaId` FK on `profiles` | TC-SL5-01 |
| C4 | Delete all 7 files in `Features/Areas/` | TC-SL5-02 (server build passes) |
| C5 | Delete `GetAreaLeaderboard.cs` | TC-SL5-02 |
| C6 | Delete Flutter `area_management_page.dart` + route `/admin/areas` | TC-SL5-03 (Flutter build passes) |
| C7 | Delete Flutter `admin_area_manager.dart` | TC-SL5-03 |
| C8 | Delete old `FindExistingAreaManager` method in `RoleAssignmentGuard` | TC-SL5-02 |
| C9 | Remove `Area.cs` entity + nav properties from `Store.cs`, `Profile.cs` | TC-SL5-02 |
| C10 | Remove `Areas DbSet` from `AppDbContext` | TC-SL5-02 |
| C11 | Delete test files for Area CRUD | TC-SL5-02 |
| C12 | Clean residual `areaId` refs in Stores, Users, ScheduleAudit features | TC-SL5-02, TC-SL5-03 |
| C13 | Remove `areaId` param from `sync_api.dart` and `sync_api_adapter.dart` | TC-SL5-03 |
| C14 | Remove `areaId` Drift column, regenerate `app_database.g.dart` | TC-SL5-03 |

## Test Contracts
| ID | Description | Why it verifies |
|---|---|---|
| TC-SL5-01 | Running `rtk dotnet ef migrations add DropAreaTable` produces a valid, clean migration that drops `area_id` from `profiles`, `area_id` from `stores`, and drops `areas` table. No `AddColumn` in the migration. | Proves schema intent is correct. |
| TC-SL5-02 | `rtk dotnet build` exits code 0 with zero errors. `rtk dotnet test` exits code 0 with all tests passing. | Proves server-side code is clean. |
| TC-SL5-03 | `flutter build apk --debug` exits code 0 with zero errors. | Proves Flutter code is clean. |

## Test Fixture & Payloads
- Tests that previously seeded `db.Areas.Add(...)` as auxiliary setup (not the subject of the test) must remove that line and replace `AreaId: areaId` in `new Store {…}` with `AreaId = null`.
- After removal, run the full test suite to confirm all affected tests still pass.
- **No new test files** are written for SL-5. The acceptance condition is compilation success and zero test regressions.

## Tools & Commands
- **Skills**: None required (deletion-only work).
- **Commands**:
  ```powershell
  # Server Build
  cmd /c rtk dotnet build
  
  # DB Migration (generate)
  cmd /c rtk dotnet ef migrations add DropAreaTable --project Common\Persistence -- --environment Development
  
  # Server Tests
  cmd /c rtk dotnet test > .agents\tmp\sl5_test_output.txt 2>&1
  
  # Flutter codegen (after removing Drift column)
  cmd /c flutter pub run build_runner build --delete-conflicting-outputs
  
  # Flutter Build Check
  cmd /c flutter build apk --debug
  ```

## Proposed Changes

### Phase B1: Server Deletions

**Delete entire folder:**
- `[DEL]` `server/Features/Areas/` (all 7 files: `AreasEndpoints.cs`, `CreateArea.cs`, `DeleteArea.cs`, `Dtos.cs`, `GetArea.cs`, `ListAreas.cs`, `UpdateArea.cs`)

**Delete files:**
- `[DEL]` `server/Features/Analytics/GetAreaLeaderboard.cs`
- `[DEL]` `server/Common/Persistence/Entities/Area.cs`
- `[DEL]` `server/tests/Checkly.Api.Tests/Features/Areas/ListAreas_Tests.cs` (and the empty folder)
- `[DEL]` `server/tests/Checkly.Api.Tests/AreaMigrationTests.cs`
- `[DEL]` `server/tests/Checkly.Api.Tests/AreaEndpointMigrationTests.cs`

**Modify files (remove references):**
| File | Change |
|---|---|
| `server/Common/Persistence/AppDbContext.cs` | Remove `public DbSet<Area> Areas => Set<Area>();` line |
| `server/Common/Persistence/Entities/Store.cs` | Remove `public Guid? AreaId { get; set; }` and `public Area? Area { get; set; }` |
| `server/Common/Persistence/Entities/Profile.cs` | Remove `public Guid? AreaId { get; set; }` and `public Area? Area { get; set; }` |
| `server/Common/Auth/RoleAssignmentGuard.cs` | Delete `FindExistingAreaManager` method (the old one that queries `p.AreaId`). Keep `FindExistingAreaManagerForStore`. Update doc comment on class. |
| `server/Common/ResourceScope.cs` | Remove `Guid? AreaId = null` parameter from the record |
| `server/Features/Analytics/AnalyticsEndpoints.cs` | Remove the registration of `GetAreaLeaderboard` |
| `server/Features/Analytics/GetAnalytics.cs` | Remove `areaId` filter path (lines ~111) |
| `server/Features/Analytics/GetAnalyticsInsightsResolver.cs` | Remove `AreaId` filter in resolver |
| `server/Features/Stores/CreateStore.cs` | Remove `AreaId` validation block + `areaId` from response DTO |
| `server/Features/Stores/UpdateStore.cs` | Remove `AreaId` update block + `areaId` from response DTO |
| `server/Features/Stores/ListStores.cs` | Remove `AreaId` filter parameter + `AreaId` from projection |
| `server/Features/Stores/GetStore.cs` | Remove `AreaId` from projection |
| `server/Features/Stores/GetStoreDashboard.cs` | Remove `AreaId` from anonymous object |
| `server/Features/Stores/Dtos.cs` | Remove `areaId` from DTOs |
| `server/Features/Users/SearchUsers.cs` | Remove `AreaId` from projection |
| `server/Features/Admin/CreateUser.cs` | Remove `AreaId = request.AreaId` from profile creation |
| `server/Features/Admin/UpdateUser.cs` | Remove `AreaId` assignment block (lines ~109–127, 260). Remove VirtualAreaId path entirely. |
| `server/Features/Admin/ListUsers.cs` | Remove Area join (lines ~37) and `AreaId` from projections |
| `server/Features/Admin/Dtos.cs` | Remove `AreaId` and `VirtualAreaId` from request/response DTOs |
| `server/Features/Submissions/SyncSubmissions.cs` | Remove remaining `areaId` parameter from handler signature |
| `server/Program.cs` | Remove `using Checkly.Api.Features.Areas;` |
| **Tests: remove `db.Areas.Add(…)` seeding** | `SyncSubmissionsEndpointTests.cs`, `SubmissionAccessGuardUnitTests.cs`, `SubmissionDelegationAuthTests.cs`, `OverdueEscalationTests.cs`, `ListActionPlansTests.cs`, `InsightsIntegrationTests.cs`, `IdorGuardTests.cs`, `ProfileStoreAssignmentTests.cs` |
| `server/tests/.../Features/Admin/UpdateUserVirtualAreaTests.cs` | Delete entirely (tests VirtualArea, which no longer exists) |
| `server/tests/.../Features/Admin/CreateUserVirtualAreaTests.cs` | Delete entirely |
| `server/tests/.../Features/Analytics/Analytics_AM_Scope_Tests.cs` | Remove area-based test cases; keep province-based ones |

**Run EF Core migration after all entity changes:**
- `rtk dotnet ef migrations add DropAreaTable`
- Verify migration `Up()` contains: `DropForeignKey` for `area_id` on `stores`, `DropForeignKey` for `area_id` on `profiles`, `DropTable("areas")`

---

### Phase B2: Flutter Deletions

**Delete files:**
- `[DEL]` `lib/features/admin/pages/area_management_page.dart`
- `[DEL]` `lib/features/admin/manager/admin_area_manager.dart`
- `[DEL]` `lib/features/admin/widgets/area_card.dart` (if exists)

**Modify files (remove references):**
| File | Change |
|---|---|
| `lib/_shared/router/app_router.dart` | Remove import of `area_management_page.dart`. Remove GoRoute for `/admin/areas`. Remove `initialAreaId` query param extraction (line ~209). |
| `lib/_shared/router/main_shell.dart` | Remove "Areas" nav item if present |
| `lib/_shared/services/sync_api.dart` | Remove `String? areaId` parameter from `pullDeltas` |
| `lib/_shared/services/sync_api_adapter.dart` | Remove `String? areaId` param and `if (areaId != null) params['areaId'] = areaId;` |
| `lib/_shared/database/tables.dart` | Remove `TextColumn get areaId => text().nullable()();` from `CachedStores` Drift table |
| `lib/_shared/database/dao/store_dao.dart` | Remove `areaId: row.areaId` and `areaId: Value(dto.areaId)` |
| `lib/features/stores/model/store_dto.dart` | Remove `areaId` field |
| `lib/features/admin/widgets/user_edit_sheet.dart` | Remove `selectedAreaId` state and Area dropdown section |
| `lib/features/admin/widgets/user_edit_sheet_body.dart` | Remove `selectedAreaId` parameter and Area picker widget |
| `lib/features/admin/widgets/user_create_sheet.dart` | Remove `areaId` parameter |
| `lib/features/admin/widgets/schedule_audit_form_logic.dart` | Remove `storeAreaId` filter logic (lines 13–51); all auditors for selected store are now eligible |
| `lib/features/admin/pages/store_management_page.dart` | Remove `initialAreaId`, `_selectedAreaId` state, and area filter loading |
| `lib/features/admin/pages/widgets/store_filter_bar.dart` | Remove Area dropdown / `selectedAreaId` |
| `lib/features/admin/pages/user_management_page.dart` | Remove `areaId` prop threading |
| `lib/features/admin/manager/admin_store_manager.dart` | Remove `areaId` param from `load()` |
| `lib/features/admin/manager/admin_user_manager.dart` | Remove `areaId` param from create/update calls |
| `lib/features/admin/services/admin_api_service.dart` | Remove `areaId` from `createUser`, `updateUser` bodies |
| `lib/locator.dart` | Remove `AdminAreaManager` registration |
| `lib/_shared/database/app_database.g.dart` | **Regenerated automatically** via `flutter pub run build_runner build` |

---

## Concept Diagram

```
Before SL-5:
[Area Entity] ──FK──> [Store.AreaId]
[Area Entity] ──FK──> [Profile.AreaId]
[/admin/areas] ──uses──> [AreaManagementPage] ──uses──> [AdminAreaManager]
[GetAreaLeaderboard] ──queries──> [Area]

After SL-5:
[Area Entity]         DELETED
[Store.AreaId]        DROPPED (column gone)
[Profile.AreaId]      DROPPED (column gone)
[/admin/areas]        DELETED (404)
[GetAreaLeaderboard]  DELETED
[AdminAreaManager]    DELETED
```

## Execution Slices

### Phase B1: Server Purge
- **Plain English**: Delete all server-side Area code — entity, endpoints, test files, and remove all `AreaId` column references from related entities, features, and tests. Generate the EF Core migration.
- **Value Delivered**: The server codebase has zero references to `Area`. DB migration is ready to apply.
- **Entry State**: SL-4 verified and merged. Server compiles with SL-4 code.
- **Exit State**: `rtk dotnet build` exits 0. `rtk dotnet test` exits 0. Migration file `DropAreaTable.cs` exists.
- **Complexity**: **High** — touches ~25 files. Requires careful deletion ordering (entity first, then features, then tests). Each compile cycle is the safety net.
- **Scope**: Server only. No Flutter changes.
- **Acceptance Criteria**: TC-SL5-01, TC-SL5-02.

### Phase B2: Flutter Purge
- **Plain English**: Delete Flutter area management page, route, manager, and clean all residual `areaId` references from stores/users/schedule audit widgets. Remove `areaId` from Drift table and regenerate the database g-file.
- **Value Delivered**: The Flutter codebase has zero references to `areaId`. App builds clean.
- **Entry State**: Phase B1 is complete and verified.
- **Exit State**: `flutter build apk --debug` exits 0.
- **Complexity**: **Medium** — ~15 files, but all are deletions and clean removals. The `schedule_audit_form_logic.dart` simplification is the trickiest (removes area-based auditor filtering).
- **Scope**: Flutter only.
- **Acceptance Criteria**: TC-SL5-03.

<command_logs>
- grep_search: AreaId in server/ — found all 7 Area feature files + entity files + tests
- grep_search: area in lib/ — found area_management_page, admin_area_manager, app_router references
- grep_search: areaId in lib/features/admin/ — found 40+ residual references in widgets/pages/managers
- grep_search: db.Areas usages — found in Program.cs, Features/Areas/, tests (15 test files)
- grep_search: FindExistingAreaManager — confirmed only declared, never called externally
- list_dir: Features/Areas/ — confirmed 7 files
- list_dir: admin/pages/ — confirmed area_management_page.dart present
- list_dir: admin/manager/ — confirmed admin_area_manager.dart present
</command_logs>

## Risk Assessment
- **Volatility**: High. This is the largest single file-count change in the Epic. However, all the logic was already removed in SL-1–4 — this is purely compilation cleanup.
- **Safe Order**: Delete entity files last on the server side (after features are gone) to avoid cascade compile errors. Always build after each batch of deletions.
- **Rollback**: Standard source control rollback. This is the last slice, so rollback would reintroduce dead code.

## Verification Plan

| Step | Command | Pass Condition |
|---|---|---|
| TC-SL5-01: DB Migration | `cmd /c rtk dotnet ef migrations add DropAreaTable` | Migration file generated. `Up()` contains `DropTable("areas")`, `DropColumn("area_id", "stores")`, `DropColumn("area_id", "profiles")`. No `AddColumn`. |
| TC-SL5-02: Server Build + Test | `cmd /c rtk dotnet build` then `cmd /c rtk dotnet test` | Exit code 0. Zero errors. All tests pass. |
| TC-SL5-03: Flutter Build | `cmd /c flutter pub run build_runner build --delete-conflicting-outputs` then `cmd /c flutter build apk --debug` | Exit code 0. Zero compilation errors. |

## Handoff Block

**Plan file**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260520_073900_sl5_area_purge.md`

**Execution sequence (strictly sequential):**
- **Phase B1 (Server Purge)**: Delete files → clean references → generate migration → Build → Run Tests.
- **Phase B2 (Flutter Purge)**: Delete files → clean references → run `build_runner` → Flutter Build Check.

> **No TDD or ATDD required.** The Epic plan explicitly states: *"SL-5: `/analyze-feature` → `/implement` (No new logic, just deleting code and running migration)"*. The verification gate is zero compilation errors and zero test regressions in the existing test suite.

Execute **ONE PHASE AT A TIME**.
