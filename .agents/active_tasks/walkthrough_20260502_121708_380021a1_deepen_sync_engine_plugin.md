# Walkthrough: SyncEngine Plugin Core (Slice A)

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\380021a1-971d-4e8c-9176-f987983e9812\implementation_plan_20260501_232410_380021a1_deepen_sync_engine_plugin.md`

## Strict Implementation Constraints & Human Reminders
- Scope is locked to Slice A only.
- The backoff helper from the prior plan is a hard pre-condition and remains the shared source of truth for retry behavior.
- Existing unsliced callers must keep compiling; Slice A cannot break the legacy constructor path before Slice B and Slice C exist.

## Decision Log
- **Proposed:** implement the new `SyncModule`/`BaseSyncModule` contract and refactor `SyncEngine` into a module orchestrator.
- **Constraint discovered:** the epic plan assumes later slices will immediately delete `sync_engine_drains.dart` and migrate all callers, but the user requested Slice A only. Deleting the legacy path in this session would break the existing app wiring and unsliced tests.
- **Implemented:** added `lib/_shared/services/sync_module.dart` with `SyncModule` plus `BaseSyncModule.processQueue<T>()`, and refactored `lib/_shared/services/sync_engine.dart` to support module mode (`modules: [...]`) while preserving legacy mode behind the existing DAO/API constructor.
- **Orchestration behavior:** module execution is sorted by ascending `priority`, checks connectivity between `executePull()` and `executePush()`, and sets `SyncState.error` when a module throws.
- **Compatibility choice:** retained `part 'sync_engine_drains.dart'` and the legacy drain chain for unsliced domains. This keeps full-suite compatibility while still satisfying the new plugin-core tests.
- **Supportability:** modified files remain small. `sync_engine.dart` is 238 lines and `sync_module.dart` is 69 lines.

## Verification Handoff
- Run `flutter analyze lib/_shared/services/sync_engine.dart lib/_shared/services/sync_module.dart`.
- Run `flutter test test/_shared/services/sync_engine_plugin_test.dart --reporter=expanded`.
- Run `flutter test test --reporter=expanded`.
- Do not start Slice B by deleting the legacy constructor or `sync_engine_drains.dart` until the feature modules and DI migration are ready in the same sequence.

<test_trace>
```text
flutter test test/_shared/services/sync_engine_plugin_test.dart --reporter=expanded
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/sync_engine_plugin_test.dart
00:00 +0: SyncEngine Plugin Architecture TC-PLUGIN-1: SyncEngine_EmptyModuleList_CompletesWithoutError
00:00 +1: SyncEngine Plugin Architecture TC-PLUGIN-2: SyncEngine_PullPhase_ExecutesAllModulesInPriorityOrder
00:00 +2: SyncEngine Plugin Architecture TC-PLUGIN-3: SyncEngine_PushPhase_ModuleThrows_SetsErrorState
00:00 +3: SyncEngine Plugin Architecture TC-PLUGIN-4: SyncEngine_OfflineCheck_BetweenModules_AbortsLoop
00:00 +4: All tests passed!

flutter test test --reporter=expanded
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart
00:49 +396: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)
00:50 +396: All tests passed!
```
</test_trace>

<forensic_evidence>
```text
flutter analyze lib/_shared/services/sync_engine.dart lib/_shared/services/sync_module.dart
Analyzing 2 items...
No issues found! (ran in 0.7s)

rg -n 'fail\(''Implement|fail\("Implement' test lib
[no matches; rg exited 1]

File size checks:
sync_engine.dart -> 238 lines
sync_module.dart -> 69 lines
```
</forensic_evidence>

## Gotcha Protocol
- No new domain rule was discovered that warrants a `GEMINI.md` update.
- Flutter verification still requires elevated execution because the SDK writes to `C:\Users\HP\flutter\bin\cache\lockfile`.
