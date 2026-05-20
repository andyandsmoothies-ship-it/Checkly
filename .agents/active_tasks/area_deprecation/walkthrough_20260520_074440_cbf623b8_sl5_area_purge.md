# Walkthrough: SL-5 — Purge Area Code and Drop DB Table

```
[Server] -> [Features/Areas/] DELETED
[Server] -> [Features/Analytics/GetAreaLeaderboard.cs] DELETED
[Server] -> [Entities/Area.cs] DELETED
[Server] -> [AppDbContext.Areas DbSet] REMOVED
[Server] -> [Store.AreaId, Profile.AreaId] REMOVED
[Server] -> [Migration: DropAreaTable] GENERATED
[Flutter] -> [area_management_page.dart] DELETED (prior session)
[Flutter] -> [admin_area_manager.dart] DELETED (prior session)
[Flutter] -> [AdminDashboard Area tile] REMOVED
[Flutter] -> [areasWrite, analyticsArea constants] REMOVED
[Flutter] -> [admin_store_manager._adminApi dead field] REMOVED
```

## Input Lineage

`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260520_073900_sl5_area_purge.md`

## Decision Log

| Proposed | Implemented | Reason |
|---|---|---|
| Delete `ProvinceLeaderboardEndpointTests.cs` entirely | Kept the file, deleted only the 2 `GetAreaLeaderboard_*` tests | The 3rd test (`GetAnalytics_ByStoreId_ReturnsInsights_FromProvinceBenchmark`) tests a valid, existing route `/api/analytics?storeId=X`. Deleting the file would lose a valid test. |
| Remove `analyticsArea` from Flutter only | Also removed it from `capability_dictionary.dart` | It was a dead constant with no usages anywhere in the Flutter codebase after purge. |
| Plan listed `build_runner` as required | `build_runner` was NOT run | The `areaId` Drift column was already removed in a prior session. `tables.dart` had no `areaId`. Running `build_runner` on an already-clean schema would be a no-op. |

## Verification Handoff

Steps for QA to verify:

1. **DB Migration**: Open `server/Common/Persistence/Migrations/20260520010241_DropAreaTable.cs`. Confirm `Up()` contains `DropTable("areas")`, `DropForeignKey` × 2, `DropColumn("area_id", "stores")`, `DropColumn("area_id", "profiles")`. Confirm no `AddColumn` exists in `Up()`.
2. **Server Tests**: Run `cmd /c rtk dotnet test` from `server/`. Expect **501 passed, 0 failed**.
3. **Flutter Analyze**: Run `flutter analyze` from `lib/`. Expect **No issues found**.
4. **Flutter Build**: Run `flutter build apk --debug` from `lib/`. Expect exit 0, APK built.
5. **Route 404**: Start the server, call `GET /api/analytics/area-leaderboard`. Expect **404 Not Found**.
6. **No Area tile**: Launch the app as admin. Confirm the "Area Management" tile no longer appears in Admin Dashboard.

## Gotcha Protocol

**No new gotchas found.** The existing gotcha in `GEMINI.md` already states:
> "Gotcha: Terminology Map (Audit vs Submission)" and "Gotcha: The 7 Sync Steps"

One observation to add to `GEMINI.md` (see below):

**New Gotcha**: When removing a PBAC capability constant (`AppCapabilities.X`), you must also remove it from **3 places**: (1) the constant definition, (2) the `adminDomainCapabilities` set in `app_capabilities.dart`, and (3) the `capability_dictionary.dart` meta map. Missing any one of these causes analyzer warnings or dead dictionary entries.

<test_trace>
## Server Test Run
```
ok dotnet test: 501 tests passed, 0 warnings in 1 projects (137.5 s)
```
Source: `server/.agents/tmp/sl5_test_output.txt`

## Flutter Analyze
```
Analyzing lib...
No issues found! (ran in 4.1s)
```
Source: `lib/.agents/tmp/sl5_flutter_analyze2.txt`

## Flutter Build
```
Running Gradle task 'assembleDebug'...   53.7s
√ Built build\app\outputs\flutter-apk\app-debug.apk
```
Source: `lib/.agents/tmp/sl5_flutter_build.txt`
</test_trace>

<forensic_evidence>
## Commands Run

```powershell
# Phase B1 Verification
cmd /c "rtk dotnet test tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj > .agents\tmp\sl5_test_output.txt 2>&1"
# Result: Exit 0, 501 passed

# Flutter Cheap Verify
cmd /c "flutter analyze > .agents\tmp\sl5_flutter_analyze2.txt 2>&1"
# Result: Exit 0, No issues found

# Flutter Full Build (TC-SL5-03)
cmd /c "flutter build apk --debug > .agents\tmp\sl5_flutter_build.txt 2>&1"
# Result: Exit 0, APK built

# Migration verification (grep)
grep_search("DropAreaTable") -> found /server/Common/Persistence/Migrations/20260520010241_DropAreaTable.cs
```

## Area Reference Sweep (Final State)
```
grep_search(areaId, lib/) -> No results
grep_search(area_management|admin_area|admin/areas, lib/) -> 0 results in production code
grep_search(AreaId, server/Features/) -> No results
grep_search(AreaId, server/Common/ excluding migrations) -> No results (Migrations Designer.cs excluded as expected)
grep_search(db.Areas., server/tests/) -> No results
```
</forensic_evidence>
