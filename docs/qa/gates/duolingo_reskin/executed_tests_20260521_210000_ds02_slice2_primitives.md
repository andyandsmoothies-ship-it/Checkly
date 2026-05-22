# Test Log: Duolingo Reskin Slice 2 - Core Primitives
Executed At: 2026-05-21T21:05:00+07:00

## Compiled Status
- **Static Analysis (`rtk flutter analyze`)**: PASS (0 issues found)
- **Unit Tests Execution (`rtk flutter test`)**: PASS (568/568 tests passed)

## Primitive Specific Tests Passed
- **BubblyButton**:
  - `BB-01: Renders label text correctly` -> PASS
  - `BB-02: Triggers onPressed callback on tap` -> PASS
  - `BB-03: Renders loading indicator instead of text when isLoading is true` -> PASS
- **StrokeCard**:
  - `SC-01: Renders children successfully` -> PASS
  - `SC-02: Renders as standard Card with zero elevation and Swan border` -> PASS
  - `SC-03: Interactivity works when onTap is provided` -> PASS
- **QuestProgressBar**:
  - `QP-01: Progress clamps values correctly` -> PASS
  - `QP-02: Renders gloss highlight inside when progress is above 5%` -> PASS
  - `QP-03: Does not render gloss highlight when progress is 0` -> PASS

<test_trace>
00:45 +563: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:46 +564: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: Network crash prevents subsequent uploads
00:50 +566: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_backoff_test.dart: AC12: PhotoQueue_FourthFailure_SetsExhausted
00:52 +567: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: TC-F1-01: AC_429_ReturnsRetryScheduled_NoDelay
01:00 +568: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: (tearDownAll)
01:00 +568: All tests passed!
</test_trace>

<forensic_evidence>
rtk flutter analyze
Analyzing Checkly...
No issues found! (ran in 37.4s)
</forensic_evidence>
