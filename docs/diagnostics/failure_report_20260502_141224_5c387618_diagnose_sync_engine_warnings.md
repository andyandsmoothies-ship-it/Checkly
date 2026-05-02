# Failure Report: SyncEngine Static Analysis Warnings

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\verification_20260502_133600_380021a1_verify_deepen_sync_engine_plugin_slice_c.md`

## Root Cause
During the Slice C extraction where `sync_engine_drains.dart` and legacy DAO parameters were deleted from `SyncEngine`, several dependencies and private helper functions within `SyncEngine` became unreferenced. In addition, integration tests that were manually injecting mock DAOs (such as `program_outbox_dao.dart`) no longer need these imports because `SyncEngine` now only requires a `List<SyncModule>`. A mock API class `_409RiskApi` was also flagged for violating Dart's `camel_case_types` naming convention.

## Explicit Code Trace (Premises + Proof)
The output of `rtk flutter analyze` highlights exactly 15 dead code lines:
1. `lib/_shared/services/sync_engine.dart`: `dart:convert`, `drift.dart`, `meta.dart` are unused imports.
2. `lib/_shared/services/sync_engine.dart`: `_backoffDelays` and `_scheduleRetry` are unused since backoff logic moved to `BaseSyncModule`.
3. `test/_shared/services/sync_engine_hardening_test.dart`: `program_outbox_dao.dart` is an unused import.
4. `test/_shared/services/sync_engine_push_test.dart`: `program_outbox_dao.dart` is an unused import, and local variable `fakeOutbox` is unused.
5. `test/features/action_plans/sync_engine_action_plan_stale_state_test.dart`: `program_outbox_dao.dart` unused.
6. `test/features/global_risks/sync_engine_global_risks_test.dart`: `program_outbox_dao.dart` unused.
7. `test/shared/services/sync_engine_backoff_test.dart`: `program_outbox_dao.dart` unused, and `_409RiskApi` violates naming rules.
8. `test/sync_engine_test.dart`: `program_outbox_dao.dart` unused, and `_FakeActionPlanApi`, `_FakeActionPlanOutboxDao` are unused private classes.

## Proposed Scope-Limited Fix
- **Action**: Delete all unreferenced imports, variables, and private declarations explicitly called out by the analyzer.
- **Action**: Rename `_409RiskApi` to `_ConflictRiskApi` to satisfy the linter.
- **Trade-offs / Pros & Cons**:
  - *Pros*: Achieving 0 warnings is required for CI to pass and ensures the codebase remains clean.
  - *Cons*: None. These are purely static analysis artifacts and dead code. There is no runtime behavior change.

<forensic_evidence>
```text
warning - Unused import: 'dart:convert' - lib\_shared\services\sync_engine.dart:2:8 - unused_import
warning - Unused import: 'package:drift/drift.dart' - lib\_shared\services\sync_engine.dart:3:8 - unused_import
warning - Unused import: 'package:meta/meta.dart' - lib\_shared\services\sync_engine.dart:4:8 - unused_import
warning - The declaration '_backoffDelays' isn't referenced - lib\_shared\services\sync_engine.dart:16:17 - unused_element
warning - The declaration '_scheduleRetry' isn't referenced - lib\_shared\services\sync_engine.dart:143:8 - unused_element
warning - Unused import: 'package:checkly/_shared/database/dao/program_outbox_dao.dart' - test\_shared\services\sync_engine_hardening_test.dart:13:8 - unused_import
warning - Unused import: 'package:checkly/_shared/database/dao/program_outbox_dao.dart' - test\_shared\services\sync_engine_push_test.dart:13:8 - unused_import
warning - The value of the local variable 'fakeOutbox' isn't used - test\_shared\services\sync_engine_push_test.dart:133:13 - unused_local_variable
warning - Unused import: 'package:checkly/_shared/database/dao/program_outbox_dao.dart' - test\features\action_plans\sync_engine_action_plan_stale_state_test.dart:13:8 - unused_import
warning - Unused import: 'package:checkly/_shared/database/dao/program_outbox_dao.dart' - test\features\global_risks\sync_engine_global_risks_test.dart:15:8 - unused_import
warning - Unused import: 'package:checkly/_shared/database/dao/program_outbox_dao.dart' - test\shared\services\sync_engine_backoff_test.dart:21:8 - unused_import
   info - The type name '_409RiskApi' isn't an UpperCamelCase identifier - test\shared\services\sync_engine_backoff_test.dart:81:7 - camel_case_types
warning - Unused import: 'package:checkly/_shared/database/dao/program_outbox_dao.dart' - test\sync_engine_test.dart:26:8 - unused_import
warning - The declaration '_FakeActionPlanApi' isn't referenced - test\sync_engine_test.dart:155:7 - unused_element
warning - The declaration '_FakeActionPlanOutboxDao' isn't referenced - test\sync_engine_test.dart:186:7 - unused_element
```
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict & Persistent path**: The 15 warnings are leftover dead code from the successful architectural migration. Located in `docs/diagnostics/failure_report_20260502_141224_5c387618_diagnose_sync_engine_warnings.md`.
2. **The required fix and its blast radius**: Delete unused imports and elements, and rename one test class. The blast radius is zero as this touches no executing code.
3. **AI Agent Mission Brief**: Sweep `sync_engine.dart` and the 6 associated test files to remove the unused imports and elements listed in the analyzer output, and rename `_409RiskApi` to `_ConflictRiskApi`.
4. **Execution Queue**:
- [ ] `@[/implement] docs/diagnostics/failure_report_20260502_141224_5c387618_diagnose_sync_engine_warnings.md`
