# Diagnostics Report: Override Warnings in Sync Tests

## Input Lineage
- **Source Input**: Multiple test files including `test/_shared/services/sync_engine_hardening_test.dart` and 4 others.

## Root Cause
The `SyncApi` abstract class (`lib/_shared/services/sync_api.dart`) was previously refactored—most likely during the extraction of Program-specific syncing out of the core module—which removed the `pushProgramEvidence` and `pushProgramPhoto` methods from its contract. 

However, several test files across the repository utilize manual mock classes (e.g., `FakeSyncApi`, `FakeSyncApiFailingSubmissions`) that implement `SyncApi`. These mocks were not updated during the refactoring and still retain the `@override` annotations above those now-deleted methods. The Dart compiler correctly flags this as a warning because the methods they claim to override no longer exist in the superclass.

Additionally, `tools/checkly_lints/lib/checkly_lints.dart` contains a boilerplate `// TODO: Export any libraries...` comment which the analyzer flags as an `info` warning.

## Explicit Code Trace (Premises + Proof)
- **Premise 1**: The compiler error states `The method doesn't override an inherited method.` at the lines where `pushProgramEvidence` is defined in test files.
- **Premise 2**: Looking at `lib/_shared/services/sync_api.dart`, the contract only defines `pushSubmission`, `pullDeltas`, `pullGlobalRisks`, `pushSubmissionRisk`, and `pullProgramAssignments`. The program push methods are missing.
- **Proof (Micro-Experiment)**: I stripped the `@override` annotations from `test/_shared/services/sync_engine_hardening_test.dart` (lines 63 and 69) and ran `dart analyze`. The file compiled successfully with `No issues found!`, proving this is solely a stale annotation issue on dead test code.

<forensic_evidence>
```bash
> grep_search "pushProgramEvidence"
test/features/global_risks/sync_engine_global_risks_test.dart
test/sync_engine_test.dart
test/_shared/services/sync_engine_push_test.dart
test/_shared/services/sync_engine_hardening_test.dart
test/_shared/services/sync_engine_backoff_test.dart
test/features/action_plans/sync_engine_action_plan_stale_state_test.dart

> cmd /c dart analyze test\_shared\services\sync_engine_hardening_test.dart
Analyzing sync_engine_hardening_test.dart...
No issues found!
```
</forensic_evidence>

## Proposed Scope-Limited Fix
The fix requires scrubbing the dead code from the test fakes. 

Since `pushProgramEvidence` and `pushProgramPhoto` are no longer part of `SyncApi`, we shouldn't just remove the `@override` tag—we should **delete the methods entirely** from the manual `FakeSyncApi` implementations to prevent future confusion. For the boilerplate TODO in `checkly_lints.dart`, simply deleting the comment resolves the info warning.

**Files to Target:**
1. `test/features/global_risks/sync_engine_global_risks_test.dart`
2. `test/sync_engine_test.dart`
3. `test/_shared/services/sync_engine_push_test.dart`
4. `test/_shared/services/sync_engine_backoff_test.dart`
5. `test/features/action_plans/sync_engine_action_plan_stale_state_test.dart`
6. `tools/checkly_lints/lib/checkly_lints.dart`

### Trade-offs / Pros & Cons
- **Pros:** Reaches "Zero Warnings" across the repository. Eliminates dead code inside test doubles.
- **Cons:** None. This is a pure cleanup of dead mock logic with zero impact on production behavior or test outcomes.

## Handoff Block
1. **Final Diagnostic Verdict:** The warnings are caused by architectural drift in test doubles; manual fakes were not updated when the core `SyncApi` interface dropped two methods.
2. **Fix & Blast Radius:** The fix is to delete `pushProgramEvidence` and `pushProgramPhoto` from all `SyncApi` fakes in the 5 test files, and delete the TODO comment in the lints package. The blast radius is completely contained to the test suite and tooling.
3. **AI Agent Mission Brief:** The Builder agent must delete the dead `pushProgramEvidence` and `pushProgramPhoto` methods from `FakeSyncApi` classes across the identified test files to clear compiler warnings.

### Execution Queue
- [ ] @[/implement] docs/diagnostics/failure_report_20260512_193024_d8e4b1_override_warnings.md
