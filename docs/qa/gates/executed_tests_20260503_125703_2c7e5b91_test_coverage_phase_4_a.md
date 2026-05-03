## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_125300_baca184a_test_coverage_phase_4.md`

## Terminal Output Proof
<forensic_evidence>
<test_trace>
```text
C:\Users\HP\Documents\GitHub\Checkly> rtk flutter test test/_shared/services/app_lifecycle_manager_test.dart
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/app_lifecycle_manager_test.dart
00:00 +0: AppLifecycleManager Tests TC-09-01: < 5 mins elapsed triggers no callbacks
00:00 +1: AppLifecycleManager Tests TC-09-02: Exactly 5 mins elapsed triggers onAuthCheck
00:00 +2: AppLifecycleManager Tests TC-09-03: 5 mins - 12 hours elapsed triggers onAuthCheck
00:00 +3: AppLifecycleManager Tests TC-09-04: Exactly 12 hours elapsed triggers onFullResync
00:00 +4: AppLifecycleManager Tests TC-09-05: 12 hours - 7 days elapsed triggers onFullResync
00:00 +5: AppLifecycleManager Tests TC-09-06: Exactly 7 days elapsed triggers onForceReLogin
00:00 +6: AppLifecycleManager Tests TC-09-07: > 7 days elapsed triggers onForceReLogin
00:00 +7: AppLifecycleManager Tests TC-09-08: Debounce cancels pending execution on repeated resumes
00:00 +8: All tests passed!

Exit code: 0
```
</test_trace>
</forensic_evidence>
