# Walkthrough: Override Warnings Fixes

## Slice 1: Diagnostic Cleanup

### Narrative
The goal of this slice was to resolve several compiler warnings indicating dead methods and stale `@override` annotations within the Flutter test suite, as well as a single `TODO` comment warning inside the `checkly_lints` package. The warnings arose due to previous backend refactoring that updated the `SyncApi` abstraction without correspondingly updating the manual fakes used in the test layer. 

### Changes Implemented
1. **Removed `pushProgramEvidence` and `pushProgramPhoto` methods:**
   * These were entirely deleted from all `FakeSyncApi` (and related `FailingApi`) implementations across the project, as they no longer exist in the actual `SyncApi` interface.
   * **Targeted Files:**
     * `test/_shared/services/sync_engine_push_test.dart`
     * `test/_shared/services/sync_engine_hardening_test.dart`
     * `test/_shared/services/sync_engine_backoff_test.dart`
     * `test/sync_engine_test.dart`
     * `test/features/action_plans/sync_engine_action_plan_stale_state_test.dart`
     * `test/features/global_risks/sync_engine_global_risks_test.dart`

2. **Resolved Linter INFO Warning:**
   * Removed an unaddressed boilerplate `TODO` comment (`// TODO: Export any libraries intended for clients of this package.`) in `tools/checkly_lints/lib/checkly_lints.dart` that was raising an info warning.

### Verifications & Testing
- Ran `dart analyze test` which successfully passed with zero issues.
- Ran `dart analyze tools/checkly_lints` which successfully passed with zero issues.
- Ran a global `dart analyze lib` which also passed with zero issues, confirming a completely clean compilation slate repository-wide.

The codebase is now fully synchronized with its interfaces and zero warnings remain on the frontend.
