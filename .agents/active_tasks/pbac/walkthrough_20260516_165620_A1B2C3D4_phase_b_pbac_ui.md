# Phase B: Flutter DTO, Drift Cache, and Offline Transition State
Workflow: /implement | Track: B2

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260516_135009_A1B2C3D4_pbac_ui.md`

## Decision Log
- **Proposed:** Implement strongly typed action keys, DTO parsing, optimistic caching rules, and drift schema upgrades for `cachedAllowedActions`.
- **Implemented:** All proposed logic was implemented.
- **Bonus:** `ActionPlanManager` was successfully split, moving the cache mapping logic into `ActionPlanCacheMapper` (`action_plan_cache_mapper.dart`) to ensure the file size remains well below the 250-line threshold.

## Verification Handoff
All tests passed successfully, and `flutter analyze` shows zero issues. The Phase B backend-to-frontend cache mapping is complete.

<test_trace>
00:02 +55: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/database/pending_photos_migration_test.dart: AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly
00:02 +56: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/database/pending_photos_migration_test.dart: AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly
00:02 +57: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/database/pending_photos_migration_test.dart: AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly
00:02 +58: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/database/pending_photos_migration_test.dart: AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly
00:02 +59: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/database/pending_photos_migration_test.dart: AC8: PendingPhotos_Migration_ExistingRowsPreserved - AnswerId preserves backwards compatibility returning null
00:02 +60: All tests passed!
Exit code: 0
</test_trace>

<forensic_evidence>
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter test test/features/action_plans test/_shared/database`
- `flutter analyze`
</forensic_evidence>

## Gotcha Protocol
No new gotchas encountered in this slice.
