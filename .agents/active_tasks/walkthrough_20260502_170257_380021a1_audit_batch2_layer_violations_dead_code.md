# Walkthrough: Audit Batch 2 Layer Violations & Dead Code

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit_code_report_20260502_161200_sentinel_pr_batch.md`

## Decision Log
- **AD-2 proposed:** move `HistoryManager` local override lookups out of raw Drift table access.
  **Implemented:** added `SubmissionDao.getLocalOverrideMetadata()` and `SubmissionDao.getDraftSavedAt()`, then removed `GetIt`/`DatabaseService` access from [history_manager.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/features/audit/manager/history_manager.dart) so the manager now hydrates through DAO-only calls.
- **DC-2 proposed:** remove dead `AuditManager._api`.
  **Implemented:** removed the `_api` field and then deleted the now-unused constructor seam from [audit_manager.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/features/audit/manager/audit_manager.dart), [locator.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/locator.dart), and the affected tests.
- **DC-3 proposed:** evaluate deleting empty `OutboxAdapter`.
  **Implemented:** deleted `OutboxAdapter` from [service_adapters.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/service_adapters.dart). Kept `Outbox` itself because active sync-engine tests still build fake `Outbox` implementations.
- **AD-1 / DD-1 proposed:** remove the stale `sync_engine_drains.dart` comment.
  **Implemented:** removed the dead reference from [core_audit_sync_module.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/features/audit/services/core_audit_sync_module.dart).
- **DC-1 proposed:** remove dead blank lines in `sync_engine.dart`.
  **Implemented:** trimmed the redundant whitespace in [sync_engine.dart](C:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/sync_engine.dart).

## Verification Handoff
- Re-run:
  - `flutter analyze lib/_shared/database/dao/submission_dao.dart lib/features/audit/manager/history_manager.dart lib/features/audit/manager/audit_manager.dart lib/_shared/services/service_adapters.dart lib/features/audit/services/core_audit_sync_module.dart lib/_shared/services/sync_engine.dart`
  - `flutter test test/features/audit/manager/history_manager_local_overrides_test.dart --reporter=expanded`
  - `flutter test test --reporter=expanded`
- No `git diff` check was run because the active workflow also forbids the agent from executing `git` commands.

<test_trace>
`flutter test test --reporter=expanded`

`00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart`
`00:06 +88: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/manager/history_manager_local_overrides_test.dart: HistoryManager_LoadHistory_HydratesLocalDraftAndOutboxMetadataWithoutManagerDbAccess`
`00:55 +397: All tests passed!`
</test_trace>

<forensic_evidence>
- `flutter analyze ...submission_dao.dart ...history_manager_local_overrides_test.dart` → `No issues found! (ran in 6.4s)`
- `flutter test test/features/audit/manager/history_manager_local_overrides_test.dart --reporter=expanded` → `All tests passed!`
- `flutter test test/features/audit/manager/history_manager_gc_test.dart --reporter=expanded` → `All tests passed!`
- `flutter analyze ...audit_manager.dart ...audit_manager_offline_test.dart` → `No issues found! (ran in 2.7s)`
- `cmd /c python .agents/scripts/verify_workflow.py "C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\task_20260502_170257_380021a1_audit_batch2_layer_violations_dead_code.md"` initially failed until the tracker was checked off and the artifact inventory header was corrected.
</forensic_evidence>

## Gotcha Protocol
- Proposed `lib/features/audit/manager/GEMINI.md` note: `HistoryManager` must never read `DatabaseService().db` or raw Drift tables for local override hydration. Keep template/store/draft metadata lookups inside `SubmissionDao` so managers stay on the business-logic layer.

## Strict Implementation Constraints & Human Reminders
- Keep the cleanup scoped to AD-2, AD-1, DD-1, DC-1, DC-2, and DC-3 from the Sentinel audit.
- Do not rewrite unrelated sync-engine or audit flows while fixing this batch.
- Preserve the existing legacy test seams if they are still referenced by active tests.
