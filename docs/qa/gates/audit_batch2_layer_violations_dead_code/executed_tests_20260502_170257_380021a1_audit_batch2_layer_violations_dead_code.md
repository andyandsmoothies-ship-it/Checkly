# Executed Tests: Audit Batch 2 Layer Violations & Dead Code

## Commands

1. `flutter analyze lib/_shared/database/dao/submission_dao.dart lib/features/audit/manager/history_manager.dart lib/features/audit/manager/audit_manager.dart lib/_shared/services/service_adapters.dart lib/features/audit/services/core_audit_sync_module.dart lib/_shared/services/sync_engine.dart test/features/audit/manager/history_manager_local_overrides_test.dart`
Result: `No issues found! (ran in 6.4s)`

2. `flutter test test/features/audit/manager/history_manager_local_overrides_test.dart --reporter=expanded`
Result: `All tests passed!`

3. `flutter test test/features/audit/manager/history_manager_gc_test.dart --reporter=expanded`
Result: `All tests passed!`

4. `flutter analyze lib/locator.dart lib/features/audit/manager/audit_manager.dart test/features/audit/audit_manager_test.dart test/features/audit/audit_manager_scoring_mode_test.dart test/features/audit/audit_manager_online_path_test.dart test/features/audit/audit_manager_offline_test.dart`
Result: `No issues found! (ran in 2.7s)`

5. `flutter test test --reporter=expanded`
Result: `All tests passed!`
Suite total: `397` tests green in the final rerun.

<test_trace>
`flutter test test --reporter=expanded`

`00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart`
`00:06 +88: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/manager/history_manager_local_overrides_test.dart: HistoryManager_LoadHistory_HydratesLocalDraftAndOutboxMetadataWithoutManagerDbAccess`
`00:55 +397: All tests passed!`
</test_trace>

<forensic_evidence>
- `flutter analyze ...history_manager_local_overrides_test.dart` -> `No issues found! (ran in 6.4s)`
- `flutter test test/features/audit/manager/history_manager_local_overrides_test.dart --reporter=expanded` -> `All tests passed!`
- `flutter test test/features/audit/manager/history_manager_gc_test.dart --reporter=expanded` -> `All tests passed!`
- `flutter analyze ...audit_manager.dart ...audit_manager_offline_test.dart` -> `No issues found! (ran in 2.7s)`
</forensic_evidence>
