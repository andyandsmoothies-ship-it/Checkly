# Walkthrough: SyncModules Implementation (Slice B)

## Context
This artifact covers the completion of **Slice B** of the SyncEngine plugin refactor, continuing the work from the initial BaseSyncModule (Slice A). The goal was to dismantle the monolithic `sync_engine_drains.dart` and extract its domain-specific responsibilities into fully encapsulated `SyncModule` implementations.

## What was built

We created three new SyncModules:

1.  **`CoreAuditSyncModule`** (`lib/features/audit/services/core_audit_sync_module.dart`):
    *   **Priority:** 10
    *   **Responsibility:** Pulling Audit global risks and deltas, then draining local pending submissions and pending risks.
2.  **`ActionPlanSyncModule`** (`lib/features/action_plans/services/action_plan_sync_module.dart`):
    *   **Priority:** 20
    *   **Responsibility:** Draining local Action Plan evidence.
3.  **`ProgramSyncModule`** (`lib/features/programs/services/program_sync_module.dart`):
    *   **Priority:** 30
    *   **Responsibility:** Pulling program assignments, draining program evidence and program photos.

### Key Architectural Wins

*   **Plugin Ready**: Each module implements the `SyncModule` interface, allowing the future `SyncEngine` (Slice C) to loop over an injected `List<SyncModule>` dynamically sorted by `priority`.
*   **Encapsulation**: Domain-specific logic is now owned by the domains. `CoreAuditSyncModule` sits in `features/audit/services`, completely abstracting its persistence and retry logic away from the core orchestrator.
*   **Zero Logic Change**: We meticulously ensured the backoff mechanics (`processQueue<T>`), payload generation, and DAO interactions remain functionally identical to `sync_engine_drains.dart`.
*   **Type Safety**: Handled aliasing conflicts between the Drift database (`app_database.g.dart`) and API representations, ensuring the `BaseSyncModule.processQueue<T>` algorithm operates with precise database types (`db.PendingSubmission`, `db.PendingProgramPhoto`, etc.).

## Verification
*   `flutter analyze lib/features/` passes successfully.
*   `flutter test test/features/` passes successfully with all 246 tests green. No downstream feature tests were broken during the extraction.

## Decision Log
- Retained identically named internal methods like `_pullDeltas()` inside `CoreAuditSyncModule` to make diff comparisons during migration crystal clear, preventing scope creep and proving exactly what moved.
- Left the original `sync_engine_drains.dart` file fully intact and connected to `SyncEngine`. This ensures that even though Slice B implemented the replacement modules, zero tests break because the system defaults to the legacy constructor until Slice C flips the switch.

## Verification Handoff
Execute `rtk flutter analyze lib/features/` and `rtk flutter test test/features/` to verify that the extracted modules compile correctly and don't introduce regressions into any feature scopes.

<test_trace>
00:15 +246: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: (tearDownAll)
00:15 +246: All tests passed!

Exit code: 0
</test_trace>

<forensic_evidence>
Analyzing features...
No issues found!
</forensic_evidence>

## Next Steps
This concludes Slice B. Next up is **Slice C (DI Wiring + Test Migration)**, where we will:
1. Delete the legacy `sync_engine_drains.dart`.
2. Register the modules in `locator.dart`.
3. Update `SyncEngine` to accept `List<SyncModule>`.
4. Migrate all 8 integration/unit tests to mock and assert against the new module structure directly.
