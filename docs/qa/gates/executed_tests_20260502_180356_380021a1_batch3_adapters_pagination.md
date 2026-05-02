# Executed Tests: Batch 3 Adapters & Pagination Refactor

## Commands

1. `flutter test test/_shared/services/sync_api_adapter_pull_global_risks_test.dart --reporter=expanded`
Result: `All tests passed!`

2. `flutter test test/_shared/services/program_assignments_sync_api_test.dart --reporter=expanded`
Result: `All tests passed!`

3. `flutter analyze lib/_shared/services/service_adapters.dart lib/_shared/services/sync_api_adapter.dart lib/_shared/services/auth_check_adapter.dart lib/_shared/services/user_role_adapter.dart lib/locator.dart test/_shared/services/sync_api_adapter_pull_global_risks_test.dart test/_shared/services/program_assignments_sync_api_test.dart test/shared/services/sync_api_adapter_test.dart`
Result: `No issues found! (ran in 3.5s)`

4. `flutter test test/shared/services/sync_api_adapter_test.dart --reporter=expanded`
Result: `All tests passed!`

5. `flutter test test --reporter=expanded`
Result: `All tests passed!`
Suite total: `398` tests green.

<test_trace>
`flutter test test --reporter=expanded`

`00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart`
`00:05 +88: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/manager/history_manager_local_overrides_test.dart: HistoryManager_LoadHistory_HydratesLocalDraftAndOutboxMetadataWithoutManagerDbAccess`
`00:59 +398: All tests passed!`
</test_trace>

<forensic_evidence>
- `flutter test test/_shared/services/sync_api_adapter_pull_global_risks_test.dart --reporter=expanded` -> `All tests passed!`
- `flutter test test/_shared/services/program_assignments_sync_api_test.dart --reporter=expanded` -> `All tests passed!`
- `flutter analyze ...service_adapters.dart ...sync_api_adapter_test.dart` -> `No issues found! (ran in 3.5s)`
- `flutter test test/shared/services/sync_api_adapter_test.dart --reporter=expanded` -> `All tests passed!`
</forensic_evidence>
