## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_125300_baca184a_test_coverage_phase_4.md`

## Summary
I have implemented the test coverage backfill for Phase A: `AppLifecycleManager` (Step 9 of the consolidated plan).

### Tests Written
- **TC-09-01**: Verified `< 5 mins` boundary triggers no callbacks.
- **TC-09-02**: Verified `Exactly 5 mins` boundary triggers `onAuthCheck`.
- **TC-09-03**: Verified `5 mins - 12 hours` boundary triggers `onAuthCheck`.
- **TC-09-04**: Verified `Exactly 12 hours` boundary triggers `onFullResync`.
- **TC-09-05**: Verified `12 hours - 7 days` boundary triggers `onFullResync`.
- **TC-09-06**: Verified `Exactly 7 days` boundary triggers `onForceReLogin`.
- **TC-09-07**: Verified `> 7 days` boundary triggers `onForceReLogin`.
- **TC-09-08**: Verified debounce cancels pending execution on rapid resumes.

### Modifications
- Added `@visibleForTesting` setter for `_lastPausedAt` in `app_lifecycle_manager.dart` to allow precise time-travel testing without mocking the global dart core clock (which is unsupported without heavy DI changes).
- Used the `fake_async` package to isolate and accelerate the 500ms `_handleResume` debounce.

### Execution Command
The Builder can run these tests via:
```bash
rtk flutter test test/_shared/services/app_lifecycle_manager_test.dart
```

## Decision Log
- Decided to inject `@visibleForTesting` `setLastPausedAt` inside `app_lifecycle_manager.dart` instead of mocking the dart clock, which is not supported natively out of the box for standard `DateTime.now()` without pervasive dependency changes.

## Verification Handoff
Tests have been executed and passed, validating the 4-tier lifecycle constraint matrix.

<forensic_evidence>
<test_trace>
```text
C:\Users\HP\Documents\GitHub\Checkly> rtk flutter test test/_shared/services/app_lifecycle_manager_test.dart
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/app_lifecycle_manager_test.dart
00:00 +8: All tests passed!
```
</test_trace>
</forensic_evidence>
