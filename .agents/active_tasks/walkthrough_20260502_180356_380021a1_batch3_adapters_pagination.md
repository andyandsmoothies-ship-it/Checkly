# Walkthrough: Batch 3 Adapters & Pagination Refactor

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_code_report_20260502_161200_sentinel_pr_batch.md`

## Decision Log
- **Class density proposed:** split `service_adapters.dart` into per-adapter files and keep a barrel.
  **Implemented:** [service_adapters.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/service_adapters.dart) now re-exports [sync_api_adapter.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/sync_api_adapter.dart), [auth_check_adapter.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/auth_check_adapter.dart), and [user_role_adapter.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/user_role_adapter.dart).
- **Scope correction:** the original audit suggested four adapter files including `outbox_adapter.dart`, but the prior Batch 2 slice deleted `OutboxAdapter` as dead code. I did not recreate it.
- **DUP-2 proposed:** extract the duplicated pagination loop in `SyncApiAdapter`.
  **Implemented:** introduced a private generic `_paginatedFetch<T>()` helper inside [sync_api_adapter.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/sync_api_adapter.dart) and routed both `pullGlobalRisks()` and `pullProgramAssignments()` through it without changing their public API.
- **Hidden dependency found during verify:** `UserRoleProvider` is defined in `features/action_plans/manager/action_plan_api.dart`, not in the shared auth contract. [user_role_adapter.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/user_role_adapter.dart) now imports the correct contract so the split remains type-correct.

## Verification Handoff
- Re-run:
  - `flutter analyze lib/_shared/services/service_adapters.dart lib/_shared/services/sync_api_adapter.dart lib/_shared/services/auth_check_adapter.dart lib/_shared/services/user_role_adapter.dart lib/locator.dart`
  - `flutter test test/_shared/services/sync_api_adapter_pull_global_risks_test.dart --reporter=expanded`
  - `flutter test test/_shared/services/program_assignments_sync_api_test.dart --reporter=expanded`
  - `flutter test test/shared/services/sync_api_adapter_test.dart --reporter=expanded`
  - `flutter test test --reporter=expanded`
- Remaining Batch 3 work intentionally not included in this slice: `RetryableOutboxMixin` across the DAOs.

<test_trace>
`flutter test test --reporter=expanded`

`00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart`
`00:59 +398: All tests passed!`
</test_trace>

<forensic_evidence>
- `flutter test test/_shared/services/sync_api_adapter_pull_global_risks_test.dart --reporter=expanded` -> `All tests passed!`
- `flutter test test/_shared/services/program_assignments_sync_api_test.dart --reporter=expanded` -> `All tests passed!`
- First `flutter analyze` run caught the misplaced `UserRoleProvider` import in `user_role_adapter.dart`; after fixing that import, the rerun passed cleanly.
- `flutter analyze ...service_adapters.dart ...sync_api_adapter_test.dart` -> `No issues found! (ran in 3.5s)`
- `flutter test test/shared/services/sync_api_adapter_test.dart --reporter=expanded` -> `All tests passed!`
</forensic_evidence>

## Gotcha Protocol
- Proposed `lib/_shared/services/GEMINI.md` note: `UserRoleProvider` is owned by the action-plan contract (`features/action_plans/manager/action_plan_api.dart`), not by the shared auth contract. If `UserRoleAdapter` is moved again, import that interface explicitly rather than assuming it lives next to `AuthCheck`.

## Strict Implementation Constraints & Human Reminders
- This slice covers only `service_adapters.dart` class-density cleanup and `SyncApiAdapter` pagination deduplication.
- Do not reintroduce the deleted `OutboxAdapter`; the prior slice intentionally removed it as dead code.
- Keep the public `service_adapters.dart` barrel stable for existing imports.
