# Walkthrough: Duolingo Reskin Slice 2 - Core Primitives

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260521_202100_ds01_duolingo_reskin.md`

## Decision Log
- **BubblyButton**: 
  - *Proposed*: Bubbly 3D button that animates and shrinks by 4px on press. Renders a solid bottom border in a darker shade of the fill color.
  - *Implemented*: Designed `BubblyButton` as a `StatefulWidget` leveraging `GestureDetector` + `AnimatedPositioned` inside a `Stack` (shadow on bottom, button face on top). A 4px press animation triggers dynamically on tap down. The 3D shadow color is calculated at runtime by lerping the base color by `0.25` towards black, ensuring full compatibility with any customized brand color.
- **StrokeCard**: 
  - *Proposed*: Zero-elevation card with 2px Swan border, R: 16px.
  - *Implemented*: Created `StrokeCard` using standard `Card` widget with border configurations. If `onTap` is provided, it incorporates a clipping `InkWell` layout to support interactive ink ripple effects.
- **QuestProgressBar**: 
  - *Proposed*: Macaw Blue progress filling.
  - *Implemented*: Built `QuestProgressBar` using `LayoutBuilder` and implicitly animated `AnimatedContainer` (easing: Curves.easeOutCubic) for ultra-smooth transitions. Added a premium glass highlight reflection pill at the top of the fill layer for bubbly aesthetics.
- **Primitives Barrel**:
  - *Proposed*: Create `primitives.dart` barrel file.
  - *Implemented*: Added `lib/_shared/widgets/primitives/primitives.dart` exporting the three widgets.

## Verification Handoff
To verify this slice, QA should build or hot-reload the application and manually execute:
1. Tap any `BubblyButton` to confirm the 3D shrink action moves the button down 4px dynamically.
2. Verify `StrokeCard` renders with 0 elevation and high contrast borders (Swan color, width 2px).
3. Push progress updates to `QuestProgressBar` to verify the bar animates smoothly using cubic easing curves and shows the gloss reflection bar.

## Gotcha Protocol
Proposed additions to `lib/GEMINI.md`:
* **BubblyButton Size & Constraints**: Always wrap `BubblyButton` in layout constraints or specify container boundaries, as it defaults to `width: double.infinity` to align with the core grid.
* **QuestProgressBar Scale Clamp**: Value parameter is clamped internally. Do not write manual clamping layers outside it.

<test_trace>
00:45 +563: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:46 +564: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
00:48 +565: C:/Users/HP/Documents/GitHub/Checkly/test/_shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
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
