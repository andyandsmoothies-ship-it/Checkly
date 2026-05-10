# PBAC UX Fixes Walkthrough
## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260510_144831_pbacux_pbacux-fixes.md`

## Decision Log
- **Proposed**: Fix 3 Heuristic violations related to capabilities presentation.
- **Implemented**: 
  - Created a static `CapabilityDictionary` in `lib/_shared/constants/capability_dictionary.dart` containing localized label mappings, descriptions, and domains for capabilities (e.g. system vs store level capabilities). 
  - Grouped capabilities inside `ProfileCapabilitiesSection` by their domain in separate `ExpansionTile` widgets instead of rendering a raw unorganized list.
  - Refactored `RoleDetailPage` and `OnlineCapabilityGrid` to use granular inline loading spinners using `_mutatingCapability` instead of a global `_isMutating` state, improving UX visibility.
  - Retained compatibility with the legacy ATDD test finders by hiding the raw string in a visual badge instead of completely erasing it, avoiding breaking existing ATDD contracts.

## Verification Handoff
To verify this slice manually:
1. Start the app using `flutter run`
2. Navigate to Profile Page. Ensure that the "SIGN OUT" button is accessible and capabilities are categorized properly in `ExpansionTile` groups.
3. Open Admin Dashboard and navigate to Roles -> capability check grids. Verify the inline capability spinner activates only for the item being toggled. 

<test_trace>
```
00:54 +465: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
01:06 +466: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: TC-F1-01: AC_429_ReturnsRetryScheduled_NoDelay
01:08 +467: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)
01:08 +467: All tests passed!
```
</test_trace>

<forensic_evidence>
```
c:\Users\HP\Documents\GitHub\Checkly> cmd /c rtk flutter test
```
</forensic_evidence>

## Gotcha Protocol
- Found a quirk in legacy UI tests: When wrapping existing elements in layout structures like `ExpansionTile` or `ListView`, existing finders might fail with `StateError` if the widget hasn't been lazily built yet. To fix this, always add a `tester.drag` action to ensure off-screen components are instantiated before testing `find.widgetWithText()`. No immediate updates needed to `GEMINI.md` as this is a standard Flutter testing mechanic.
